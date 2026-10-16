# Grader for the M10 capstone "Mini Floorplan Checker" (PRD §9.1, §11).
# Pure Tcl with no file access, so the same code runs in tclsh and in the browser playground.
# Needs: labData(inputs.txt) (the starter's input lines), labData(expected.txt) (the report for those inputs,
# shown on the page) and labData(hidden.txt) (hashes of the reports for the hidden floorplans).
# Provides: labCheck learnerCode -> the report as text, with a RESULT line and a SCORE line.
#
# THIS GRADER CONTAINS NO SOLUTION (user decision, P3 Week 10). It never works out a report itself:
#   - the visible report is compared with data/expected.txt;
#   - each hidden floorplan's report is compared line by line with FNV-1a hashes in data/hidden.txt.
#     The hidden INPUTS are public (labHidden below); only their expected lines are hashed. A hash keeps the
#     expected text out of plain sight; it is not a secret (a learner can still work the answer out by hand).
#   - the procs are called with small test cases whose expected answers are written out below.
# expected.txt and hidden.txt are generated from the private reference solution
# (Capeur/SJTU-VLSI-TCL-Language-solutions, tools/make-capstone-data.tcl); CI checks them there.
#
# Points (PRD rubric): correctness 50, error handling 25 (automatic); readability 25 is a self-check on the page.

# A loop that never ends must not freeze the checker: every run, and every proc call, may use at most
# this many commands. A correct script uses fewer than 2000. (interp limit works in tclsh 8.6, 9.0 and Wacl.)
set labCommandLimit 100000
set labCallLimit 10000
# An endless loop that prints would also fill the memory: Wacl has only 16 MB, and running out stops the
# whole browser interpreter. So the captured output is capped too; a correct report is under 1000 characters.
set labOutputLimit 20000
# The terminal checker (tests/test.tcl) also sets labTimeLimit, in seconds per run. A loop with an empty
# body, like while 1 {}, runs no commands, so the command limit never stops it; a time limit does (tested
# on Tcl 8.6, 9.0 and Wacl). In the browser it stays 0, off: the playground's 5 s timeout covers that case.
if {![info exists labTimeLimit]} {
    set labTimeLimit 0
}

# Set (or reset) the time limit of a child interpreter: labTimeLimit seconds from now.
proc labStartClock {child} {
    global labTimeLimit
    if {$labTimeLimit > 0} {
        interp limit $child time -seconds {}
        set end [expr {[clock milliseconds] + 1000 * $labTimeLimit}]
        interp limit $child time -seconds [expr {$end / 1000}] -milliseconds [expr {$end % 1000}]
    }
}

# Stand-in for puts inside the learner's script: collect the text instead of printing it.
proc labCapture {args} {
    global labOutput labOutputLimit
    if {[string length $labOutput] > $labOutputLimit} {
        error "output limit exceeded"
    }
    set newline 1
    if {[lindex $args 0] eq "-nonewline"} {
        set newline 0
        set args [lrange $args 1 end]
    }
    if {[llength $args] == 2} {
        # puts stdout text: drop the channel name
        set args [lrange $args 1 end]
    }
    append labOutput [lindex $args 0]
    if {$newline} {
        append labOutput \n
    }
    return ""
}

proc labTooLong {message} {
    return [expr {[string match "command count limit exceeded*" $message] || $message eq "time limit exceeded" || $message eq "output limit exceeded"}]
}

# Run a script in a fresh safe interpreter, then make some calls in the same interpreter.
# Returns {status message output results}; status is ok, error, or toolong (a limit stopped a loop
# that never ends). results has one {status value} per call; its status is ok, error, toolong,
# missing (no such command) or skipped (the script itself never ended).
proc labRun {code {calls {}}} {
    global labOutput labCommandLimit labCallLimit
    set labOutput ""
    set child [interp create -safe]
    interp alias $child puts {} labCapture
    interp limit $child commands -value $labCommandLimit
    labStartClock $child
    set status ok
    if {[catch {$child eval $code} message]} {
        set status error
        if {[labTooLong $message]} {
            set status toolong
        }
    }
    set results {}
    set outOfTime {}
    foreach call $calls {
        if {$status eq "toolong"} {
            lappend results [list skipped ""]
            continue
        }
        # A proc that ran out of time once is not called again: each call would wait the full time limit.
        if {[lindex $call 0] in $outOfTime} {
            lappend results [list skipped ""]
            continue
        }
        # A fresh allowance for every call. A limit that was reached blocks the child until it is
        # raised, so remove both limits before reading the command count.
        interp limit $child commands -value {}
        labStartClock $child
        interp limit $child commands -value [expr {[$child eval {info cmdcount}] + $labCallLimit}]
        if {[$child eval [list info commands [lindex $call 0]]] eq ""} {
            lappend results [list missing ""]
        } elseif {[catch {$child eval $call} value]} {
            if {[labTooLong $value]} {
                lappend results [list toolong $value]
                if {$value eq "time limit exceeded"} {
                    lappend outOfTime [lindex $call 0]
                }
            } else {
                lappend results [list error $value]
            }
        } else {
            lappend results [list ok $value]
        }
    }
    interp delete $child
    return [list $status $message $labOutput $results]
}

