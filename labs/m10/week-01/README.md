# Week 1 lab: Chip passport

The full lab page, with step-by-step instructions, hints and an in-browser **Check my work** button, is on
the course site: `/m10/week-01/lab/`.

Write a script that prints Lumen-1's passport: the five lines in `data/passport.txt`, in that order.

## Files

| File | What it is |
|---|---|
| `starter.tcl` | Your script. Type your commands under each step comment. |
| `data/passport.txt` | The exact output your script must print. |
| `data/facts.txt` | The three `set` lines from the starter. The checker looks for them. |
| `tests/test.tcl` | The checker. Do not edit it. |
| `tests/checker.tcl` | The grading code (shared with the browser). Do not edit it. |
| `tests/selftest.tcl` | Tests for the checker itself, run by CI. |

## Rules

- Capitals, spelling and punctuation must match. Extra spaces are forgiven.
- Keep the three lines `set chipName Lumen-1`, `set chipWidth 400` and `set chipHeight 300` exactly as they are.
  The checker changes their values and runs your script again, to test that you used `$chipName`,
  `$chipWidth` and `$chipHeight`.
- Sign your work in the `# Made by:` comment.

## Check your work

From this folder:

```sh
tclsh tests/test.tcl              # checks starter.tcl
tclsh tests/test.tcl mine.tcl     # checks another file
```

Each test gets a `PASS`, `FAIL` (with what was expected and what your script printed), `TODO` or `NOTE` line.
The last line is `RESULT: PASS 9/9` when everything is right. The exit code is 0 only on a full pass.

Solutions are not published.
