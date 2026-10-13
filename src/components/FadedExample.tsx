import { useState } from 'preact/hooks';

interface Props {
    template: string;                 // blanks written as ___1___, ___2___ …
    answers: (string | string[])[];   // per blank: accepted strings; "/regex/" strings are regular expressions
    hints?: string[];
}

export function matchesAnswer(input: string, accepted: string | string[]): boolean {
    const value = input.trim();
    return [accepted].flat().some((a) => {
        const re = /^\/(.+)\/([a-z]*)$/.exec(a);
        return re ? new RegExp(re[1], re[2]).test(value) : value === a;
    });
}

export default function FadedExample({ template, answers, hints = [] }: Props) {
    const [values, setValues] = useState<string[]>(() => answers.map(() => ''));
    const [checked, setChecked] = useState<boolean[]>(() => answers.map(() => false));
    const parts = template.split(/___(\d+)___/);   // text, index, text, index …

    const stateOf = (i: number) => (!checked[i] || values[i].trim() === '' ? '' : matchesAnswer(values[i], answers[i]) ? 'ok' : 'bad');
    const allDone = answers.every((a, i) => matchesAnswer(values[i], a));

    const update = (i: number, v: string) => {
        setValues(values.map((old, j) => (j === i ? v : old)));
        setChecked(checked.map((old, j) => (j === i ? true : old)));
    };

    return (
        <section class="tc-box" aria-label="Faded example">
            <p class="tc-title">Fill in the blanks</p>
            <pre class="tc-code" style="white-space:pre-wrap">
                {parts.map((part, k) => {
                    if (k % 2 === 0) return part;
                    const i = Number(part) - 1;
                    return (
                        <input class="tc-input tc-blank" type="text" spellcheck={false} autocomplete="off"
                            aria-label={`Blank ${i + 1}`} data-state={stateOf(i)} value={values[i]}
                            onInput={(e) => update(i, (e.target as HTMLInputElement).value)} />
                    );
                })}
            </pre>
            <ul aria-live="polite" style="list-style:none;padding:0">
                {answers.map((_, i) => {
                    const s = stateOf(i);
                    if (!s) return null;
                    return (
                        <li>
                            <span class={`tc-badge ${s === 'ok' ? 'tc-ok' : 'tc-bad'}`}>{s === 'ok' ? '✔ correct' : '✘ not yet'}</span>{' '}
                            Blank {i + 1}{s === 'bad' && hints[i] ? ` — hint: ${hints[i]}` : ''}
                        </li>
                    );
                })}
            </ul>
            {allDone && <p class="tc-feedback tc-ok" role="status">All blanks are right. Well done!</p>}
        </section>
    );
}
