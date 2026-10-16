# Self-test of checker.tcl, so the grader can be trusted (PRD §11).
# Run by CI on Tcl 8.6, 9.0 and in Wacl: scripts/extract-snippets.mjs adds labData(...),
# labStarter and checker.tcl in front of this file. Any failed check raises an error.
#
# The passing program below is BUILT here, because the checker needs one to prove that it can
# say PASS (decision log, P3: allowed for small weekly labs only; capstones and exams are tested
# against the private solutions repository instead).

set checks 0
proc expectIn {label needle report} {
    global checks
    if {[string first $needle $report] < 0} {
        error "selftest '$label': expected to find [list $needle] in:\n$report"
    }
    incr checks
}
proc expectNotIn {label needle report} {
    global checks
    if {[string first $needle $report] >= 0} {
        error "selftest '$label': did not expect [list $needle] in:\n$report"
    }
    incr checks
}

set inputs [labFacts $labData(inputs.txt)]

# 1. The starter gives exactly the input lines that the checker looks for.
if {[dict keys $inputs] ne {rawNames knownLayers knownPurposes}} {
    error "selftest: inputs.txt should give rawNames, knownLayers and knownPurposes, not: [dict keys $inputs]"
}
foreach {name value} $inputs {
    if {[labSwapLine $labStarter $name $value $value] eq ""} {
        error "selftest: starter.tcl lacks the line: set $name $value"
    }
    incr checks
}
# The raw names keep their spaces: element 1 is " poly_drawing ".
if {[lindex [labValue [dict get $inputs rawNames]] 1] ne " poly_drawing "} {
    error "selftest: the second raw name should be \" poly_drawing \", with spaces"
}
incr checks

# 2. data/expected.txt (shown on the lab page) is what the checker really computes.
if {[join [labTargets $inputs] \n] ne [join [labLines $labData(expected.txt)] \n]} {
    error "selftest: data/expected.txt differs from the checker's own results:\n[join [labTargets $inputs] \n]"
}
incr checks
# Every kind of name appears in the main inputs.
foreach kind {ok dash nopurpose layer purpose} {
    if {[lsearch -exact -index 0 [labResults $inputs] $kind] == -1} {
        error "selftest: the main inputs have no name of kind $kind"
    }
    incr checks
}

# 3. The swaps test what they say: a lower-case name with no purpose and rounding, then other purposes.
set swapOne [join [labTargets [lindex $labSwaps 0 1]] \n]
expectIn swapLower "OK VIA1_pin" $swapOne
expectIn swapNoPurpose "BAD METAL2: no purpose" $swapOne
expectIn swapRound "Valid: 2 of 3 (66.7%)" $swapOne
set swapTwo [join [labTargets [lindex $labSwaps 1 1]] \n]
expectIn swapPurposes "BAD METAL1_pin: unknown purpose pin" $swapTwo
expectIn swapFirst "BAD POLY_drawing_old: unknown purpose drawing_old" $swapTwo
expectIn swapHalf "Valid: 2 of 4 (50.0%)" $swapTwo

# 4. The untouched starter runs, and nothing is answered yet.
set report [labCheck $labStarter]
expectIn starter "PASS Your script runs without an error" $report
expectIn starter "TODO Valid names, trimmed, layer in capitals, purpose in lower case: no OK or BAD line printed yet. The first one should be: OK METAL1_drawing" $report
expectIn starter "TODO The summary line: not printed yet. It should be: Valid: 5 of 8 (62.5%)" $report
expectIn starter "TODO Follows the inputs: lower case, and a name with no purpose" $report
expectIn starter "RESULT: FAIL 1/10" $report

# A program that passes: trim, map, match, first, range, toupper, tolower, lsearch and format.
set correct ""
foreach {name value} $inputs {
    append correct "set $name $value\n"
}
append correct {set valid 0
foreach raw $rawNames {
    set name [string map {- _} [string trim $raw]]
    if {![string match *_* $name]} {
        puts "BAD [string toupper $name]: no purpose"
    } else {
        set cut [string first _ $name]
        set layer [string toupper [string range $name 0 [expr {$cut - 1}]]]
        set purpose [string tolower [string range $name [expr {$cut + 1}] end]]
        set clean "${layer}_$purpose"
        if {[lsearch $knownLayers $layer] == -1} {
            puts "BAD $clean: unknown layer $layer"
        } elseif {[lsearch $knownPurposes $purpose] == -1} {
            puts "BAD $clean: unknown purpose $purpose"
        } else {
            puts "OK  $clean"
            incr valid
        }
    }
}
set total [llength $rawNames]
puts "Valid: $valid of $total ([format %.1f [expr {100.0 * $valid / $total}]]%)"
}

