# M10 capstone: Mini Floorplan Checker

The full capstone page, with the specification, the rubric, hints and an in-browser **Check my work**
button, is on the course site: `/m10/capstone/`.

Check a floorplan of Lumen-1 with four proposed new blocks and three badly typed entries: refuse the bad
entries with `try`, compute the areas, find the blocks outside the chip and every pair of blocks that clash,
and print a formatted report.
With the starter's inputs, your script must print the lines in `data/expected.txt`.

## Files

| File | What it is |
|---|---|
| `starter.tcl` | Your script. Type your code under each step comment. |
| `data/inputs.txt` | The four input lines from the starter. The checker looks for them. |
| `data/expected.txt` | The exact report for the starter's inputs. |
| `data/hidden.txt` | Fingerprints (hashes) of the reports for three hidden floorplans. |
| `tests/test.tcl` | The checker. Do not edit it. |
| `tests/checker.tcl` | The grading code (shared with the browser). Do not edit it. |
| `tests/selftest.tcl` | Tests for the checker itself, run by CI. |

## The rules, in short

- Blocks are `{name x y w h}`; the chip is the rectangle from (0, 0) to (`chipWidth`, `chipHeight`).
- `checkBlock` refuses a block with exactly one of these messages, checked in this order:
  `needs 5 values, got N`; `x is not a number: …` (then y, w, h); `w must be positive, got …` (then h).
- **Blocks may touch the chip's edge, but not each other.** The boundary is a limit, not a neighbour: two
  touching blocks leave no room between them for wires, but a block that reaches the edge has nothing on the
  other side that needs room. It is still inside the chip.
- Every good block gets an area line, even if it is outside the chip, and is checked for conflicts with every
  other good block. **Total** and its percentage count only the good blocks **inside** the chip.
- `Skipped: N` counts the bad entries. **Problems** counts the Outside lines plus the Conflict lines only.
- Keep the four input lines exactly as they are. Words, capitals and punctuation must match; extra spaces are
  forgiven.

## Check your work

From this folder:

```sh
tclsh tests/test.tcl              # checks starter.tcl
tclsh tests/test.tcl mine.tcl     # checks another file
```

You get one `PASS` / `FAIL` / `NOTE` line per test with its points, then `RESULT: PASS 17/17` when every
automatic test passes, and a `SCORE` line: correctness out of 50 and error handling out of 25. Readability
(25 points) is not checked automatically: score yourself with the list on the capstone page.

A loop that never ends does not freeze the checker: after a few seconds it stops your script and tells you.
If the tests seem stuck for more than a few seconds, press Ctrl+C: your loop probably never ends.

No solution is published. The expected reports of the hidden floorplans are stored only as fingerprints.
