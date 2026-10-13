# Self-test of checker.tcl, so the grader can be trusted (PRD §11).
# Run by CI on Tcl 8.6, 9.0 and in Wacl: scripts/extract-snippets.mjs adds labData(...),
# labStarter and checker.tcl in front of this file. Any failed check raises an error.

set checks 0
proc expectIn {label needle report} {
    global checks
    if {[string first $needle $report] < 0} {
        error "selftest '$label': expected to find [list $needle] in:\n$report"
    }
    incr checks
}

set puzzles [labPuzzles $labData(puzzles.txt)]
set total [llength $puzzles]
if {$total != 15} {
    error "selftest: expected 15 puzzles, found $total"
}
incr checks

# 1. Every real output can be written by a learner as  set pNN {output}  (balanced braces,
#    no trailing backslash), and every puzzle runs without an error.
set correct ""
foreach puzzle $puzzles {
    lassign $puzzle number revisit code
    set raw [labRun $code]
    set output [labNormalize $raw]
    if {[string trim $raw \n] ne $output} {
        error "selftest: puzzle $number prints spaces at the start or end of a line, which the checker ignores"
    }
    set probe [interp create -safe]
    set back [$probe eval "set p \{$output\}"]
    interp delete $probe
    if {$back ne $output} {
        error "selftest: puzzle $number output cannot be written inside braces: [list $output]"
    }
    if {$revisit eq ""} {
        error "selftest: puzzle $number has no 'revisit' hint"
    }
    append correct "set [format p%02d $number] \{$output\}\n"
}
incr checks

# 2. The untouched starter: nothing answered, no crash.
set report [labCheck $labStarter]
expectIn starter "TODO Puzzle 15: not answered yet." $report
expectIn starter "RESULT: FAIL 0/15" $report

# 3. All predictions right.
expectIn correct "RESULT: PASS 15/15" [labCheck $correct]

# 4. One wrong prediction: expected and received are both shown, with a lesson to revisit.
set oneWrong [string map [list "set p02 \{Lumen-1 is 400 um wide\}" "set p02 \{\$chipName is 400 um wide\}"] $correct]
set report [labCheck $oneWrong]
expectIn wrong "FAIL Puzzle 2" $report
expectIn wrong "| Lumen-1 is 400 um wide" $report
expectIn wrong "| \$chipName is 400 um wide" $report
expectIn wrong "Revisit: Lesson A" $report
expectIn wrong "RESULT: FAIL 14/15" $report

# 5. A multi-line prediction written with extra blank lines still counts as right.
set spaced [string map [list "set p01 \{" "set p01 \{\n"] $correct]
if {$spaced eq $correct} {
    error "selftest 'spaced': the test input was not built"
}
expectIn spaced "PASS Puzzle 1" [labCheck $spaced]

# 6. An indented prediction still counts as right.
set indented [string map [list "set p01 \{Block: CORE\nBlock: \$block\}" "set p01 \{\n    Block: CORE\n    Block: \$block\n\}"] $correct]
if {$indented eq $correct} {
    error "selftest 'indented': the test input was not built (string map did not match)"
}
set report [labCheck $indented]
expectIn indented "PASS Puzzle 1" $report
expectIn indented "RESULT: PASS 15/15" $report

# 7. A file Tcl cannot read gives a friendly message, not a crash.
set report [labCheck "set p01 \{oops\n"]
expectIn broken "Your file could not be read" $report
expectIn broken "RESULT: FAIL 0/15" $report

puts "SELFTEST PASS $checks checks"
