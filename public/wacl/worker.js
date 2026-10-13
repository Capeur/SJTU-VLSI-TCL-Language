/* Web Worker host for Wacl (Tcl 8.6.6 in WebAssembly).
 * Wacl is packaged as an AMD module for require.js and expects `window`.
 * We load its text, drop the one `delete window.Module` call, and give it
 * tiny `define`/`require` shims. Running in a worker lets the page kill a
 * runaway script (PRD §7 "hard timeout"). Protocol:
 *   in : { id, code }          out: { id, ok, stdout, stderr, result, error, outputLimit, crashed }
 *   out (once): { ready: true } or { fatal: "message" }
 * Before every message the interpreter is reset (globals, procs and namespaces created by an
 * earlier run are deleted), and after it any partial output line is flushed.
 *
 * Two guards keep a runaway script from breaking the page (decision log, P3):
 *  - outputLimit: an execution trace on puts counts the characters printed; past OUTPUT_LIMIT the
 *    next puts fails, which stops the script. The real puts still runs, so its own error messages
 *    are unchanged. The JS side also stops storing lines past the limit.
 *  - crashed: Wacl has a fixed 16 MB heap. A script that outgrows it makes Emscripten abort, after
 *    which this interpreter can never run again. The worker reports crashed and refuses further
 *    work; the page (src/lib/tclRuntime.ts) then terminates it and starts a fresh one on the next run.
 */
'use strict';
var base = self.location.href.replace(/[^/]*$/, '');
var waclInterp = null;
var outBuf = [];
var errBuf = [];
var ttyOut = null;   // Emscripten's stdout/stderr line buffers, captured by the patch below
var ttyErr = null;
var OUTPUT_LIMIT = 50000;   // characters per run, stdout and stderr together
var outChars = 0;
var crashed = false;

// Tcl run before every script so one run cannot see variables, procs or namespaces from another.
var RESET_SCRIPT =
    'foreach __v [info vars ::*] { if {[lsearch -exact $::__keepVars $__v] < 0} { catch {unset $__v} } }\n' +
    'foreach __p [info procs ::*] { if {[lsearch -exact $::__keepProcs $__p] < 0} { catch {rename $__p {}} } }\n' +
    'foreach __n [namespace children ::] { if {[lsearch -exact $::__keepNs $__n] < 0} { catch {namespace delete $__n} } }\n' +
    'unset -nocomplain __v __p __n';
// Installed once, before the snapshot, so the reset keeps it.
var LIMIT_SCRIPT =
    'set ::__waclOut 0\n' +
    'set ::__waclOverflow 0\n' +
    'proc ::__waclCount {command op} {\n' +
    '    incr ::__waclOut [expr {[string length [lindex $command end]] + 1}]\n' +
    '    if {$::__waclOut > ' + OUTPUT_LIMIT + '} {\n' +
    '        set ::__waclOverflow 1\n' +
    '        return -code error -errorcode {WACL OUTPUT_LIMIT} "output limit reached"\n' +
    '    }\n' +
    '}\n' +
    'trace add execution puts enter ::__waclCount';
var SNAPSHOT_SCRIPT =
    'set ::__keepVars [concat [info vars ::*] ::__keepVars ::__keepProcs ::__keepNs]\n' +
    'set ::__keepProcs [info procs ::*]\n' +
    'set ::__keepNs [namespace children ::]';

