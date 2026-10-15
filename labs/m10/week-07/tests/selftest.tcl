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

# 1. The starter gives exactly the input line that the checker looks for, nested braces included.
if {[dict keys $inputs] ne {plan}} {
    error "selftest: inputs.txt should give plan, not: [dict keys $inputs]"
}
if {[labSwapLine $labStarter plan [dict get $inputs plan] [dict get $inputs plan]] eq ""} {
    error "selftest: starter.tcl lacks the line: set plan [dict get $inputs plan]"
}
incr checks

# 2. data/expected.txt (shown on the lab page) is what the checker really computes.
if {[join [labTargets $inputs] \n] ne [join [labLines $labData(expected.txt)] \n]} {
    error "selftest: data/expected.txt differs from the checker's own results:\n[join [labTargets $inputs] \n]"
}
incr checks

# 3. The checker's own rule is the course's touching rule, on every kind of case the lab promises:
#    edge, corner, a 1 um gap, inside, identical, and the same answer in both orders.
foreach {a b want} {
    {0 0 30 20} {30 0 60 20} 1
    {0 0 30 20} {30 20 50 40} 1
    {0 0 30 20} {31 0 60 20} 0
    {0 0 30 20} {0 21 30 40} 0
    {0 0 100 100} {20 20 40 40} 1
    {10 10 50 30} {10 10 50 30} 1
} {
    if {[labOverlaps $a $b] != $want || [labOverlaps $b $a] != $want} {
        error "selftest: labOverlaps {$a} {$b} should be $want in both orders"
    }
    incr checks
}
# The main inputs have an edge touch, a corner touch, two 1 um gaps and a real overlap.
expectIn mainEdge "Conflict: ALU and REGS" [join [labTargets $inputs] \n]
expectIn mainCorner "Conflict: REGS and CACHE" [join [labTargets $inputs] \n]
expectNotIn mainGap "Conflict: REGS and CTRL" [join [labTargets $inputs] \n]
expectNotIn mainGapY "Conflict: CTRL and CACHE" [join [labTargets $inputs] \n]
# The swaps test what they say: no conflict at all, then inside and identical.
expectIn swapNone "Conflicts: 0" [join [labTargets [lindex $labSwaps 0 1]] \n]
expectIn swapInside "Conflict: BIG and SMALL\nConflict: BIG and COPY\nConflict: SMALL and COPY\nConflicts: 3" [join [labTargets [lindex $labSwaps 1 1]] \n]

# 4. The untouched starter runs, and nothing is answered yet.
set report [labCheck $labStarter]
expectIn starter "PASS Your script runs without an error" $report
expectIn starter "TODO rectArea: not defined yet." $report
expectIn starter "TODO rectOverlaps (7 tests): not defined yet." $report
expectIn starter "TODO The area lines: not printed yet. The first should be: ALU: 3000 um2" $report
expectIn starter "TODO Follows the input: blocks 1 um apart, no conflict" $report
expectIn starter "RESULT: FAIL 1/15" $report

# A program that passes: two procs, a foreach, and the pair loop.
set correct "set plan [dict get $inputs plan]\n"
append correct {proc rectArea {rect} {
    set width [expr {[lindex $rect 2] - [lindex $rect 0]}]
    set height [expr {[lindex $rect 3] - [lindex $rect 1]}]
    return [expr {$width * $height}]
}
proc rectOverlaps {a b} {
    set xClash [expr {[lindex $a 0] <= [lindex $b 2] && [lindex $b 0] <= [lindex $a 2]}]
    set yClash [expr {[lindex $a 1] <= [lindex $b 3] && [lindex $b 1] <= [lindex $a 3]}]
    return [expr {$xClash && $yClash}]
}
foreach block $plan {
    puts "[lindex $block 0]: [rectArea [lindex $block 1]] um2"
}
set conflicts 0
set count [llength $plan]
for {set i 0} {$i < $count} {incr i} {
    for {set j [expr {$i + 1}]} {$j < $count} {incr j} {
        if {[rectOverlaps [lindex $plan $i 1] [lindex $plan $j 1]]} {
            puts "Conflict: [lindex $plan $i 0] and [lindex $plan $j 0]"
            incr conflicts
        }
    }
}
puts "Conflicts: $conflicts"
}

# 5. A correct program passes every test.
expectIn correct "RESULT: PASS 15/15" [labCheck $correct]

# 6. < instead of <=: the edge and corner groups fail and name the touching rule; the gaps still pass.
set strict [string map [list {<=} {<}] $correct]
set report [labCheck $strict]
expectIn strict "FAIL rectOverlaps: rectangles touching along an edge" $report
expectIn strict "FAIL rectOverlaps: rectangles touching at a corner" $report
expectIn strict "Touching counts in this course: use <=, not <." $report
expectIn strict "PASS rectOverlaps: a 1 um gap" $report
expectIn strict "PASS rectOverlaps gives the same answer in both orders" $report
expectIn strict "FAIL The conflict lines" $report
expectIn strict "Your count matches your own Conflict lines" $report

# 7. Only the x axis tested: "one above the other" is wrongly a clash, and so is a 1 um gap on y.
set report [labCheck [string map [list {return [expr {$xClash && $yClash}]} {return $xClash}] $correct]]
expectIn xOnly "FAIL rectOverlaps: overlapping and separate rectangles" $report
expectIn xOnly "one above the other, with a gap: only their x spans overlap:" $report
expectIn xOnly "join the two tests with &&" $report
expectIn xOnly "FAIL rectOverlaps: a 1 um gap" $report

