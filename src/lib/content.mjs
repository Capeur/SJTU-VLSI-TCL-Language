// Shared by the site (build time) and by scripts/validate-quizzes.mjs: loading and validating
// quiz banks (PRD §8.2) and glossary entries (PRD §8.4).
import fs from 'node:fs';
import path from 'node:path';
import { parse } from 'yaml';
import { z } from 'zod';

// Resolved from the working directory (the repo root), so it also works once Astro bundles this file.
const root = path.resolve(process.cwd(), 'src', 'content');

const base = {
    id: z.string().regex(/^[a-z0-9-]+$/),
    lesson: z.string().optional(),
    tags: z.array(z.string()).default([]),
    review: z.boolean().default(false),
    prompt: z.string().min(1),
    explanation: z.string().min(1),
    code: z.string().optional(),
    long_decimal: z.boolean().default(false),   // M10: allow printing > 4 decimal places (see extract-snippets)
};

export const questionSchema = z.discriminatedUnion('type', [
    z.object({
        ...base, type: z.literal('mcq'),
        choices: z.array(z.string()).min(2),
        answer: z.string(),
        distractor_feedback: z.record(z.string(), z.string()).optional(),
    }).refine((q) => q.choices.includes(q.answer), { message: 'mcq answer must be one of choices' }),
    z.object({
        ...base, type: z.literal('multi-select'),
        choices: z.array(z.string()).min(2),
        answer: z.array(z.string()).min(1),
    }).refine((q) => q.answer.every((a) => q.choices.includes(a)), { message: 'multi-select answers must be in choices' }),
    z.object({ ...base, type: z.literal('predict-output'), code: z.string(), answer: z.string() }),
    z.object({
        ...base, type: z.literal('fill-blank'),
        // prompt contains ___ ; answer = accepted strings, or "/regex/" strings
        answer: z.array(z.string()).min(1),
    }),
    z.object({
        ...base, type: z.literal('find-the-bug'),
        code: z.string(), answer: z.number().int().min(1),   // 1-based line number
    }),
    z.object({
        ...base, type: z.literal('order-steps'),
        steps: z.array(z.string()).min(2),                     // listed in the CORRECT order
    }),
]);

export const glossarySchema = z.object({
    term: z.string(),
    short: z.string().max(220),
    long: z.string().optional(),
    see_also: z.array(z.string()).default([]),
    first_taught: z.string().optional(),
});

export function readYamlDir(dir) {
    const full = path.join(root, dir);
    if (!fs.existsSync(full)) return [];
    return fs.readdirSync(full).filter((f) => f.endsWith('.yaml')).sort().map((file) => ({
        name: file.replace(/\.yaml$/, ''),
        file: path.join(full, file),
        data: parse(fs.readFileSync(path.join(full, file), 'utf8')),
    }));
}

// PRD §0 rule 8: a course bank records who reviewed it. A bank file is either a plain list of
// questions (demo only) or { ai_assisted, reviewed_by, review_date, questions: [...] }.
export const bankMetaSchema = z.object({
    ai_assisted: z.boolean(),
    reviewed_by: z.string(),
    review_date: z.string().regex(/^(\d{4}-\d{2}-\d{2})?$/),
});

export function loadQuizBanks() {
    return readYamlDir('quizzes').map(({ name, data, file }) => {
        const list = Array.isArray(data) ? data : (data?.questions ?? []);
        const meta = Array.isArray(data) || !data ? null : bankMetaSchema.parse(data);
        return { name, file, meta, questions: list.map((q) => questionSchema.parse(q)) };
    });
}

export function loadGlossary() {
    const map = {};
    for (const { name, data } of readYamlDir('glossary')) {
        const entry = glossarySchema.parse(data);
        map[name] = entry;
    }
    return map;
}

// Milestone exams (PRD §9.1; decision log, P3 Week 10): src/content/exams/<name>.yaml.
// Every item is graded by RUNNING Tcl in the browser, so the public file holds NO answers and no
// explanations (the reference answers live in the private solutions repository). The schema is strict:
// an `answer` or `explanation` field is an error.
//   predict-output  `code`; the learner types the output. `output_hash` = FNV-1a of the normalised real output,
//                   used only by CI to check that tclsh 8.6, 9.0 and Wacl all print the same thing.
//   complete-code   `code` with exactly one ___ and a `target` output; the learner's text fills the blank.
//   choose-code     `choices`: short scripts; `target`: the output that exactly one of them prints.
const examBase = {
    id: z.string().regex(/^m\d0-exam-\d\d$/),
    week: z.number().int().min(1).max(40),
    tags: z.array(z.string()).default([]),
    revisit: z.string().regex(/^m\d0-w\d\d-[ab]$/),   // the lesson to revisit, e.g. m10-w03-a
    prompt: z.string().min(1),
};
export const examItemSchema = z.discriminatedUnion('type', [
    z.object({ ...examBase, type: z.literal('predict-output'), code: z.string(), output_hash: z.string().regex(/^[0-9a-f]{8}$/) }).strict(),
    z.object({ ...examBase, type: z.literal('complete-code'), code: z.string(), target: z.string() }).strict()
        .refine((q) => q.code.split('___').length === 2, { message: 'complete-code needs exactly one ___ in code' }),
    z.object({ ...examBase, type: z.literal('choose-code'), choices: z.array(z.string()).min(3), target: z.string() }).strict(),
]);
export const examSchema = z.object({
    ai_assisted: z.boolean(),
    reviewed_by: z.string(),
    review_date: z.string().regex(/^(\d{4}-\d{2}-\d{2})?$/),
    title: z.string(),
    items: z.array(examItemSchema).min(1),
}).strict();

export function loadExams() {
    return readYamlDir('exams').map(({ name, data, file }) => ({ name, file, ...examSchema.parse(data) }));
}

/** FNV-1a (32 bits) of the UTF-8 bytes of a text, as 8 hex digits. Same as labFnv in the Tcl graders. */
export function fnv1a(text) {
    let hash = 0x811c9dc5;
    for (const byte of new TextEncoder().encode(text)) {
        hash = Math.imul(hash ^ byte, 0x01000193) >>> 0;
    }
    return hash.toString(16).padStart(8, '0');
}

/** Output in a fair form, exactly as the playground compares it (src/lib/tclRuntime.ts normaliseOutput). */
export function normaliseOutput(text) {
    return text.replace(/\r/g, '').split('\n').map((line) => line.replace(/\s+$/, '')).join('\n').replace(/\s+$/, '');
}

/** The hash stored for a predict-output exam item. */
export function examOutputHash(output) {
    return fnv1a(`exam:${normaliseOutput(output)}`);
}
