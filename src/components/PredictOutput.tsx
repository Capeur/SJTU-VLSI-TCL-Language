import { useState } from 'preact/hooks';
import { useTclRun, TIMEOUT_MESSAGE } from './useTclRun';
import { normaliseOutput } from '../lib/tclRuntime';

interface Props { code: string; expected: string; explanation: string; }

/** Predict → Run → Explain. Run stays locked until the learner has typed a prediction. */
export default function PredictOutput({ code, expected, explanation }: Props) {
    const [guess, setGuess] = useState('');
    const state = useTclRun();
    const busy = state.phase === 'loading' || state.phase === 'running';
    const { result } = state;
    const matches = result && !result.timedOut && normaliseOutput(guess) === normaliseOutput(result.stdout);

    return (
        <section class="tc-box" aria-label="Predict, run, explain">
            <p class="tc-title">Predict → Run → Explain</p>
            <p>Read the code. What will it print? Type your prediction before you run it.</p>
            <pre class="tc-code" tabindex={0}>{code}</pre>
            <label for="po-guess"><strong>Your prediction</strong></label>
            <textarea id="po-guess" class="tc-textarea" style="min-height:3.5rem" spellcheck={false} value={guess}
                onInput={(e) => setGuess((e.target as HTMLTextAreaElement).value)} />
            <div class="tc-row">
                <button type="button" class="tc-btn primary" disabled={busy || guess.trim() === ''} onClick={() => state.run(code)}>▶ Run</button>
                {guess.trim() === '' && <span style="font-size:0.85rem">Type a prediction to unlock Run.</span>}
            </div>
            <div aria-live="polite">
                {busy && <p class="tc-out">{state.phase === 'loading' ? 'Loading the Tcl engine (first run only)…' : 'Running…'}</p>}
                {state.failure && <p class="tc-out err">{state.failure}</p>}
                {result?.timedOut && <p class="tc-out err">{TIMEOUT_MESSAGE}</p>}
                {result && !result.timedOut && (
                    <>
                        <p>Tcl printed:</p>
                        <pre class="tc-out">{result.stdout || '(no output)'}</pre>
                        {result.error && <pre class="tc-out err">{result.error}</pre>}
                        {matches
                            ? <p class="tc-feedback tc-ok">✔ Your prediction matches. Nice reading!</p>
                            : (
                                <div class="tc-feedback tc-info">
                                    <p><strong>Not quite — and that is useful.</strong> Compare your guess with the real output.</p>
                                    <p>{explanation}</p>
                                </div>
                            )}
                    </>
                )}
                {/* expected is kept for the snippet tests; it is never shown before the learner runs */}
                <span hidden data-expected>{expected}</span>
            </div>
        </section>
    );
}
