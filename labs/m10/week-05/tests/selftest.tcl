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

# 1. The starter gives exactly the input lines that the checker looks for, braced lists included.
if {[dict keys $inputs] ne {rect shapes minWidth}} {
    error "selftest: inputs.txt should give rect, shapes and minWidth, not: [dict keys $inputs]"
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

# 3. The swaps test what they say: no narrow shape, then two (one by width, one by height).
expectIn swapNone "Too narrow: none" [join [labTargets [lindex $labSwaps 0 1]] \n]
expectIn swapTwo "Too narrow: shape 1\nToo narrow: shape 2" [join [labTargets [lindex $labSwaps 1 1]] \n]

# 4. The untouched starter runs, and nothing is answered yet.
set report [labCheck $labStarter]
expectIn starter "PASS Your script runs without an error" $report
expectIn starter "TODO Line 1 (the width): not printed yet. It should be: Width: 60 um" $report
expectIn starter "TODO The too-narrow lines: not printed yet. With these inputs: Too narrow: shape 3" $report
expectIn starter "TODO Follows the inputs: four shapes, none too narrow" $report
expectIn starter "RESULT: FAIL 1/11" $report

# A program that passes: lindex for one rectangle, then foreach, lappend and an if.
set correct ""
foreach {name value} $inputs {
    append correct "set $name $value\n"
}
append correct {set width [expr {[lindex $rect 2] - [lindex $rect 0]}]
set height [expr {[lindex $rect 3] - [lindex $rect 1]}]
puts "Width: $width um"
puts "Height: $height um"
puts "Area: [expr {$width * $height}] um2"
set count 0
set total 0
set narrow {}
foreach {x1 y1 x2 y2} $shapes {
    incr count
    set width [expr {$x2 - $x1}]
    set height [expr {$y2 - $y1}]
    set area [expr {$width * $height}]
    incr total $area
    puts "Shape $count: width $width, height $height, area $area"
    if {$width < $minWidth || $height < $minWidth} {
        lappend narrow $count
    }
}
puts "Shapes: $count"
puts "Total area: $total um2"
if {[llength $narrow] == 0} {
    puts "Too narrow: none"
}
foreach number $narrow {
    puts "Too narrow: shape $number"
}
}

# 5. A correct program passes every test.
expectIn correct "RESULT: PASS 11/11" [labCheck $correct]

# 6. Index from 1 instead of 0: the width line names the counting rule.
set report [labCheck [string map [list {[lindex $rect 2] - [lindex $rect 0]} {[lindex $rect 3] - [lindex $rect 1]}] $correct]]
expectIn index "FAIL Line 1 (the width)" $report
expectIn index "Received: Width: 30 um" $report
expectIn index "lindex counts from 0" $report

# 7. foreach with one variable: one line per number, and a hint that says so.
set oneVar {set rect {30 40 90 70}
set shapes {30 40 90 70 100 40 104 150 120 60 170 62}
set minWidth 3
set count 0
foreach number $shapes {
    incr count
    puts "Shape $count: width $number, height 0, area 0"
}
}
set report [labCheck $oneVar]
expectIn oneVar "FAIL The shape lines" $report
expectIn oneVar "One line per NUMBER" $report

# 8. Only the width tested: the narrow shape (narrow by its height) is missed.
set report [labCheck [string map [list {$width < $minWidth || $height < $minWidth} {$width < $minWidth}] $correct]]
expectIn widthOnly "FAIL The too-narrow lines" $report
expectIn widthOnly "Received: Too narrow: none" $report
expectIn widthOnly "join the two tests with ||" $report

# 9. llength as the count: 12 numbers, not 3 shapes.
set report [labCheck [string map [list {puts "Shapes: $count"} {puts "Shapes: [llength $shapes]"}] $correct]]
expectIn llength "FAIL The shape count" $report
expectIn llength "Received: Shapes: 12" $report
expectIn llength "llength gives 4 numbers per shape" $report

# 10. No "none" line: the main inputs pass, the first swap names the mistake.
set noNone [string map [list "if \{\[llength \$narrow\] == 0\} \{\n    puts \"Too narrow: none\"\n\}\n" ""] $correct]
set report [labCheck $noNone]
expectIn noNone "PASS The too-narrow lines" $report
expectIn noNone "FAIL Follows the inputs: four shapes, none too narrow" $report
expectIn noNone "Line 10 is missing. It should say: Too narrow: none" $report
expectIn noNone "RESULT: FAIL 10/11" $report

# 11. Lines typed by hand pass the main checks but fail both swaps.
set typed ""
foreach {name value} $inputs {
    append typed "set $name $value\n"
}
foreach line [labTargets $inputs] {
    append typed "[list puts $line]\n"
}
set report [labCheck $typed]
expectIn typed "RESULT: FAIL 9/11" $report
expectIn typed "FAIL Follows the inputs: two shapes, both too narrow" $report

# 12. An endless while loop is stopped and named; an error and an extra line are reported.
set report [labCheck "[string map [list {set count 0} "set count 0\nset i 0\nwhile \{\$i < 3\} \{\n    puts \"waiting\"\n\}"] $correct]"]
expectIn endless "FAIL Your script ran too long" $report
expectIn endless "RESULT: FAIL 0/11" $report
set report [labCheck [string map [list {lindex $rect 3} {lindex $rect}] $correct]]
expectIn error "FAIL Your script stops with an error" $report
expectIn extra "Your script prints 10 lines, but the report has 9" [labCheck "$correct\nputs \"Done\"\n"]

# 13. A changed input line gives a NOTE that names the line, not a FAIL.
set report [labCheck [string map [list "set shapes \{30 40" "set shapes \[list 30 40"] $correct]]
expectIn changed "NOTE Follows the inputs: four shapes, none too narrow: I could not find the line   set shapes {30 40 90 70" $report
expectNotIn changed "FAIL Follows" $report

puts "SELFTEST PASS $checks checks"
