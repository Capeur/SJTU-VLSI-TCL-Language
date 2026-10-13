/* Web Worker host for Wacl (Tcl 8.6.6 in WebAssembly).
 * Wacl is packaged as an AMD module for require.js and expects `window`.
 * We load its text, drop the one `delete window.Module` call, and give it
 * tiny `define`/`require` shims. Running in a worker lets the page kill a
 * runaway script (PRD §7 "hard timeout"). Protocol:
 *   in : { id, code }          out: { id, ok, stdout, stderr, result, error }
 *   out (once): { ready: true } or { fatal: "message" }
 */
'use strict';
var base = self.location.href.replace(/[^/]*$/, '');
var waclInterp = null;
var outBuf = [];
var errBuf = [];

self.require = { toUrl: function (p) { return base + p.replace(/^tcl\//, ''); } };
var factory = null;
self.define = function (_name, fn) { factory = fn; };

fetch(base + 'wacl.js')
    .then(function (r) { return r.text(); })
    .then(function (text) {
        text = text.replace('delete window.Module;', '');
        (0, eval)(text);
        var mod = factory();
        mod.onReady(function (interp) {
            interp.stdout = function (line) { outBuf.push(line); };
            interp.stderr = function (line) { errBuf.push(line); };
            waclInterp = interp;
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
    outBuf = [];
    errBuf = [];
    var reply = { id: msg.id, ok: true, result: '', error: '' };
    try {
        reply.result = waclInterp.Eval(msg.code);
    } catch (e) {
        reply.ok = false;
        reply.error = (e && e.errorInfo) ? String(e.errorInfo) : String(e);
    }
    reply.stdout = outBuf.join('\n');
    reply.stderr = errBuf.join('\n');
    self.postMessage(reply);
};
