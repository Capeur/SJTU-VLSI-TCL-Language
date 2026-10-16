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
# No check below depends on the order of array names: every wrong order used here is a fixed one
# (sorted, or reversed with lsort -decreasing), never whatever array names happens to give.

set inputs [labFacts $labData(inputs.txt)]

# 1. The starter gives exactly the input lines that the checker looks for.
if {[dict keys $inputs] ne {layerNumbers shapeLayers lookUp}} {
    error "selftest: inputs.txt should give layerNumbers, shapeLayers and lookUp, not: [dict keys $inputs]"
}
foreach {name value} $inputs {
    if {[labSwapLine $labStarter $name $value $value] eq ""} {
        error "selftest: starter.tcl lacks the line: set $name $value"
    }
    incr checks
}
# The swaps keep the same layer table.
foreach swap $labSwaps {
    if {[dict get [lindex $swap 1] layerNumbers] ne [dict get $inputs layerNumbers]} {
        error "selftest: swap '[lindex $swap 0]' changes the layer table"
    }
    incr checks
}

# 2. data/expected.txt (shown on the lab page) is what the checker really computes.
if {[join [labTargets $inputs] \n] ne [join [labLines $labData(expected.txt)] \n]} {
    error "selftest: data/expected.txt differs from the checker's own results:\n[join [labTargets $inputs] \n]"
}
incr checks

# 3. The swaps test what they say: two unknown layers sorted and named once, then no unknown and a failed look-up.
set swapOne [join [labTargets [lindex $labSwaps 0 1]] \n]
expectIn swapLookUp "TEXT: number 63, datatype 0, purpose drawing" $swapOne
expectIn swapSorted "Unknown: METAL9, VIA2" $swapOne
expectIn swapTotals "Shapes: 6, on unknown layers: 3" $swapOne
set swapTwo [join [labTargets [lindex $labSwaps 1 1]] \n]
expectIn swapMissing "METAL3: not in the table" $swapTwo
expectIn swapNone "Unknown: none" $swapTwo
expectIn swapZero "Shapes: 4, on unknown layers: 0" $swapTwo

# 4. The untouched starter runs, and nothing is answered yet.
set report [labCheck $labStarter]
expectIn starter "PASS Your script runs without an error" $report
expectIn starter "TODO The layer names: not printed yet. It should be: Layers: ACTIVE POLY CONTACT METAL1 VIA1 METAL2 TEXT" $report
expectIn starter "TODO The count for each layer: not printed yet. The first count line should be: ACTIVE 1.0: 2" $report
expectIn starter "TODO Follows the inputs: two unknown layers, each seen twice" $report
expectIn starter "RESULT: FAIL 1/10" $report

# A program that passes: dict keys, dict for, split, nested dict set / get / exists, arrays and lsort.
set correct ""
foreach {name value} $inputs {
    append correct "set $name $value\n"
}
append correct {puts "Layers: [dict keys $layerNumbers]"
set layers [dict create]
dict for {name gds} $layerNumbers {
    set parts [split $gds .]
    dict set layers $name number [lindex $parts 0]
    dict set layers $name datatype [lindex $parts 1]
    dict set layers $name purpose drawing
}
if {[dict exists $layers $lookUp]} {
    set number [dict get $layers $lookUp number]
    set datatype [dict get $layers $lookUp datatype]
    set purpose [dict get $layers $lookUp purpose]
    puts "$lookUp: number $number, datatype $datatype, purpose $purpose"
} else {
    puts "$lookUp: not in the table"
}
dict for {name gds} $layerNumbers {
    set count($name) 0
}
set unknownShapes 0
foreach layer $shapeLayers {
    if {[dict exists $layers $layer]} {
        incr count($layer)
    } else {
        set unknown($layer) 1
        incr unknownShapes
    }
}
dict for {name gds} $layerNumbers {
    puts "$name $gds: $count($name)"
}
set unknownNames [lsort [array names unknown]]
if {[llength $unknownNames] == 0} {
    puts "Unknown: none"
} else {
    puts "Unknown: [join $unknownNames {, }]"
}
puts "Shapes: [llength $shapeLayers], on unknown layers: $unknownShapes"
}

# 5. A correct program passes every test.
expectIn correct "RESULT: PASS 10/10" [labCheck $correct]

