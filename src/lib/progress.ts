// Local-only progress (PRD §7 ProgressTracker). No network, no cookies.
// Every storage access is wrapped in try/catch; if storage is blocked we keep state in memory.

export interface Card {
    box: number;      // Leitner box 1–5
    due: number;      // epoch ms
}

export interface ProgressState {
    version: 1;
    visited: Record<string, number>;                                  // lesson id -> epoch ms
    quiz: Record<string, { correct: number; total: number; at: number }>;
    cards: Record<string, Card>;                                      // question id -> Leitner card
}

const KEY = 'tcl-to-tapeout:progress:v1';
const DAY = 86_400_000;
export const BOX_DAYS = [1, 3, 7, 14, 30];

function empty(): ProgressState {
    return { version: 1, visited: {}, quiz: {}, cards: {} };
}

let memory: ProgressState = empty();
let storageWorks = true;

function isState(value: unknown): value is ProgressState {
    const v = value as ProgressState;
    return !!v && v.version === 1 && typeof v.visited === 'object' && typeof v.quiz === 'object' && typeof v.cards === 'object';
}

export function load(): ProgressState {
    try {
        const raw = window.localStorage.getItem(KEY);
        if (raw) {
            const parsed = JSON.parse(raw);
            if (isState(parsed)) memory = parsed;
        }
        storageWorks = true;
    } catch {
        storageWorks = false;
    }
    return memory;
}

export function save(state: ProgressState): void {
    memory = state;
    try {
        window.localStorage.setItem(KEY, JSON.stringify(state));
    } catch {
        storageWorks = false;
    }
}

export function isPersistent(): boolean {
    return storageWorks;
}

export function markVisited(lessonId: string): void {
    const state = load();
    state.visited[lessonId] = Date.now();
    save(state);
}

export function recordQuiz(quizId: string, correct: number, total: number): void {
    const state = load();
    state.quiz[quizId] = { correct, total, at: Date.now() };
    save(state);
}

/** Wrong answers go to box 1, due now. A right answer in review moves the card up one box. */
export function recordAnswer(questionId: string, wasCorrect: boolean, now = Date.now()): void {
    const state = load();
    const card = state.cards[questionId];
    if (!wasCorrect) {
        state.cards[questionId] = { box: 1, due: now };
    } else if (card) {
        const box = Math.min(5, card.box + 1);
        state.cards[questionId] = { box, due: now + BOX_DAYS[box - 1] * DAY };
    }
    save(state);
}

/** Add a card the learner has not missed (quiz items with review: true). */
export function ensureCard(questionId: string, now = Date.now()): void {
    const state = load();
    if (!state.cards[questionId]) {
        state.cards[questionId] = { box: 1, due: now };
        save(state);
    }
}

export function dueCards(now = Date.now()): string[] {
    const state = load();
    return Object.entries(state.cards)
        .filter(([, card]) => card.due <= now)
        .sort((a, b) => a[1].due - b[1].due)
        .map(([id]) => id);
}

export function exportJson(): string {
    return JSON.stringify(load(), null, 2);
}

/** Returns an error message, or null on success. */
export function importJson(text: string): string | null {
    try {
        const parsed = JSON.parse(text);
        if (!isState(parsed)) return 'This file is not a progress export from this course.';
        save(parsed);
        return null;
    } catch {
        return 'That file is not valid JSON.';
    }
}

export function reset(): void {
    save(empty());
}
