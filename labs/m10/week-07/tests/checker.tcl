# Grader for the Week 7 lab "rectArea and rectOverlaps" (PRD §11).
# Pure Tcl with no file access, so the same code runs in tclsh and in the browser playground.
# Needs: labData(inputs.txt), the "set plan {…}" input line given in the starter.
# Provides: labCheck learnerCode -> the report as text.
# New this week: besides the printed report, the checker CALLS the learner's procs rectArea and
# rectOverlaps with test rectangles, in both argument orders. The rule is the course's touching rule
# (decision log, P3 Weeks 6-7): rectangles are closed, so touching at an edge or a corner counts as a
# conflict, and a 1 um gap does not.
# The checker works out every expected line and answer itself, so no answers are stored.
# (data/expected.txt is only for the lab page; selftest.tcl checks that it agrees with labTargets.)

# A loop that never ends must not freeze the checker: every run, and every proc call, may use at most
# this many commands. A correct script uses fewer than 500. (interp limit works in tclsh 8.6, 9.0 and Wacl.)
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

# The checker's own answers.
proc labArea {rect} {
    return [expr {([lindex $rect 2] - [lindex $rect 0]) * ([lindex $rect 3] - [lindex $rect 1])}]
}
proc labOverlaps {a b} {
    lassign $a ax1 ay1 ax2 ay2
    lassign $b bx1 by1 bx2 by2
    return [expr {$ax1 <= $bx2 && $bx1 <= $ax2 && $ay1 <= $by2 && $by1 <= $ay2}]
}

# The expected report for some inputs, as a list of lines.
proc labTargets {inputs} {
    set plan [labValue [dict get $inputs plan]]
    set lines {}
    foreach block $plan {
        lappend lines "[lindex $block 0]: [labArea [lindex $block 1]] um2"
    }
    set conflicts 0
    set count [llength $plan]
    for {set i 0} {$i < $count} {incr i} {
        for {set j [expr {$i + 1}]} {$j < $count} {incr j} {
            if {[labOverlaps [lindex $plan $i 1] [lindex $plan $j 1]]} {
                lappend lines "Conflict: [lindex $plan $i 0] and [lindex $plan $j 0]"
                incr conflicts
            }
        }
    }
    lappend lines "Conflicts: $conflicts"
    return $lines
}

# The lines of a report that match a pattern, in order.
proc labPick {lines pattern} {
    set picked {}
    foreach line $lines {
        if {[regexp $pattern $line]} {
            lappend picked $line
        }
    }
    return $picked
}

# Test rectangles for rectArea: {rect}.
set labAreaCases {
    {0 0 30 20}
    {10 10 50 30}
    {5 5 6 6}
}

# Test pairs for rectOverlaps, in groups: a label, a hint, then {a b what} cases.
# The expected answers come from labOverlaps, the course rule.
set labOverlapGroups {
    {"rectOverlaps: overlapping and separate rectangles"
     "Both axes must overlap: test the x spans AND the y spans, and join the two tests with &&. On each axis, use the rule from spansOverlap."
     {{0 0 40 30} {20 10 60 50} "two rectangles that overlap"}
     {{0 20 100 40} {40 0 60 100} "a cross: each one sticks out of the other"}
     {{0 0 10 10} {50 50 60 60} "two rectangles far apart"}
     {{0 0 40 10} {10 30 30 50} "one above the other, with a gap: only their x spans overlap"}
     {{0 0 10 40} {30 10 50 30} "side by side, with a gap: only their y spans overlap"}}
    {"rectOverlaps: rectangles touching along an edge"
     "TOUCH"
     {{0 0 30 20} {30 0 60 20} "side by side, sharing the edge x = 30"}
     {{0 0 30 20} {5 20 25 40} "one on top of the other, sharing part of the edge y = 20"}}
    {"rectOverlaps: rectangles touching at a corner"
     "TOUCH"
     {{0 0 30 20} {30 20 50 40} "touching at the corner (30, 20)"}
     {{0 20 30 40} {30 0 50 20} "touching at the corner (30, 20), the other diagonal"}}
    {"rectOverlaps: a 1 um gap"
     "A 1 um gap is space between the blocks, so the answer is 0. Compare the edges themselves, with no + 1 or - 1."
     {{0 0 30 20} {31 0 60 20} "a 1 um gap between them on x"}
     {{0 0 30 20} {0 21 30 40} "a 1 um gap between them on y"}
     {{0 0 30 20} {31 21 50 40} "corner to corner, 1 um apart on both axes"}}
    {"rectOverlaps: one rectangle inside another"
     "When one rectangle is inside the other, no corner of the big one is inside the small one. Test the spans on each axis, as in spansOverlap, not the corners."
     {{0 0 100 100} {20 20 40 40} "a small rectangle inside a big one"}}
    {"rectOverlaps: identical rectangles"
     "Two identical rectangles overlap completely, so the answer is 1. Every comparison in the rule is true for them."
     {{10 10 50 30} {10 10 50 30} "two identical rectangles"}}
}