# One line in a fair form: no spaces at the ends, and a run of spaces counts as one space.
proc labTidy {line} {
    return [regsub -all {\s+} [string trim $line] " "]
}

# Text as a list of tidy lines, without the empty lines at the end.
proc labLines {text} {
    set lines {}
    foreach line [split [string map [list \r ""] $text] \n] {
        lappend lines [labTidy $line]
    }
    while {[llength $lines] > 0 && [lindex $lines end] eq ""} {
        set lines [lrange $lines 0 end-1]
    }
    return $lines
}

# The given "set name value" lines, as a flat list: name value name value ...
# A value is kept exactly as written, braces included, and may hold lists inside lists.
proc labFacts {text} {
    set facts {}
    foreach line [labLines $text] {
        if {[regexp {^set (\S+) (.+)$} $line -> name value] && [info complete $value]} {
            lappend facts $name $value
        }
    }
    return $facts
}

# A value as Tcl sees it: {{ALU {30 30 90 80}}} becomes the list {ALU {30 30 90 80}}.
proc labValue {written} {
    if {[string index $written 0] eq "\{" && [string index $written end] eq "\}"} {
        return [string range $written 1 end-1]
    }
    return $written
}

# Replace the line "set name old" in the learner's code with "set name new".
# Returns "" when the learner's code has no such line.
proc labSwapLine {code name old new} {
    set lines [split $code \n]
    set index 0
    foreach line $lines {
        if {[labTidy $line] eq "set $name $old"} {
            return [join [lreplace $lines $index $index "set $name $new"] \n]
        }
        incr index
    }
    return ""
}

# FNV-1a, 32 bits, of the UTF-8 bytes of a text, as 8 hex digits. Pure Tcl (8.6, 9.0, Wacl).
proc labFnv {text} {
    set hash 2166136261
    binary scan [encoding convertto utf-8 $text] cu* bytes
    foreach byte $bytes {
        set hash [expr {(($hash ^ $byte) * 16777619) & 0xFFFFFFFF}]
    }
    return [format %08x $hash]
}

# The hash of one tidy report line, as stored in data/hidden.txt.
proc labHashLine {line} {
    return [labFnv "m10-capstone:$line"]
}

# The kind of a report line: its first word for the fixed lines, or "area" for a block's area line.
proc labKind {line} {
    if {[regexp {^(Mini|Skipped:|Skipped|Total|Outside:|Conflict:|Problems:)(\s|$)} $line -> kind]} {
        return $kind
    }
    return area
}

# The lines of a report whose kind is in a list, in order.
proc labOfKind {lines kinds} {
    set picked {}
    foreach line $lines {
        if {[labKind $line] in $kinds} {
            lappend picked $line
        }
    }
    return $picked
}

# The hidden floorplans: a label and the new inputs (written as in a set line). Their expected reports
# are only stored as hashes in data/hidden.txt.
set labHidden [list \
    [list "a clean floorplan: Lumen-1 as it is" \
        [list chipName Lumen-1 chipWidth 400 chipHeight 300 blocks "{{CORE 20 20 200 160} {SRAM 240 20 140 160} {ADC 20 200 120 80} {SENSOR 160 200 100 80} {PADS 280 200 100 80}}"]] \
    [list "blocks on every edge, a corner touch and 1 um gaps" \
        [list chipName Lumen-1 chipWidth 400 chipHeight 300 blocks "{{NW 0 280 20 20} {SE 380 0 20 20} {A 100 100 50 50} {B 150 150 30 30} {C 181 150 20 20} {D 100 40 50 59}}"]] \
    [list "a test chip, with bad entries everywhere" \
        [list chipName TestChip chipWidth 200 chipHeight 100 blocks "{{X1 0 0 50 50} {X2 abc 0 10 10} {X3 10 10 10} {X4 60 0 0 20} {X5 1 2 3 4 5 6} {X6 210 10 20 20} {X7 40 40 20 20} {X8 150 50 50 60} {X9 10 60 -2 5} {X10 20 70 30 h}}"]] \
]

