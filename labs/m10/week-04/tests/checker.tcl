# Grader for the Week 4 lab "Is this wire wide enough?" (PRD §11).
# Pure Tcl with no file access, so the same code runs in tclsh and in the browser playground.
# Needs: labData(inputs.txt), the "set name value" input lines given in the starter.
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

# The expected report for some inputs, as a list of lines.
proc labTargets {inputs} {
    set wireName [dict get $inputs wireName]
    set wireWidth [dict get $inputs wireWidth]
    set minWidth [dict get $inputs minWidth]
    set minSpace [dict get $inputs minSpace]
    set channelWidth [dict get $inputs channelWidth]
    set lines [list "Wire $wireName: $wireWidth um wide, minimum $minWidth um"]
    if {$wireWidth < $minWidth} {
        lappend lines "Result: TOO NARROW"
    } elseif {$wireWidth == $minWidth} {
        lappend lines "Result: OK, AT THE MINIMUM"
    } else {
        lappend lines "Result: OK"
    }
    set x $minSpace
    set count 0
    while {$x + $minWidth + $minSpace <= $channelWidth} {
        incr count
        lappend lines "Track $count: x = $x um"
        incr x [expr {$minWidth + $minSpace}]
    }
    lappend lines "Tracks that fit: $count"
    return $lines
}

# The track lines of a report: the lines "Track N: ..." that follow the first two lines.
proc labTrackLines {lines} {
    set tracks {}
    foreach line [lrange $lines 2 end] {
        if {![regexp {^Track \d+:} $line]} {
            break
        }
        lappend tracks $line
    }
    return $tracks
}

# A hint for wrong track lines, or "" when none fits.
proc labTrackHint {want got} {
    set wantCount [llength $want]
    set gotCount [llength $got]
    if {$gotCount > 0 && [regexp {^Track 1: x = 0 um$} [lindex $got 0]] && [lindex $want 0] ne [lindex $got 0]} {
        return "The first track starts minSpace away from CORE, at x = minSpace, not at x = 0."
    }
    if {$gotCount == $wantCount + 1 && [lrange $got 0 end-1] eq $want} {
        return "One track too many: the last one does not fit. A track fits only if x + minWidth + minSpace <= channelWidth."
    }
    if {$gotCount == $wantCount - 1 && [lrange $want 0 end-1] eq $got} {
        return "One track too few. A track that ends exactly minSpace before SRAM still fits, so the test is <=, not <."
    }
    return ""
}

