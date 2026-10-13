# Grader for the Week 3 lab "Substitution detective" (PRD §11).
# Pure Tcl with no file access, so the same code runs in tclsh and in the browser playground.
# Needs: labData(puzzles.txt). Provides: labCheck learnerCode -> the report as text.
# Each puzzle runs in a fresh safe interpreter, with puts captured, to get its real output.
# (Wacl, the browser Tcl, cannot create full child interpreters, but safe ones work.)

# Split puzzles.txt into a list of {number revisit code} items.
proc labPuzzles {text} {
    set puzzles {}
    set number 0
    set revisit ""
    set code ""
    foreach line [split $text \n] {
        if {[string match "### *" $line]} {
            if {$number > 0} {
                lappend puzzles [list $number $revisit [string trim $code \n]]
            }
            set parts [split [string range $line 4 end] |]
            set number [string trim [lindex $parts 0]]
            set revisit [string trim [join [lrange $parts 1 end] |]]
            set code ""
        } elseif {$number > 0 && ![string match "## *" $line]} {
            append code $line \n
        }
    }
    if {$number > 0} {
        lappend puzzles [list $number $revisit [string trim $code \n]]
    }
    return $puzzles
}

# Stand-in for puts inside a puzzle: collect the text instead of printing it.
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

# Run one puzzle and return what it prints.
proc labRun {code} {
    global labOutput
    set labOutput ""
    set child [interp create -safe]
    interp alias $child puts {} labCapture
    set failed [catch {$child eval $code} message]
    interp delete $child
    if {$failed} {
        return -code error "puzzle raised an error: $message"
    }
    return $labOutput
}

# Compare outputs fairly: ignore spaces at the start and end of each line (learners indent
# multi-line predictions) and blank lines at the start or end. No puzzle prints such spaces;
# selftest.tcl checks that.
proc labNormalize {text} {
    set lines {}
    foreach line [split [string map [list \r ""] $text] \n] {
        lappend lines [string trim $line]
    }
    return [string trim [join $lines \n] \n]
}

# Show multi-line text indented, one "| " per line, so empty lines stay visible.
proc labShow {text} {
    set out {}
    foreach line [split [labNormalize $text] \n] {
        lappend out "      | $line"
    }
    return [join $out \n]
}

proc labCheck {learnerCode} {
    global labData
    set puzzles [labPuzzles $labData(puzzles.txt)]
    set total [llength $puzzles]
    set report {}

    # Read the predictions in their own safe interpreter.
    set learner [interp create -safe]
    interp alias $learner puts {} labCapture
    if {[catch {$learner eval $learnerCode} message]} {
        interp delete $learner
        lappend report "FAIL Your file could not be read. Tcl says: $message"
        lappend report "     Check that every \{ has a matching \} and every \" has a partner."
        lappend report "     Revisit: Lesson A, \"Words and grouping\"."
        lappend report "RESULT: FAIL 0/$total"
        return [join $report \n]
    }

    set passed 0
    foreach puzzle $puzzles {
        lassign $puzzle number revisit code
        set name [format p%02d $number]
        if {![$learner eval [list info exists $name]]} {
            lappend report "FAIL Puzzle $number: the line for $name is missing. Add: set $name {your prediction}"
            continue
        }
        set prediction [$learner eval [list set $name]]
        if {[string trim $prediction] eq "???"} {
            lappend report "TODO Puzzle $number: not answered yet."
            continue
        }
        set expected [labRun $code]
        if {[labNormalize $prediction] eq [labNormalize $expected]} {
            incr passed
            lappend report "PASS Puzzle $number"
            continue
        }
        lappend report "FAIL Puzzle $number"
        lappend report "     Tcl prints:"
        lappend report [labShow $expected]
        lappend report "     You wrote:"
        lappend report [labShow $prediction]
        lappend report "     Revisit: $revisit"
    }
    interp delete $learner

    if {$passed == $total} {
        lappend report "RESULT: PASS $passed/$total"
    } else {
        lappend report "RESULT: FAIL $passed/$total"
    }
    return [join $report \n]
}
