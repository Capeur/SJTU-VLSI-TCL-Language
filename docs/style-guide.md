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
