# Week 5 lab: Rectangles as lists

The full lab page, with step-by-step instructions, a picture of the shapes, hints and an in-browser
**Check my work** button, is on the course site: `/m10/week-05/lab/`.

Store METAL1 rectangles as lists `{x1 y1 x2 y2}`, work out their widths, heights and areas, and find the
ones that are narrower than the minimum width.
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

- Keep the three input lines (`set rect {30 40 90 70}`, `set shapes {30 40 90 70 100 40 104 150 120 60 170 62}`,
  `set minWidth 3`) exactly as they are. The checker changes their values twice and runs your script again,
  to test that every line is worked out from the lists.
- A rectangle is `{x1 y1 x2 y2}`: (x1, y1) is the bottom-left corner and (x2, y2) the top-right corner.
  `shapes` holds several rectangles in one flat list, four numbers per rectangle.
- A shape is too narrow if its width or its height is less than `minWidth`. Print one line
  `Too narrow: shape N` per narrow shape, in order, or `Too narrow: none`.
- Words, capitals and units must match; extra spaces are forgiven.

## Check your work

From this folder:

```sh
tclsh tests/test.tcl              # checks starter.tcl
tclsh tests/test.tcl mine.tcl     # checks another file
```

Each test gets a `PASS`, `FAIL` (with what was expected, what your script printed and a hint), `TODO` or
`NOTE` line. The last line is `RESULT: PASS 11/11` when everything is right. The exit code is 0 only on a full pass.

A loop that never ends does not freeze the checker: after a few seconds it stops your script and tells you.
If the tests seem stuck for more than a few seconds, press Ctrl+C: your loop probably never ends.

Solutions are not published. The checker works out every expected line from the inputs itself.
