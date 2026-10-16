import { useEffect, useState } from 'preact/hooks';
import { getRuntime, normaliseOutput } from '../lib/tclRuntime';
import { runProblem } from './useTclRun';
import { recordQuiz } from '../lib/progress';
import { useUid } from './useUid';

// A milestone exam (PRD §9.1; decision log, P3 Week 10). The page holds NO answers: every item is graded by
// RUNNING Tcl in the browser, through src/lib/tclRuntime.ts, so the timeout, the output limit and the restart
// after a crash protect it (style rule 28).
//   predict-output: the learner types the output; the item's code is run and its output compared.
//   complete-code:  the learner's text fills the blank ___; the result is run and compared with the target.
//   choose-code:    the chosen script is run and compared with the target.

export interface ExamItem {
    id: string;
    type: 'predict-output' | 'complete-code' | 'choose-code';
    week: number;
    prompt: string;
    code?: string;
    target?: string;
    choices?: string[];
    revisitUrl: string;
    revisitLabel: string;
}

interface Result { ok: boolean; printed: string; note: string; }

interface Props { examId: string; items: ExamItem[]; }

const TYPE_HELP: Record<ExamItem['type'], string> = {
    'predict-output': 'Type exactly what this prints.',
    'complete-code': 'Type what goes in the blank ___ so that the script prints the target.',
    'choose-code': 'Choose the script that prints exactly the target.',
};

/** The script to run for an item and an answer, or null when there is nothing to run. */
function scriptFor(item: ExamItem, answer: string): string | null {
    if (item.type === 'predict-output') return item.code ?? '';
    if (item.type === 'complete-code') return answer.trim() === '' ? null : (item.code ?? '').replace('___', answer.trim());
    const index = Number(answer);
    return answer !== '' && item.choices?.[index] !== undefined ? item.choices[index] : null;
}

