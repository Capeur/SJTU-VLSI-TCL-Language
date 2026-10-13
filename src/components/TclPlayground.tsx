import { useState } from 'preact/hooks';
import { useTclRun, TIMEOUT_MESSAGE } from './useTclRun';

interface Props {
    code?: string;
    readonly?: boolean;
    drvlite?: boolean;
    stdin?: string;
}

export function Output({ phase, result, failure }: ReturnType<typeof useTclRun>) {
    return (
        <div aria-live="polite">
            {phase === 'loading' && <p class="tc-out">Loading the Tcl engine (first run only)…</p>}
            {phase === 'running' && <p class="tc-out">Running…</p>}
            {failure && <p class="tc-out err">{failure}</p>}
            {result?.timedOut && <p class="tc-out err">{TIMEOUT_MESSAGE}</p>}
            {result && !result.timedOut && (
                <>
                    <pre class="tc-out" aria-label="Output">{result.stdout || (result.ok ? '(no output)' : '')}</pre>
                    {result.stderr && <pre class="tc-out err" aria-label="Error output">{result.stderr}</pre>}
                    {result.error && <pre class="tc-out err" aria-label="Error message">{result.error}</pre>}
                </>
            )}
        </div>
    );
}

export default function TclPlayground({ code = '', readonly = false, drvlite = false, stdin }: Props) {
    const [text, setText] = useState(code);
    const [copied, setCopied] = useState(false);
    const state = useTclRun();
    const busy = state.phase === 'loading' || state.phase === 'running';

    const copy = async () => {
        try {
            await navigator.clipboard.writeText(text);
            setCopied(true);
            setTimeout(() => setCopied(false), 1500);
        } catch { /* clipboard blocked: nothing to do */ }
    };

    return (
        <div class="tc-box" data-playground>
            <p class="tc-title">Try it — Tcl playground <span class="tc-badge tc-info">Tcl 8.6.6</span></p>
            <textarea
                class="tc-textarea" spellcheck={false} readOnly={readonly} value={text}
                aria-label="Tcl code"
                onInput={(e) => setText((e.target as HTMLTextAreaElement).value)}
                onKeyDown={(e) => { if (e.key === 'Enter' && (e.ctrlKey || e.metaKey) && !busy) { e.preventDefault(); state.run(text, { drvlite, stdin }); } }}
            />
            <div class="tc-row">
                <button type="button" class="tc-btn primary" disabled={busy} onClick={() => state.run(text, { drvlite, stdin })}>▶ Run</button>
                <button type="button" class="tc-btn" disabled={readonly || text === code} onClick={() => setText(code)}>Reset</button>
                <button type="button" class="tc-btn" onClick={copy}>{copied ? 'Copied!' : 'Copy'}</button>
                <span style="font-size:0.8rem;opacity:0.8">Ctrl+Enter runs · best on a computer</span>
            </div>
            <Output {...state} />
        </div>
    );
}
