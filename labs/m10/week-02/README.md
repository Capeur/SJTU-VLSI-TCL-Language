# Week 2 lab: What does one Lumen-1 cost?

The full lab page, with step-by-step instructions, hints and an in-browser **Check my work** button, is on
the course site: `/m10/week-02/lab/`.

Compute Lumen-1's area, how many chips fit on a square test wafer, and the cost of one chip.
With the starter's inputs, your script must print the six lines in `data/expected.txt`.

## Files

| File | What it is |
|---|---|
| `starter.tcl` | Your script. Type your commands under each step comment. |
| `data/inputs.txt` | The four input lines from the starter. The checker looks for them. |
| `data/expected.txt` | The exact output for the starter's inputs. |
| `tests/test.tcl` | The checker. Do not edit it. |
| `tests/checker.tcl` | The grading code (shared with the browser). Do not edit it. |
| `tests/selftest.tcl` | Tests for the checker itself, run by CI. |

## Rules

- Keep the four input lines (`set chipWidth 400`, `set chipHeight 300`, `set waferSide 10000`,
  `set waferCost 1980`) exactly as they are. The checker changes their values and runs your script again,
  to test that every number is computed, not typed.
- Only whole chips count. Words, capitals and units must match; extra spaces are forgiven.

## Check your work

From this folder:

```sh
tclsh tests/test.tcl              # checks starter.tcl
tclsh tests/test.tcl mine.tcl     # checks another file
```

Each test gets a `PASS`, `FAIL` (with what was expected, what your script printed and a hint), `TODO` or
`NOTE` line. The last line is `RESULT: PASS 9/9` when everything is right. The exit code is 0 only on a full pass.

Solutions are not published. The checker works out every expected number from the inputs itself.