# 8. "Is a corner of A inside B?": misses the cross and the big rectangle, and is not symmetric.
set corner [string map [list {set xClash [expr {[lindex $a 0] <= [lindex $b 2] && [lindex $b 0] <= [lindex $a 2]}]} {set xClash [expr {[lindex $b 0] <= [lindex $a 0] && [lindex $a 0] <= [lindex $b 2]}]} {set yClash [expr {[lindex $a 1] <= [lindex $b 3] && [lindex $b 1] <= [lindex $a 3]}]} {set yClash [expr {[lindex $b 1] <= [lindex $a 1] && [lindex $a 1] <= [lindex $b 3]}]}] $correct]
set report [labCheck $corner]
expectIn corner "FAIL rectOverlaps: one rectangle inside another" $report
expectIn corner "not the corners" $report
expectIn corner "FAIL rectOverlaps gives the same answer in both orders" $report
expectIn corner "two rectangles that overlap: rectOverlaps {0 0 40 30} {20 10 60 50} gives 0, but rectOverlaps {20 10 60 50} {0 0 40 30} gives 1." $report
# Touching fails here too, but not because of <: the hint states the rule instead of blaming <.
expectNotIn corner "use <=, not <" $report
expectIn corner "The rule: x1a <= x2b && x1b <= x2a && y1a <= y2b && y1b <= y2a" $report
expectIn corner "FAIL The conflict lines" $report

# 9. true/false instead of 1/0, and puts instead of return, get their own messages.
set report [labCheck [string map [list {return [expr {$xClash && $yClash}]} {if {$xClash && $yClash} {
        return true
    }
    return false}] $correct]]
expectIn trueFalse "returns true. Return 1 or 0" $report
set report [labCheck [string map [list {return [expr {$width * $height}]} {puts [expr {$width * $height}]}] $correct]]
expectIn putsArea "FAIL rectArea" $report
expectIn putsArea "returns an empty value, but should return 600. Did you use puts instead of return?" $report

# 10. j starting at 0: a block clashes with itself, and the hint names the start of the inner loop.
set report [labCheck [string map [list {set j [expr {$i + 1}]} {set j 0}] $correct]]
expectIn jZero "Received: Conflict: ALU and ALU" $report
expectIn jZero "The inner loop must start AFTER" $report

# 11. A rectOverlaps with the wrong arguments stops with an error, which is reported per call.
set report [labCheck [string map [list {proc rectOverlaps {a b} } {proc rectOverlaps {ax1 ay1 ax2 ay2 bx1 by1 bx2 by2} }] $correct]]
expectIn wrongArgs "stops with an error. Tcl says: wrong # args: should be \"rectOverlaps ax1 ay1 ax2 ay2 bx1 by1 bx2 by2\"" $report

# 12. An endless loop in the main script is stopped and named; one inside a proc is stopped per call.
set report [labCheck [string map [list {incr j} {incr i}] $correct]]
expectIn endless "FAIL Your script ran too long" $report
expectIn endless "RESULT: FAIL 0/15" $report
# (Only the procs, no report: the main script ends, and the endless call is stopped on its own.)
set procsOnly [string range $correct 0 [string first "foreach block" $correct]-1]
set report [labCheck [string map [list "proc rectArea \{rect\} \{\n" "proc rectArea \{rect\} \{\n    set n 0\n    while \{\$n < 1\} \{\n        set width 1\n    \}\n"] $procsOnly]]
expectIn endlessProc "rectArea {0 0 30 20} never ends. Look for a loop inside the proc." $report
expectIn endlessProc "PASS rectOverlaps gives the same answer in both orders" $report

# 13. Lines typed by hand pass the report tests but fail both swaps.
set typed "set plan [dict get $inputs plan]\n"
append typed [string range $correct [string first "proc rectArea" $correct] [string first "foreach block" $correct]-1]
foreach line [labTargets $inputs] {
    append typed "[list puts $line]\n"
}
set report [labCheck $typed]
expectIn typed "RESULT: FAIL 13/15" $report
expectIn typed "FAIL Follows the input: a block inside another, and two identical blocks" $report

# 14. An extra line and a changed input line are reported.
expectIn extra "Your script prints 10 lines, but the report has 9" [labCheck "$correct\nputs \"Done\"\n"]
set report [labCheck [string map [list "set plan \{\{ALU" "set plan \[list \{ALU"] $correct]]
expectIn changed "NOTE Follows the input: blocks 1 um apart, no conflict: I could not find the line   set plan {{ALU" $report
expectNotIn changed "FAIL Follows" $report

# Terminal time limit (tests/test.tcl sets labTimeLimit): a loop with an EMPTY body runs no commands, so
# only the time limit can stop it. With the limit on, it is stopped and named like any endless loop.
set labTimeLimit 1
set report [labCheck "$labStarter\nwhile 1 {}\n"]
expectIn emptyLoop "FAIL Your script ran too long" $report
set report [labCheck "[string map [list "proc rectArea \{rect\} \{\n" "proc rectArea \{rect\} \{\n    while 1 \{\}\n"] $procsOnly]"]
expectIn emptyLoopProc "rectArea {0 0 30 20} never ends. Look for a loop inside the proc." $report
expectIn emptyLoopProc "rectArea {10 10 50 30} was not run: an earlier call of rectArea never ended." $report
expectIn emptyLoopProc "PASS rectOverlaps gives the same answer in both orders" $report
set labTimeLimit 0

puts "SELFTEST PASS $checks checks"
