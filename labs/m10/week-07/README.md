# Week 7 lab: rectArea and rectOverlaps

The full lab page, with step-by-step instructions, a picture of the floorplan, hints and an in-browser
**Check my work** button, is on the course site: `/m10/week-07/lab/`.

Write two procs, `rectArea` and `rectOverlaps`, then use them to check a floorplan of five blocks inside
CORE: print each block's area, and every pair of blocks that clash.
With the starter's input, your script must print the lines in `data/expected.txt`.

## Files

| File | What it is |
|---|---|
| `starter.tcl` | Your script. Type your commands under each step comment. |
| `data/inputs.txt` | The input line from the starter. The checker looks for it. |
| `data/expected.txt` | The exact output for the starter's input. |
| `tests/test.tcl` | The checker. Do not edit it. |
| `tests/checker.tcl` | The grading code (shared with the browser). Do not edit it. |
| `tests/selftest.tcl` | Tests for the checker itself, run by CI. |

## Rules

- Keep the input line `set plan {…}` exactly as it is. The checker changes it twice and runs your script
  again, to test that every line is worked out from the floorplan.
- `rectArea rect` returns the area of a rectangle `{x1 y1 x2 y2}`.
- `rectOverlaps a b` returns `1` if the two rectangles overlap **or touch**, and `0` if there is space
  between them. The course rule: `x1a <= x2b && x1b <= x2a && y1a <= y2b && y1b <= y2a`.
  Touching along an edge or at a corner counts; a 1 µm gap does not. `rectOverlaps a b` and
  `rectOverlaps b a` must give the same answer.
- The checker calls both procs with its own test rectangles, so use exactly these names and argument orders.
- Check every pair of blocks once, in order (the second block of a pair comes after the first in `plan`).
- Words, capitals and punctuation must match; extra spaces are forgiven.

## Check your work

From this folder:

```sh
tclsh tests/test.tcl              # checks starter.tcl
tclsh tests/test.tcl mine.tcl     # checks another file
```

Each test gets a `PASS`, `FAIL` (with what was expected, what your script printed and a hint), `TODO` or
`NOTE` line. The last line is `RESULT: PASS 15/15` when everything is right. The exit code is 0 only on a full pass.

Solutions are not published. The checker works out every expected line and answer from the inputs itself.