# What each kind of line must say, for hints on the hidden tests.
set labKindHints {
    Mini      "The first line names the chip and its size, from chipName, chipWidth and chipHeight."
    Skipped   "Each bad block gets one line, in input order: Skipped NAME: and the message of checkBlock."
    Skipped:  "Skipped: N counts the bad blocks. Print it even when N is 0."
    area      "One area line per VALID block, in input order, blocks outside the chip included."
    Total     "Total adds up only the valid blocks INSIDE the chip. The share is of chipWidth x chipHeight, rounded with format %.1f."
    Outside:  "One Outside line per valid block that is not inside the chip, in input order. A block that touches the edge is still inside."
    Conflict: "Check every pair of valid blocks once (j from i + 1), outside blocks included. Touching counts."
    Problems: "Problems counts the Outside lines plus the Conflict lines only, not the skipped blocks."
}

# Test cases for the procs: a group title, points, a hint, then {call expected} cases.
# expected is a value, "error: message" for checkBlock's errors, or "ok" for a call that must not fail.
set labProcGroups {
    {"rectArea" 3 "rectArea takes ONE rectangle {x1 y1 x2 y2} and returns (x2 - x1) * (y2 - y1)." {Week 7, Lesson A, "proc: name a recipe"}
        {{rectArea {0 0 10 5}} 50}
        {{rectArea {20 20 220 180}} 32000}
        {{rectArea {5 5 6 8}} 3}}
    {"rectOverlaps: touching counts" 4 "Use <= in all four comparisons: x1a <= x2b && x1b <= x2a && y1a <= y2b && y1b <= y2a. With <, touching would be fine." {Week 7, Lesson A, "A command that answers yes or no: the touching rule"}
        {{rectOverlaps {0 0 10 10} {10 0 20 10}} 1}
        {{rectOverlaps {10 0 20 10} {0 0 10 10}} 1}
        {{rectOverlaps {0 0 10 10} {10 10 20 20}} 1}
        {{rectOverlaps {10 10 20 20} {0 0 10 10}} 1}
        {{rectOverlaps {0 0 10 10} {0 10 10 20}} 1}
        {{rectOverlaps {0 10 10 20} {0 0 10 10}} 1}}
    {"rectOverlaps: gaps, overlaps, inside, identical" 4 "Two rectangles clash only if they overlap or touch on BOTH axes. Test x, then y, and join them with &&." {Week 7, Lesson A, "A command that answers yes or no: the touching rule"}
        {{rectOverlaps {0 0 10 10} {11 0 20 10}} 0}
        {{rectOverlaps {11 0 20 10} {0 0 10 10}} 0}
        {{rectOverlaps {0 0 10 10} {0 11 10 20}} 0}
        {{rectOverlaps {0 0 10 10} {5 12 15 20}} 0}
        {{rectOverlaps {5 12 15 20} {0 0 10 10}} 0}
        {{rectOverlaps {0 0 10 10} {5 5 15 15}} 1}
        {{rectOverlaps {0 0 30 30} {10 10 20 20}} 1}
        {{rectOverlaps {10 10 20 20} {0 0 30 30}} 1}
        {{rectOverlaps {0 0 10 10} {0 0 10 10}} 1}
        {{rectOverlaps {0 0 10 10} {50 50 60 60}} 0}}
    {"blockRect" 3 "blockRect turns {name x y w h} into the corners {x1 y1 x2 y2} = {x y x+w y+h}." {Week 6, Lesson B, "A list of rectangles"}
        {{blockRect {CORE 20 20 200 160}} {20 20 220 180}}
        {{blockRect {T 0 0 5 7}} {0 0 5 7}}
        {{blockRect {LDO 382 20 18 60}} {382 20 400 80}}}
    {"rectInside: touching the boundary is allowed" 3 "The boundary is a limit, not a neighbour: compare with >= on the left and bottom and <= on the right and top." {Week 7, Lesson B, "global: facts the whole script shares"}
        {{rectInside {0 0 10 10} {0 0 400 300}} 1}
        {{rectInside {390 290 400 300} {0 0 400 300}} 1}
        {{rectInside {0 100 400 120} {0 0 400 300}} 1}
        {{rectInside {0 0 400 300} {0 0 400 300}} 1}
        {{rectInside {50 50 60 60} {0 0 400 300}} 1}}
    {"rectInside: sticking out on any side" 3 "A rectangle is inside only if ALL four sides are inside: join the four tests with &&." {Week 7, Lesson B, "global: facts the whole script shares"}
        {{rectInside {395 0 405 10} {0 0 400 300}} 0}
        {{rectInside {-1 0 10 10} {0 0 400 300}} 0}
        {{rectInside {0 -5 10 10} {0 0 400 300}} 0}
        {{rectInside {0 295 10 301} {0 0 400 300}} 0}
        {{rectInside {500 500 510 510} {0 0 400 300}} 0}}
    {"checkBlock: good blocks pass, a wrong number of values fails" 3 "Count the values with llength first: error \"needs 5 values, got N\". A good block must not raise an error." {Week 10, Lesson B, "Defensive procs"}
        {{checkBlock {CORE 20 20 200 160}} ok}
        {{checkBlock {X 0 0 1.5 2}} ok}
        {{checkBlock {FUSE 10 10 20}} {error: needs 5 values, got 4}}
        {{checkBlock {A 1 2 3 4 5}} {error: needs 5 values, got 6}}}
    {"checkBlock: a value that is not a number" 4 "Check x, y, w and h in this order with string is double -strict: error \"w is not a number: ten\"." {Week 10, Lesson B, "Defensive procs"}
        {{checkBlock {B x0 1 2 3}} {error: x is not a number: x0}}
        {{checkBlock {C 1 2 3 zero}} {error: h is not a number: zero}}
        {{checkBlock {L 5 290 ten 8}} {error: w is not a number: ten}}}
    {"checkBlock: a width or height that is not positive" 3 "After the number checks, check w, then h: error \"w must be positive, got -5\". Zero is not positive." {Week 10, Lesson B, "Defensive procs"}
        {{checkBlock {D 1 2 0 5}} {error: w must be positive, got 0}}
        {{checkBlock {E 1 2 5 -3}} {error: h must be positive, got -3}}}
}