# The three swap tests: a label, the new inputs, a hint for the usual mistake, and where to revisit.
set labSwaps {
    {
        "a wire exactly at the minimum"
        {wireName BUS wireWidth 4 minWidth 4 minSpace 3 channelWidth 33}
        "A wire exactly at the minimum width is allowed, and it gets its own result: OK, AT THE MINIMUM. Test for it with == in an elseif."
        {Lesson A, "elseif: the first true test wins"}
    }
    {
        "a channel that fits exactly"
        {wireName VDD wireWidth 6 minWidth 2 minSpace 1 channelWidth 13}
        "Here the last track ends exactly minSpace before SRAM, so it still fits. Use <= in your loop condition, not <."
        {Lesson B, "while: repeat while a test is true"}
    }
    {
        "a channel with no room"
        {wireName DATA wireWidth 1 minWidth 3 minSpace 2 channelWidth 6}
        "Here not even one track fits, so the report has no Track lines. A while loop checks its condition before the first pass, so it can run zero times."
        {Lesson B, "while: repeat while a test is true"}
    }
}

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
        lappend report "     Is there a loop that never ends? Check that the loop changes x every time it runs (incr x ...),"
        lappend report "     so that its condition becomes false in the end."
        lappend report "     Revisit: Lesson B, \"Why loops need braces\"."
        lappend report "TODO The other 8 tests: fix the endless loop first."
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

    # Test 2: the wire line.
    set want [lindex $targets 0]
    if {[llength $lines] < 1} {
        lappend report "TODO Line 1 (the wire): not printed yet. It should be: $want"
    } elseif {[lindex $lines 0] eq $want} {
        incr passed
        lappend report "PASS Line 1 (the wire)"
    } else {
        lappend report "FAIL Line 1 (the wire)"
        lappend report "     Expected: $want"
        lappend report "     Received: [lindex $lines 0]"
        lappend report "     Check the words, capitals and units, and use the variables \$wireName, \$wireWidth and \$minWidth."
        lappend report "     Revisit: Week 1, Lesson B, \"Variables: give a value a name\"."
    }

    # Test 3: the result line.
    set want [lindex $targets 1]
    set results {"Result: TOO NARROW" "Result: OK, AT THE MINIMUM" "Result: OK"}
    if {[llength $lines] < 2} {
        lappend report "TODO Line 2 (the result): not printed yet. It should be: $want"
    } elseif {[lindex $lines 1] eq $want} {
        incr passed
        lappend report "PASS Line 2 (the result)"
    } else {
        set got [lindex $lines 1]
        lappend report "FAIL Line 2 (the result)"
        lappend report "     Expected: $want"
        lappend report "     Received: $got"
        if {[lsearch -exact $results $got] >= 0} {
            lappend report "     Your if chose the wrong branch. Compare wireWidth with minWidth: which one is smaller?"
        } else {
            lappend report "     The result must be exactly one of: TOO NARROW, OK, AT THE MINIMUM, or OK."
        }
        lappend report "     Revisit: Lesson A, \"if and else: two branches\"."
    }

    # Test 4: the track lines.
    set wantTracks [labTrackLines $targets]
    set gotTracks [labTrackLines $lines]
    if {$gotTracks eq $wantTracks} {
        incr passed
        lappend report "PASS The track lines"
    } elseif {[llength $lines] <= 2} {
        lappend report "TODO The track lines: not printed yet. The first should be: [lindex $wantTracks 0]"
    } else {
        lappend report "FAIL The track lines"
        lappend report "     Expected: [join $wantTracks { | }]"
        if {[llength $gotTracks] == 0} {
            lappend report "     Received: no lines that start with Track. Line 3 is: [lindex $lines 2]"
        } else {
            lappend report "     Received: [join $gotTracks { | }]"
        }
        set hint [labTrackHint $wantTracks $gotTracks]
        if {$hint ne ""} {
            lappend report "     $hint"
        }
        lappend report "     Revisit: Lesson B, \"while: repeat while a test is true\"."
    }

    # Test 5: the count line, right after the track lines.
    set want [lindex $targets end]
    set index [expr {2 + [llength $gotTracks]}]
    if {$index >= [llength $lines]} {
        lappend report "TODO The count line: not printed yet. It should be: $want"
    } elseif {[lindex $lines $index] eq $want} {
        incr passed
        lappend report "PASS The count line"
    } else {
        lappend report "FAIL The count line (the line after the tracks)"
        lappend report "     Expected: $want"
        lappend report "     Received: [lindex $lines $index]"
        lappend report "     Count the tracks with a counter: set it to 0 before the loop, and incr it once per track."
        lappend report "     Revisit: Lesson B, \"while: repeat while a test is true\"."
    }

    # Test 6: nothing extra.
    set count [llength $lines]
    set wanted [llength $targets]
    if {$lines eq $targets} {
        incr passed
        lappend report "PASS No extra lines"
    } elseif {$count < $wanted} {
        lappend report "TODO No extra lines: finish all four steps first."
    } elseif {$count > $wanted} {
        lappend report "FAIL No extra lines: your script prints $count lines, but the report has $wanted."
        lappend report "     The first extra line is: [lindex $lines $wanted]"
        lappend report "     Remove the extra puts commands, or turn them into comments with #."
    } else {
        lappend report "TODO No extra lines: get every line right first."
    }

    # Tests 7 to 9: change the inputs and run again, so every branch and every loop length is tested.
    set swapped ""
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
                lappend report "     Keep the five input lines exactly as they are in the starter, then check again."
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
            lappend report "     With these inputs your loop never ends. Check that it changes x every time it runs."
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
        lappend report "     Work every line out from the variables, with if and a loop, instead of typing it."
        lappend report "     Revisit: $revisit."
    }

    if {$passed == $total} {
        lappend report "RESULT: PASS $passed/$total"
    } else {
        lappend report "RESULT: FAIL $passed/$total"
    }
    return [join $report \n]
}
