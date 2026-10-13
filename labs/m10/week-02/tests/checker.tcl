# Grader for the Week 2 lab "What does one Lumen-1 cost?" (PRD §11).
# Pure Tcl with no file access, so the same code runs in tclsh and in the browser playground.
# Needs: labData(inputs.txt), the "set name value" input lines given in the starter.
# Provides: labCheck learnerCode -> the report as text.
# The checker works out every expected number from the inputs, so no answers are stored.
# (data/expected.txt is only for the lab page; selftest.tcl checks that it agrees with labTargets.)

# Stand-in for puts inside the learner's script: collect the text instead of printing it.
proc labCapture {args} {
    global labOutput
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

# Run a script in a fresh safe interpreter. Returns {failed message output}.
proc labRun {code} {
    global labOutput
    set labOutput ""
    set child [interp create -safe]
    interp alias $child puts {} labCapture
    set failed [catch {$child eval $code} message]
    interp delete $child
    return [list $failed $message $labOutput]
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
proc labFacts {text} {
    set facts {}
    foreach line [labLines $text] {
        if {[regexp {^set (\S+) (\S+)$} $line -> name value]} {
            lappend facts $name $value
        }
    }
    return $facts
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

# The six expected lines for some inputs. Each item: {before number after kind revisit wrongWay name}.
# kind is integer or decimal; wrongWay is what integer division would give for a decimal line.
proc labTargets {inputs} {
    set chipWidth [dict get $inputs chipWidth]
    set chipHeight [dict get $inputs chipHeight]
    set waferSide [dict get $inputs waferSide]
    set waferCost [dict get $inputs waferCost]
    set area [expr {$chipWidth * $chipHeight}]
    set perRow [expr {$waferSide / $chipWidth}]
    set rows [expr {$waferSide / $chipHeight}]
    set perWafer [expr {$perRow * $rows}]
    set lessonA "Lesson A, \"Whole numbers and decimals\""
    return [list \
        [list "Chip area: " $area " um2" integer "Lesson A, \"The order of operations\"" "" "area in um2"] \
        [list "Chip area: " [expr {$area / 1000000.0}] " mm2" decimal $lessonA [expr {$area / 1000000}] "area in mm2"] \
        [list "Chips per row: " $perRow "" integer $lessonA "" "chips per row"] \
        [list "Rows per wafer: " $rows "" integer $lessonA "" "rows per wafer"] \
        [list "Chips per wafer: " $perWafer "" integer "Lesson B, \"Square brackets run a command first\"" "" "chips per wafer"] \
        [list "Cost per chip: " [expr {$waferCost / double($perWafer)}] " dollars" decimal "Lesson A, \"Common traps\"" [expr {$waferCost / $perWafer}] "cost per chip"] \
    ]
}

proc labTargetText {target} {
    lassign $target before number after
    return "$before$number$after"
}

# Compare one printed line with its target. Returns {ok hint}; hint may be "".
# Decimal answers count as right when they are equal up to rounding in the last digits.
proc labCompare {target got} {
    lassign $target before number after kind revisit wrongWay
    set beforeLength [string length $before]
    set afterLength [string length $after]
    set wordsOk [expr {[string range $got 0 [expr {$beforeLength - 1}]] eq $before}]
    if {$afterLength > 0 && [string range $got end-[expr {$afterLength - 1}] end] ne $after} {
        set wordsOk 0
    }
    set printed [string trim [string range $got $beforeLength end-$afterLength]]
    if {!$wordsOk || $printed eq ""} {
        return [list 0 "Check the words around the number: capitals, spelling, colons and units."]
    }
    if {$kind eq "integer"} {
        if {$printed eq $number} {
            return [list 1 ""]
        }
        if {[string is double -strict $printed] && [string first . $printed] >= 0} {
            return [list 0 "Only whole chips count, so this number must be a whole number. Divide two integers here, with no .0, so that the part after the point is dropped."]
        }
        return [list 0 ""]
    }
    if {[string is double -strict $printed]} {
        set tolerance [expr {1e-9 * max(1.0, abs($number))}]
        if {abs($printed - $number) <= $tolerance} {
            return [list 1 ""]
        }
        if {[string is integer -strict $printed] && $printed == $wrongWay} {
            return [list 0 "This looks like integer division: both numbers were whole, so the part after the point was dropped. Make one of them a decimal, for example by writing .0 after a number."]
        }
    }
    return [list 0 ""]
}

set labSwapInputs {chipWidth 500 chipHeight 250 waferSide 12000 waferCost 2880}

proc labCheck {learnerCode} {
    global labData labSwapInputs
    set inputs [labFacts $labData(inputs.txt)]
    set targets [labTargets $inputs]
    set total [expr {[llength $targets] + 3}]
    set report {}
    set passed 0

    # Test 1: the script runs.
    lassign [labRun $learnerCode] failed message output
    set lines [labLines $output]
    if {$failed} {
        lappend report "FAIL Your script stops with an error. Tcl says: $message"
        lappend report "     The lines printed before the error are still checked below."
        lappend report "     Revisit: Lesson B, \"Common traps\" (read the error message first)."
    } else {
        incr passed
        lappend report "PASS Your script runs without an error"
    }

    # Tests 2 to 7: one per line of output.
    set number 0
    set allLinesOk 1
    foreach target $targets {
        incr number
        set want [labTargetText $target]
        set what "Line $number ([lindex $target 6])"
        if {$number > [llength $lines]} {
            set allLinesOk 0
            lappend report "TODO $what: not printed yet. It should be: $want"
            continue
        }
        set got [lindex $lines [expr {$number - 1}]]
        lassign [labCompare $target $got] ok hint
        if {$ok} {
            incr passed
            lappend report "PASS $what"
            continue
        }
        set allLinesOk 0
        lappend report "FAIL $what"
        lappend report "     Expected: $want"
        lappend report "     Received: $got"
        if {$hint ne ""} {
            lappend report "     $hint"
        }
        lappend report "     Revisit: [lindex $target 4]."
    }

    # Test 8: nothing extra.
    set count [llength $lines]
    set wanted [llength $targets]
    if {$count == $wanted} {
        incr passed
        lappend report "PASS No extra lines"
    } elseif {$count < $wanted} {
        lappend report "TODO No extra lines: finish all six steps first."
    } else {
        lappend report "FAIL No extra lines: your script prints $count lines, but the report has $wanted."
        lappend report "     The first extra line is: [lindex $lines $wanted]"
        lappend report "     Remove the extra puts commands, or turn them into comments with #."
    }

    # Test 9: every number is computed from the inputs. Change the inputs and run again.
    set swapped $learnerCode
    set missing ""
    foreach {name value} $inputs {
        set next [labSwapLine $swapped $name $value [dict get $labSwapInputs $name]]
        if {$next eq ""} {
            set missing "set $name $value"
            break
        }
        set swapped $next
    }
    if {$missing ne ""} {
        lappend report "NOTE Computes from the inputs: I could not find the line   $missing   in your script."
        lappend report "     Keep the four input lines exactly as they are in the starter, then check again."
    } elseif {!$allLinesOk} {
        lappend report "TODO Computes from the inputs: get all six lines right first. Then this test changes the inputs and runs your script again."
    } else {
        lassign [labRun $swapped] swapFailed swapMessage swapOutput
        set swapLines [labLines $swapOutput]
        set problem ""
        set number 0
        foreach target [labTargets $labSwapInputs] {
            set got [lindex $swapLines $number]
            incr number
            if {![lindex [labCompare $target $got] 0]} {
                set problem "Line $number should then say: [labTargetText $target]\n     It says: $got"
                break
            }
        }
        set described {}
        foreach {name value} $labSwapInputs {
            lappend described "$name $value"
        }
        if {$swapFailed} {
            lappend report "FAIL Computes from the inputs: with other inputs, your script stops with an error. Tcl says: $swapMessage"
        } elseif {$problem ne ""} {
            lappend report "FAIL Computes from the inputs: I changed the inputs to [join $described {, }] and ran your script again."
            lappend report "     $problem"
            lappend report "     Work this number out with expr from the variables, instead of typing it."
            lappend report "     Revisit: Lesson B, \"Square brackets run a command first\"."
        } else {
            incr passed
            lappend report "PASS Computes from the inputs: every number follows when the inputs change"
        }
    }

    if {$passed == $total} {
        lappend report "RESULT: PASS $passed/$total"
    } else {
        lappend report "RESULT: FAIL $passed/$total"
    }
    return [join $report \n]
}
