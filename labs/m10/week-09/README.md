# Week 9 lab: The layer table

The full lab page, with step-by-step instructions, hints and an in-browser **Check my work** button,
is on the course site: `/m10/week-09/lab/`.

Build a table of Lumen-1's teaching layers from their GDS numbers, look one layer up, count the shapes of a
small layout on each layer, and list the shapes on layers that are not in the table.
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

- Keep the three input lines (`set layerNumbers {…}`, `set shapeLayers {…}`, `set lookUp METAL1`) exactly as
  they are. The checker changes the shapes and the layer to look up twice, and runs your script again.
- `layerNumbers` is a dict: each layer name is followed by its GDS number, `layer.datatype`. These are teaching
  numbers, not any factory's. In this course, datatype 0 means `drawing` for every layer.
- The record of a layer is `{number N datatype D purpose drawing}`. Print it as
  `METAL1: number 4, datatype 0, purpose drawing`, or `NAME: not in the table`.
- The count lines follow the order of the table, one per layer, even with 0 shapes. Do not rely on the order of
  `array names`: it is not promised and may differ between Tcl versions.
- The `Unknown:` line names each unknown layer once, sorted, separated by `, `; or `Unknown: none`.
- Words, capitals and punctuation must match; extra spaces are forgiven.

## Check your work

From this folder:

```sh
tclsh tests/test.tcl              # checks starter.tcl
tclsh tests/test.tcl mine.tcl     # checks another file
```

Each test gets a `PASS`, `FAIL` (with what was expected, what your script printed and a hint), `TODO` or
`NOTE` line. The last line is `RESULT: PASS 10/10` when everything is right. The exit code is 0 only on a full pass.

A loop that never ends does not freeze the checker: after a few seconds it stops your script and tells you.
If the tests seem stuck for more than a few seconds, press Ctrl+C: your loop probably never ends.

Solutions are not published. The checker works out every expected line from the inputs itself.