# 6. Counts in a fixed wrong order: sorted by name, or reversed. Both name the table order.
set loop "dict for {name gds} \$layerNumbers \{\n    puts \"\$name \$gds: \$count(\$name)\"\n\}"
set sorted "foreach name \[lsort \[array names count\]\] \{\n    puts \"\$name \[dict get \$layerNumbers \$name\]: \$count(\$name)\"\n\}"
set report [labCheck [string map [list $loop $sorted] $correct]]
expectIn sortedCounts "PASS The count for each layer" $report
expectIn sortedCounts "FAIL The counts in table order" $report
expectIn sortedCounts "These are sorted by name" $report
set reversed [string map [list {lsort [array names count]} {lsort -decreasing [array names count]}] $sorted]
set report [labCheck [string map [list $loop $reversed] $correct]]
expectIn reversedCounts "FAIL The counts in table order" $report
expectIn reversedCounts "array names gives the names in no promised order" $report

# 7. Layers with no shape left out; a wrong look-up record; the unknown layers unsorted (a fixed order).
set report [labCheck [string map [list "dict for \{name gds\} \$layerNumbers \{\n    set count(\$name) 0\n\}\n" "" "puts \"\$name \$gds: \$count(\$name)\"" "if \{\$count(\$name) > 0\} \{ puts \"\$name \$gds: \$count(\$name)\" \}" "\$count(\$name)\"" "\$count(\$name)\""] [string map [list "dict for \{name gds\} \$layerNumbers \{\n    set count(\$name) 0\n\}\n" "foreach layer \$shapeLayers \{ set count(\$layer) 0 \}\n"] $correct]]]
expectIn noZeros "FAIL The count for each layer" $report
expectIn noZeros "Every layer of the table needs a line, even with 0 shapes" $report
set report [labCheck [string map [list {set number [dict get $layers $lookUp number]} {set number [dict get $layerNumbers $lookUp]}] $correct]]
expectIn record "FAIL The record of METAL1" $report
expectIn record "Split the GDS number at the dot" $report
set report [labCheck [string map [list {set unknown($layer) 1} {lappend unknownList $layer} {[lsort [array names unknown]]} {[expr {[info exists unknownList] ? $unknownList : {}}]}] $correct]]
expectIn inputOrder "PASS The unknown layers" $report
expectIn inputOrder "FAIL Follows the inputs: two unknown layers, each seen twice" $report
expectIn inputOrder "It says: Unknown: VIA2, METAL9, VIA2" $report

# 8. A look-up without dict exists fails the second swap with an error.
set report [labCheck [string map [list {if {[dict exists $layers $lookUp]} } {if {1} }] $correct]]
expectIn noExists "FAIL Follows the inputs: no unknown layer, and a look-up that fails" $report
expectIn noExists "key \"METAL3\" not known in dictionary" $report
expectIn noExists "RESULT: FAIL 9/10" $report

# 9. $count alone is explained.
set report [labCheck "$correct\nputs \$count\n"]
expectIn wholeArray "can't read \"count\": variable is array" $report
expectIn wholeArray "Read one element" $report

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
expectIn typed "FAIL Follows the inputs: no unknown layer, and a look-up that fails" $report

# 11. An endless while loop is stopped and named; an extra line is reported.
set report [labCheck "[string map [list {set unknownShapes 0} "set unknownShapes 0\nset i 0\nwhile \{\$i < 3\} \{\n    puts \"waiting\"\n\}"] $correct]"]
expectIn endless "FAIL Your script ran too long" $report
expectIn endless "RESULT: FAIL 0/10" $report
expectIn extra "Your script prints 12 lines, but the report has 11" [labCheck "$correct\nputs \"Done\"\n"]

# 12. A changed input line gives a NOTE that names the line, not a FAIL.
set report [labCheck [string map [list "set lookUp METAL1" "set lookUp \"METAL1\""] $correct]]
expectIn changed "NOTE Follows the inputs: two unknown layers, each seen twice: I could not find the line   set lookUp METAL1" $report
expectNotIn changed "FAIL Follows" $report

# Terminal time limit (tests/test.tcl sets labTimeLimit): a loop with an EMPTY body runs no commands, so
# only the time limit can stop it. With the limit on, it is stopped and named like any endless loop.
set labTimeLimit 1
set report [labCheck "$labStarter\nwhile 1 {}\n"]
expectIn emptyLoop "FAIL Your script ran too long" $report
set labTimeLimit 0

puts "SELFTEST PASS $checks checks"