# Report lines for one failed proc call.
proc labCallProblem {call result want} {
    lassign $result status value
    switch -- $status {
        toolong { return "     $call never ends. Look for a loop inside the proc." }
        skipped { return "     $call was not run: an earlier call of [lindex $call 0] never ended." }
        error { return "     $call stops with an error. Tcl says: $value" }
    }
    if {[string is boolean -strict $value] && $value ne "0" && $value ne "1"} {
        return "     $call returns $value. Return 1 or 0: expr \{…\} with <= and && gives exactly that."
    }
    if {$value eq ""} {
        return "     $call returns an empty value, but should return $want. Did you use puts instead of return?"
    }
    return "     $call returns $value, but should return $want."
}

proc labCheck {learnerCode} {
    global labData labSwaps labAreaCases labOverlapGroups
    set inputs [labFacts $labData(inputs.txt)]
    set targets [labTargets $inputs]
    set total 15
    set report {}
    set passed 0

    # Every call the checker makes: rectArea on each case, then rectOverlaps on each pair, A B then B A.
    set calls {}
    foreach rect $labAreaCases {
        lappend calls [list rectArea $rect]
    }
    foreach group $labOverlapGroups {
        foreach case [lrange $group 2 end] {
            lassign $case a b
            lappend calls [list rectOverlaps $a $b] [list rectOverlaps $b $a]
        }
    }

    # Test 1: the script runs.
    lassign [labRun $learnerCode $calls] status message output results
    set lines [labLines $output]
    if {$status eq "toolong"} {
        lappend report "FAIL Your script ran too long, or printed far too much, so the checker stopped it."
        lappend report "     Is there a loop that never ends? In a for loop, the last part must change what the condition tests:"
        lappend report "     for {set j \[expr {\$i + 1}\]} {\$j < \$count} {incr j} — check that each loop increments its OWN variable."
        lappend report "     Revisit: Lesson A, \"Every pair, once\"."
        lappend report "TODO The other [expr {$total - 1}] tests: fix the endless loop first."
        lappend report "RESULT: FAIL 0/$total"
        return [join $report \n]
    }
    if {$status eq "error"} {
        lappend report "FAIL Your script stops with an error. Tcl says: $message"
        lappend report "     The procs and lines defined before the error are still checked below."
        lappend report "     Revisit: Lesson A, \"Common traps\" (read the error message first)."
    } else {
        incr passed
        lappend report "PASS Your script runs without an error"
    }
    set answers {}
    foreach call $calls result $results {
        dict set answers $call $result
    }

    # Test 2: rectArea.
    set problems {}
    set missing 0
    foreach rect $labAreaCases {
        set call [list rectArea $rect]
        set result [dict get $answers $call]
        set want [labArea $rect]
        if {[lindex $result 0] eq "missing"} {
            set missing 1
            break
        }
        if {[lindex $result 0] ne "ok" || [lindex $result 1] ne $want} {
            lappend problems [labCallProblem $call $result $want]
        }
    }
    if {$missing} {
        lappend report "TODO rectArea: not defined yet. Write: proc rectArea {rect} {…}, with exactly this name."
    } elseif {[llength $problems] == 0} {
        incr passed
        lappend report "PASS rectArea"
    } else {
        lappend report "FAIL rectArea"
        foreach line $problems {
            lappend report $line
        }
        lappend report "     The area is (x2 - x1) * (y2 - y1), and rectArea must RETURN it."
        lappend report "     Revisit: Lesson A, \"proc: name a recipe\"."
    }

    # Tests 3 to 8: rectOverlaps, one group of cases each, in the order A B.
    # Test 9: every case again in the order B A; both orders must agree.
    if {[lindex [dict get $answers [list rectOverlaps {0 0 40 30} {20 10 60 50}]] 0] eq "missing"} {
        lappend report "TODO rectOverlaps (7 tests): not defined yet. Write: proc rectOverlaps {a b} {…}, with exactly this name."
    } else {
        set touchHint "Touching counts in this course: use <=, not <. With < touching would be fine, but our blocks need space between them."
        # First collect the problems of every group, so that the touching hint is only given when
        # touching is the ONLY thing that goes wrong.
        set groupProblems {}
        set groupZero {}
        set otherFails 0
        foreach group $labOverlapGroups {
            set problems {}
            set saidZero 0
            foreach case [lrange $group 2 end] {
                lassign $case a b what
                set call [list rectOverlaps $a $b]
                set result [dict get $answers $call]
                set want [labOverlaps $a $b]
                if {[lindex $result 0] ne "ok" || [lindex $result 1] ne $want} {
                    lappend problems "     $what:"
                    lappend problems [labCallProblem $call $result $want]
                    if {[lindex $result 1] eq "0"} {
                        set saidZero 1
                    }
                }
            }
            lappend groupProblems $problems
            lappend groupZero $saidZero
            if {[llength $problems] > 0 && [lindex $group 1] ne "TOUCH"} {
                set otherFails 1
            }
        }
        foreach group $labOverlapGroups problems $groupProblems saidZero $groupZero {
            set label [lindex $group 0]
            set hint [lindex $group 1]
            if {[llength $problems] == 0} {
                incr passed
                lappend report "PASS $label"
                continue
            }
            lappend report "FAIL $label"
            foreach line $problems {
                lappend report $line
            }
            if {$hint ne "TOUCH"} {
                lappend report "     $hint"
            } elseif {$saidZero && !$otherFails} {
                lappend report "     $touchHint"
            } else {
                lappend report "     The rule: x1a <= x2b && x1b <= x2a && y1a <= y2b && y1b <= y2a, where a is {x1a y1a x2a y2a}."
            }
            lappend report "     Revisit: Lesson A, \"A command that answers yes or no: the touching rule\"."
        }

        set problems {}
        foreach group $labOverlapGroups {
            foreach case [lrange $group 2 end] {
                lassign $case a b what
                set forward [dict get $answers [list rectOverlaps $a $b]]
                set backward [dict get $answers [list rectOverlaps $b $a]]
                if {[lindex $backward 0] ne "ok" || [lindex $backward 1] ne [lindex $forward 1]} {
                    lappend problems "     $what: rectOverlaps {$a} {$b} gives [lindex $forward 1], but rectOverlaps {$b} {$a} gives [lindex $backward 1]."
                }
            }
        }
        if {[llength $problems] == 0} {
            incr passed
            lappend report "PASS rectOverlaps gives the same answer in both orders"
        } else {
            lappend report "FAIL rectOverlaps gives the same answer in both orders"
            foreach line [lrange $problems 0 2] {
                lappend report $line
            }
            if {[llength $problems] > 3} {
                lappend report "     … and [expr {[llength $problems] - 3}] more."
            }
            lappend report "     \"Does A clash with B?\" and \"does B clash with A?\" are the same question. Write the four"
            lappend report "     comparisons of the rule, two per axis, so that a and b play the same part."
            lappend report "     Revisit: Lesson A, \"A command that answers yes or no: the touching rule\"."
        }
    }

    # Test 10: one area line per block.
    set wantAreas [labPick $targets {um2$}]
    set gotAreas [labPick $lines {um2$}]
    if {$gotAreas eq $wantAreas} {
        incr passed
        lappend report "PASS The area lines"
    } elseif {[llength $gotAreas] == 0} {
        lappend report "TODO The area lines: not printed yet. The first should be: [lindex $wantAreas 0]"
    } else {
        lappend report "FAIL The area lines"
        lappend report "     Expected: [join $wantAreas { | }]"
        lappend report "     Received: [join $gotAreas { | }]"
        lappend report "     foreach block \$plan {…}: the name is lindex \$block 0, and rectArea \[lindex \$block 1\] gives the area."
        lappend report "     Revisit: Week 6, Lesson B, \"A list of rectangles\"."
    }

    # Test 11: the conflict lines.
    set wantPairs [labPick $targets {^Conflict:}]
    set gotPairs [labPick $lines {^Conflict:}]
    set plan [labValue [dict get $inputs plan]]
    if {$gotPairs eq $wantPairs} {
        incr passed
        lappend report "PASS The conflict lines"
    } elseif {[llength $gotPairs] == 0 && [llength $wantPairs] > 0 && [llength [labPick $lines {^Conflicts:}]] == 0} {
        lappend report "TODO The conflict lines: not printed yet. The first should be: [lindex $wantPairs 0]"
    } else {
        lappend report "FAIL The conflict lines"
        lappend report "     Expected: [join $wantPairs { | }]"
        lappend report "     Received: [join $gotPairs { | }]"
        set selfPair 0
        foreach line $gotPairs {
            if {[regexp {^Conflict: (\S+) and (\S+)$} $line -> first second] && $first eq $second} {
                set selfPair 1
            }
        }
        if {$selfPair || [llength $gotPairs] >= 2 * [llength $wantPairs] && [llength $wantPairs] > 0} {
            lappend report "     A block is compared with itself, or a pair comes up twice. The inner loop must start AFTER"
            lappend report "     the outer one: for {set j \[expr {\$i + 1}\]} {\$j < \$count} {incr j}."
        } else {
            lappend report "     Compare every pair once with the pair loop (j starts at i + 1). Call rectOverlaps on the two"
            lappend report "     rectangles, lindex \$plan \$i 1 and lindex \$plan \$j 1, and print: Conflict: NAME1 and NAME2."
            lappend report "     If a rectOverlaps test above fails, fix that first: these lines depend on it."
        }
        lappend report "     Revisit: Lesson A, \"Every pair, once\"."
    }

    # Test 12: the number of conflicts.
    set want [lindex [labPick $targets {^Conflicts:}] 0]
    set got [lindex [labPick $lines {^Conflicts:}] 0]
    if {$got eq $want} {
        incr passed
        lappend report "PASS The number of conflicts"
    } elseif {$got eq ""} {
        lappend report "TODO The number of conflicts: not printed yet. It should be: $want"
    } else {
        lappend report "FAIL The number of conflicts"
        lappend report "     Expected: $want"
        lappend report "     Received: $got"
        if {$got eq "Conflicts: [llength $gotPairs]"} {
            lappend report "     Your count matches your own Conflict lines, so fix those lines first: the count will follow."
            lappend report "     Revisit: Lesson A, \"Every pair, once\"."
        } else {
            lappend report "     Set a counter to 0 before the loops, and incr it each time you print a Conflict line."
            lappend report "     Revisit: Week 4, Lesson B, \"while: repeat while a test is true\" (counters)."
        }
    }

    # Test 13: every line, in order, and nothing extra.
    set count [llength $lines]
    set wanted [llength $targets]
    if {$lines eq $targets} {
        incr passed
        lappend report "PASS All lines in order, nothing extra"
    } elseif {$count < $wanted} {
        lappend report "TODO All lines in order, nothing extra: finish all five steps first."
    } else {
        lappend report "FAIL All lines in order, nothing extra"
        set number 0
        foreach wantLine $targets gotLine $lines {
            incr number
            if {$wantLine ne $gotLine} {
                break
            }
        }
        if {$number > $wanted} {
            lappend report "     Your script prints $count lines, but the report has $wanted. The first extra line is: [lindex $lines $wanted]"
            lappend report "     Remove the extra puts commands (inside your procs too), or turn them into comments with #."
        } else {
            lappend report "     Line $number should be: [lindex $targets [expr {$number - 1}]]"
            lappend report "     It is: [lindex $lines [expr {$number - 1}]]"
            lappend report "     Print the lines in the order of the specification, with no extra lines."
        }
    }

    # Tests 14 and 15: change the floorplan and run again.
    set missingLine ""
    foreach {name value} $inputs {
        if {[labSwapLine $learnerCode $name $value $value] eq ""} {
            set missingLine "set $name $value"
            break
        }
    }
    set first 1
    foreach swap $labSwaps {
        lassign $swap label newInputs hint
        set what "Follows the input: $label"
        if {$missingLine ne ""} {
            if {$first} {
                lappend report "NOTE $what: I could not find the line   $missingLine   in your script."
                lappend report "     Keep the input line exactly as it is in the starter, then check again."
            } else {
                lappend report "NOTE $what: needs the same input line back."
            }
            set first 0
            continue
        }
        if {$lines ne $targets} {
            lappend report "TODO $what: get all the lines right first. Then this test changes the floorplan and runs your script again."
            continue
        }
        set swapped $learnerCode
        foreach {name value} $inputs {
            set swapped [labSwapLine $swapped $name $value [dict get $newInputs $name]]
        }
        lassign [labRun $swapped] swapStatus swapMessage swapOutput
        set swapLines [labLines $swapOutput]
        set swapTargets [labTargets $newInputs]
        if {$swapStatus eq "ok" && $swapLines eq $swapTargets} {
            incr passed
            lappend report "PASS $what"
            continue
        }
        lappend report "FAIL $what"
        lappend report "     I changed the input to: set plan [dict get $newInputs plan]"
        lappend report "     and ran your script again."
        if {$swapStatus eq "toolong"} {
            lappend report "     With this floorplan your script never ends. Check both loops."
        } elseif {$swapStatus eq "error"} {
            lappend report "     With this floorplan your script stops with an error. Tcl says: $swapMessage"
        } else {
            set number 0
            foreach wantLine $swapTargets gotLine $swapLines {
                incr number
                if {$wantLine ne $gotLine} {
                    break
                }
            }
            if {$number > [llength $swapTargets]} {
                lappend report "     Line $number should not be there. It says: $gotLine"
            } elseif {$number > [llength $swapLines]} {
                lappend report "     Line $number is missing. It should say: $wantLine"
            } else {
                lappend report "     Line $number should say: $wantLine"
                lappend report "     It says: $gotLine"
            }
            lappend report "     $hint"
        }
        lappend report "     Work every line out from plan, with your procs and the pair loop, instead of typing it."
        lappend report "     Revisit: Lesson A, \"Every pair, once\"."
    }

    if {$passed == $total} {
        lappend report "RESULT: PASS $passed/$total"
    } else {
        lappend report "RESULT: FAIL $passed/$total"
    }
    return [join $report \n]
}

# The two swap tests: a label, the new input (written as in the set line), and a hint.
set labSwaps [list \
    [list "blocks 1 um apart, no conflict" \
        [list plan "{{ALU {30 30 90 80}} {REGS {91 30 140 80}} {CTRL {141 30 200 80}}}"] \
        "Here every gap is 1 um, so there is no conflict, and the last line must be: Conflicts: 0"] \
    [list "a block inside another, and two identical blocks" \
        [list plan "{{BIG {30 30 130 130}} {SMALL {50 50 60 60}} {COPY {50 50 60 60}} {SIDE {131 30 200 130}}}"] \
        "Here SMALL and COPY lie inside BIG, and they are identical to each other: three conflicts. SIDE is 1 um away from BIG."] \
]
