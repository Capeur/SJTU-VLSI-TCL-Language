# Grader for the Week 9 lab "The layer table" (PRD §11).
# Pure Tcl with no file access, so the same code runs in tclsh and in the browser playground.
# Needs: labData(inputs.txt), the "set name value" input lines given in the starter.
# Provides: labCheck learnerCode -> the report as text.
# The checker works out every expected line from the inputs, so no answers are stored.
# (data/expected.txt is only for the lab page; selftest.tcl checks that it agrees with labTargets.)
# No expected line depends on the order of array names: the report follows the order of the layer
# table (a dict, insertion order), and the unknown layers are sorted (user decision, P3 Weeks 8-9).
# A loop that never ends must not freeze the checker: every run may use at most this many commands.
# A correct script uses fewer than 300. (interp limit works in tclsh 8.6, 9.0 and Wacl 8.6.6.)
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

# The expected report for some inputs, as a list of lines.
proc labTargets {inputs} {
    set layerNumbers [labValue [dict get $inputs layerNumbers]]
    set shapeLayers [labValue [dict get $inputs shapeLayers]]
    set lookUp [labValue [dict get $inputs lookUp]]
    set lines [list "Layers: [dict keys $layerNumbers]"]
    if {[dict exists $layerNumbers $lookUp]} {
        lassign [split [dict get $layerNumbers $lookUp] .] number datatype
        lappend lines "$lookUp: number $number, datatype $datatype, purpose drawing"
    } else {
        lappend lines "$lookUp: not in the table"
    }
    set counts [dict create]
    dict for {name gds} $layerNumbers {
        dict set counts $name 0
    }
    set unknown {}
    set unknownShapes 0
    foreach layer $shapeLayers {
        if {[dict exists $counts $layer]} {
            dict incr counts $layer
        } else {
            if {[lsearch -exact $unknown $layer] == -1} {
                lappend unknown $layer
            }
            incr unknownShapes
        }
    }
    dict for {name gds} $layerNumbers {
        lappend lines "$name $gds: [dict get $counts $name]"
    }
    if {[llength $unknown] == 0} {
        lappend lines "Unknown: none"
    } else {
        lappend lines "Unknown: [join [lsort $unknown] {, }]"
    }
    lappend lines "Shapes: [llength $shapeLayers], on unknown layers: $unknownShapes"
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

# The count lines: "ACTIVE 1.0: 2".
set labCountPattern {^[A-Z][A-Z0-9]* [0-9]+\.[0-9]+: }

# The two swap tests: a label, the new inputs (written as in a set line), a hint, and where to revisit.
set labSwaps [list \
    [list "two unknown layers, each seen twice" \
        [list layerNumbers "{ACTIVE 1.0 POLY 2.0 CONTACT 3.0 METAL1 4.0 VIA1 5.0 METAL2 6.0 TEXT 63.0}" shapeLayers "{VIA2 POLY METAL9 POLY VIA2 TEXT}" lookUp TEXT] \
        "Here VIA2 comes before METAL9 in the shapes, and both appear twice. The Unknown line names each unknown layer once, sorted: METAL9, VIA2. An array keeps each key once; lsort \[array names unknown\] sorts them." \
        {Lesson B, "array names: no promised order"}] \
    [list "no unknown layer, and a look-up that fails" \
        [list layerNumbers "{ACTIVE 1.0 POLY 2.0 CONTACT 3.0 METAL1 4.0 VIA1 5.0 METAL2 6.0 TEXT 63.0}" shapeLayers "{METAL2 METAL2 CONTACT METAL2}" lookUp METAL3] \
        "Here METAL3 is not in the table: test with dict exists before dict get, and print: METAL3: not in the table. No shape is on an unknown layer, so print: Unknown: none." \
        {Lesson A, "Records inside a dict"}] \
]

# One test that compares one line of the report.
# Adds a PASS, FAIL or TODO to the report variable of the caller; returns 1 on a PASS.
proc labLineTest {reportName title want got hints revisit} {
    upvar 1 $reportName report
    if {$got eq $want} {
        lappend report "PASS $title"
        return 1
    }
    if {$got eq ""} {
        lappend report "TODO $title: not printed yet. It should be: $want"
        return 0
    }
    lappend report "FAIL $title"
    lappend report "     Expected: $want"
    lappend report "     Received: $got"
    foreach hint $hints {
        lappend report "     $hint"
    }
    lappend report "     Revisit: $revisit."
    return 0
}

proc labCheck {learnerCode} {
    global labData labSwaps labCountPattern
    set inputs [labFacts $labData(inputs.txt)]
    set targets [labTargets $inputs]
    set total 10
    set report {}
    set passed 0

    # Test 1: the script runs.
    lassign [labRun $learnerCode] status message output
    set lines [labLines $output]
    if {$status eq "toolong"} {
        lappend report "FAIL Your script ran too long, or printed far too much, so the checker stopped it."
        lappend report "     Is there a loop that never ends? foreach and dict for always end, so look at any while loop:"
        lappend report "     it must change what its condition tests every time it runs."
        lappend report "     Revisit: Week 4, Lesson B, \"Why loops need braces\"."
        lappend report "TODO The other [expr {$total - 1}] tests: fix the endless loop first."
        lappend report "RESULT: FAIL 0/$total"
        return [join $report \n]
    }
    if {$status eq "error"} {
        lappend report "FAIL Your script stops with an error. Tcl says: $message"
        lappend report "     The lines printed before the error are still checked below."
        if {[string match "*variable is array*" $message]} {
            lappend report "     An array is a set of variables, so \$name alone cannot be read. Read one element: \$count(\$layer)."
            lappend report "     Revisit: Lesson B, \"Common traps\"."
        } elseif {[string match "*not known in dictionary*" $message] || [string match "*no such element in array*" $message]} {
            lappend report "     A key that is not there cannot be read. Test it first with dict exists, and remember that capitals count."
            lappend report "     Revisit: Lesson A, \"Common traps\"."
        } else {
            lappend report "     Revisit: Lesson A, \"Common traps\" (read the error message first)."
        }
    } else {
        incr passed
        lappend report "PASS Your script runs without an error"
    }

    # Test 2: the layer names.
    incr passed [labLineTest report "The layer names" [lindex $targets 0] [lindex [labPick $lines {^Layers:}] 0] \
        [list "dict keys \$layerNumbers gives the names in table order. Print them after Layers: ."] \
        {Lesson A, "Keys and values"}]

    # Test 3: the look-up line.
    set lookUp [labValue [dict get $inputs lookUp]]
    incr passed [labLineTest report "The record of $lookUp" [lindex $targets 1] [lindex [labPick $lines "^$lookUp:"] 0] \
        [list "Split the GDS number at the dot: split 4.0 . gives the list 4 0, the number and the datatype." \
            "Store them with dict set layers \$name number …, then read them with dict get \$layers \$lookUp number."] \
        {Lesson A, "Records inside a dict"}]

    # Tests 4 and 5: the count lines, first the counts (in any order), then the order.
    set wantCounts [labPick $targets $labCountPattern]
    set gotCounts [labPick $lines $labCountPattern]
    set countsRight [expr {[lsort $gotCounts] eq [lsort $wantCounts]}]
    if {[llength $gotCounts] == 0} {
        lappend report "TODO The count for each layer: not printed yet. The first count line should be: [lindex $wantCounts 0]"
        lappend report "TODO The counts in table order: print the count lines first."
    } else {
        if {$countsRight} {
            incr passed
            lappend report "PASS The count for each layer"
        } else {
            lappend report "FAIL The count for each layer"
            lappend report "     Expected (in some order): [join [lsort $wantCounts] { | }]"
            lappend report "     Received: [join [lsort $gotCounts] { | }]"
            if {[llength $gotCounts] < [llength $wantCounts]} {
                lappend report "     Every layer of the table needs a line, even with 0 shapes. Set each counter to 0 first, with dict for over the table."
            } else {
                lappend report "     For each shape whose layer is in the table, incr count(\$layer). Print each line as: NAME GDS: COUNT"
            }
            lappend report "     Revisit: Lesson B, \"An array: a family of variables\"."
        }
        if {$gotCounts eq $wantCounts} {
            incr passed
            lappend report "PASS The counts in table order"
        } elseif {!$countsRight} {
            lappend report "TODO The counts in table order: get the counts right first."
        } else {
            lappend report "FAIL The counts in table order"
            lappend report "     Expected: [join $wantCounts { | }]"
            lappend report "     Received: [join $gotCounts { | }]"
            if {$gotCounts eq [lsort $wantCounts]} {
                lappend report "     These are sorted by name. The report follows the TABLE: walk it with dict for {name gds} \$layerNumbers."
            } else {
                lappend report "     If you loop over \[array names count\], that is the problem: array names gives the names in no promised order,"
                lappend report "     and it may differ between Tcl versions. Walk the table with dict for {name gds} \$layerNumbers instead."
            }
            lappend report "     Revisit: Lesson B, \"array names: no promised order\"."
        }
    }

    # Test 6: the unknown layers.
    set want [lindex [labPick $targets {^Unknown:}] 0]
    set got [lindex [labPick $lines {^Unknown:}] 0]
    incr passed [labLineTest report "The unknown layers" $want $got \
        [list "A layer is unknown when dict exists \$layers \$layer gives 0. Remember each one in an array, set unknown(\$layer) 1," \
            "then print them with join \[lsort \[array names unknown\]\] \", \". With no unknown layer, print: Unknown: none"] \
        {Lesson B, "array names: no promised order"}]

    # Test 7: the totals.
    set want [lindex $targets end]
    set got [lindex [labPick $lines {^Shapes:}] 0]
    incr passed [labLineTest report "The totals" $want $got \
        [list "The first number is llength \$shapeLayers. The second counts every shape on an unknown layer, repeats included."] \
        {Lesson B, "An array: a family of variables"}]

    # Test 8: every line, in order, and nothing extra.
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

    # Tests 9 and 10: change the inputs and run again.
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
            if {$name ne "layerNumbers"} {
                lappend described "$name $value"
            }
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
            lappend report "     $hint"
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
        lappend report "     Work every line out from the inputs, with the dict and the arrays, instead of typing it."
        lappend report "     Revisit: $revisit."
    }

    if {$passed == $total} {
        lappend report "RESULT: PASS $passed/$total"
    } else {
        lappend report "RESULT: FAIL $passed/$total"
    }
    return [join $report \n]
}
