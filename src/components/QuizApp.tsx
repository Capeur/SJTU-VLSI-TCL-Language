import { useEffect, useState } from 'preact/hooks';
import QuestionView from './QuestionView';
import { shuffle, type Question } from './quizLogic';
import { recordAnswer, ensureCard, recordQuiz } from '../lib/progress';

export type QuizMode = 'warmup' | 'exit' | 'weekly' | 'exam';

interface Props {
    quizId: string;
    mode: QuizMode;
    count: number;
    mix: number;                 // share of questions taken from the current lesson (0–1)
    current: Question[];         // the current lesson's pool
    earlier: Question[];         // earlier weeks' pool
    required?: Question[];       // at least one of these is always drawn (Quiz `require` tag)
}

const TITLES: Record<QuizMode, string> = { warmup: 'Warm-up', exit: 'Exit quiz', weekly: 'Weekly quiz', exam: 'Exam' };

export function pick(current: Question[], earlier: Question[], count: number, mix: number, random = Math.random, required: Question[] = []): Question[] {
    const wantCurrent = Math.min(current.length, Math.round(count * mix));
    let chosen = shuffle(current, random).slice(0, wantCurrent);
    // A required question (Quiz `require` tag) takes the place of one current question if none was drawn.
    if (required.length && wantCurrent > 0 && !chosen.some((q) => required.includes(q))) {
        chosen = [shuffle(required, random)[0], ...chosen.slice(1)];
    }
    const rest = shuffle(earlier, random).slice(0, count - chosen.length);
    const filler = chosen.length + rest.length < count
        ? shuffle(current.filter((q) => !chosen.includes(q)), random).slice(0, count - chosen.length - rest.length) : [];
    return shuffle([...chosen, ...rest, ...filler], random);
}

export default function QuizApp({ quizId, mode, count, mix, current, earlier, required = [] }: Props) {
    const [questions, setQuestions] = useState<Question[] | null>(null);
    const [index, setIndex] = useState(0);
    const [answers, setAnswers] = useState<boolean[]>([]);
    const [answeredNow, setAnsweredNow] = useState(false);
    const [round, setRound] = useState(0);

    // Picked in the browser only, so the static HTML never disagrees with what the learner sees.
    useEffect(() => { setQuestions(pick(current, earlier, count, mix, Math.random, required)); }, [round]);

    if (!questions) return <div class="tc-box"><p>Loading quiz… (This quiz needs JavaScript.)</p></div>;
    if (questions.length === 0) return <div class="tc-box"><p>No questions available yet for this quiz.</p></div>;

    const finished = index >= questions.length;
    if (finished) {
        const correct = answers.filter(Boolean).length;
        return (
            <section class="tc-box" aria-label={TITLES[mode]}>
                <p class="tc-title">{TITLES[mode]} — your score</p>
                <p role="status"><strong>{correct} / {questions.length}</strong></p>
                {correct < questions.length && <p>Missed questions were added to your <a href={`${import.meta.env.BASE_URL.replace(/\/$/, '')}/review/`}>spaced review</a> deck.</p>}
                {(mode === 'weekly' || mode === 'exam') && (
                    <details open>
                        <summary>Review every explanation</summary>
                        {questions.map((q, i) => (
                            <p><span class={`tc-badge ${answers[i] ? 'tc-ok' : 'tc-bad'}`}>{answers[i] ? '✔' : '✘'}</span> <strong>{q.prompt}</strong> {q.explanation}</p>
                        ))}
                    </details>
                )}
                <button type="button" class="tc-btn" onClick={() => { setIndex(0); setAnswers([]); setAnsweredNow(false); setRound(round + 1); setQuestions(null); }}>Try again with new questions</button>
            </section>
        );
    }

    const q = questions[index];
    const onAnswered = (correct: boolean) => {
        const next = [...answers, correct];
        setAnswers(next);
        setAnsweredNow(true);
        recordAnswer(q.id, correct);
        if (q.review) ensureCard(q.id);
        if (next.length === questions.length) recordQuiz(quizId, next.filter(Boolean).length, questions.length);
    };

    return (
        <section aria-label={TITLES[mode]}>
            <p class="tc-title">{TITLES[mode]} — question {index + 1} of {questions.length}</p>
            <QuestionView key={q.id + round} question={q} onAnswered={onAnswered} />
            {answeredNow && (
                <button type="button" class="tc-btn primary" onClick={() => { setIndex(index + 1); setAnsweredNow(false); }}>
                    {index + 1 === questions.length ? 'See score' : 'Next question'}
                </button>
            )}
        </section>
    );
}
