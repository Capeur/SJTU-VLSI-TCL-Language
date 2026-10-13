import { useState } from 'preact/hooks';

interface Props { hints: string[]; }

/** Up to 3 hints, revealed one at a time (PRD §7). */
export default function Hints({ hints }: Props) {
    const shown = hints.slice(0, 3);
    const [count, setCount] = useState(0);
    return (
        <section class="tc-box" aria-label="Hints">
            <p class="tc-title">Stuck? Hints</p>
            <ol aria-live="polite">{shown.slice(0, count).map((h) => <li>{h}</li>)}</ol>
            {count < shown.length
                ? <button type="button" class="tc-btn" onClick={() => setCount(count + 1)}>Show hint {count + 1} of {shown.length}</button>
                : <p>No more hints — you can do it. Ask for help if you need it.</p>}
        </section>
    );
}
