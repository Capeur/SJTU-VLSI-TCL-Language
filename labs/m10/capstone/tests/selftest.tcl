# Self-test of the capstone grader (PRD §11). Run by CI on Tcl 8.6, 9.0 and in Wacl: scripts/extract-snippets.mjs
# adds labData(...), labStarter and checker.tcl in front of this file. Any failed check raises an error.
#
# Unlike the weekly labs, this self-test NEVER builds a passing program (decision log, P3: capstones and exams
# are tested against the private solutions repository, Capeur/SJTU-VLSI-TCL-Language-solutions, by the CI job
# "solutions"). Here we only test what can be tested without a solution: the data files, the hash, the
# starter, a report typed by hand, wrong procs, endless loops and a missing input line.

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
proc expectEqual {label got want} {
    global checks
    if {$got ne $want} {
        error "selftest '$label': got [list $got], expected [list $want]"
    }
    incr checks
}

set inputs [labFacts $labData(inputs.txt)]

# 1. The starter gives exactly the input lines that the checker looks for.
expectEqual inputNames [dict keys $inputs] {chipName chipWidth chipHeight blocks}
foreach {name value} $inputs {
    if {[labSwapLine $labStarter $name $value $value] eq ""} {
        error "selftest: starter.tcl lacks the line: set $name $value"
    }
    incr checks
}
# Every hidden floorplan sets the same four inputs.
foreach hidden $labHidden {
    expectEqual hiddenInputs [dict keys [lindex $hidden 1]] {chipName chipWidth chipHeight blocks}
}

# 2. FNV-1a gives the published test values (so 8.6, 9.0 and Wacl hash alike).
expectEqual fnvEmpty [labFnv ""] 811c9dc5
expectEqual fnvA [labFnv a] e40c292c
expectEqual fnvFoobar [labFnv foobar] bf9cf968

# 3. The data files have the right shape: the visible report starts and ends as specified, and hidden.txt
#    has one report per hidden floorplan, each from the first line to Problems.
set targets [labLines $labData(expected.txt)]
expectEqual visibleFirst [labKind [lindex $targets 0]] Mini
expectEqual visibleLast [labKind [lindex $targets end]] Problems:
expectIn visibleTotal "Total 83480 um2 (69.6% of the chip)" [join $targets \n]
expectIn visibleSkipped "Skipped: 3" [join $targets \n]
expectIn visibleProblems "Problems: 4" [join $targets \n]
set test 0
foreach hidden $labHidden {
    incr test
    set rows [labHiddenHashes $labData(hidden.txt) $test]
    if {[llength $rows] < 4} {
        error "selftest: hidden.txt has no report for hidden floorplan $test"
    }
    expectEqual "hidden${test}First" [lindex $rows 0 0] Mini
    expectEqual "hidden${test}Last" [lindex $rows end 0] Problems:
}
# The kinds of the visible report lines.
expectEqual kindArea [labKind "CORE 32000 um2"] area
expectEqual kindSkippedLine [labKind "Skipped FUSE: needs 5 values, got 4"] Skipped
expectEqual kindSkippedCount [labKind "Skipped: 3"] Skipped:

# 4. The untouched starter runs; nothing is answered yet, and every proc is missing.
set report [labCheck $labStarter]
expectIn starter "PASS Your script runs without an error" $report
expectIn starter "There is no proc called rectArea" $report
expectIn starter "Missing line: Mini Floorplan Checker: Lumen-1, 400 x 300 um" $report
expectIn starter "RESULT: FAIL 1/17" $report
expectIn starter "SCORE: 0/75 automatic" $report

