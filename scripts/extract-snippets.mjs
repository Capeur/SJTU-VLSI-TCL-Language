// Collects every runnable Tcl snippet into snippets/<page-id>/<n>.tcl (+ .expected, .only, .drvlite).
// Sources (PRD §15.2): ```tcl run blocks, <PredictOutput>, <VersionNote> samples, <Trap> wrong/fix code,
// <WorkedExample> and <TclPlayground> code (must run without error, or fail with `fails="…"`),
// predict-output quiz items, and lab checker self-tests (labs/**/tests/selftest.tcl).
// M10 snippets get a <n>.maxdecimals file (4): run-snippets fails if they print a decimal with more
// places, unless the snippet is marked intentional (```tcl run longdecimal, longDecimal prop, or
// long_decimal: true on a quiz item). Rounding is taught only in Week 8 (format).
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { parse as parseYaml } from 'yaml';
import { walk, fencedBlocks, componentTags } from './lib/mdx-scan.mjs';
import { loadQuizBanks } from '../src/lib/content.mjs';
import { isGradable, labSelftestScript } from '../src/lib/labs.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const docsDir = path.join(root, 'src/content/docs');
const outDir = path.join(root, 'snippets');

// Clear old generated output but keep .gitkeep.
for (const entry of fs.readdirSync(outDir)) {
    if (entry !== '.gitkeep') fs.rmSync(path.join(outDir, entry), { recursive: true, force: true });
}

let total = 0;

/** Where a page's snippets run: its `runs_in` frontmatter, else the playground for M10 and the terminal after. */
function pageRunsIn(text) {
    const match = /^---\n([\s\S]*?)\n---/.exec(text);
    const front = match ? parseYaml(match[1]) ?? {} : {};
    if (Array.isArray(front.runs_in)) return front.runs_in.includes('playground') ? 'playground' : 'terminal';
    return front.milestone === 'm10' ? 'playground' : 'terminal';
}
const MAX_DECIMALS = 4;
const isM10 = (pageId) => /^(m10__|quiz__m10-|lab__m10__)/.test(pageId);
function emit(pageId, n, { code, expected, error, only, drvlite, runsIn, longDecimal }) {
    const dir = path.join(outDir, pageId);
    fs.mkdirSync(dir, { recursive: true });
    const base = path.join(dir, String(n).padStart(2, '0'));
    fs.writeFileSync(`${base}.tcl`, code.endsWith('\n') ? code : `${code}\n`);
    if (expected !== undefined) fs.writeFileSync(`${base}.expected`, expected);
    if (error !== undefined) fs.writeFileSync(`${base}.error`, error);   // must fail with this message
    if (only) fs.writeFileSync(`${base}.only`, only);
    if (drvlite) fs.writeFileSync(`${base}.drvlite`, '');
    fs.writeFileSync(`${base}.runs_in`, runsIn);
    if (isM10(pageId) && !longDecimal) fs.writeFileSync(`${base}.maxdecimals`, String(MAX_DECIMALS));
    total++;
}

for (const file of walk(docsDir, ['.md', '.mdx'])) {
    const text = fs.readFileSync(file, 'utf8');
    const pageId = path.relative(docsDir, file).replace(/\.mdx?$/, '').replace(/[\\/]/g, '__');
    let n = 0;
    const runsIn = pageRunsIn(text);
    for (const { code, attrs } of fencedBlocks(text)) {
        // A fence can override the page: ```tcl run runs_in=terminal
        const where = attrs.runs_in === 'terminal' || attrs.runs_in === 'playground' ? attrs.runs_in : runsIn;
        emit(pageId, ++n, { code, expected: typeof attrs.expect === 'string' ? attrs.expect : undefined, drvlite: !!attrs.drvlite, runsIn: where, longDecimal: !!attrs.longdecimal });
    }
    for (const tag of componentTags(text, ['PredictOutput', 'VersionNote', 'Trap', 'WorkedExample', 'TclPlayground'])) {
        const p = tag.props;
        const longDecimal = !!p.longDecimal;
        if (tag.name === 'PredictOutput') emit(pageId, ++n, { code: p.code, expected: p.expected, runsIn: 'playground', longDecimal });
        else if (tag.name === 'WorkedExample') emit(pageId, ++n, { code: p.code, runsIn, longDecimal });
        else if (tag.name === 'TclPlayground') {
            if (typeof p.code === 'string' && p.code.trim()) emit(pageId, ++n, { code: p.code, error: p.fails, drvlite: !!p.drvlite, runsIn: 'playground', longDecimal });
        }
        else if (tag.name === 'Trap') {
            emit(pageId, ++n, { code: p.wrong, expected: p.output, error: p.error, runsIn, longDecimal });
            emit(pageId, ++n, { code: p.fix, runsIn, longDecimal });
        } else {
            if (p.code86) emit(pageId, ++n, { code: p.code86, expected: p.expect86, error: p.fails86, only: '8.6', runsIn, longDecimal });
            if (p.code90) emit(pageId, ++n, { code: p.code90, expected: p.expect90, error: p.fails90, only: '9.0', runsIn, longDecimal });
        }
    }
}
for (const bank of loadQuizBanks()) {
    let n = 0;
    for (const q of bank.questions) {
        if (q.type === 'predict-output') emit(`quiz__${bank.name}`, ++n, { code: q.code, expected: q.answer, runsIn: 'terminal', longDecimal: q.long_decimal });
    }
}
// Lab checkers test themselves on every Tcl version and in Wacl (the browser "Check" button uses them).
const labsDir = path.join(root, 'labs');
for (const ms of fs.existsSync(labsDir) ? fs.readdirSync(labsDir).sort() : []) {
    const msDir = path.join(labsDir, ms);
    if (!fs.statSync(msDir).isDirectory()) continue;
    for (const week of fs.readdirSync(msDir).sort()) {
        const dir = path.join(msDir, week);
        if (!isGradable(dir)) continue;
        const script = labSelftestScript(dir);
        if (script) emit(`lab__${ms}__${week}`, 1, { code: script, runsIn: ms === 'm10' ? 'playground' : 'terminal' });
    }
}
console.log(`extract-snippets: wrote ${total} snippet(s) to snippets/`);
