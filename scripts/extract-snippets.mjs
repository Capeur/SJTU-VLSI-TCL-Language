// Collects every runnable Tcl snippet into snippets/<page-id>/<n>.tcl (+ .expected, .only, .drvlite).
// Sources (PRD §15.2): ```tcl run blocks, <PredictOutput>, <VersionNote> samples, predict-output quiz items.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { walk, fencedBlocks, componentTags } from './lib/mdx-scan.mjs';
import { loadQuizBanks } from '../src/lib/content.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const docsDir = path.join(root, 'src/content/docs');
const outDir = path.join(root, 'snippets');

// Clear old generated output but keep .gitkeep.
for (const entry of fs.readdirSync(outDir)) {
    if (entry !== '.gitkeep') fs.rmSync(path.join(outDir, entry), { recursive: true, force: true });
}

let total = 0;
function emit(pageId, n, { code, expected, only, drvlite }) {
    const dir = path.join(outDir, pageId);
    fs.mkdirSync(dir, { recursive: true });
    const base = path.join(dir, String(n).padStart(2, '0'));
    fs.writeFileSync(`${base}.tcl`, code.endsWith('\n') ? code : `${code}\n`);
    if (expected !== undefined) fs.writeFileSync(`${base}.expected`, expected);
    if (only) fs.writeFileSync(`${base}.only`, only);
    if (drvlite) fs.writeFileSync(`${base}.drvlite`, '');
    total++;
}

for (const file of walk(docsDir, ['.md', '.mdx'])) {
    const text = fs.readFileSync(file, 'utf8');
    const pageId = path.relative(docsDir, file).replace(/\.mdx?$/, '').replace(/[\\/]/g, '__');
    let n = 0;
    for (const { code, attrs } of fencedBlocks(text)) {
        emit(pageId, ++n, { code, expected: typeof attrs.expect === 'string' ? attrs.expect : undefined, drvlite: !!attrs.drvlite });
    }
    for (const tag of componentTags(text, ['PredictOutput', 'VersionNote'])) {
        const p = tag.props;
        if (tag.name === 'PredictOutput') emit(pageId, ++n, { code: p.code, expected: p.expected });
        else {
            if (p.code86) emit(pageId, ++n, { code: p.code86, expected: p.expect86, only: '8.6' });
            if (p.code90) emit(pageId, ++n, { code: p.code90, expected: p.expect90, only: '9.0' });
        }
    }
}
for (const bank of loadQuizBanks()) {
    let n = 0;
    for (const q of bank.questions) {
        if (q.type === 'predict-output') emit(`quiz__${bank.name}`, ++n, { code: q.code, expected: q.answer });
    }
}
console.log(`extract-snippets: wrote ${total} snippet(s) to snippets/`);
