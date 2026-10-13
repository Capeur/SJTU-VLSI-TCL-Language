// Runs every snippet marked runs_in=playground through the REAL browser engine (Wacl, Tcl 8.6.6)
// in headless Chrome, using the same worker.js that learners get. This catches code that passes on
// tclsh 8.6.17 / 9.0 but fails on Wacl 8.6.6 (PRD §16 risk). Run `npm run snippets:extract` first.
// Chrome: set CHROME=/path/to/chrome (defaults to google-chrome / chromium on PATH locations).
import fs from 'node:fs';
import http from 'node:http';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import puppeteer from 'puppeteer-core';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const snipDir = path.join(root, 'snippets');
const publicDir = path.join(root, 'public');
const TIMEOUT_MS = 8000;

const chrome = [process.env.CHROME, '/usr/bin/google-chrome', '/usr/bin/google-chrome-stable', '/usr/bin/chromium', '/usr/bin/chromium-browser']
    .find((p) => p && fs.existsSync(p));
if (!chrome) { console.error('run-wacl-snippets: no Chrome found; set CHROME=/path/to/chrome'); process.exit(2); }

const norm = (t) => t.replace(/\r/g, '').split('\n').map((l) => l.trimEnd()).join('\n').trimEnd();

const jobs = [];
for (const page of fs.readdirSync(snipDir, { withFileTypes: true }).filter((d) => d.isDirectory())) {
    for (const file of fs.readdirSync(path.join(snipDir, page.name)).filter((f) => f.endsWith('.tcl')).sort()) {
        const base = path.join(snipDir, page.name, file.replace(/\.tcl$/, ''));
        const read = (ext) => (fs.existsSync(base + ext) ? fs.readFileSync(base + ext, 'utf8') : undefined);
        if (read('.runs_in')?.trim() !== 'playground') continue;
        if (read('.only') !== undefined && read('.only').trim() !== '8.6') continue;   // Wacl is Tcl 8.6.6
        if (fs.existsSync(base + '.drvlite')) continue;                                // DRV-Lite arrives in P5
        jobs.push({ name: `${page.name}/${file}`, code: read('.tcl'), expected: read('.expected') });
    }
}
console.log(`Running ${jobs.length} playground snippet(s) in Wacl (headless Chrome)`);
if (jobs.length === 0) process.exit(0);

// Tiny static server: workers need http(s), not file://.
const server = http.createServer((req, res) => {
    const url = decodeURIComponent(req.url.split('?')[0]);
    if (url === '/') { res.setHeader('content-type', 'text/html'); res.end('<!doctype html><title>wacl</title>'); return; }
    const file = path.join(publicDir, url);
    if (!file.startsWith(publicDir) || !fs.existsSync(file) || fs.statSync(file).isDirectory()) { res.statusCode = 404; res.end(); return; }
    res.end(fs.readFileSync(file));
});
await new Promise((r) => server.listen(0, '127.0.0.1', r));
const origin = `http://127.0.0.1:${server.address().port}`;

const browser = await puppeteer.launch({ executablePath: chrome, headless: true, args: ['--no-sandbox'] });
const page = await browser.newPage();
await page.goto(origin);
await page.evaluate((workerUrl) => {
    window.__start = () => new Promise((resolve, reject) => {
        const w = new Worker(workerUrl);
        window.__w = w;
        w.onmessage = (e) => { if (e.data.ready) resolve(); else if (e.data.fatal) reject(new Error(e.data.fatal)); };
        w.onerror = (e) => reject(new Error(e.message));
    });
    window.__run = (code, timeoutMs) => new Promise((resolve) => {
        const timer = setTimeout(() => { window.__w.terminate(); resolve({ timedOut: true }); }, timeoutMs);
        window.__w.onmessage = (e) => { clearTimeout(timer); resolve(e.data); };
        window.__w.postMessage({ id: 1, code });
    });
}, `${origin}/wacl/worker.js`);
await page.evaluate(() => window.__start());

let pass = 0, fail = 0;
for (const job of jobs) {
    const reply = await page.evaluate((code, t) => window.__run(code, t), job.code, TIMEOUT_MS);
    let problem = null;
    if (reply.timedOut) { problem = `timed out after ${TIMEOUT_MS} ms`; await page.evaluate(() => window.__start()); }
    else if (!reply.ok) problem = `Tcl error in Wacl: ${reply.error}`;
    else if (job.expected !== undefined && norm(reply.stdout) !== norm(job.expected)) {
        problem = `expected ${JSON.stringify(norm(job.expected))} but Wacl printed ${JSON.stringify(norm(reply.stdout))}`;
    }
    if (problem) { fail++; console.log(`FAIL ${job.name}: ${problem}`); } else { pass++; console.log(`ok   ${job.name}`); }
}
await browser.close();
server.close();
console.log(`RESULT: ${fail === 0 ? 'PASS' : 'FAIL'} ${pass} passed, ${fail} failed (Wacl, Tcl 8.6.6)`);
process.exit(fail ? 1 : 0);
