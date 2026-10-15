# Week 6 lab: Sort cells by area

The full lab page, with step-by-step instructions, a picture of the cells, hints and an in-browser
**Check my work** button, is on the course site: `/m10/week-06/lab/`.

Rank a small library of standard cells from the largest area to the smallest, name the largest ones,
and look up the rank of one cell.
With the starter's inputs, your script must print the lines in `data/expected.txt`.

## Files

| File | What it is |
|---|---|
| `starter.tcl` | Your script. Type your commands under each step comment. |
| `data/inputs.txt` | The three input lines from the starter. The checker looks for them. |
| `data/expected.txt` | The exact output for the starter's inputs. |
| `tests/test.tcl` | The checker. Do not edit it. |
| `tests/checker.tcl` | The grading code (shared with the browser). Do not edit it. |
| `tests/selftest.tcl` | Tests for the checker itself, run by CI. |

## Rules

- Keep the three input lines (`set cells {…}`, `set topCount 3`, `set findCell NOR2`) exactly as they are.
  The checker changes their values twice and runs your script again, to test that every line is worked
  out from the inputs.
- Each cell is a pair `{name {x1 y1 x2 y2}}`: its name, then its rectangle in µm. The area is
  (x2 − x1) × (y2 − y1).
- Print the cells largest first, numbered from 1. Cells with the same area keep the order they were given
  in (lsort does this for you).
- The last line is `NAME: rank N`, or `NAME: not found` if the cell is not in the list.
- Words, capitals and punctuation must match; extra spaces are forgiven.

## Check your work

From this folder:

```sh
tclsh tests/test.tcl              # checks starter.tcl
tclsh tests/test.tcl mine.tcl     # checks another file
```

Each test gets a `PASS`, `FAIL` (with what was expected, what your script printed and a hint), `TODO` or
`NOTE` line. The last line is `RESULT: PASS 9/9` when everything is right. The exit code is 0 only on a full pass.

Solutions are not published. The checker works out every expected line from the inputs itself.
