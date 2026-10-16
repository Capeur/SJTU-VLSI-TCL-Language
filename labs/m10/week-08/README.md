# Week 8 lab: Check the layer names

The full lab page, with step-by-step instructions, hints and an in-browser **Check my work** button,
is on the course site: `/m10/week-08/lab/`.

Clean a list of layer names typed by people, check each one against the layers of Lumen-1 and a list of
purposes, and print a summary with the share of valid names.
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

## Our cleaning rules

These are the course's rules for this lab, not the behaviour of a real design tool.

1. Trim the spaces at both ends of the name, then replace every `-` with `_`.
2. A name with no `_` has no purpose: print `BAD`, the name in capitals, and `: no purpose`.
3. Otherwise, cut the name at its **first** `_`. The layer is the part before it, in capitals;
   the purpose is the part after it, in lower case. The clean name is `LAYER_purpose`.
4. If the layer is not in `knownLayers`: `BAD <clean name>: unknown layer <layer>`.
   Else, if the purpose is not in `knownPurposes`: `BAD <clean name>: unknown purpose <purpose>`.
   Else: `OK <clean name>`.
5. Last line: `Valid: <OK count> of <name count> (<share>%)`, with the share rounded to 1 decimal.

- Keep the three input lines (`set rawNames {…}`, `set knownLayers {…}`, `set knownPurposes {…}`)
  exactly as they are. The checker changes their values twice and runs your script again.
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
