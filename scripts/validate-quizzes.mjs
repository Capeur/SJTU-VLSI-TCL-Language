// Build-time content validation (PRD §8.2, §15.1 step 2):
//  - quiz banks parse against the schema, ids are unique across all banks
//  - every predict-output answer equals the real tclsh output
//  - glossary entries parse; see_also points at existing entries
// Usage: node scripts/validate-quizzes.mjs   (TCLSH=/path/to/tclsh to pick the interpreter)
import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { loadQuizBanks, loadGlossary } from '../src/lib/content.mjs';

const tclsh = process.env.TCLSH || 'tclsh';
const errors = [];
let checked = 0;

let banks;
let glossary;
try { banks = loadQuizBanks(); } catch (e) { console.error('Quiz schema error:\n', e.issues ? JSON.stringify(e.issues, null, 2) : e); process.exit(1); }
try { glossary = loadGlossary(); } catch (e) { console.error('Glossary schema error:\n', e.issues ? JSON.stringify(e.issues, null, 2) : e); process.exit(1); }

const seen = new Map();
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'quiz-'));
for (const bank of banks) {
    for (const q of bank.questions) {
        if (seen.has(q.id)) errors.push(`duplicate question id ${q.id} (${bank.name} and ${seen.get(q.id)})`);
        seen.set(q.id, bank.name);
        if (q.type === 'find-the-bug' && q.answer > q.code.replace(/\n$/, '').split('\n').length) errors.push(`${q.id}: answer line is beyond the code`);
        if (q.type === 'predict-output') {
            const file = path.join(tmp, `${q.id}.tcl`);
            fs.writeFileSync(file, q.code);
            const run = spawnSync(tclsh, [file], { encoding: 'utf8', timeout: 10000 });
            const norm = (t) => t.replace(/\r/g, '').split('\n').map((l) => l.trimEnd()).join('\n').trimEnd();
            if (norm(run.stdout ?? '') !== norm(q.answer)) {
                errors.push(`${q.id}: answer ${JSON.stringify(q.answer)} but ${tclsh} printed ${JSON.stringify(norm(run.stdout ?? ''))}${run.stderr ? ` (stderr: ${run.stderr.trim()})` : ''}`);
            }
            checked++;
        }
    }
}
fs.rmSync(tmp, { recursive: true, force: true });

for (const [key, entry] of Object.entries(glossary)) {
    if (entry.term !== key) errors.push(`glossary/${key}.yaml: term "${entry.term}" must equal the file name`);
    for (const ref of entry.see_also) if (!glossary[ref]) errors.push(`glossary/${key}.yaml: see_also "${ref}" does not exist`);
}

const total = [...seen.keys()].length;
if (errors.length) {
    console.error(`validate-quizzes: ${errors.length} problem(s)\n - ${errors.join('\n - ')}`);
    process.exit(1);
}
console.log(`validate-quizzes: OK — ${banks.length} bank(s), ${total} question(s), ${checked} predict-output answer(s) match ${tclsh}, ${Object.keys(glossary).length} glossary entr${Object.keys(glossary).length === 1 ? 'y' : 'ies'}`);
