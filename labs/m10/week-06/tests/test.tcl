# Week 6 lab check (terminal version of the "Check my work" button).
# From the lab folder, run:          tclsh tests/test.tcl
# To check a different file, run:    tclsh tests/test.tcl myCells.tcl
# It prints one line per test and a last line "RESULT: PASS n/n" or "RESULT: FAIL k/n".

set labDir [file dirname [file dirname [file normalize [info script]]]]

proc readText {path} {
    set channel [open $path r]
    fconfigure $channel -encoding utf-8
    set text [read $channel]
    close $channel
    return $text
}

foreach path [lsort [glob -directory [file join $labDir data] *]] {
    set labData([file tail $path]) [readText $path]
}
set learnerFile [file join $labDir starter.tcl]
if {$argc > 0} {
    set learnerFile [lindex $argv 0]
}

# In the terminal, every run of your script also gets a time limit, in seconds (see checker.tcl).
set labTimeLimit 3
source [file join $labDir tests checker.tcl]
puts "Checking [file tail $learnerFile] ..."
puts "If the tests seem stuck for more than a few seconds, press Ctrl+C: your loop probably never ends."
flush stdout
set report [labCheck [readText $learnerFile]]
puts $report
exit [expr {[string match "*RESULT: PASS*" $report] ? 0 : 1}]
