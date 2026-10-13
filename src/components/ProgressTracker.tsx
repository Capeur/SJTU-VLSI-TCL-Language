import { useEffect, useState } from 'preact/hooks';
import { load, isPersistent, exportJson, importJson, reset, type ProgressState } from '../lib/progress';

/** Local-only progress: summary, export/import as JSON, reset (PRD §7). */
export default function ProgressTracker() {
    const [state, setState] = useState<ProgressState | null>(null);
    const [persistent, setPersistent] = useState(true);
    const [message, setMessage] = useState('');
    const [confirmReset, setConfirmReset] = useState(false);

    const refresh = () => { setState({ ...load() }); setPersistent(isPersistent()); };
    useEffect(refresh, []);

    const download = () => {
        const blob = new Blob([exportJson()], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url; a.download = 'tcl-to-tapeout-progress.json'; a.click();
        URL.revokeObjectURL(url);
        setMessage('Progress file downloaded.');
    };
    const onFile = async (e: Event) => {
        const file = (e.target as HTMLInputElement).files?.[0];
        if (!file) return;
        const error = importJson(await file.text());
        setMessage(error ?? 'Progress imported.');
        refresh();
    };

    if (!state) return <div class="tc-box"><p>Loading progress…</p></div>;
    const quizzes = Object.values(state.quiz);
    return (
        <section class="tc-box" aria-label="Your progress">
            <p class="tc-title">Your progress (stored only in this browser)</p>
            {!persistent && <p class="tc-feedback tc-warn" role="note">Your browser blocks local storage, so progress is kept only until you close this tab. Use Export to save it.</p>}
            <ul>
                <li>Lessons visited: <strong>{Object.keys(state.visited).length}</strong></li>
                <li>Quizzes finished: <strong>{quizzes.length}</strong> (best total {quizzes.reduce((s, q) => s + q.correct, 0)} / {quizzes.reduce((s, q) => s + q.total, 0)})</li>
                <li>Review cards: <strong>{Object.keys(state.cards).length}</strong></li>
            </ul>
            <div class="tc-row">
                <button type="button" class="tc-btn" onClick={download}>Export JSON</button>
                <label class="tc-btn" tabIndex={0} onKeyDown={(e) => { if (e.key === 'Enter' || e.key === ' ') (e.currentTarget.querySelector('input') as HTMLInputElement).click(); }}>
                    Import JSON <input type="file" accept="application/json" class="tc-sr" tabIndex={-1} onChange={onFile} />
                </label>
                {!confirmReset
                    ? <button type="button" class="tc-btn" onClick={() => setConfirmReset(true)}>Reset…</button>
                    : <>
                        <span>Erase all progress?</span>
                        <button type="button" class="tc-btn" onClick={() => { reset(); refresh(); setConfirmReset(false); setMessage('Progress erased.'); }}>Yes, erase</button>
                        <button type="button" class="tc-btn" onClick={() => setConfirmReset(false)}>Cancel</button>
                    </>}
            </div>
            <p role="status">{message}</p>
        </section>
    );
}
