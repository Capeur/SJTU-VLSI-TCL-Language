# Week 4 lab: Is this wire wide enough?

The full lab page, with step-by-step instructions, a picture of the channel, hints and an in-browser
**Check my work** button, is on the course site: `/m10/week-04/lab/`.

Check one METAL1 wire against the minimum width, then count how many minimum-width wires fit side by side
in the 20 µm channel between the CORE and SRAM blocks of Lumen-1.
With the starter's inputs, your script must print the lines in `data/expected.txt`.

## Files

| File | What it is |
|---|---|
| `starter.tcl` | Your script. Type your commands under each step comment. |
| `data/inputs.txt` | The five input lines from the starter. The checker looks for them. |
| `data/expected.txt` | The exact output for the starter's inputs. |
| `tests/test.tcl` | The checker. Do not edit it. |
| `tests/checker.tcl` | The grading code (shared with the browser). Do not edit it. |
| `tests/selftest.tcl` | Tests for the checker itself, run by CI. |

## Rules

- Keep the five input lines (`set wireName CLK`, `set wireWidth 2`, `set minWidth 3`, `set minSpace 2`,
  `set channelWidth 20`) exactly as they are. The checker changes their values three times and runs your
  script again, to test every branch of your `if` and every length of your loop.
- The result is exactly one of `TOO NARROW`, `OK, AT THE MINIMUM` or `OK`.
- The first track starts `minSpace` away from CORE. A track fits if `x + minWidth + minSpace` is not more
  than `channelWidth`.
- Words, capitals and units must match; extra spaces are forgiven.
- These are teaching numbers. Real chips use much thinner wires.

## Check your work

From this folder:

```sh
tclsh tests/test.tcl              # checks starter.tcl
tclsh tests/test.tcl mine.tcl     # checks another file
```

Each test gets a `PASS`, `FAIL` (with what was expected, what your script printed and a hint), `TODO` or
`NOTE` line. The last line is `RESULT: PASS 9/9` when everything is right. The exit code is 0 only on a full pass.

A loop that never ends does not freeze the checker: after a few seconds it stops your script and tells you.
If the tests seem stuck for more than a few seconds, press Ctrl+C: your loop probably never ends.

Solutions are not published. The checker works out every expected line from the inputs itself.
