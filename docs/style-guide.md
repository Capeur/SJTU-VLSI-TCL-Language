# Style guide (PRD §12, condensed)

1. Grade 9–10 reading level; short sentences, active voice, address the learner as "you".
2. Define every term on first use with `<GlossaryTerm>`. Spell out acronyms (VLSI, GDS, DRC, dbu, RDB).
3. One idea per paragraph; ≤ 150 words between interactive elements; ≤ 3 goals per lesson.
4. Keep one analogy: the chip is a city map drawn in layers.
5. Code: 4-space indent; always brace `expr` and `if`/`while` conditions; descriptive names (`rectArea`); no clever one-liners in M10.
6. Every runnable snippet is tested; expected outputs come from real runs.
7. Calibre commands only from the status table, inside `<RealCalibre>` with the right badge. Never present ⚠️ as real syntax.
8. List `sources:` in frontmatter and "Further reading". Paraphrase; quote ≤ 1 short sentence, rarely.
9. Encouraging tone; errors are normal and useful.
10. Diagrams get alt text that says what they teach.

## Playground vs terminal code

11. **Playground lessons must not use `gets stdin`.** The browser has no keyboard input for a script. Either pass the text with the playground's `stdin` prop and read the Tcl variable `stdinText` (for example `split $stdinText \n`), or mark the snippet as terminal-only with `runs_in: terminal` (page frontmatter, or ` ```tcl run runs_in=terminal ` on one block).
12. Code that needs the real machine (`exec`, `open` on real files, `glob`, `socket`) is terminal-only too. `<RunWhere>` disables its Playground tab for these automatically.
13. Every snippet on a page whose frontmatter lists `runs_in: [playground]` (and every M10 page by default) is also run in the real browser engine, Wacl (Tcl 8.6.6), by CI. A snippet that works on your tclsh but fails there is a bug in the lesson. Use only features that exist in Tcl 8.6.6.

## Writing MDX safely (learned in P2)

14. **Put `$`, `{`, `}` and `[ ]` in prose inside inline code.** In MDX, a bare `{` starts a JavaScript expression, and the KaTeX plugin reads `$…$` as maths.
15. **Code containing backslashes goes in `String.raw`.** In a component prop, write ``code={String.raw`puts "a\tb"`}``. A plain template literal turns `\t` into a real tab before Tcl sees it.
16. **`<Trap>` takes `error` (the real first line(s) of the error message) or `output` (what the wrong code really prints).** CI runs `wrong` and `fix` on Tcl 8.6, 9.0 and Wacl, and fails if the text does not match.
17. **A `<TclPlayground>` that is meant to fail declares it:** ``fails={`can not find channel named "Hello"`}``. Every other playground and every `<WorkedExample>` must run without an error.
18. **Error text that differs between Tcl 8.6 and 9.0 goes in a `<VersionNote>`** with `fails86` / `fails90`.
19. **Use the chip's facts from `src/data/lumen-1.json`.** In prose write `{chip.name}`. In Tcl code, use the same numbers; `npm run validate` checks `chipName`, `chipWidth`, `chipHeight` and `{NAME x y w h}` blocks.
20. **M10 output never shows a decimal with more than 4 places** (rounding comes in Week 8). Pick friendlier numbers. If a long decimal is the point of the example, mark it: ```` ```tcl run longdecimal ````, `longDecimal` on a component, or `long_decimal: true` on a quiz item. `run-snippets` enforces this.
21. **Lessons, traps and quizzes must not reuse a lab's numbers**, so that they never give away a lab answer.

## Code-writing labs (from Week 1)

22. The lab page shows the target output from the lab's data file (`import x from '…/data/expected.txt?raw'`), never a hand-copied block.
23. Values the checker swaps live in `data/*.txt` as `set name value` lines and appear unchanged in `starter.tcl`; the self-test checks both. Tell learners to keep those lines exactly as given.
24. A lab self-test may build a passing program only for a small weekly lab. Capstone and exam graders are tested against the private solutions repository.
25. **From Week 4, a lab checker guards against loops that never end:** `interp limit $child commands`, plus a cap on captured output (Wacl has a fixed 16 MB heap). A runaway script gets a FAIL that says so; the checker never hangs or crashes the browser interpreter. The self-test covers both a silent and a printing endless loop.

28. **Every component that runs learner code in the browser goes through `src/lib/tclRuntime.ts`** (usually via `useTclRun`, showing `runProblem(result)`). That is what gives it the 5 s timeout, the output limit and the restart after an out-of-memory crash. The LayoutCanvas of P5 must do the same; `npm run test:browser` covers the guards.

## Scripts that read MDX (learned in P3)

26. **Never write a component tag such as `<Trap>` in an MDX comment or in prose.** `scripts/lib/mdx-scan.mjs` reads it as a real tag with no props, and snippet extraction crashes. Write "Trap component" instead.
27. **Quiz prompts and feedback quote only error messages that are the same on Tcl 8.6 and 9.0.** Quiz banks have no `VersionNote`; when the wording differs, describe the error in plain words.
29. **No `\'` inside a JavaScript string in a component prop** (`Goals`, `CheatCard`, notes). The MDX scanners do not read escapes, so a `\'` silently hides the rest of the page from `check-lessons` and snippet extraction. Write a typographic apostrophe (’) or use double quotes around the string.
30. **Quote a YAML frontmatter goal that contains `: `** (`- "Control what a proc can see: arguments…"`). Unquoted, YAML reads it as a mapping and the build fails.
