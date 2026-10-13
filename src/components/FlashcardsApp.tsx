import { useEffect, useState } from 'preact/hooks';
import { answerText, type Question } from './quizLogic';
import { load, ensureCard, recordAnswer, dueCards, BOX_DAYS } from '../lib/progress';

interface Props { questions: Question[]; }

/** Leitner spaced review: 5 boxes, intervals 1/3/7/14/30 days (PRD §7). */
export default function FlashcardsApp({ questions }: Props) {
    const byId = new Map(questions.map((q) => [q.id, q]));
    const [queue, setQueue] = useState<string[] | null>(null);
    const [shown, setShown] = useState(false);
    const [boxes, setBoxes] = useState<number[]>([0, 0, 0, 0, 0]);

    const refresh = () => {
        const state = load();
        setQueue(dueCards().filter((id) => byId.has(id)));
        const counts = [0, 0, 0, 0, 0];
        Object.entries(state.cards).forEach(([id, c]) => { if (byId.has(id)) counts[c.box - 1]++; });
        setBoxes(counts);
        setShown(false);
    };

    useEffect(() => {
        questions.filter((q) => q.review).forEach((q) => ensureCard(q.id));
        refresh();
    }, []);

    if (!queue) return <div class="tc-box"><p>Loading your review deck… (Spaced review needs JavaScript.)</p></div>;

    const q = queue.length ? byId.get(queue[0])! : null;
    const rate = (correct: boolean) => { recordAnswer(q!.id, correct); refresh(); };

    return (
        <section class="tc-box" aria-label="Spaced review">
            <p class="tc-title">Spaced review</p>
            <p aria-label="Cards per box">Boxes (revisited after {BOX_DAYS.join(' / ')} days): {boxes.map((n, i) => <span class="tc-badge tc-info" style="margin-right:0.3rem">Box {i + 1}: {n}</span>)}</p>
            {!q ? <p role="status" class="tc-feedback tc-ok">Nothing is due right now. Come back tomorrow — spacing is what makes it stick!</p> : (
                <>
                    <p><strong>{queue.length}</strong> card{queue.length === 1 ? '' : 's'} due.</p>
                    <p><strong>{q.prompt}</strong></p>
                    {q.code && <pre class="tc-code" tabindex={0}>{q.code}</pre>}
                    {q.choices && <ul>{q.choices.map((c) => <li>{c}</li>)}</ul>}
                    {!shown
                        ? <button type="button" class="tc-btn primary" onClick={() => setShown(true)}>Show answer</button>
                        : (
                            <div aria-live="polite">
                                <p class="tc-feedback tc-info"><strong>Answer:</strong> <code>{answerText(q)}</code><br />{q.explanation}</p>
                                <div class="tc-row">
                                    <button type="button" class="tc-btn primary" onClick={() => rate(true)}>I knew it</button>
                                    <button type="button" class="tc-btn" onClick={() => rate(false)}>I missed it</button>
                                </div>
                            </div>
                        )}
                </>
            )}
        </section>
    );
}
