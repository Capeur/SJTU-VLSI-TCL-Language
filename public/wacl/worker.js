/* Web Worker host for Wacl (Tcl 8.6.6 in WebAssembly).
 * Wacl is packaged as an AMD module for require.js and expects `window`.
 * We load its text, drop the one `delete window.Module` call, and give it
 * tiny `define`/`require` shims. Running in a worker lets the page kill a
 * runaway script (PRD §7 "hard timeout"). Protocol:
 *   in : { id, code }          out: { id, ok, stdout, stderr, result, error }
 *   out (once): { ready: true } or { fatal: "message" }
 * Before every message the interpreter is reset (globals, procs and namespaces created by an
 * earlier run are deleted), and after it any partial output line is flushed.
 */
'use strict';
var base = self.location.href.replace(/[^/]*$/, '');
var waclInterp = null;
var outBuf = [];
var errBuf = [];
var ttyOut = null;   // Emscripten's stdout/stderr line buffers, captured by the patch below
var ttyErr = null;

// Tcl run before every script so one run cannot see variables, procs or namespaces from another.
var RESET_SCRIPT =
    'foreach __v [info vars ::*] { if {[lsearch -exact $::__keepVars $__v] < 0} { catch {unset $__v} } }\n' +
    'foreach __p [info procs ::*] { if {[lsearch -exact $::__keepProcs $__p] < 0} { catch {rename $__p {}} } }\n' +
    'foreach __n [namespace children ::] { if {[lsearch -exact $::__keepNs $__n] < 0} { catch {namespace delete $__n} } }\n' +
    'unset -nocomplain __v __p __n';
var SNAPSHOT_SCRIPT =
    'set ::__keepVars [concat [info vars ::*] ::__keepVars ::__keepProcs ::__keepNs]\n' +
    'set ::__keepProcs [info procs ::*]\n' +
    'set ::__keepNs [namespace children ::]';

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
            interp.stdout = function (line) { outBuf.push(line); };
            interp.stderr = function (line) { errBuf.push(line); };
            waclInterp = interp;
            interp.Eval(SNAPSHOT_SCRIPT);
            self.postMessage({ ready: true });
        });
    })
    .catch(function (e) { self.postMessage({ fatal: String(e) }); });

self.onmessage = function (event) {
    var msg = event.data;
    if (!waclInterp) {
        self.postMessage({ id: msg.id, ok: false, stdout: '', stderr: '', error: 'Tcl is not ready yet.' });
        return;
    }
    try { waclInterp.Eval(RESET_SCRIPT); } catch (e) { /* a failed reset must not block the run */ }
    outBuf = [];
    errBuf = [];
    var reply = { id: msg.id, ok: true, result: '', error: '' };
    try {
        reply.result = waclInterp.Eval(msg.code);
    } catch (e) {
        reply.ok = false;
        reply.error = (e && e.errorInfo) ? String(e.errorInfo) : String(e);
    }
    try { waclInterp.Eval('flush stdout; flush stderr'); } catch (e) { /* channel closed by the script */ }
    drainTty(self.__ttyOut, outBuf);
    drainTty(self.__ttyErr, errBuf);
    reply.stdout = outBuf.join('\n');
    reply.stderr = errBuf.join('\n');
    self.postMessage(reply);
};
