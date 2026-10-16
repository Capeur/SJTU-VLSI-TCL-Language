# Grader for the Week 8 lab "Check the layer names" (PRD §11).
# Pure Tcl with no file access, so the same code runs in tclsh and in the browser playground.
# Needs: labData(inputs.txt), the "set name value" input lines given in the starter.
# Provides: labCheck learnerCode -> the report as text.
# The checker works out every expected line from the inputs, so no answers are stored.
# (data/expected.txt is only for the lab page; selftest.tcl checks that it agrees with labTargets.)
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

# Our cleaning rules for one raw name (the course's rules, not a real tool's).
# Returns {kind line}: kind is ok, dash (ok, after replacing - with _), nopurpose, layer or purpose.
proc labCheckName {raw knownLayers knownPurposes} {
    set name [string map {- _} [string trim $raw]]
    if {![string match *_* $name]} {
        return [list nopurpose "BAD [string toupper $name]: no purpose"]
    }
    set cut [string first _ $name]
    set layer [string toupper [string range $name 0 [expr {$cut - 1}]]]
    set purpose [string tolower [string range $name [expr {$cut + 1}] end]]
    set clean "${layer}_$purpose"
    if {[lsearch -exact $knownLayers $layer] == -1} {
        return [list layer "BAD $clean: unknown layer $layer"]
    }
    if {[lsearch -exact $knownPurposes $purpose] == -1} {
        return [list purpose "BAD $clean: unknown purpose $purpose"]
    }
    if {[string first - $raw] >= 0} {
        return [list dash "OK $clean"]
    }
    return [list ok "OK $clean"]
}

# One {kind line} per raw name, for some inputs.
proc labResults {inputs} {
    set rawNames [labValue [dict get $inputs rawNames]]
    set knownLayers [labValue [dict get $inputs knownLayers]]
    set knownPurposes [labValue [dict get $inputs knownPurposes]]
    set results {}
    foreach raw $rawNames {
        lappend results [labCheckName $raw $knownLayers $knownPurposes]
    }
    return $results
}

# The summary line: "Valid: 5 of 8 (62.5%)".
proc labSummary {valid total} {
    return "Valid: $valid of $total ([format %.1f [expr {100.0 * $valid / $total}]]%)"
}

# The expected report for some inputs, as a list of lines.
proc labTargets {inputs} {
    set lines {}
    set valid 0
    foreach result [labResults $inputs] {
        lassign $result kind line
        lappend lines $line
        if {$kind eq "ok" || $kind eq "dash"} {
            incr valid
        }
    }
    lappend lines [labSummary $valid [llength [labValue [dict get $inputs rawNames]]]]
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
    [list "lower case, and a name with no purpose" \
        [list rawNames "{{ via1_PIN} TEXT_drawing metal2}" knownLayers "{ACTIVE POLY CONTACT METAL1 VIA1 METAL2 TEXT}" knownPurposes "{drawing pin}"] \
        "Here via1_PIN must become VIA1_pin, and metal2 has no _, so the line is: BAD METAL2: no purpose (the name in capitals). 2 of 3 is 66.666…%, which format %.1f rounds to 66.7." \
        {Lesson A, "Clean up a name", and Lesson B, "format: neat columns and rounded numbers"}] \
    [list "other purposes, and two underscores" \
        [list rawNames "{TEXT_label METAL1_pin POLY_drawing_old ACTIVE_drawing}" knownLayers "{ACTIVE POLY CONTACT METAL1 VIA1 METAL2 TEXT}" knownPurposes "{drawing label}"] \
        "Here the purposes are drawing and label, so pin is unknown: test with lsearch \$knownPurposes, not with a typed list. POLY_drawing_old is cut at its FIRST _, so its purpose is drawing_old." \
        {Lesson A, "Cut at the underscore"}] \
]

# One test: every expected line of one kind must be in the learner's report.
# Adds a PASS, FAIL or TODO to the report variable of the caller; returns 1 on a PASS.
proc labKindTest {reportName title kind results lines hint revisit} {
    upvar 1 $reportName report
    global labKnownLayers
    set nameLines [labPick $lines {^(OK|BAD)\M}]
    set wanted {}
    set index 0
    foreach result $results {
        if {[lindex $result 0] eq $kind} {
            lappend wanted $index [lindex $result 1]
        }
        incr index
    }
    if {[llength $wanted] == 0} {
        lappend report "PASS $title (no such name in these inputs)"
        return 1
    }
    if {[llength $nameLines] == 0} {
        lappend report "TODO $title: no OK or BAD line printed yet. The first one should be: [lindex $results 0 1]"
        return 0
    }
    foreach {index want} $wanted {
        if {[lsearch -exact $lines $want] == -1} {
            lappend report "FAIL $title"
            lappend report "     Expected: $want"
            set got [lindex $nameLines $index]
            if {$got eq ""} {
                lappend report "     Received: no line for this name (name number [expr {$index + 1}])."
            } else {
                lappend report "     Received: $got"
            }
            if {[regexp {unknown layer (\S+)$} $got -> layer] && $layer ne [string toupper $layer] && [lsearch -exact $labKnownLayers [string toupper $layer]] != -1} {
                lappend report "     For lsearch, capitals count: $layer is not in knownLayers, but [string toupper $layer] is. Put the layer in capitals before you look it up."
            }
            lappend report "     $hint"
            lappend report "     Revisit: $revisit."
            return 0
        }
    }
    lappend report "PASS $title"
    return 1
}