export default function ExamPaper({ examId, items }: Props) {
    const uid = useUid('exam');
    const [answers, setAnswers] = useState<string[]>(() => items.map(() => ''));
    const [phase, setPhase] = useState<'answering' | 'checking' | 'done'>('answering');
    const [progress, setProgress] = useState('');
    const [results, setResults] = useState<Result[]>([]);
    const [failure, setFailure] = useState('');
    const [ready, setReady] = useState(false);
    useEffect(() => setReady(true), []);
    const unanswered = answers.filter((a) => a.trim() === '').length;

    const setAnswer = (i: number, value: string) => setAnswers(answers.map((a, j) => (j === i ? value : a)));

    async function check() {
        setFailure('');
        setPhase('checking');
        setProgress('Loading the Tcl engine (first run only)…');
        const runtime = getRuntime();
        try {
            await runtime.init();
        } catch (e) {
            setPhase('answering');
            setFailure(`The Tcl engine could not start (${(e as Error).message}). Try reloading the page.`);
            return;
        }
        const out: Result[] = [];
        for (let i = 0; i < items.length; i++) {
            setProgress(`Checking item ${i + 1} of ${items.length}…`);
            const item = items[i];
            const answer = answers[i];
            const script = scriptFor(item, answer);
            if (script === null || (item.type === 'predict-output' && answer.trim() === '')) {
                out.push({ ok: false, printed: '', note: 'No answer.' });
                continue;
            }
            const result = await runtime.run(script);
            const problem = runProblem(result);
            const printed = result.stdout;
            if (problem) out.push({ ok: false, printed, note: problem });
            else if (!result.ok) out.push({ ok: false, printed, note: `It stops with an error: ${result.error.split('\n')[0]}` });
            else {
                const want = item.type === 'predict-output' ? answer : item.target ?? '';
                out.push({ ok: normaliseOutput(printed) === normaliseOutput(want), printed, note: '' });
            }
        }
        const correct = out.filter((r) => r.ok).length;
        recordQuiz(examId, correct, items.length);
        setResults(out);
        setPhase('done');
    }

    if (phase === 'done') {
        const correct = results.filter((r) => r.ok).length;
        const share = Math.round((100 * correct) / items.length);
        return (
            <section class="tc-box" aria-label="Exam results">
                <p class="tc-title">Your result</p>
                <p role="status"><strong>{correct} / {items.length}</strong> ({share} %). {share >= 60
                    ? 'That is a solid base for M20. Revisit the lessons of the items you missed.'
                    : 'Below 60 %: spend a few days on the lessons of the items you missed, then take the exam again.'}</p>
                <ol>
                    {items.map((item, i) => (
                        <li data-item={item.id} data-ok={results[i].ok ? 'true' : 'false'}>
                            <span class={`tc-badge ${results[i].ok ? 'tc-ok' : 'tc-bad'}`}>{results[i].ok ? '✔ right' : '✘ not yet'}</span>{' '}
                            Week {item.week}. {results[i].note}{' '}
                            {item.type === 'predict-output' && results[i].printed !== '' && !results[i].ok && (
                                <>Tcl really prints:<pre class="tc-out">{results[i].printed}</pre></>
                            )}
                            {item.type !== 'predict-output' && !results[i].ok && results[i].note === '' && (
                                <>Your answer printed:<pre class="tc-out">{results[i].printed || '(no output)'}</pre></>
                            )}
                            {!results[i].ok && <>Revisit: <a href={item.revisitUrl}>{item.revisitLabel}</a>.</>}
                        </li>
                    ))}
                </ol>
                <button type="button" class="tc-btn" onClick={() => setPhase('answering')}>Change my answers and check again</button>
            </section>
        );
    }

    const busy = phase === 'checking';
    return (
        <form onSubmit={(e) => e.preventDefault()} aria-label="Exam" data-ready={ready ? 'true' : undefined}>
            {items.map((item, i) => (
                <fieldset class="tc-box" disabled={busy}>
                    <legend class="tc-title">Item {i + 1} of {items.length} · Week {item.week}</legend>
                    <p>{item.prompt} <em>{TYPE_HELP[item.type]}</em></p>
                    {item.type !== 'choose-code' && <pre class="tc-code" tabindex={0}>{item.code}</pre>}
                    {item.type !== 'predict-output' && (
                        <>
                            <p>Target output:</p>
                            <pre class="tc-out">{item.target}</pre>
                        </>
                    )}
                    {item.type === 'predict-output' && (
                        <>
                            <label for={`${uid}-${i}`}><strong>Your prediction</strong></label>
                            <textarea id={`${uid}-${i}`} class="tc-textarea" style="min-height:3.5rem" spellcheck={false}
                                value={answers[i]} onInput={(e) => setAnswer(i, (e.target as HTMLTextAreaElement).value)} />
                        </>
                    )}
                    {item.type === 'complete-code' && (
                        <>
                            <label for={`${uid}-${i}`}><strong>Your text for the blank</strong></label>{' '}
                            <input id={`${uid}-${i}`} class="tc-input" type="text" spellcheck={false} autocomplete="off"
                                value={answers[i]} onInput={(e) => setAnswer(i, (e.target as HTMLInputElement).value)} />
                        </>
                    )}
                    {item.type === 'choose-code' && (item.choices ?? []).map((code, c) => (
                        <label class="tc-choice" style="display:block">
                            <input type="radio" name={`${uid}-${i}`} value={String(c)} checked={answers[i] === String(c)}
                                onChange={() => setAnswer(i, String(c))} /> Script {c + 1}
                            <pre class="tc-code">{code}</pre>
                        </label>
                    ))}
                </fieldset>
            ))}
            <div class="tc-row">
                <button type="button" class="tc-btn primary" disabled={busy || !ready} onClick={check}>Check my exam</button>
                {!busy && unanswered > 0 && <span style="font-size:0.9rem">{unanswered} item{unanswered === 1 ? '' : 's'} still without an answer.</span>}
            </div>
            <p aria-live="polite">{busy ? progress : ''}</p>
            {failure && <p class="tc-out err">{failure}</p>}
        </form>
    );
}
