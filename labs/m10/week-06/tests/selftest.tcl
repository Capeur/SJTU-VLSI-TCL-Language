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

# 1. The starter gives exactly the input lines that the checker looks for, nested braces included.
if {[dict keys $inputs] ne {cells topCount findCell}} {
    error "selftest: inputs.txt should give cells, topCount and findCell, not: [dict keys $inputs]"
}
foreach {name value} $inputs {
    if {[labSwapLine $labStarter $name $value $value] eq ""} {
        error "selftest: starter.tcl lacks the line: set $name $value"
    }
    incr checks
}

# 2. data/expected.txt (shown on the lab page) is what the checker really computes.
if {[join [labTargets $inputs] \n] ne [join [labLines $labData(expected.txt)] \n]} {
    error "selftest: data/expected.txt differs from the checker's own results:\n[join [labTargets $inputs] \n]"
}
incr checks

# 3. The swaps test what they say: a tie that keeps its input order and a missing cell, then the last rank.
set swapOne [join [labTargets [lindex $labSwaps 0 1]] \n]
expectIn swapTie "2. XOR2: 56 um2\n3. AOI21: 56 um2" $swapOne
expectIn swapMissing "NAND2: not found" $swapOne
expectIn swapLast "TIE: rank 6" [join [labTargets [lindex $labSwaps 1 1]] \n]

# 4. The untouched starter runs, and nothing is answered yet.
set report [labCheck $labStarter]
expectIn starter "PASS Your script runs without an error" $report
expectIn starter "TODO The cell count: not printed yet. It should be: Cells: 5" $report
expectIn starter "TODO The area of each cell: not printed yet. The first ranked line should be: 1. DFF: 140 um2" $report
expectIn starter "TODO Follows the inputs: a tie, and a cell that is not there" $report
expectIn starter "RESULT: FAIL 1/9" $report

# A program that passes: pairs, lsort -index, lmap, lrange, join and lsearch.
set correct ""
foreach {name value} $inputs {
    append correct "set $name $value\n"
}
append correct {puts "Cells: [llength $cells]"
set pairs {}
foreach cell $cells {
    set rect [lindex $cell 1]
    set area [expr {([lindex $rect 2] - [lindex $rect 0]) * ([lindex $rect 3] - [lindex $rect 1])}]
    lappend pairs [list [lindex $cell 0] $area]
}
set sorted [lsort -integer -decreasing -index 1 $pairs]
set rank 0
foreach pair $sorted {
    incr rank
    puts "$rank. [lindex $pair 0]: [lindex $pair 1] um2"
}
set names [lmap pair $sorted {lindex $pair 0}]
set top [lrange $names 0 [expr {$topCount - 1}]]
puts "Largest $topCount: [join $top ", "]"
set index [lsearch $names $findCell]
if {$index != -1} {
    puts "$findCell: rank [expr {$index + 1}]"
} else {
    puts "$findCell: not found"
}
}

# 5. A correct program passes every test.
expectIn correct "RESULT: PASS 9/9" [labCheck $correct]

# 6. Sorting mistakes get their own hints.
set report [labCheck [string map [list {-integer -decreasing -index 1} {-integer -index 1}] $correct]]
expectIn ascending "PASS The area of each cell" $report
expectIn ascending "FAIL The order of the cells" $report
expectIn ascending "Add -decreasing" $report
expectIn ascending "The rank comes from the names in sorted order, largest first. Fix the order of the cells first." $report
set report [labCheck [string map [list {-integer -decreasing -index 1} {-decreasing -index 1}] $correct]]
expectIn text "sorted as text" $report
set report [labCheck [string map [list {set sorted [lsort -integer -decreasing -index 1 $pairs]} {lsort -integer -decreasing -index 1 $pairs
set sorted $pairs}] $correct]]
expectIn unsorted "in the order of the input" $report

# 7. A wrong area (x2 * y2 only) fails the areas test, and the order test waits for it.
set report [labCheck [string map [list {([lindex $rect 2] - [lindex $rect 0]) * ([lindex $rect 3] - [lindex $rect 1])} {[lindex $rect 2] * [lindex $rect 3] + 1}] $correct]]
expectIn area "FAIL The area of each cell" $report
expectIn area "TODO The order of the cells: get the areas right first." $report

# 8. The rank without + 1 names the counting rule; the end of lrange without - 1 is caught too.
set report [labCheck [string map [list {rank [expr {$index + 1}]} {rank $index}] $correct]]
expectIn rank "Received: NOR2: rank 1" $report
expectIn rank "Ranks count from 1: add 1." $report
set report [labCheck [string map [list {[expr {$topCount - 1}]} {$topCount}] $correct]]
expectIn lrange "Received: Largest 3: DFF, NOR2, NAND2, BUF" $report
expectIn lrange "the end index is topCount - 1" $report

# 9. A test for "found" that forgets -1 passes the main inputs, but the first swap names the mistake.
set report [labCheck [string map [list {if {$index != -1} } {if {$index >= 0 || 1} }] $correct]]
expectIn noMinusOne "FAIL Follows the inputs: a tie, and a cell that is not there" $report
expectIn noMinusOne "It says: NAND2: rank 0" $report
expectIn noMinusOne "RESULT: FAIL 8/9" $report

# 10. Lines typed by hand pass the main checks but fail both swaps.
set typed ""
foreach {name value} $inputs {
    append typed "set $name $value\n"
}
foreach line [labTargets $inputs] {
    append typed "[list puts $line]\n"
}
set report [labCheck $typed]
expectIn typed "RESULT: FAIL 7/9" $report
expectIn typed "FAIL Follows the inputs: six cells, find the smallest" $report

# 11. An endless while loop is stopped and named; an error and an extra line are reported.
set report [labCheck "[string map [list {set rank 0} "set rank 0\nset i 0\nwhile \{\$i < 3\} \{\n    puts \"waiting\"\n\}"] $correct]"]
expectIn endless "FAIL Your script ran too long" $report
expectIn endless "RESULT: FAIL 0/9" $report
set report [labCheck [string map [list {lsort -integer -decreasing -index 1 $pairs} {lsort -integer -decreasing -index 1 $pairz}] $correct]]
expectIn error "FAIL Your script stops with an error. Tcl says: can't read \"pairz\": no such variable" $report
expectIn extra "Your script prints 9 lines, but the report has 8" [labCheck "$correct\nputs \"Done\"\n"]

# 12. A changed input line gives a NOTE that names the line, not a FAIL.
set report [labCheck [string map [list "set topCount 3" "set topCount \[expr \{1 + 2\}\]"] $correct]]
expectIn changed "NOTE Follows the inputs: a tie, and a cell that is not there: I could not find the line   set topCount 3" $report
expectNotIn changed "FAIL Follows" $report

# Terminal time limit (tests/test.tcl sets labTimeLimit): a loop with an EMPTY body runs no commands, so
# only the time limit can stop it. With the limit on, it is stopped and named like any endless loop.
set labTimeLimit 1
set report [labCheck "$labStarter\nwhile 1 {}\n"]
expectIn emptyLoop "FAIL Your script ran too long" $report
set labTimeLimit 0

puts "SELFTEST PASS $checks checks"
