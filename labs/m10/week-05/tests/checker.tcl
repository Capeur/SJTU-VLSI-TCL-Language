# Grader for the Week 5 lab "Rectangles as lists" (PRD §11).
# Pure Tcl with no file access, so the same code runs in tclsh and in the browser playground.
# Needs: labData(inputs.txt), the "set name value" input lines given in the starter (a value may be
# a list in braces, like {30 40 90 70}).
# Provides: labCheck learnerCode -> the report as text.
# The checker works out every expected line from the inputs, so no answers are stored.
# (data/expected.txt is only for the lab page; selftest.tcl checks that it agrees with labTargets.)

# A loop that never ends must not freeze the checker: every run may use at most this many commands.
# A correct script uses fewer than 200. (interp limit works in tclsh 8.6, 9.0 and Wacl 8.6.6.)
set labCommandLimit 100000
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

# Run a script in a fresh safe interpreter. Returns {status message output};
# status is ok, error, or toolong (a limit stopped a loop that never ends).
proc labRun {code} {
    global labOutput labCommandLimit
    set labOutput ""
    set child [interp create -safe]
    interp alias $child puts {} labCapture
    interp limit $child commands -value $labCommandLimit
    labStartClock $child
    set status ok
    if {[catch {$child eval $code} message]} {
        set status error
        if {[string match "command count limit exceeded*" $message] || $message eq "time limit exceeded" || $message eq "output limit exceeded"} {
            set status toolong
        }
    }
    interp delete $child
    return [list $status $message $labOutput]
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
# A value is kept exactly as written, braces included: {30 40 90 70}.
proc labFacts {text} {
    set facts {}
    foreach line [labLines $text] {
        if {[regexp {^set (\S+) (\{[^\{\}]*\}|\S+)$} $line -> name value]} {
            lappend facts $name $value
        }
    }
    return $facts
}

# A value as Tcl sees it: {30 40 90 70} becomes the list 30 40 90 70.
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

# The expected report for some inputs, as a list of lines.
proc labTargets {inputs} {
    set rect [labValue [dict get $inputs rect]]
    set shapes [labValue [dict get $inputs shapes]]
    set minWidth [labValue [dict get $inputs minWidth]]
    set width [expr {[lindex $rect 2] - [lindex $rect 0]}]
    set height [expr {[lindex $rect 3] - [lindex $rect 1]}]
    set lines [list "Width: $width um" "Height: $height um" "Area: [expr {$width * $height}] um2"]
    set count 0
    set total 0
    set narrow {}
    foreach {x1 y1 x2 y2} $shapes {
        incr count
        set width [expr {$x2 - $x1}]
        set height [expr {$y2 - $y1}]
        set area [expr {$width * $height}]
        incr total $area
        lappend lines "Shape $count: width $width, height $height, area $area"
        if {$width < $minWidth || $height < $minWidth} {
            lappend narrow $count
        }
    }
    lappend lines "Shapes: $count" "Total area: $total um2"
    if {[llength $narrow] == 0} {
        lappend lines "Too narrow: none"
    }
    foreach number $narrow {
        lappend lines "Too narrow: shape $number"
    }
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

# The two swap tests: a label, the new inputs (written as in a set line), a hint, and where to revisit.
set labSwaps [list \
    [list "four shapes, none too narrow" \
        [list rect "{10 10 50 40}" shapes "{10 10 50 40 60 10 66 90 70 20 120 30 130 100 190 160}" minWidth 5] \
        "With no narrow shape, the last line must be: Too narrow: none. Count the narrow shapes, or collect them in a list with lappend, and test the count after the loop." \
        {Lesson B, "lappend: grow a list"}] \
    [list "two shapes, both too narrow" \
        [list rect "{0 0 8 8}" shapes "{0 0 2 40 10 0 60 1}" minWidth 3] \
        "Here both shapes are too narrow: one by its width, one by its height. Print one Too narrow line for each, in order." \
        {Lesson B, "lappend: grow a list"}] \
]

proc labCheck {learnerCode} {
    global labData labSwaps
    set inputs [labFacts $labData(inputs.txt)]
    set targets [labTargets $inputs]
    set total 11
    set report {}
    set passed 0

    # Test 1: the script runs.
    lassign [labRun $learnerCode] status message output
    set lines [labLines $output]
    if {$status eq "toolong"} {
        lappend report "FAIL Your script ran too long, or printed far too much, so the checker stopped it."
        lappend report "     Is there a loop that never ends? A foreach loop always ends, so look at any while loop:"
        lappend report "     it must change what its condition tests every time it runs."
        lappend report "     Revisit: Week 4, Lesson B, \"Why loops need braces\"."
        lappend report "TODO The other [expr {$total - 1}] tests: fix the endless loop first."
        lappend report "RESULT: FAIL 0/$total"
        return [join $report \n]
    }
    if {$status eq "error"} {
        lappend report "FAIL Your script stops with an error. Tcl says: $message"
        lappend report "     The lines printed before the error are still checked below."
        lappend report "     Revisit: Lesson A, \"Common traps\" (read the error message first)."
    } else {
        incr passed
        lappend report "PASS Your script runs without an error"
    }

    # Tests 2 to 4: the first rectangle.
    set indexHint "The corners are {x1 y1 x2 y2}, and lindex counts from 0: x1 is index 0, y1 is 1, x2 is 2 and y2 is 3."
    set number 0
    foreach what {"Line 1 (the width)" "Line 2 (the height)" "Line 3 (the area)"} \
            hint [list "The width is x2 - x1. $indexHint" "The height is y2 - y1. $indexHint" "The area is the width times the height."] {
        set want [lindex $targets $number]
        incr number
        if {$number > [llength $lines]} {
            lappend report "TODO $what: not printed yet. It should be: $want"
        } elseif {[lindex $lines [expr {$number - 1}]] eq $want} {
            incr passed
            lappend report "PASS $what"
        } else {
            lappend report "FAIL $what"
            lappend report "     Expected: $want"
            lappend report "     Received: [lindex $lines [expr {$number - 1}]]"
            lappend report "     $hint"
            lappend report "     Revisit: Lesson A, \"Rectangles as lists\"."
        }
    }

    # Test 5: one line per shape.
    set wantShapes [labPick $targets {^Shape \d+:}]
    set gotShapes [labPick $lines {^Shape \d+:}]
    if {$gotShapes eq $wantShapes} {
        incr passed
        lappend report "PASS The shape lines"
    } elseif {[llength $gotShapes] == 0} {
        lappend report "TODO The shape lines: not printed yet. The first should be: [lindex $wantShapes 0]"
    } else {
        lappend report "FAIL The shape lines"
        lappend report "     Expected: [join $wantShapes { | }]"
        lappend report "     Received: [join $gotShapes { | }]"
        set shapeNumbers [llength [labValue [dict get $inputs shapes]]]
        if {[llength $gotShapes] == $shapeNumbers} {
            lappend report "     One line per NUMBER: foreach with one variable takes one item per pass. Give it four: foreach {x1 y1 x2 y2} \$shapes {…}"
        } elseif {[llength $gotShapes] != [llength $wantShapes]} {
            lappend report "     There are [llength $wantShapes] shapes: four numbers each. Use foreach {x1 y1 x2 y2} \$shapes {…}"
        } else {
            lappend report "     Inside the loop, the width is \$x2 - \$x1 and the height is \$y2 - \$y1. Number the shapes with a counter that starts at 0 and goes up with incr."
        }
        lappend report "     Revisit: Lesson B, \"Several variables at once\"."
    }

    # Tests 6 and 7: the count and the total.
    foreach what {"The shape count" "The total area"} pattern {{^Shapes:} {^Total area:}} \
            hint {"Count the shapes, not the numbers: llength gives 4 numbers per shape. Use a counter in the loop, or divide llength by 4." "Start a total at 0 before the loop, and add each shape's area to it inside the loop: incr total \$area."} \
            revisit {{Lesson B, "foreach: visit every item"} {Lesson B, "foreach: visit every item"}} {
        set want [lindex [labPick $targets $pattern] 0]
        set got [lindex [labPick $lines $pattern] 0]
        if {$got eq $want} {
            incr passed
            lappend report "PASS $what"
        } elseif {$got eq ""} {
            lappend report "TODO $what: not printed yet. It should be: $want"
        } else {
            lappend report "FAIL $what"
            lappend report "     Expected: $want"
            lappend report "     Received: $got"
            lappend report "     $hint"
            lappend report "     Revisit: $revisit."
        }
    }

    # Test 8: the narrow shapes.
    set wantNarrow [labPick $targets {^Too narrow:}]
    set gotNarrow [labPick $lines {^Too narrow:}]
    if {$gotNarrow eq $wantNarrow} {
        incr passed
        lappend report "PASS The too-narrow lines"
    } elseif {[llength $gotNarrow] == 0} {
        lappend report "TODO The too-narrow lines: not printed yet. With these inputs: [join $wantNarrow { | }]"
    } else {
        lappend report "FAIL The too-narrow lines"
        lappend report "     Expected: [join $wantNarrow { | }]"
        lappend report "     Received: [join $gotNarrow { | }]"
        lappend report "     A shape is too narrow if its width OR its height is less than minWidth: join the two tests with ||."
        lappend report "     A side exactly as wide as minWidth is fine. Print \"Too narrow: shape N\", one line per shape."
        lappend report "     Revisit: Week 4, Lesson A, \"Comparisons give 1 or 0\", and Lesson B, \"lappend: grow a list\"."
    }

    # Test 9: every line, in order, and nothing extra.
    set count [llength $lines]
    set wanted [llength $targets]
    if {$lines eq $targets} {
        incr passed
        lappend report "PASS All lines in order, nothing extra"
    } elseif {$count < $wanted} {
        lappend report "TODO All lines in order, nothing extra: finish all six steps first."
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
            lappend report "     Remove the extra puts commands, or turn them into comments with #."
        } else {
            lappend report "     Line $number should be: [lindex $targets [expr {$number - 1}]]"
            lappend report "     It is: [lindex $lines [expr {$number - 1}]]"
            lappend report "     Print the lines in the order of the specification, with no extra lines."
        }
    }

    # Tests 10 and 11: change the inputs and run again.
    set missing ""
    foreach {name value} $inputs {
        if {[labSwapLine $learnerCode $name $value $value] eq ""} {
            set missing "set $name $value"
            break
        }
    }
    set first 1
    foreach swap $labSwaps {
        lassign $swap label newInputs hint revisit
        set what "Follows the inputs: $label"
        if {$missing ne ""} {
            if {$first} {
                lappend report "NOTE $what: I could not find the line   $missing   in your script."
                lappend report "     Keep the three input lines exactly as they are in the starter, then check again."
            } else {
                lappend report "NOTE $what: needs the same input line back."
            }
            set first 0
            continue
        }
        if {$lines ne $targets} {
            lappend report "TODO $what: get all the lines right first. Then this test changes the inputs and runs your script again."
            continue
        }
        set swapped $learnerCode
        foreach {name value} $inputs {
            set swapped [labSwapLine $swapped $name $value [dict get $newInputs $name]]
        }
        set described {}
        foreach {name value} $newInputs {
            lappend described "$name $value"
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
        lappend report "     I changed the inputs to [join $described {, }] and ran your script again."
        if {$swapStatus eq "toolong"} {
            lappend report "     With these inputs your script never ends. Check every while loop."
        } elseif {$swapStatus eq "error"} {
            lappend report "     With these inputs your script stops with an error. Tcl says: $swapMessage"
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
        lappend report "     Work every line out from the lists, with lindex and foreach, instead of typing it."
        lappend report "     Revisit: $revisit."
    }

    if {$passed == $total} {
        lappend report "RESULT: PASS $passed/$total"
    } else {
        lappend report "RESULT: FAIL $passed/$total"
    }
    return [join $report \n]
}
