import { useState, useRef } from 'preact/hooks';
import TclPlayground from './TclPlayground';
import { hostFeatureProblem } from '../lib/tclRuntime';
import { useUid } from './useUid';

interface Props { code: string; filename?: string; }

/** Tabs: Playground / Terminal. The Playground tab is disabled when the code needs the real machine. */
export default function RunWhere({ code, filename = 'script.tcl' }: Props) {
    const uid = useUid('rw');
    const problem = hostFeatureProblem(code);
    const tabs = [
        { id: 'playground', label: 'Playground', disabled: problem !== null },
        { id: 'terminal', label: 'Terminal', disabled: false },
    ];
    const [active, setActive] = useState(problem ? 'terminal' : 'playground');
    const refs = useRef<Record<string, HTMLButtonElement | null>>({});

    const onKey = (e: KeyboardEvent, index: number) => {
        if (e.key !== 'ArrowRight' && e.key !== 'ArrowLeft') return;
        e.preventDefault();
        const step = e.key === 'ArrowRight' ? 1 : -1;
        for (let n = 1; n <= tabs.length; n++) {
            const next = tabs[(index + step * n + tabs.length * 2) % tabs.length];
            if (!next.disabled) { setActive(next.id); refs.current[next.id]?.focus(); return; }
        }
    };

    return (
        <section class="tc-box tc-tabs" aria-label={`Where to run ${filename}`}>
            <p class="tc-title">Where to run this</p>
            <div role="tablist" aria-label="Where to run this">
                {tabs.map((tab, i) => (
                    <button
                        type="button" role="tab" id={`${uid}-tab-${tab.id}`} aria-controls={`${uid}-panel-${tab.id}`}
                        aria-selected={active === tab.id} aria-disabled={tab.disabled}
                        tabIndex={active === tab.id ? 0 : -1}
                        ref={(el) => { refs.current[tab.id] = el; }}
                        onClick={() => { if (!tab.disabled) setActive(tab.id); }}
                        onKeyDown={(e) => onKey(e, i)}
                    >{tab.label}{tab.disabled ? ' (not available)' : ''}</button>
                ))}
            </div>
            {problem && <p class="tc-feedback tc-warn" role="note">This code {problem}, so it cannot run in the browser. Use the Terminal tab.</p>}
            {active === 'playground' && !problem && (
                <div role="tabpanel" id={`${uid}-panel-playground`} aria-labelledby={`${uid}-tab-playground`}><TclPlayground code={code} /></div>
            )}
            {active === 'terminal' && (
                <div role="tabpanel" id={`${uid}-panel-terminal`} aria-labelledby={`${uid}-tab-terminal`}>
                    <p>Save this as <code>{filename}</code>, then run <code>tclsh {filename}</code> in a terminal.</p>
                    <pre class="tc-code" tabindex={0}>{code}</pre>
                </div>
            )}
        </section>
    );
}