# 5. The visible report typed by hand passes the visible report tests only: no procs, and every hidden
#    floorplan fails, because typed lines do not follow the inputs.
set typed ""
foreach {name value} $inputs {
    append typed "set $name $value\n"
}
foreach line $targets {
    append typed "[list puts $line]\n"
}
set report [labCheck $typed]
expectIn typed "PASS Report: the first line, the area lines and the Total (4/4)" $report
expectIn typed "PASS Report: the Outside lines, the Conflict lines and Problems (6/6)" $report
expectIn typed "PASS Report: one Skipped line per bad block, the Skipped count, and the report goes on (10/10)" $report
expectIn typed "FAIL Hidden floorplan 1" $report
expectIn typed "FAIL Hidden floorplan 3" $report
expectIn typed "FAIL The script validates the blocks with try (0/5)" $report
expectIn typed "SCORE: 20/75 automatic (correctness 10/50, error handling 10/25)" $report

# 6. Wrong procs: each failing group names its own mistake; the hidden tests hash the learner's lines.
set wrong "$typed
proc rectArea {rect} {return 50}
proc rectOverlaps {a b} {return 0}
proc rectInside {rect boundary} {return 1}
proc checkBlock {block} {error \"bad block\"}
"
set report [labCheck $wrong]
expectIn wrongArea "FAIL Proc rectArea (0/3)" $report
expectIn wrongArea "rectArea {20 20 220 180} returns 50, but should return 32000." $report
expectIn wrongOverlaps "FAIL Proc rectOverlaps: touching counts (0/4)" $report
expectIn wrongOverlaps "With <, touching would be fine." $report
expectIn wrongInside "PASS Proc rectInside: touching the boundary is allowed (3/3)" $report
expectIn wrongInside "FAIL Proc rectInside: sticking out on any side (0/3)" $report
expectIn wrongCheck "checkBlock {CORE 20 20 200 160} stops with an error. Tcl says: bad block" $report
expectIn wrongCheck "checkBlock {B x0 1 2 3} raises \"bad block\", but the message should be exactly \"x is not a number: x0\"." $report
expectIn wrongBlockRect "There is no proc called blockRect" $report
set report [labCheck "$typed\nproc rectArea {rect} {puts 50}\n"]
expectIn putsNotReturn "Did you use puts instead of return?" $report

# 7. A hidden floorplan failure shows the learner's line and the kind of line expected, never the expected text.
set report [labCheck $typed]
expectIn hiddenKind "It should be a line of the kind \"Skipped:\"; yours is: Skipped FUSE: needs 5 values, got 4" $report
expectNotIn hiddenSecret "Total 80000" $report

# 8. A script that stops with an error, an endless loop, and a changed input line.
set report [labCheck "$typed\nerror \"stopped on purpose\"\n"]
expectIn error "FAIL Your script stops with an error. Tcl says: stopped on purpose" $report
set report [labCheck "$typed\nset i 0\nwhile \{\$i < 3\} \{\n    puts waiting\n\}\n"]
expectIn endless "FAIL Your script ran too long" $report
expectIn endless "RESULT: FAIL 0/17" $report
set report [labCheck [string map [list "set chipWidth 400" "set chipWidth \[expr \{200 * 2\}\]"] $typed]]
expectIn changed "NOTE Hidden floorplan 1: a clean floorplan: Lumen-1 as it is (0/6): I could not find the line   set chipWidth 400" $report

# 9. try in a comment does not count; try in the code does.
set report [labCheck "$typed\n# try \{ this \} in a comment\n"]
expectIn tryComment "FAIL The script validates the blocks with try (0/5)" $report
set report [labCheck "$typed\ntry \{\n    set x 1\n\} on error \{message\} \{\n    puts \$message\n\}\n"]
expectIn tryCode "PASS The script validates the blocks with try (5/5)" $report

# Terminal time limit (tests/test.tcl sets labTimeLimit): a loop with an EMPTY body runs no commands, so
# only the time limit can stop it.
set labTimeLimit 1
set report [labCheck "$labStarter\nwhile 1 {}\n"]
expectIn emptyLoop "FAIL Your script ran too long" $report
set labTimeLimit 0

puts "SELFTEST PASS $checks checks"
