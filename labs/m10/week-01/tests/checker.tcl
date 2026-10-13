# Grader for the Week 1 lab "Chip passport" (PRD §11).
# Pure Tcl with no file access, so the same code runs in tclsh and in the browser playground.
# Needs: labData(passport.txt), the target output, and labData(facts.txt), the "set name value"
# lines given in the starter. Provides: labCheck learnerCode -> the report as text.
# The learner's script runs in a fresh safe interpreter, with puts captured.

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
# Capitals, spelling and punctuation still count.
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

# A short name for a passport line: the text before the colon, or "title".
proc labLineName {line} {
    set colon [string first : $line]
    if {$colon < 0} {
        return title
    }
    return [string range $line 0 [expr {$colon - 1}]]
}

proc labCheck {learnerCode} {
    global labData
    set target [labLines $labData(passport.txt)]
    set facts [labFacts $labData(facts.txt)]
    set total [expr {[llength $target] + 4}]
    set report {}
    set passed 0

    # Test 1: the script runs.
    lassign [labRun $learnerCode] failed message output
    set lines [labLines $output]
    if {$failed} {
        lappend report "FAIL Your script stops with an error. Tcl says: $message"
        lappend report "     The lines printed before the error are still checked below."
        lappend report "     Revisit: Lesson A, \"Common traps\" (read the error message first)."
    } else {
        incr passed
        lappend report "PASS Your script runs without an error"
    }

    # Tests 2 to 6: one per passport line. Lines that show a fact use variables (Lesson B).
    set number 0
    set factLinesOk 1
    foreach want $target {
        incr number
        set what "Line $number ([labLineName $want])"
        set usesFact 0
        foreach {name value} $facts {
            if {[string first $value $want] >= 0} {
                set usesFact 1
            }
        }
        if {$usesFact} {
            set revisit "Lesson B, \"Variables: give a value a name\""
        } else {
            set revisit "Lesson A, \"Scripts, commands and output\""
        }
        if {$number > [llength $lines]} {
            lappend report "TODO $what: not printed yet. It should be: $want"
            if {$usesFact} {
                set factLinesOk 0
            }
            continue
        }
        set got [lindex $lines [expr {$number - 1}]]
        if {$got eq $want} {
            incr passed
            lappend report "PASS $what"
            continue
        }
        if {$usesFact} {
            set factLinesOk 0
        }
        lappend report "FAIL $what"
        lappend report "     Expected: $want"
        lappend report "     Received: $got"
        lappend report "     Check capitals, spelling and punctuation. Revisit: $revisit."
    }

    # Test 7: nothing extra.
    set count [llength $lines]
    set wanted [llength $target]
    if {$count == $wanted} {
        incr passed
        lappend report "PASS No extra lines"
    } elseif {$count < $wanted} {
        lappend report "TODO No extra lines: finish the passport first."
    } else {
        lappend report "FAIL No extra lines: your script prints $count lines, but the passport has $wanted."
        lappend report "     The first extra line is: [lindex $lines $wanted]"
        lappend report "     Remove the extra puts commands, or turn them into comments with #. Revisit: Lesson A, \"Comments: notes for humans\"."
    }

    # Test 8: the passport really uses the variables. Change the facts and run again.
    set swapped $learnerCode
    set missing ""
    set changes {}
    foreach {name value} $facts {
        if {[string is integer -strict $value]} {
            set new [expr {$value + 111}]
        } else {
            set new Testchip
        }
        set next [labSwapLine $swapped $name $value $new]
        if {$next eq ""} {
            set missing "set $name $value"
            break
        }
        set swapped $next
        lappend changes $value $new
    }
    if {$missing ne ""} {
        lappend report "NOTE Uses variables: I could not find the line   $missing   in your script."
        lappend report "     Keep the three set lines exactly as they are in the starter, then check again."
    } elseif {!$factLinesOk} {
        lappend report "TODO Uses variables: get the Name and Size lines right first. Then this test changes the facts and runs your script again."
    } else {
        lassign [labRun $swapped] swapFailed swapMessage swapOutput
        set swapLines [labLines $swapOutput]
        set problem ""
        set number 0
        foreach want $target {
            set swapWant [string map $changes $want]
            set swapGot [lindex $swapLines $number]
            incr number
            if {$swapWant ne $want && $swapGot ne $swapWant} {
                set problem "Line $number should then say: $swapWant\n     It says: $swapGot"
                break
            }
        }
        set newFacts {}
        foreach {old new} $changes {
            lappend newFacts $new
        }
        if {$swapFailed} {
            lappend report "FAIL Uses variables: with other facts, your script stops with an error. Tcl says: $swapMessage"
        } elseif {$problem ne ""} {
            lappend report "FAIL Uses variables: I changed the facts to [join $newFacts {, }] and ran your script again."
            lappend report "     $problem"
            lappend report "     Write \$chipName, \$chipWidth and \$chipHeight in your puts lines instead of typing the facts."
            lappend report "     Revisit: Lesson B, \"Variables: give a value a name\"."
        } else {
            incr passed
            lappend report "PASS Uses variables: the passport follows when the facts change"
        }
    }

    # Test 9: the script is signed with a comment.
    set signed ""
    foreach line [split $learnerCode \n] {
        if {[regexp {^\s*#\s*Made by:(.*)$} $line -> who]} {
            set signed [string trim $who]
        }
    }
    if {$signed ne "" && $signed ne "???"} {
        incr passed
        lappend report "PASS Signed: Made by: $signed"
    } elseif {$signed eq "???"} {
        lappend report "TODO Signed: replace ??? after \"Made by:\" with your name (Step 6). Keep the # at the start."
    } else {
        lappend report "FAIL Signed: I could not find the comment   # Made by: your name"
        lappend report "     Add it as a line of its own, starting with #. Revisit: Lesson A, \"Comments: notes for humans\"."
    }

    if {$passed == $total} {
        lappend report "RESULT: PASS $passed/$total"
    } else {
        lappend report "RESULT: FAIL $passed/$total"
    }
    return [join $report \n]
}