# 1 if a proc result matches what was expected (numbers compare as numbers: 50 and 50.0 are equal).
proc labSame {value want} {
    if {[llength $value] != [llength $want]} {
        return 0
    }
    foreach v $value w $want {
        if {[string is double -strict $v] && [string is double -strict $w]} {
            if {$v != $w} {
                return 0
            }
        } elseif {$v ne $w} {
            return 0
        }
    }
    return 1
}

# The report line for one failed proc call, or "" when the call gave what was expected.
proc labCallProblem {call result want} {
    lassign $result status value
    if {$status eq "skipped"} {
        return "$call was not run: an earlier call of [lindex $call 0] never ended."
    }
    if {$status eq "toolong"} {
        return "$call never ends. Look for a loop inside the proc."
    }
    if {$status eq "missing"} {
        return "There is no proc called [lindex $call 0]. Write it with exactly this name."
    }
    if {[string match "error: *" $want]} {
        set message [string range $want 7 end]
        if {$status ne "error"} {
            return "$call should raise the error \"$message\", but it did not."
        }
        if {$value ne $message} {
            return "$call raises \"$value\", but the message should be exactly \"$message\"."
        }
        return ""
    }
    if {$status eq "error"} {
        return "$call stops with an error. Tcl says: $value"
    }
    if {$want eq "ok"} {
        return ""
    }
    if {![labSame $value $want]} {
        if {$value eq ""} {
            return "$call returns an empty value, but should return $want. Did you use puts instead of return?"
        }
        return "$call returns $value, but should return $want."
    }
    return ""
}

# The stored hashes: hidden.txt has one line per report line: test number, line number, kind, hash.
proc labHiddenHashes {text test} {
    set lines {}
    foreach row [split $text \n] {
        if {[llength $row] == 4 && [lindex $row 0] == $test} {
            lappend lines [list [lindex $row 2] [lindex $row 3]]
        }
    }
    return $lines
}

# Adds a PASS or FAIL line for one test to the caller's report and score. Returns 1 on a PASS.
proc labResult {reportName scoreName ok title points details} {
    upvar 1 $reportName report $scoreName score
    if {$ok} {
        lappend report "PASS $title ($points/$points)"
        incr score $points
        return 1
    }
    lappend report "FAIL $title (0/$points)"
    foreach line $details {
        lappend report "     $line"
    }
    return 0
}

