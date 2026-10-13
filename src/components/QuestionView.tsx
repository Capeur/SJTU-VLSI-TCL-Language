import { useState } from 'preact/hooks';
import { grade, answerText, shuffle, type Question, type Response } from './quizLogic';

interface Props {
    question: Question;
    onAnswered: (correct: boolean, response: Response) => void;
    /** When true the question is already answered (review of a finished quiz). */
    locked?: boolean;
}

function NumberedCode({ code }: { code: string }) {
    return (
        <pre class="tc-code" tabindex={0}>{code.replace(/\n$/, '').split('\n').map((l, i) => `${String(i + 1).padStart(2)}  ${l}`).join('\n')}</pre>
    );
}

export default function QuestionView({ question: q, onAnswered, locked = false }: Props) {
    const [response, setResponse] = useState<Response>(q.type === 'multi-select' ? [] : null);
    const [order, setOrder] = useState<string[]>(() => {
        if (q.type !== 'order-steps') return [];
        let mixed = shuffle(q.steps ?? []);
        if (JSON.stringify(mixed) === JSON.stringify(q.steps)) mixed = [...mixed].reverse();
        return mixed;
    });
    const [result, setResult] = useState<boolean | null>(null);
    const done = result !== null;
    const uid = q.id;

    const submit = () => {
        const value: Response = q.type === 'order-steps' ? order : response;
        const correct = grade(q, value);
        setResult(correct);
        onAnswered(correct, value);
    };
    const canSubmit = q.type === 'order-steps' ? true
        : q.type === 'multi-select' ? ((response as string[]).length > 0)
            : response !== null && String(response).trim() !== '';

    const move = (i: number, d: number) => {
        const next = [...order];
        [next[i], next[i + d]] = [next[i + d], next[i]];
        setOrder(next);
    };

    return (
        <fieldset class="tc-box" disabled={done || locked} style="min-inline-size:auto">
            <legend class="tc-title">{q.prompt}</legend>
            {q.code && q.type === 'find-the-bug' ? <NumberedCode code={q.code} />
                : q.code && q.type !== 'predict-output' ? <pre class="tc-code" tabindex={0}>{q.code}</pre> : null}
            {q.type === 'predict-output' && <pre class="tc-code" tabindex={0}>{q.code}</pre>}

            {q.type === 'mcq' && q.choices!.map((c, i) => (
                <label class="tc-choice"><input type="radio" name={uid} checked={response === c} onChange={() => setResponse(c)} /> <span>{c}</span></label>
            ))}
            {q.type === 'multi-select' && q.choices!.map((c) => (
                <label class="tc-choice"><input type="checkbox" name={uid}
                    checked={(response as string[]).includes(c)}
                    onChange={(e) => {
                        const on = (e.target as HTMLInputElement).checked;
                        const cur = response as string[];
                        setResponse(on ? [...cur, c] : cur.filter((x) => x !== c));
                    }} /> <span>{c}</span></label>
            ))}
            {q.type === 'predict-output' && (
                <>
                    <label for={`${uid}-in`}>What does it print?</label>
                    <textarea id={`${uid}-in`} class="tc-textarea" style="min-height:3.5rem" spellcheck={false}
                        onInput={(e) => setResponse((e.target as HTMLTextAreaElement).value)} />
                </>
            )}
            {q.type === 'fill-blank' && (
                <>
                    <label for={`${uid}-in`}>Your answer</label>{' '}
                    <input id={`${uid}-in`} class="tc-input" type="text" spellcheck={false} autocomplete="off"
                        onInput={(e) => setResponse((e.target as HTMLInputElement).value)} />
                </>
            )}
            {q.type === 'find-the-bug' && (
                <div role="radiogroup" aria-label="Which line has the bug?">
                    {q.code!.replace(/\n$/, '').split('\n').map((_, i) => (
                        <label class="tc-choice"><input type="radio" name={uid} checked={response === i + 1} onChange={() => setResponse(i + 1)} /> <span>Line {i + 1}</span></label>
                    ))}
                </div>
            )}
            {q.type === 'order-steps' && (
                <ol class="tc-order">
                    {order.map((s, i) => (
                        <li>
                            {s}{' '}
                            <button type="button" class="tc-btn" aria-label={`Move up: ${s}`} disabled={i === 0} onClick={() => move(i, -1)}>↑</button>{' '}
                            <button type="button" class="tc-btn" aria-label={`Move down: ${s}`} disabled={i === order.length - 1} onClick={() => move(i, 1)}>↓</button>
                        </li>
                    ))}
                </ol>
            )}

            {!done && !locked && <div class="tc-row"><button type="button" class="tc-btn primary" disabled={!canSubmit} onClick={submit}>Check</button></div>}
            <div aria-live="polite">
                {done && (
                    <div class={`tc-feedback ${result ? 'tc-ok' : 'tc-bad'}`}>
                        <p><strong>{result ? '✔ Correct!' : '✘ Not quite.'}</strong>{!result && <> The answer is: <code>{answerText(q)}</code></>}</p>
                        {!result && q.type === 'mcq' && typeof response === 'string' && q.distractor_feedback?.[response] && <p>{q.distractor_feedback[response]}</p>}
                        <p>{q.explanation}</p>
                    </div>
                )}
            </div>
        </fieldset>
    );
}