// Wacl's interp.Eval(code) runs  catch {<code>} ::jsResult  so a brace inside a string in the code
// (puts "{") unbalances that wrapper and the script fails before it starts. So the code is first
// stored in a variable as one double-quoted word in which every special character, braces included,
// is backslash-escaped (backslashes inside braces stop a brace from counting), then evaluated.
function tclWord(text) {
    return '"' + text.replace(/[\\$\[\]"{}]/g, '\\$&') + '"';
}

// An Emscripten abort (out of memory, or Tcl_Panic) is a plain JS error, not a Tcl error object.
function isAbort(e) {
    if (e && e.errorInfo) return false;
    return /abort\(|Cannot enlarge memory|out of memory/i.test(String(e && e.message !== undefined ? e.message : e));
}

function keep(list, line) {
    outChars += line.length + 1;
    if (outChars <= OUTPUT_LIMIT) list.push(line);
}

// Emscripten only hands a line to print() when it sees a newline, so `puts -nonewline x` stays
// hidden in its buffer. Move whatever is left into our output list.
function drainTty(tty, list) {
    if (tty && tty.output && tty.output.length > 0) {
        list.push(new TextDecoder().decode(new Uint8Array(tty.output)));
        tty.output = [];
    }
}

self.require = { toUrl: function (p) { return base + p.replace(/^tcl\//, ''); } };
var factory = null;
self.define = function (_name, fn) { factory = fn; };

fetch(base + 'wacl.js')
    .then(function (r) { return r.text(); })
    .then(function (text) {
        text = text.replace('delete window.Module;', '');
        // Remember the stdout / stderr buffers so drainTty() can reach them.
        text = text.replace('put_char:(function(tty,val){if(val===null||val===10){Module["print"]',
            'put_char:(function(tty,val){self.__ttyOut=tty;if(val===null||val===10){Module["print"]');
        text = text.replace('put_char:(function(tty,val){if(val===null||val===10){Module["printErr"]',
            'put_char:(function(tty,val){self.__ttyErr=tty;if(val===null||val===10){Module["printErr"]');
        (0, eval)(text);
        var mod = factory();
        mod.onReady(function (interp) {
            interp.stdout = function (line) { keep(outBuf, line); };
            interp.stderr = function (line) { keep(errBuf, line); };
            waclInterp = interp;
            interp.Eval(LIMIT_SCRIPT);
            interp.Eval(SNAPSHOT_SCRIPT);
            self.postMessage({ ready: true });
        });
    })
    .catch(function (e) { self.postMessage({ fatal: String(e) }); });

self.onmessage = function (event) {
    var msg = event.data;
    if (crashed) {
        self.postMessage({ id: msg.id, ok: false, stdout: '', stderr: '', error: '', crashed: true });
        return;
    }
    if (!waclInterp) {
        self.postMessage({ id: msg.id, ok: false, stdout: '', stderr: '', error: 'Tcl is not ready yet.' });
        return;
    }
    outBuf = [];
    errBuf = [];
    outChars = 0;
    var reply = { id: msg.id, ok: true, result: '', error: '', outputLimit: false, crashed: false };
    try {
        try { waclInterp.Eval(RESET_SCRIPT + '\nset ::__waclOut 0\nset ::__waclOverflow 0'); } catch (e) { if (isAbort(e)) throw e; }
        try {
            waclInterp.Eval('set ::__waclCode ' + tclWord(msg.code));
            reply.result = waclInterp.Eval('eval [set ::__waclCode][unset ::__waclCode]');
        } catch (e) {
            if (isAbort(e)) throw e;
            reply.ok = false;
            reply.error = (e && e.errorInfo) ? String(e.errorInfo) : String(e);
            // Hide our own wrapper line from the learner; keep Tcl's line number of the error.
            reply.error = reply.error.replace(/\n\s*invoked from within\n"eval \[set ::__waclCode\][\s\S]*$/, '');
        }
        try { waclInterp.Eval('unset -nocomplain ::__waclCode'); } catch (e) { if (isAbort(e)) throw e; }
        try { waclInterp.Eval('flush stdout; flush stderr'); } catch (e) { if (isAbort(e)) throw e; /* channel closed by the script */ }
        drainTty(self.__ttyOut, outBuf);
        drainTty(self.__ttyErr, errBuf);
        var overflow = '0';
        try { overflow = waclInterp.Eval('set ::__waclOverflow'); } catch (e) { if (isAbort(e)) throw e; }
        if (String(overflow) === '1' || outChars > OUTPUT_LIMIT) {
            // The learner sees a friendly message instead of our trace's error.
            reply.outputLimit = true;
            reply.ok = false;
            reply.error = '';
        }
    } catch (e) {
        // Out of memory: this interpreter is dead. Report it; the page starts a fresh worker.
        crashed = true;
        waclInterp = null;
        reply.ok = false;
        reply.crashed = true;
        reply.error = '';
    }
    // After a crash the buffers hold Emscripten's own abort text, which means nothing to a learner.
    reply.stdout = reply.crashed ? '' : outBuf.join('\n');
    reply.stderr = reply.crashed ? '' : errBuf.join('\n');
    self.postMessage(reply);
};
