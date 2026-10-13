# Self-test of checker.tcl, so the grader can be trusted (PRD §11).
# Run by CI on Tcl 8.6, 9.0 and in Wacl: scripts/extract-snippets.mjs adds labData(...),
# labStarter and checker.tcl in front of this file. Any failed check raises an error.
#
# The passing program below is BUILT from the target output and the facts, because the checker
# needs one to prove that it can say PASS (decision log, P3: allowed for small weekly labs only;
# capstones and exams are tested against the private solutions repository instead).

set checks 0
proc expectIn {label needle report} {
    global checks
    if {[string first $needle $report] < 0} {
        error "selftest '$label': expected to find [list $needle] in:\n$report"
    }
    incr checks
}

set facts [labFacts $labData(facts.txt)]
set target [labLines $labData(passport.txt)]

# 1. The starter gives exactly the fact lines that the checker looks for.
foreach {name value} $facts {
    if {[labSwapLine $labStarter $name $value $value] eq ""} {
        error "selftest: starter.tcl lacks the line: set $name $value"
    }
    incr checks
}

# 2. The untouched starter runs, and nothing is answered yet.
set report [labCheck $labStarter]
expectIn starter "PASS Your script runs without an error" $report
expectIn starter "TODO Line 1 (title): not printed yet. It should be: CHIP PASSPORT" $report
expectIn starter "TODO Signed" $report
expectIn starter "RESULT: FAIL 1/9" $report

# Build programs from the facts: one puts per target line, with each fact replaced by its variable.
set toVariables {}
foreach {name value} $facts {
    lappend toVariables $value "\$$name"
}
proc program {facts target map signature} {
    set code "# Made by: $signature\n"
    foreach {name value} $facts {
        append code "set $name $value\n"
    }
    foreach line $target {
        append code "puts \"[string map $map $line]\"\n"
    }
    return $code
}
set correct [program $facts $target $toVariables Selftest]
set typed [program $facts $target {} Selftest]

# 3. A correct passport passes every test.
expectIn correct "RESULT: PASS 9/9" [labCheck $correct]

# 4. Typing the facts instead of using the variables fails only the swap test.
set report [labCheck $typed]
expectIn typed "FAIL Uses variables" $report
expectIn typed "Line 2 should then say: Name: Testchip" $report
expectIn typed "RESULT: FAIL 8/9" $report
set report [labCheck [string map [list "\$chipWidth x \$chipHeight" "400 x \$chipHeight"] $correct]]
expectIn typedSize "Line 3 should then say: Size: 511 x 411" $report

# 5. A changed fact line gives a NOTE that names the line, not a FAIL.
set report [labCheck [string map [list "set chipWidth 400" "set chipWidth 400 ;# um"] $correct]]
expectIn changed "NOTE Uses variables: I could not find the line   set chipWidth 400" $report
expectIn changed "RESULT: FAIL 8/9" $report

# 6. An error is reported with Tcl's own message; earlier lines still count.
set report [labCheck [string map [list "puts \"Size:" "Puts \"Size:"] $correct]]
expectIn error "FAIL Your script stops with an error. Tcl says: invalid command name \"Puts\"" $report
expectIn error "PASS Line 2 (Name)" $report
expectIn error "TODO Line 3 (Size)" $report

# 7. A wrong line shows what was expected and what was received.
set report [labCheck [string map [list "Blocks: CORE" "Blocks: core"] $correct]]
expectIn wrong "FAIL Line 4 (Blocks)" $report
expectIn wrong "Received: Blocks: core" $report
expectIn wrong "RESULT: FAIL 8/9" $report

# 8. Extra spaces are forgiven; an extra line is not.
expectIn spaces "PASS Line 2 (Name)" [labCheck [string map [list "puts \"Name: " "puts \"   Name:     "] $correct]]
set report [labCheck "$correct\nputs \"Thanks!\"\n"]
expectIn extra "FAIL No extra lines: your script prints 6 lines, but the passport has 5." $report

# 9. The signature must be filled in, and must stay a comment.
expectIn unsigned "TODO Signed" [labCheck [string map [list "Made by: Selftest" "Made by: ???"] $correct]]
set report [labCheck [string map [list "# Made by: Selftest" "Made by: Selftest"] $correct]]
expectIn uncommented "invalid command name \"Made\"" $report

puts "SELFTEST PASS $checks checks"
