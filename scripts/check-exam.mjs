// Checks the milestone exams in src/content/exams/ (PRD §9.1; decision log, P3 Week 10) with a real tclsh:
//   - the schema (no answers, no explanations), unique ids, and that each `revisit` lesson exists;
//   - the M10 blueprint: 30 items, >= 60 % predict-output, >= 1/3 on Week 3;
//   - predict-output: the code runs without an error and its normalised output matches output_hash;
//   - choose-code: exactly one choice prints the target;
//   - no item repeats the code of a public quiz-bank item (whose answer is public).
// complete-code items need their reference answers, so the private solutions repository checks them.
// It prints item ids and reasons ONLY, never an output: an output is an answer, and CI logs are public.
// Usage: TCLSH=tclsh9.0 node scripts/check-exam.mjs           check (part of `npm run validate`)
//        node scripts/check-exam.mjs --write-hashes             (re)write every output_hash from tclsh
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { loadExams, loadQuizBanks, normaliseOutput, examOutputHash } from '../src/lib/content.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const tclsh = process.env.TCLSH || 'tclsh';
const writeHashes = process.argv.includes('--write-hashes');
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'exam-'));

/** Runs Tcl code; returns { ok, stdout }. */
function runTcl(code, name) {
    const file = path.join(tmp, `${name}.tcl`);
    fs.writeFileSync(file, code);
    const r = spawnSync(tclsh, [file], { encoding: 'utf8', timeout: 10000 });
    if (r.error) { console.error(`check-exam: cannot run ${tclsh}: ${r.error.message}`); process.exit(2); }
    return { ok: r.status === 0, stdout: r.stdout ?? '' };
}

const blueprints = { m10: { items: 30, predictShare: 0.6, focusWeek: 3, focusShare: 1 / 3, lastWeek: 10 } };
const quizCodes = new Set(loadQuizBanks().flatMap((b) => b.questions).filter((q) => q.code).map((q) => normaliseOutput(q.code)));
const errors = [];
let checked = 0;
const exams = loadExams();
for (const exam of exams) {
    const items = exam.items;
    const ids = new Set();
    const lessonFile = (id) => {
        const [, ms, week, lesson] = /^(m\d0)-w(\d\d)-([ab])$/.exec(id);
        return path.join(root, 'src/content/docs', ms, `week-${week}`, `lesson-${lesson}.mdx`);
    };
    for (const item of items) {
        if (ids.has(item.id)) errors.push(`${item.id}: duplicate id`);
        ids.add(item.id);
        if (!fs.existsSync(lessonFile(item.revisit))) errors.push(`${item.id}: revisit page ${item.revisit} does not exist`);
        const codes = item.type === 'choose-code' ? item.choices : [item.code];
        for (const code of codes) if (quizCodes.has(normaliseOutput(code))) errors.push(`${item.id}: repeats the code of a public quiz item`);
    }
    const bp = blueprints[exam.name];
    if (bp) {
        const predict = items.filter((q) => q.type === 'predict-output').length;
        const focus = items.filter((q) => q.week === bp.focusWeek).length;
        if (items.length !== bp.items) errors.push(`${exam.name}: ${items.length} items, the blueprint asks for ${bp.items}`);
        if (predict < bp.predictShare * items.length) errors.push(`${exam.name}: ${predict} predict-output items, fewer than ${bp.predictShare * 100} %`);
        if (focus < bp.focusShare * items.length) errors.push(`${exam.name}: ${focus} Week ${bp.focusWeek} items, fewer than 1/3`);
        if (items.some((q) => q.week > bp.lastWeek)) errors.push(`${exam.name}: an item is from after Week ${bp.lastWeek}`);
        console.log(`check-exam: ${exam.name}: ${items.length} items, ${predict} predict-output (${Math.round(100 * predict / items.length)} %), ${focus} on Week ${bp.focusWeek}`);
    }

    let text = fs.readFileSync(exam.file, 'utf8');
    for (const item of items) {
        if (item.type === 'predict-output') {
            const { ok, stdout } = runTcl(item.code, item.id);
            if (!ok) { errors.push(`${item.id}: the code stops with an error`); continue; }
            const hash = examOutputHash(stdout);
            if (writeHashes) {
                const re = new RegExp(`(- id: ${item.id}\\n[\\s\\S]*?output_hash: ")[0-9a-f]{8}(")`);
                text = text.replace(re, `$1${hash}$2`);
            } else if (hash !== item.output_hash) {
                errors.push(`${item.id}: the real output does not match output_hash (rerun --write-hashes if the item changed on purpose)`);
            }
            checked++;
        } else if (item.type === 'choose-code') {
            const hits = item.choices.filter((code, i) => normaliseOutput(runTcl(code, `${item.id}-${i}`).stdout) === normaliseOutput(item.target)).length;
            if (hits !== 1) errors.push(`${item.id}: ${hits} choices print the target; exactly one must`);
            checked++;
        }
    }
    if (writeHashes) fs.writeFileSync(exam.file, text);
}
fs.rmSync(tmp, { recursive: true, force: true });
if (errors.length) {
    console.error(`check-exam: ${errors.length} problem(s)\n - ${errors.join('\n - ')}`);
    process.exit(1);
}
console.log(`check-exam: OK — ${exams.length} exam(s), ${checked} item(s) checked with ${tclsh}${writeHashes ? ' (hashes written)' : ''}`);
