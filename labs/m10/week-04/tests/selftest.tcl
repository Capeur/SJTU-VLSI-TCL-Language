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

# 3. The three swaps really take the three paths: each branch, and a loop that runs zero times.
set swapResults {}
foreach swap $labSwaps {
    lappend swapResults [lindex [labTargets [lindex $swap 1]] 1]
}
if {$swapResults ne {{Result: OK, AT THE MINIMUM} {Result: OK} {Result: TOO NARROW}}} {
    error "selftest: the swaps do not cover every branch: $swapResults"
}
expectIn noRoom "Tracks that fit: 0" [join [labTargets [lindex $labSwaps 2 1]] \n]
expectIn exactFit "Track 4: x = 10 um" [join [labTargets [lindex $labSwaps 1 1]] \n]

# 4. The untouched starter runs, and nothing is answered yet.
set report [labCheck $labStarter]
expectIn starter "PASS Your script runs without an error" $report
expectIn starter "TODO Line 1 (the wire): not printed yet. It should be: Wire CLK: 2 um wide, minimum 3 um" $report
expectIn starter "TODO The track lines" $report
expectIn starter "TODO Follows the inputs: a wire exactly at the minimum" $report
expectIn starter "RESULT: FAIL 1/9" $report

# A program that passes: an if/elseif/else, then a while loop.
set correct ""
foreach {name value} $inputs {
    append correct "set $name $value\n"
}
append correct {puts "Wire $wireName: $wireWidth um wide, minimum $minWidth um"
if {$wireWidth < $minWidth} {
    puts "Result: TOO NARROW"
} elseif {$wireWidth == $minWidth} {
    puts "Result: OK, AT THE MINIMUM"
} else {
    puts "Result: OK"
}
set x $minSpace
set tracks 0
while {$x + $minWidth + $minSpace <= $channelWidth} {
    incr tracks
    puts "Track $tracks: x = $x um"
    incr x [expr {$minWidth + $minSpace}]
}
puts "Tracks that fit: $tracks"
}

# 5. A correct program passes every test.
expectIn correct "RESULT: PASS 9/9" [labCheck $correct]

# 6. No elseif for "at the minimum": the main inputs pass, the first swap names the mistake.
set noMinimum [string map [list "\} elseif \{\$wireWidth == \$minWidth\} \{\n    puts \"Result: OK, AT THE MINIMUM\"\n" ""] $correct]
set report [labCheck $noMinimum]
expectIn noMinimum "FAIL Follows the inputs: a wire exactly at the minimum" $report
expectIn noMinimum "Line 2 should say: Result: OK, AT THE MINIMUM" $report
expectIn noMinimum "It says: Result: OK" $report
expectIn noMinimum "with == in an elseif" $report
expectIn noMinimum "RESULT: FAIL 8/9" $report

# 7. < instead of <= in the loop: the exact-fit swap names it.
set report [labCheck [string map [list {<= $channelWidth} {< $channelWidth}] $correct]]
expectIn lessThan "PASS The track lines" $report
expectIn lessThan "FAIL Follows the inputs: a channel that fits exactly" $report
expectIn lessThan "Line 6 should say: Track 4: x = 10 um" $report
expectIn lessThan "Use <= in your loop condition" $report

# 8. Track lines typed by hand: the swaps fail.
set typed ""
foreach {name value} $inputs {
    append typed "set $name $value\n"
}
foreach line [labTargets $inputs] {
    append typed "[list puts $line]\n"
}
set report [labCheck $typed]
expectIn typed "RESULT: FAIL 6/9" $report
expectIn typed "FAIL Follows the inputs: a channel with no room" $report

# 9. A loop that never ends (incr x forgotten) is stopped and named, not left to hang.
set report [labCheck [string map [list "    incr x \[expr \{\$minWidth + \$minSpace\}\]\n" ""] $correct]]
expectIn endless "FAIL Your script ran too long, or printed far too much, so the checker stopped it." $report
expectIn endless "RESULT: FAIL 0/9" $report
# The same without any output: only the command limit can stop it.
set silent [string map [list "    puts \"Track \$tracks: x = \$x um\"\n" "" "    incr x \[expr \{\$minWidth + \$minSpace\}\]\n" ""] $correct]
if {[string first "puts \"Track \$tracks" $silent] >= 0} {
    error "selftest: the silent endless loop still prints"
}
expectIn silent "FAIL Your script ran too long" [labCheck $silent]

# 10. Track mistakes get a hint: starting at x = 0, and one track too many.
set report [labCheck [string map [list {set x $minSpace} {set x 0}] $correct]]
expectIn fromZero "FAIL The track lines" $report
expectIn fromZero "at x = minSpace, not at x = 0" $report
set report [labCheck [string map [list {$x + $minWidth + $minSpace <= $channelWidth} {$x + $minWidth <= $channelWidth}] $correct]]
expectIn tooMany "One track too many" $report
expectIn tooMany "FAIL The count line" $report

# 11. The wrong branch is named; an error and an extra line are reported.
set report [labCheck [string map [list {$wireWidth < $minWidth} {$wireWidth > $minWidth}] $correct]]
expectIn branch "Your if chose the wrong branch" $report
set report [labCheck [string map [list "\} else \{\n    puts \"Result: OK\"" "\}\nelse \{\n    puts \"Result: OK\""] $correct]]
expectIn elseLine "FAIL Your script stops with an error. Tcl says: invalid command name \"else\"" $report
expectIn extra "FAIL No extra lines" [labCheck "$correct\nputs \"Done\"\n"]

# 12. A changed input line gives a NOTE that names the line, not a FAIL.
set report [labCheck [string map [list "set minSpace 2" "set minSpace 2.0"] $correct]]
expectIn changed "NOTE Follows the inputs: a wire exactly at the minimum: I could not find the line   set minSpace 2" $report
expectNotIn changed "FAIL Follows" $report

puts "SELFTEST PASS $checks checks"
