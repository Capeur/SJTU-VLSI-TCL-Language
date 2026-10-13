// Checks lesson pages (frontmatter lesson: a | b) against PRD §6.3 and §12.3:
//   - sections appear in the template order. Concept + worked-example pairs (4–5) may repeat, and
//     Predict → Run → Explain (7) may sit right after the concept it tests, before the faded
//     example (decision log, P2). Order: LessonMeta, ChipStory, Goals, warm-up Quiz,
//     { WorkedExample | PredictOutput }+, FadedExample, PredictOutput*, Trap×1–3, exit Quiz,
//     CheatCard, FurtherReading. At least one PredictOutput.
//   - at most 150 words of prose between two interactive elements.
// Pages still marked "P0 placeholder" are skipped.
// Usage: node scripts/check-lessons.mjs [--verbose]   (--verbose prints each page's sections and word gaps)
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { parse as parseYaml } from 'yaml';
import { walk } from './lib/mdx-scan.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const MAX_WORDS = 150;
const verbose = process.argv.includes('--verbose');
const INTERACTIVE = ['Quiz', 'TclPlayground', 'PredictOutput', 'FadedExample', 'WorkedExample', 'Trap', 'Hints', 'RunWhere', 'LabPlayground', 'Flashcards', 'ProgressTracker'];
const SECTION_TAGS = ['LessonMeta', 'ChipStory', 'Goals', 'Quiz', 'WorkedExample', 'FadedExample', 'PredictOutput', 'Trap', 'CheatCard', 'FurtherReading'];

/** Remove a tag starting at i (handles nested {…} and `…` in attributes); returns end index. */
function tagEnd(text, i) {
    let depth = 0, inTpl = false, inStr = null;
    for (let j = i + 1; j < text.length; j++) {
        const c = text[j];
        if (inTpl) { if (c === '\\') j++; else if (c === '`') inTpl = false; continue; }
        if (inStr) { if (c === inStr) inStr = null; continue; }
        if (depth > 0) {
            if (c === '`') inTpl = true; else if (c === '"' || c === "'") inStr = c;
            else if (c === '{') depth++; else if (c === '}') depth--;
            continue;
        }
        if (c === '{') depth++;
        else if (c === '"' || c === "'") inStr = c;
        else if (c === '>') return j + 1;
    }
    return text.length;
}

const problems = [];
let checked = 0;
for (const file of walk(path.join(root, 'src/content/docs'), ['.mdx'])) {
    const text = fs.readFileSync(file, 'utf8');
    const fm = /^---\n([\s\S]*?)\n---/.exec(text);
    const front = fm ? parseYaml(fm[1]) ?? {} : {};
    if (!['a', 'b'].includes(front.lesson) || text.includes('P0 placeholder')) continue;
    checked++;
    const rel = path.relative(root, file);
    let body = text.slice(fm[0].length)
        .replace(/^import .*$/gm, '')
        .replace(/\{\/\*[\s\S]*?\*\/\}/g, '')
        .replace(/<details>[\s\S]*?<\/details>/g, ' ');   // optional "for the curious" material

    // Walk the body: collect section tags in order and count prose words between interactive tags.
    const sequence = [];
    let words = 0;
    let lastBreak = 'start of page';
    let i = 0;
    while (i < body.length) {
        const m = /<([A-Z][A-Za-z]*)\b/.exec(body.slice(i));
        const proseEnd = m ? i + m.index : body.length;
        const prose = body.slice(i, proseEnd).replace(/<\/[A-Z][A-Za-z]*>/g, ' ').replace(/^#+ .*$/gm, ' ');
        words += (prose.match(/[A-Za-z0-9][A-Za-z0-9'’-]*/g) ?? []).length;
        if (!m) break;
        const name = m[1];
        const end = tagEnd(body, proseEnd);
        const tag = body.slice(proseEnd, end);
        if (SECTION_TAGS.includes(name)) {
            const mode = name === 'Quiz' ? (/mode="(\w+)"/.exec(tag)?.[1] ?? '?') : '';
            sequence.push(name === 'Quiz' ? `Quiz:${mode}` : name);
        }
        if (INTERACTIVE.includes(name)) {
            if (verbose) console.log(`  ${rel}: ${String(words).padStart(3)} words before <${name}>`);
            if (words > MAX_WORDS) problems.push(`${rel}: ${words} words of prose between ${lastBreak} and <${name}> (limit ${MAX_WORDS})`);
            words = 0;
            lastBreak = `<${name}>`;
        }
        i = end;
    }

    const s = sequence.join(' ');
    if (verbose) console.log(`  ${rel}: ${s}`);
    const pattern = /^LessonMeta ChipStory Goals Quiz:warmup( (WorkedExample|PredictOutput))*( WorkedExample)( (WorkedExample|PredictOutput))* FadedExample( PredictOutput)*( Trap){1,3} Quiz:exit CheatCard FurtherReading$/;
    if (!pattern.test(s)) problems.push(`${rel}: sections out of PRD §6.3 order:\n      ${s}`);
    if (!sequence.includes('PredictOutput')) problems.push(`${rel}: no Predict → Run → Explain section`);
    if ((front.goals ?? []).length > 3) problems.push(`${rel}: more than 3 goals`);
    for (const key of ['ai_assisted', 'reviewed_by', 'review_date']) if (!(key in front)) problems.push(`${rel}: frontmatter lacks ${key}`);
    if (!(front.sources ?? []).length) problems.push(`${rel}: sources: is empty`);
}
if (problems.length) {
    console.error(`check-lessons: ${problems.length} problem(s)\n - ${problems.join('\n - ')}`);
    process.exit(1);
}
console.log(`check-lessons: OK — ${checked} lesson page(s) follow PRD §6.3 and the ${MAX_WORDS}-word rule`);
