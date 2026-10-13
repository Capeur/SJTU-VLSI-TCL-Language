// Grading helpers shared by Quiz and Flashcards. Question shape: see src/lib/content.mjs.
import { normaliseOutput } from '../lib/tclRuntime';
import { matchesAnswer } from './FadedExample';

export interface Question {
    id: string;
    type: 'mcq' | 'multi-select' | 'predict-output' | 'fill-blank' | 'find-the-bug' | 'order-steps';
    lesson?: string;
    review: boolean;
    prompt: string;
    explanation: string;
    code?: string;
    choices?: string[];
    answer?: string | string[] | number;
    steps?: string[];
    distractor_feedback?: Record<string, string>;
}

export type Response = string | string[] | number | null;

export function grade(q: Question, response: Response): boolean {
    switch (q.type) {
        case 'mcq': return response === q.answer;
        case 'multi-select': {
            const got = [...((response as string[]) ?? [])].sort();
            const want = [...(q.answer as string[])].sort();
            return got.length === want.length && got.every((v, i) => v === want[i]);
        }
        case 'predict-output': return normaliseOutput(String(response ?? '')) === normaliseOutput(q.answer as string);
        case 'fill-blank': return matchesAnswer(String(response ?? ''), q.answer as string[]);
        case 'find-the-bug': return Number(response) === q.answer;
        case 'order-steps': return JSON.stringify(response) === JSON.stringify(q.steps);
    }
}

export function answerText(q: Question): string {
    switch (q.type) {
        case 'multi-select': return (q.answer as string[]).join(', ');
        case 'fill-blank': return (q.answer as string[]).find((a) => !/^\/.+\/$/.test(a)) ?? '(matches a pattern)';
        case 'find-the-bug': return `Line ${q.answer}`;
        case 'order-steps': return (q.steps ?? []).map((s, i) => `${i + 1}. ${s}`).join('  ');
        default: return String(q.answer);
    }
}

/** Fisher–Yates with an injectable random source, so tests can be deterministic. */
export function shuffle<T>(items: T[], random: () => number = Math.random): T[] {
    const out = [...items];
    for (let i = out.length - 1; i > 0; i--) {
        const j = Math.floor(random() * (i + 1));
        [out[i], out[j]] = [out[j], out[i]];
    }
    return out;
}