proc labCheck {learnerCode} {
    global labData labSwaps labKnownLayers
    set inputs [labFacts $labData(inputs.txt)]
    set labKnownLayers [labValue [dict get $inputs knownLayers]]
    set targets [labTargets $inputs]
    set results [labResults $inputs]
    set total 10
    set report {}
    set passed 0

    # Test 1: the script runs.
    lassign [labRun $learnerCode] status message output
    set lines [labLines $output]
    if {$status eq "toolong"} {
        lappend report "FAIL Your script ran too long, or printed far too much, so the checker stopped it."
        lappend report "     Is there a loop that never ends? foreach always ends, so look at any while loop:"
        lappend report "     it must change what its condition tests every time it runs."
        lappend report "     Revisit: Week 4, Lesson B, \"Why loops need braces\"."
        lappend report "TODO The other [expr {$total - 1}] tests: fix the endless loop first."
        lappend report "RESULT: FAIL 0/$total"
        return [join $report \n]
    }
    if {$status eq "error"} {
        lappend report "FAIL Your script stops with an error. Tcl says: $message"
        lappend report "     The lines printed before the error are still checked below."
        if {[regexp {can't read "([A-Za-z0-9]+_)": no such variable} $message -> name]} {
            lappend report "     Tcl read $name as one variable name, because _ can be part of a name."
            lappend report "     Write \$\{[string range $name 0 end-1]\}_ so that the braces show where the name ends."
            lappend report "     Revisit: Lesson A, \"Common traps\"."
        } else {
            lappend report "     Revisit: Lesson A, \"Common traps\" (read the error message first)."
        }
    } else {
        incr passed
        lappend report "PASS Your script runs without an error"
    }

    # Tests 2 to 6: one kind of name each.
    incr passed [labKindTest report "Valid names, trimmed, layer in capitals, purpose in lower case" ok $results $lines \
        "Clean each name first: string trim removes the spaces at the ends. Then cut it at the first _ and use string toupper for the layer and string tolower for the purpose. Print OK, then the clean name." \
        {Lesson A, "Clean up a name"}]
    incr passed [labKindTest report "A dash is replaced with _" dash $results $lines \
        "Replace every - with _ before you test for _: set name \[string map {- _} \$name\]." \
        {Lesson B, "string map: swap pieces of text"}]
    incr passed [labKindTest report "A name with no _ has no purpose" nopurpose $results $lines \
        "string match *_* \$name gives 0 when the name has no _. Then print BAD, the name in capitals (string toupper), and: no purpose." \
        {Lesson B, "Glob patterns: string match"}]
    incr passed [labKindTest report "An unknown layer" layer $results $lines \
        "lsearch \$knownLayers \$layer gives -1 when the layer is not in the list. Test the layer first, then the purpose, and print the clean name." \
        {Week 6, Lesson A, "lrange cuts, lsearch finds"}]
    incr passed [labKindTest report "An unknown purpose" purpose $results $lines \
        "The purpose is everything after the first _, in lower case. lsearch \$knownPurposes \$purpose gives -1 when it is not in the list." \
        {Lesson A, "Cut at the underscore"}]

    # Test 7: the summary line.
    set want [lindex $targets end]
    set got [lindex [labPick $lines {^Valid:}] 0]
    if {$got eq $want} {
        incr passed
        lappend report "PASS The summary line"
    } elseif {$got eq ""} {
        lappend report "TODO The summary line: not printed yet. It should be: $want"
    } else {
        lappend report "FAIL The summary line"
        lappend report "     Expected: $want"
        lappend report "     Received: $got"
        regexp {^Valid: (\d+) of (\d+)} $want -> valid count
        if {![regexp {^Valid: (\d+) of (\d+)} $got -> gotValid gotCount]} {
            lappend report "     Print it as: Valid: N of TOTAL (SHARE%)"
        } elseif {$gotValid != $valid} {
            lappend report "     Count the OK names: set valid 0 before the loop, and incr valid after each OK line."
        } elseif {$gotCount != $count} {
            lappend report "     The total is the number of raw names: llength \$rawNames."
        } elseif {[expr {100 * $valid % $count}] != 0 && [regexp "\\([expr {100 * $valid / $count}](\\.0)?%\\)" $got]} {
            lappend report "     100 * $valid / $count is integer division (Week 2), so the decimals are lost. Write 100.0 to get a decimal number."
        } elseif {[regexp {\.\d\d} $got]} {
            lappend report "     Round the share to 1 decimal with format: \[format %.1f \$share\]."
        } else {
            lappend report "     The share is 100.0 * valid / total, rounded with format %.1f, then a % sign."
        }
        lappend report "     Revisit: Lesson B, \"format: neat columns and rounded numbers\"."
    }

    # Test 8: every line, in order, and nothing extra.
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
            lappend report "     Remove the extra puts commands, or turn them into comments with #."
        } else {
            lappend report "     Line $number should be: [lindex $targets [expr {$number - 1}]]"
            lappend report "     It is: [lindex $lines [expr {$number - 1}]]"
            lappend report "     Print one line per name, in the order of rawNames, then the summary."
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
            if {$name ne "knownLayers"} {
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
        lappend report "     Work every line out from the inputs with the string commands, instead of typing it."
        lappend report "     Revisit: $revisit."
    }

    if {$passed == $total} {
        lappend report "RESULT: PASS $passed/$total"
    } else {
        lappend report "RESULT: FAIL $passed/$total"
    }
    return [join $report \n]
}