# 5. A correct program passes every test.
expectIn correct "RESULT: PASS 10/10" [labCheck $correct]

# 6. Each cleaning step that is left out fails its own test.
set report [labCheck [string map [list {[string trim $raw]} {$raw}] $correct]]
expectIn noTrim "FAIL Valid names, trimmed" $report
expectIn noTrim "Expected: OK POLY_drawing" $report
set report [labCheck [string map [list {set layer [string toupper } {set layer [string trim }] $correct]]
expectIn noUpper "FAIL Valid names, trimmed" $report
expectIn noUpper "Received: BAD poly_drawing: unknown layer poly" $report
expectIn noUpper "Put the layer in capitals before you look it up." $report
set report [labCheck [string map [list {[string map {- _} [string trim $raw]]} {[string trim $raw]}] $correct]]
expectIn noMap "FAIL A dash is replaced with _" $report
expectIn noMap "Received: BAD VIA1-DRAWING: no purpose" $report
expectIn noMap "PASS Valid names, trimmed" $report
set report [labCheck [string map [list {BAD [string toupper $name]: no purpose} {BAD $name: no purpose}] $correct]]
expectIn noPurposeAsTyped "PASS A name with no _ has no purpose" $report
expectIn noPurposeAsTyped "FAIL Follows the inputs: lower case, and a name with no purpose" $report
expectIn noPurposeAsTyped "It says: BAD metal2: no purpose" $report

# 7. The summary: integer division and no rounding get their own hints.
set report [labCheck [string map [list {100.0 * $valid} {100 * $valid}] $correct]]
expectIn intDivision "Received: Valid: 5 of 8 (62.0%)" $report
expectIn intDivision "integer division" $report
set report [labCheck [string map [list {[format %.1f [expr {100.0 * $valid / $total}]]} {[expr {100.0 * $valid / $total}]}] $correct]]
expectIn noFormat "PASS The summary line" $report
expectIn noFormat "FAIL Follows the inputs: lower case, and a name with no purpose" $report
expectIn noFormat "It says: Valid: 2 of 3 (66.66666666666667%)" $report

# 8. A typed list of purposes passes the main inputs but fails the second swap.
set report [labCheck [string map [list {lsearch $knownPurposes $purpose} {lsearch {drawing pin} $purpose}] $correct]]
expectIn typedPurposes "PASS Follows the inputs: lower case, and a name with no purpose" $report
expectIn typedPurposes "FAIL Follows the inputs: other purposes, and two underscores" $report
expectIn typedPurposes "It says: BAD TEXT_label: unknown purpose label" $report
expectIn typedPurposes "RESULT: FAIL 9/10" $report

# 9. $layer_ instead of ${layer}_ is explained.
set report [labCheck [string map [list {"${layer}_$purpose"} {"$layer_$purpose"}] $correct]]
expectIn underscoreName "can't read \"layer_\": no such variable" $report
expectIn underscoreName "Write \${layer}_" $report

# 10. Lines typed by hand pass the main checks but fail both swaps.
set typed ""
foreach {name value} $inputs {
    append typed "set $name $value\n"
}
foreach line [labTargets $inputs] {
    append typed "[list puts $line]\n"
}
set report [labCheck $typed]
expectIn typed "RESULT: FAIL 8/10" $report
expectIn typed "FAIL Follows the inputs: other purposes, and two underscores" $report

# 11. An endless while loop is stopped and named; an extra line is reported.
set report [labCheck "[string map [list {set valid 0} "set valid 0\nset i 0\nwhile \{\$i < 3\} \{\n    puts \"waiting\"\n\}"] $correct]"]
expectIn endless "FAIL Your script ran too long" $report
expectIn endless "RESULT: FAIL 0/10" $report
expectIn extra "Your script prints 10 lines, but the report has 9" [labCheck "$correct\nputs \"Done\"\n"]

# 12. A changed input line gives a NOTE that names the line, not a FAIL.
set report [labCheck [string map [list "set knownPurposes {drawing pin}" "set knownPurposes \[list drawing pin\]"] $correct]]
expectIn changed "NOTE Follows the inputs: lower case, and a name with no purpose: I could not find the line   set knownPurposes {drawing pin}" $report
expectNotIn changed "FAIL Follows" $report

# Terminal time limit (tests/test.tcl sets labTimeLimit): a loop with an EMPTY body runs no commands, so
# only the time limit can stop it. With the limit on, it is stopped and named like any endless loop.
set labTimeLimit 1
set report [labCheck "$labStarter\nwhile 1 {}\n"]
expectIn emptyLoop "FAIL Your script ran too long" $report
set labTimeLimit 0

puts "SELFTEST PASS $checks checks"
