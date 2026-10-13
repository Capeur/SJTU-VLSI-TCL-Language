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

set inputs [labFacts $labData(inputs.txt)]

# 1. The starter gives exactly the input lines that the checker looks for.
foreach {name value} $inputs {
    if {[labSwapLine $labStarter $name $value $value] eq ""} {
        error "selftest: starter.tcl lacks the line: set $name $value"
    }
    incr checks
}

# 2. data/expected.txt (shown on the lab page) is what the checker really computes.
set computed {}
foreach target [labTargets $inputs] {
    lappend computed [labTargetText $target]
}
if {[join $computed \n] ne [join [labLines $labData(expected.txt)] \n]} {
    error "selftest: data/expected.txt differs from the checker's own results:\n[join $computed \n]"
}
incr checks

# 3. The untouched starter runs, and nothing is answered yet.
set report [labCheck $labStarter]
expectIn starter "PASS Your script runs without an error" $report
expectIn starter "TODO Line 1 (area in um2): not printed yet. It should be: Chip area: 120000 um2" $report
expectIn starter "TODO Computes from the inputs" $report
expectIn starter "RESULT: FAIL 1/9" $report

# A program that passes, one step per line.
set correct ""
foreach {name value} $inputs {
    append correct "set $name $value\n"
}
append correct {set chipArea [expr {$chipWidth * $chipHeight}]
puts "Chip area: $chipArea um2"
puts "Chip area: [expr {$chipArea / 1000000.0}] mm2"
set perRow [expr {$waferSide / $chipWidth}]
puts "Chips per row: $perRow"
set rows [expr {$waferSide / $chipHeight}]
puts "Rows per wafer: $rows"
set perWafer [expr {$perRow * $rows}]
puts "Chips per wafer: $perWafer"
puts "Cost per chip: [expr {$waferCost / ($perWafer * 1.0)}] dollars"
}

# 4. A correct program passes every test.
expectIn correct "RESULT: PASS 9/9" [labCheck $correct]

# 5. The integer-division trap is named.
set report [labCheck [string map [list {($perWafer * 1.0)} {$perWafer}] $correct]]
expectIn intdiv "FAIL Line 6 (cost per chip)" $report
expectIn intdiv "Received: Cost per chip: 2 dollars" $report
expectIn intdiv "This looks like integer division" $report
expectIn intdiv "RESULT: FAIL 7/9" $report

# 6. A decimal where whole chips are counted is named too.
set report [labCheck [string map [list {$waferSide / $chipWidth} {$waferSide / ($chipWidth * 1.0)}] $correct]]
expectIn wholeChips "FAIL Line 3 (chips per row)" $report
expectIn wholeChips "Only whole chips count" $report

# 7. A typed number fails the swap test, which names the line.
set report [labCheck [string map [list {set rows [expr {$waferSide / $chipHeight}]} {set rows 33}] $correct]]
expectIn typed "FAIL Computes from the inputs" $report
expectIn typed "Line 4 should then say: Rows per wafer: 48" $report
expectIn typed "RESULT: FAIL 8/9" $report

# 8. A changed input line gives a NOTE that names the line, not a FAIL.
set report [labCheck [string map [list "set waferCost 1980" "set waferCost 1980.0"] $correct]]
expectIn changed "NOTE Computes from the inputs: I could not find the line   set waferCost 1980" $report

# 9. Decimals that differ only by rounding in the last digits still count as right.
#    (0.001 * 400 * 0.001 * 300 prints 0.12000000000000001.)
set report [labCheck [string map [list {[expr {$chipArea / 1000000.0}]} {[expr {0.001 * $chipWidth * 0.001 * $chipHeight}]}] $correct]]
expectIn rounding "Chip area: 0.12000000000000001 mm2" [lindex [labRun [string map [list {[expr {$chipArea / 1000000.0}]} {[expr {0.001 * $chipWidth * 0.001 * $chipHeight}]}] $correct]] 2]
expectIn rounding "PASS Line 2 (area in mm2)" $report

# 10. Wrong words around a number, an error and an extra line.
expectIn words "Check the words around the number" [labCheck [string map [list "Chips per row:" "Chips in a row:"] $correct]]
set report [labCheck [string map [list {puts "Rows} {Puts "Rows}] $correct]]
expectIn error "FAIL Your script stops with an error. Tcl says: invalid command name \"Puts\"" $report
expectIn error "PASS Line 3 (chips per row)" $report
expectIn extra "FAIL No extra lines" [labCheck "$correct\nputs \"Done\"\n"]

puts "SELFTEST PASS $checks checks"
