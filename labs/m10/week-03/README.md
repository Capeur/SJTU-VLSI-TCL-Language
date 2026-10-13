# Week 3 lab: Substitution detective

The full lab page, with hints and an in-browser **Check my work** button, is on the course site:
`/m10/week-03/lab/`.

**This lab trains prediction. Predict first, run to check.**

## Files

| File | What it is |
|---|---|
| `data/puzzles.txt` | The 15 puzzles. Read them; do not run them before you predict. |
| `starter.tcl` | Your answers: one line `set pNN {…}` per puzzle. Replace `???` with your prediction. |
| `tests/test.tcl` | The checker. Do not edit it. |
| `tests/checker.tcl` | The grading code (shared with the browser). Do not edit it. |
| `tests/selftest.tcl` | Tests for the checker itself, run by CI. |

## Rules

- Write each prediction **inside braces**, exactly as the puzzle prints it.
- If a puzzle prints two lines, put both lines inside the braces.

## Check your work

From this folder:

```sh
tclsh tests/test.tcl              # checks starter.tcl
tclsh tests/test.tcl mine.tcl     # checks another file
```

Each puzzle gets a `PASS`, `FAIL` (with what Tcl prints, what you wrote, and what to revisit) or `TODO` line.
The last line is `RESULT: PASS 15/15` when all predictions are right. The exit code is 0 only on a full pass.

Solutions are not published. The checker works out every correct output by running the puzzle itself.
