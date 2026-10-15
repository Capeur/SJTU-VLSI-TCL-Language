# Grader for the Week 6 lab "Sort cells by area" (PRD §11).
# Pure Tcl with no file access, so the same code runs in tclsh and in the browser playground.
# Needs: labData(inputs.txt), the "set name value" input lines given in the starter (a value may be
# a nested list in braces, like {{INV {0 0 3 10}} {NAND2 {0 0 5 10}}}).
# Provides: labCheck learnerCode -> the report as text.
# The checker works out every expected line from the inputs, so no answers are stored.
# (data/expected.txt is only for the lab page; selftest.tcl checks that it agrees with labTargets.)

# A loop that never ends must not freeze the checker: every run may use at most this many commands.
# A correct script uses fewer than 200. (interp limit works in tclsh 8.6, 9.0 and Wacl 8.6.6.)
set labCommandLimit 100000
# An endless loop that prints would also fill the memory: Wacl has only 16 MB, and running out stops the
# whole browser interpreter. So the captured output is capped too; a correct report is under 1000 characters.
set labOutputLimit 20000

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
    set status ok
    if {[catch {$child eval $code} message]} {
        set status error
        if {[string match "command count limit exceeded*" $message] || $message eq "output limit exceeded"} {
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

# A value as Tcl sees it: {{INV {0 0 3 10}}} becomes the list {INV {0 0 3 10}}.
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

# The {name area} pairs of the cells, in the order they were given.
proc labPairs {cells} {
    set pairs {}
    foreach cell $cells {
        set rect [lindex $cell 1]
        set area [expr {([lindex $rect 2] - [lindex $rect 0]) * ([lindex $rect 3] - [lindex $rect 1])}]
        lappend pairs [list [lindex $cell 0] $area]
    }
    return $pairs
}

# Pairs as numbered report lines: "1. DFF: 140 um2".
proc labRankLines {pairs} {
    set lines {}
    set rank 0
    foreach pair $pairs {
        incr rank
        lappend lines "$rank. [lindex $pair 0]: [lindex $pair 1] um2"
    }
    return $lines
}

# The expected report for some inputs, as a list of lines.
proc labTargets {inputs} {
    set cells [labValue [dict get $inputs cells]]
    set topCount [labValue [dict get $inputs topCount]]
    set findCell [labValue [dict get $inputs findCell]]
    set sorted [lsort -integer -decreasing -index 1 [labPairs $cells]]
    set lines [list "Cells: [llength $cells]"]
    foreach line [labRankLines $sorted] {
        lappend lines $line
    }
    set names [lmap pair $sorted {lindex $pair 0}]
    lappend lines "Largest $topCount: [join [lrange $names 0 [expr {$topCount - 1}]] {, }]"
    set index [lsearch -exact $names $findCell]
    if {$index == -1} {
        lappend lines "$findCell: not found"
    } else {
        lappend lines "$findCell: rank [expr {$index + 1}]"
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

# Ranked lines without their numbers: "DFF: 140 um2".
proc labUnnumbered {lines} {
    return [lmap line $lines {regsub {^\d+\.\s*} $line ""}]
}

# The two swap tests: a label, the new inputs (written as in a set line), a hint, and where to revisit.
set labSwaps [list \
    [list "a tie, and a cell that is not there" \
        [list cells "{{XOR2 {0 0 7 8}} {INV {0 0 2 8}} {MUX2 {0 0 9 8}} {AOI21 {0 0 7 8}}}" topCount 2 findCell NAND2] \
        "Here the cells are 8 um tall, XOR2 and AOI21 have the same area, and NAND2 is not in the list. lsearch gives -1 for it: test with != -1 and print: NAND2: not found." \
        {Lesson A, "Common traps"}] \
    [list "six cells, find the smallest" \
        [list cells "{{BUF {0 0 4 12}} {DFF {0 0 16 12}} {INV {0 0 3 12}} {NAND3 {0 0 7 12}} {TIE {0 0 2 12}} {NOR3 {0 0 8 12}}}" topCount 6 findCell TIE] \
        "Here there are six cells, 12 um tall, and topCount is 6. Work out each area from the rectangle, and the end of lrange from topCount." \
        {Lesson A, "lrange cuts, lsearch finds"}] \
]

proc labCheck {learnerCode} {
    global labData labSwaps
    set inputs [labFacts $labData(inputs.txt)]
    set targets [labTargets $inputs]
    set total 9
    set report {}
    set passed 0

    # Test 1: the script runs.
    lassign [labRun $learnerCode] status message output
    set lines [labLines $output]
    if {$status eq "toolong"} {
        lappend report "FAIL Your script ran too long, or printed far too much, so the checker stopped it."
        lappend report "     Is there a loop that never ends? foreach and lmap always end, so look at any while loop:"
        lappend report "     it must change what its condition tests every time it runs."
        lappend report "     Revisit: Week 4, Lesson B, \"Why loops need braces\"."
        lappend report "TODO The other [expr {$total - 1}] tests: fix the endless loop first."
        lappend report "RESULT: FAIL 0/$total"
        return [join $report \n]
    }
    if {$status eq "error"} {
        lappend report "FAIL Your script stops with an error. Tcl says: $message"
        lappend report "     The lines printed before the error are still checked below."
        lappend report "     Revisit: Lesson B, \"Common traps\" (read the error message first)."
    } else {
        incr passed
        lappend report "PASS Your script runs without an error"
    }

    # Test 2: the number of cells.
    set want [lindex [labPick $targets {^Cells:}] 0]
    set got [lindex [labPick $lines {^Cells:}] 0]
    if {$got eq $want} {
        incr passed
        lappend report "PASS The cell count"
    } elseif {$got eq ""} {
        lappend report "TODO The cell count: not printed yet. It should be: $want"
    } else {
        lappend report "FAIL The cell count"
        lappend report "     Expected: $want"
        lappend report "     Received: $got"
        lappend report "     Each cell is ONE element of cells: a pair of a name and a rectangle. llength \$cells counts the pairs."
        lappend report "     Revisit: Lesson B, \"A list of rectangles\"."
    }

    # Tests 3 and 4: the ranked lines, first their areas (in any order), then their order.
    set wantRanked [labPick $targets {^\d+\.}]
    set gotRanked [labPick $lines {^\d+\.}]
    set wantItems [labUnnumbered $wantRanked]
    set gotItems [labUnnumbered $gotRanked]
    set areasRight [expr {[lsort $gotItems] eq [lsort $wantItems]}]
    set orderRight [expr {$gotRanked eq $wantRanked}]
    if {[llength $gotRanked] == 0} {
        lappend report "TODO The area of each cell: not printed yet. The first ranked line should be: [lindex $wantRanked 0]"
        lappend report "TODO The order of the cells: print the ranked lines first."
    } else {
        if {$areasRight} {
            incr passed
            lappend report "PASS The area of each cell"
        } else {
            lappend report "FAIL The area of each cell"
            lappend report "     Expected (in some order): [join [lsort $wantItems] { | }]"
            lappend report "     Received: [join [lsort $gotItems] { | }]"
            lappend report "     Each cell is {name {x1 y1 x2 y2}}. lindex \$cell 0 is the name and lindex \$cell 1 the rectangle;"
            lappend report "     the area is (x2 - x1) * (y2 - y1). Print each line as: 1. DFF: 140 um2"
            lappend report "     Revisit: Lesson B, \"A list of rectangles\"."
        }
        if {$gotRanked eq $wantRanked} {
            incr passed
            lappend report "PASS The order of the cells"
        } elseif {!$areasRight} {
            lappend report "TODO The order of the cells: get the areas right first."
        } else {
            lappend report "FAIL The order of the cells"
            lappend report "     Expected: [join $wantRanked { | }]"
            lappend report "     Received: [join $gotRanked { | }]"
            set pairs [labPairs [labValue [dict get $inputs cells]]]
            if {$gotItems eq $wantItems} {
                lappend report "     The cells are in the right order, but the numbers in front are not 1, 2, 3 and so on."
                lappend report "     Use a counter that starts at 0, and incr it before each puts."
            } elseif {$gotItems eq [labUnnumbered [labRankLines [lsort -integer -index 1 $pairs]]]} {
                lappend report "     These are smallest first. Add -decreasing to lsort to get the largest first."
            } elseif {$gotItems eq [labUnnumbered [labRankLines [lsort -decreasing -index 1 $pairs]]]} {
                lappend report "     The areas were sorted as text, so 60 comes before 140. Add -integer to lsort."
            } elseif {$gotItems eq [labUnnumbered [labRankLines $pairs]]} {
                lappend report "     These are in the order of the input. Sort the pairs with lsort -integer -decreasing -index 1, and keep the result with set."
            } else {
                lappend report "     Sort the {name area} pairs with lsort -integer -decreasing -index 1, then print them in that order."
            }
            lappend report "     Revisit: Lesson A, \"Sort pairs by one field\"."
        }
    }

    # Test 5: the largest cells.
    set want [lindex [labPick $targets {^Largest}] 0]
    set got [lindex [labPick $lines {^Largest}] 0]
    if {$got eq $want} {
        incr passed
        lappend report "PASS The largest cells"
    } elseif {$got eq ""} {
        lappend report "TODO The largest cells: not printed yet. It should be: $want"
    } else {
        lappend report "FAIL The largest cells"
        lappend report "     Expected: $want"
        lappend report "     Received: $got"
        if {!$orderRight} {
            lappend report "     This line uses the names in sorted order, largest first. Fix the order of the cells first."
        } elseif {[string first "," $got] < 0 && [llength [split $got]] > 3} {
            lappend report "     Put \", \" between the names with join: join \$top \", \""
        } else {
            lappend report "     lrange \$names 0 \[expr {\$topCount - 1}\] gives the first topCount names: the end index is topCount - 1,"
            lappend report "     because counting starts at 0. Then glue them with join and \", \"."
        }
        lappend report "     Revisit: Lesson A, \"lrange cuts, lsearch finds\", and Lesson B, \"split and join\"."
    }

    # Test 6: the rank of the cell to find.
    set rankPattern {^[A-Za-z][^ ]* (rank|not found)}
    set want [lindex [labPick $targets $rankPattern] 0]
    set got [lindex [labPick $lines $rankPattern] 0]
    if {$got eq $want} {
        incr passed
        lappend report "PASS The rank of the cell to find"
    } elseif {$got eq ""} {
        lappend report "TODO The rank of the cell to find: not printed yet. It should be: $want"
    } else {
        lappend report "FAIL The rank of the cell to find"
        lappend report "     Expected: $want"
        lappend report "     Received: $got"
        if {!$orderRight} {
            lappend report "     The rank comes from the names in sorted order, largest first. Fix the order of the cells first."
        } elseif {[regexp {rank (-?\d+)$} $want -> wantRank] && [regexp {rank (-?\d+)$} $got -> gotRank] && $gotRank == $wantRank - 1} {
            lappend report "     lsearch gives an index, counting from 0. Ranks count from 1: add 1."
        } else {
            lappend report "     Use lsearch on the list of names in sorted order (the one you made with lmap). It gives the index, from 0;"
            lappend report "     the rank is that index + 1."
        }
        lappend report "     Revisit: Lesson A, \"lrange cuts, lsearch finds\"."
    }

    # Test 7: every line, in order, and nothing extra.
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

    # Tests 8 and 9: change the inputs and run again.
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
        lappend report "     Work every line out from the inputs, with lsort, lrange and lsearch, instead of typing it."
        lappend report "     Revisit: $revisit."
    }

    if {$passed == $total} {
        lappend report "RESULT: PASS $passed/$total"
    } else {
        lappend report "RESULT: FAIL $passed/$total"
    }
    return [join $report \n]
}