# Compares the lines of some kinds with the expected ones, in order. Returns "" or the problem lines.
proc labCompareKinds {lines targets kinds} {
    set want [labOfKind $targets $kinds]
    set got [labOfKind $lines $kinds]
    if {$got eq $want} {
        return ""
    }
    set number 0
    foreach wantLine $want gotLine $got {
        incr number
        if {$wantLine ne $gotLine} {
            break
        }
    }
    if {$number > [llength $want]} {
        return [list "This line should not be there: $gotLine"]
    }
    if {$gotLine eq ""} {
        return [list "Missing line: $wantLine"]
    }
    return [list "Expected: $wantLine" "Received: $gotLine"]
}

proc labCheck {learnerCode} {
    global labData labHidden labProcGroups labKindHints
    set inputs [labFacts $labData(inputs.txt)]
    set targets [labLines $labData(expected.txt)]
    set report {}
    set score 0
    set passed 0
    set total 17

    # The calls of every proc test, made in the same interpreter after the script.
    set calls {}
    foreach group $labProcGroups {
        foreach item [lrange $group 4 end] {
            lappend calls [lindex $item 0]
        }
    }

    # Test 1: the script runs (no points, but the rest depends on it).
    lassign [labRun $learnerCode $calls] status message output results
    set lines [labLines $output]
    if {$status eq "toolong"} {
        lappend report "FAIL Your script ran too long, or printed far too much, so the checker stopped it."
        lappend report "     Is there a loop that never ends? foreach always ends, so look at any while loop:"
        lappend report "     it must change what its condition tests every time it runs."
        lappend report "     Revisit: Week 4, Lesson B, \"Why loops need braces\"."
        lappend report "TODO The other [expr {$total - 1}] tests: fix the endless loop first."
        lappend report "RESULT: FAIL 0/$total"
        lappend report "SCORE: 0/75 automatic (correctness 0/50, error handling 0/25); readability 25: self-check on the page"
        return [join $report \n]
    }
    if {$status eq "error"} {
        lappend report "FAIL Your script stops with an error. Tcl says: $message"
        lappend report "     A bad block must not stop the checker: call checkBlock inside try, and report the error."
        lappend report "     Revisit: Week 10, Lesson B, \"try … on error\"."
    } else {
        incr passed
        lappend report "PASS Your script runs without an error"
    }

    # Tests 2 to 7 and 13 to 15: the procs, called with test cases.
    set correctness 0
    set handling 0
    set index 0
    set procReport {}
    foreach group $labProcGroups {
        lassign $group title points hint revisit
        set problems {}
        foreach item [lrange $group 4 end] {
            lassign $item call want
            set problem [labCallProblem $call [lindex $results $index] $want]
            incr index
            if {$problem ne "" && [llength $problems] < 2} {
                lappend problems $problem
            }
        }
        set kindScore [expr {[string match "checkBlock*" $title] ? "handling" : "correctness"}]
        set groupLines {}
        set ok [labResult groupLines $kindScore [expr {[llength $problems] == 0}] "Proc $title" $points [concat $problems [list $hint "Revisit: $revisit."]]]
        incr passed $ok
        dict lappend procReport $kindScore {*}$groupLines
    }

    # Tests 8 and 9: the visible report (correctness).
    set visible {}
    set ok [labResult visible correctness [expr {[labCompareKinds $lines $targets {Mini area Total}] eq ""}] \
        "Report: the first line, the area lines and the Total" 4 \
        [concat [labCompareKinds $lines $targets {Mini area Total}] \
            [list "Area lines: one per valid block, in input order. Total: only the blocks INSIDE the chip, with the share rounded by format %.1f." \
                "Revisit: Week 8, Lesson B, \"format: neat columns and rounded numbers\"."]]]
    incr passed $ok
    set ok [labResult visible correctness [expr {[labCompareKinds $lines $targets {Outside: Conflict: Problems:}] eq ""}] \
        "Report: the Outside lines, the Conflict lines and Problems" 6 \
        [concat [labCompareKinds $lines $targets {Outside: Conflict: Problems:}] \
            [list "Outside: one line per valid block not inside the chip. Conflict: every pair of valid blocks once, touching counts." \
                "Problems counts the Outside and Conflict lines only." \
                "Revisit: Week 7, Lesson A, \"Every pair, once\"."]]]
    incr passed $ok

    # Tests 10 to 12: the hidden floorplans (correctness).
    set missing ""
    foreach {name value} $inputs {
        if {[labSwapLine $learnerCode $name $value $value] eq ""} {
            set missing "set $name $value"
            break
        }
    }
    set test 0
    set hiddenPoints {6 7 7}
    foreach hidden $labHidden {
        lassign $hidden label newInputs
        set points [lindex $hiddenPoints $test]
        incr test
        set title "Hidden floorplan $test: $label"
        if {$missing ne ""} {
            lappend visible "NOTE $title (0/$points): I could not find the line   $missing   in your script."
            lappend visible "     Keep the four input lines exactly as they are in the starter, then check again."
            continue
        }
        set swapped $learnerCode
        foreach {name value} $inputs {
            set swapped [labSwapLine $swapped $name $value [dict get $newInputs $name]]
        }
        lassign [labRun $swapped] swapStatus swapMessage swapOutput
        set swapLines [labLines $swapOutput]
        set want [labHiddenHashes $labData(hidden.txt) $test]
        set details {}
        if {$swapStatus eq "toolong"} {
            lappend details "With these inputs your script never ends. Check every while loop."
        } elseif {$swapStatus eq "error"} {
            lappend details "With these inputs your script stops with an error. Tcl says: $swapMessage"
            lappend details "A bad block must not stop the checker: call checkBlock inside try."
        } else {
            set number 0
            foreach pair $want line $swapLines {
                incr number
                lassign $pair kind hash
                if {$pair eq ""} {
                    lappend details "Your report has more lines than expected. Line $number should not be there: $line"
                    break
                }
                if {$line eq "" && $number > [llength $swapLines]} {
                    lappend details "Your report stops too early: line $number is missing. It should be a line of the kind \"$kind\"."
                    lappend details [dict get $labKindHints $kind]
                    break
                }
                if {[labHashLine $line] ne $hash} {
                    lappend details "Line $number is not what it should be. It should be a line of the kind \"$kind\"; yours is: $line"
                    lappend details [dict get $labKindHints $kind]
                    break
                }
            }
        }
        if {[llength $details]} {
            set described {}
            foreach {name value} $newInputs {
                lappend described "$name $value"
            }
            set details [linsert $details 0 "I changed the inputs to [join $described {, }] and ran your script again."]
            lappend details "Work every line out from the inputs, instead of typing it."
        }
        set ok [labResult visible correctness [expr {[llength $details] == 0}] $title $points $details]
        incr passed $ok
    }

    # Test 16: the Skipped lines, the count, and a report that goes on to the end (error handling).
    set handlingReport {}
    set problems [labCompareKinds $lines $targets {Skipped Skipped:}]
    if {$problems eq "" && [llength [labOfKind $lines {Problems:}]] == 0} {
        set problems [list "Your report never reaches the Problems line: a bad block must not stop the script."]
    }
    set ok [labResult handlingReport handling [expr {$problems eq ""}] \
        "Report: one Skipped line per bad block, the Skipped count, and the report goes on" 10 \
        [concat $problems [list "For each block: try {checkBlock \$block} on error {message} {puts \"Skipped NAME: \$message\"}, then carry on." \
            "Revisit: Week 10, Lesson B, \"try … on error\"."]]]
    incr passed $ok

    # Test 17: the script uses try (the PRD asks for it).
    set ok [labResult handlingReport handling [regexp -line {^[^#]*\mtry\s+\{} $learnerCode] \
        "The script validates the blocks with try" 5 \
        [list "The capstone asks you to use try … on error to handle the bad blocks." \
            "Revisit: Week 10, Lesson B, \"try … on error\"."]]
    incr passed $ok

    # The report: correctness first, then error handling.
    set correctnessScore $correctness
    set handlingScore $handling
    lappend report "--- Correctness (50 points)"
    if {[dict exists $procReport correctness]} {
        foreach line [dict get $procReport correctness] {
            lappend report $line
        }
    }
    foreach line $visible {
        lappend report $line
    }
    lappend report "--- Error handling (25 points)"
    if {[dict exists $procReport handling]} {
        foreach line [dict get $procReport handling] {
            lappend report $line
        }
    }
    foreach line $handlingReport {
        lappend report $line
    }
    lappend report "--- Readability (25 points): not checked automatically. Score yourself with the list on the capstone page."
    if {$passed == $total} {
        lappend report "RESULT: PASS $passed/$total"
    } else {
        lappend report "RESULT: FAIL $passed/$total"
    }
    set automatic [expr {$correctnessScore + $handlingScore}]
    lappend report "SCORE: $automatic/75 automatic (correctness $correctnessScore/50, error handling $handlingScore/25); readability 25: self-check on the page"
    return [join $report \n]
}
