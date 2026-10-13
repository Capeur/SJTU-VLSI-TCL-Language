// Browser test of the playground guards (decision log, P3), on the BUILT site in headless Chrome:
//   1. while 1 {puts hi}   is stopped by the output limit (fast, not by the 5 s timeout) with a
//      friendly message, and the next normal run in the same playground works;
//   2. a script that runs out of memory (Wacl has a fixed 16 MB heap) shows the crash message, and
//      the next run works without a page reload (the runtime starts a fresh worker);
//   3. after the crash, another component on the page (PredictOutput) shares the fresh engine.
// Run `npm run build` first. Chrome: set CHROME=/path/to/chrome (default: google-chrome / chromium).
// Usage: node scripts/test-playground-limits.mjs
import fs from 'node:fs';
import http from 'node:http';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import puppeteer from 'puppeteer-core';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const dist = path.join(root, 'dist');
const BASE = '/SJTU-VLSI-TCL-Language';
if (!fs.existsSync(path.join(dist, 'demo', 'index.html'))) { console.error('test-playground-limits: run `npm run build` first'); process.exit(2); }
const chrome = [process.env.CHROME, '/usr/bin/google-chrome', '/usr/bin/google-chrome-stable', '/usr/bin/chromium', '/usr/bin/chromium-browser']
    .find((p) => p && fs.existsSync(p));
if (!chrome) { console.error('test-playground-limits: no Chrome found; set CHROME=/path/to/chrome'); process.exit(2); }

const types = { '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript', '.css': 'text/css', '.svg': 'image/svg+xml',
    '.json': 'application/json', '.wasm': 'application/wasm', '.png': 'image/png', '.woff2': 'font/woff2' };
const server = http.createServer((req, res) => {
    let url = decodeURIComponent(req.url.split('?')[0]);
    if (!url.startsWith(BASE)) { res.statusCode = 404; res.end(); return; }
    let file = path.join(dist, url.slice(BASE.length));
    if (fs.existsSync(file) && fs.statSync(file).isDirectory()) file = path.join(file, 'index.html');
    if (!file.startsWith(dist) || !fs.existsSync(file)) { res.statusCode = 404; res.end(); return; }
    res.setHeader('content-type', types[path.extname(file)] ?? 'application/octet-stream');
    res.end(fs.readFileSync(file));
});
await new Promise((r) => server.listen(0, '127.0.0.1', r));
const origin = `http://127.0.0.1:${server.address().port}`;

const browser = await puppeteer.launch({ executablePath: chrome, headless: true, args: ['--no-sandbox'] });
const page = await browser.newPage();
const pageErrors = [];
page.on('pageerror', (e) => pageErrors.push(e.message));
await page.goto(`${origin}${BASE}/demo/`, { waitUntil: 'networkidle0' });

const failures = [];
const check = (ok, what) => { console.log(`${ok ? 'ok  ' : 'FAIL'} ${what}`); if (!ok) failures.push(what); };

// The first playground on the page: type code (as a learner would), press Run, wait for the result.
const box = await page.$('[data-playground]');
await box.scrollIntoView();
await page.waitForFunction((el) => {
    // Hydrated once typing changes the component's state (Reset becomes enabled).
    const ta = el.querySelector('textarea');
    ta.value = `${ta.value} `;
    ta.dispatchEvent(new Event('input', { bubbles: true }));
    return [...el.querySelectorAll('button')].some((b) => b.textContent === 'Reset' && !b.disabled);
}, { timeout: 30000, polling: 250 }, box);

async function runInPlayground(code) {
    await page.evaluate((el, text) => {
        const ta = el.querySelector('textarea');
        ta.value = text;
        ta.dispatchEvent(new Event('input', { bubbles: true }));
    }, box, code);
    const start = Date.now();
    await page.evaluate((el) => [...el.querySelectorAll('button')].find((b) => b.textContent.includes('Run')).click(), box);
    await page.waitForFunction((el) => {
        const t = el.textContent;
        return !t.includes('Running…') && !t.includes('Loading the Tcl engine') && el.querySelector('.tc-out');
    }, { timeout: 20000, polling: 50 }, box);
    const out = await page.evaluate((el) => ({
        problem: el.querySelector('[data-run-problem]')?.textContent ?? '',
        output: el.querySelector('pre[aria-label="Output"]')?.textContent ?? '',
    }), box);
    return { ...out, ms: Date.now() - start };
}

// A first normal run also loads Wacl.
let r = await runInPlayground('puts "before: [expr {6 * 7}]"');
check(r.output === 'before: 42' && !r.problem, `a normal run works (printed ${JSON.stringify(r.output)})`);

r = await runInPlayground('while 1 {puts hi}');
check(r.problem.includes('printed far too much') && r.problem.includes('Does your loop ever stop?'), `while 1 {puts hi} shows the output-limit message (${r.ms} ms)`);
check(r.ms < 4000, `it is stopped by the output limit, before the 5 s timeout (${r.ms} ms)`);
check(r.output.startsWith('hi\nhi\n') && r.output.length <= 50000, `the start of the output is shown, capped (${r.output.length} characters)`);

r = await runInPlayground('puts "after: [expr {6 * 7}]"');
check(r.output === 'after: 42' && !r.problem, `the next normal run works (printed ${JSON.stringify(r.output)})`);

r = await runInPlayground('set s x\nwhile 1 {append s $s}');
check(r.problem.includes('used up all the memory') && r.problem.includes('no need to reload'), `an out-of-memory script shows the crash message (${r.ms} ms)`);
check(!/Cannot enlarge memory|abort\(/.test(await page.evaluate((el) => el.textContent, box)), 'no Emscripten text is shown to the learner');

r = await runInPlayground('puts "fresh: [expr {6 * 7}]"');
check(r.output === 'fresh: 42' && !r.problem, `after the crash, the next run works without a reload (printed ${JSON.stringify(r.output)})`);

// Another component shares the fresh engine.
const predict = await page.$('section[aria-label="Predict, run, explain"]');
await predict.scrollIntoView();
await page.waitForFunction((el) => {
    const ta = el.querySelector('textarea');
    ta.value = 'my guess';
    ta.dispatchEvent(new Event('input', { bubbles: true }));
    const run = [...el.querySelectorAll('button')].find((b) => b.textContent.includes('Run'));
    return run && !run.disabled;
}, { timeout: 30000, polling: 250 }, predict);
await page.evaluate((el) => [...el.querySelectorAll('button')].find((b) => b.textContent.includes('Run')).click(), predict);
await page.waitForFunction((el) => el.textContent.includes('Tcl printed:') || el.querySelector('[data-run-problem]'), { timeout: 20000 }, predict);
const predictProblem = await page.evaluate((el) => el.querySelector('[data-run-problem]')?.textContent ?? '', predict);
check(predictProblem === '', 'PredictOutput runs normally on the same page after the crash');

check(pageErrors.length === 0, `no page errors${pageErrors.length ? `: ${pageErrors.join(' | ')}` : ''}`);
await browser.close();
server.close();
console.log(`RESULT: ${failures.length ? 'FAIL' : 'PASS'} playground limits (${failures.length} failure(s))`);
process.exit(failures.length ? 1 : 0);
