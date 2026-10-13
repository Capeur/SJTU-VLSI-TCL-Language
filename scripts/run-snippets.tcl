# Runs every snippet in snippets/ with the Tcl that runs THIS script, and compares stdout exactly
# (trailing whitespace trimmed) with the .expected file (PRD §15.2).
#   <n>.only     "8.6" or "9.0": run only on that Tcl version (used by <VersionNote>)
#   <n>.drvlite  preload drvlite/drvlite.tcl (arrives in P5)
#   <n>.error    the script must FAIL, and its error output must contain this text (used by <Trap>)
# Usage: tclsh scripts/run-snippets.tcl ?snippetsDir? ?timeoutMs?
set here [file dirname [file normalize [info script]]]
set root [file dirname $here]
set snipDir [expr {$argc > 0 ? [lindex $argv 0] : [file join $root snippets]}]
set timeoutMs [expr {$argc > 1 ? [lindex $argv 1] : 10000}]
set tclsh [info nameofexecutable]
set version [info tclversion]

proc trimLines {text} {
    set lines {}
    foreach line [split [string map [list \r\n \n] $text] \n] {
        lappend lines [string trimright $line]
    }
    return [string trimright [join $lines \n]]
}

proc readFile {path} {
    set ch [open $path r]
    fconfigure $ch -encoding utf-8
    set data [read $ch]
    close $ch
    return $data
}

# Run a script file with a timeout; returns {status stdout}. status: ok | error | timeout
proc runWithTimeout {tclsh args timeoutMs} {
    set ch [open |[list $tclsh {*}$args 2>@1] r]
    fconfigure $ch -blocking 0 -encoding utf-8
    set pid [pid $ch]
    set ::done 0
    set ::buffer ""
    fileevent $ch readable {
        append ::buffer [read $::ch]
        if {[eof $::ch]} { set ::done 1 }
    }
    set ::ch $ch
    set timer [after $timeoutMs {set ::done timeout}]
    vwait ::done
    after cancel $timer
    if {$::done eq "timeout"} {
        catch {exec kill -9 $pid}
        catch {close $ch}
        return [list timeout $::buffer]
    }
    fconfigure $ch -blocking 1
    set status ok
    if {[catch {close $ch} err]} { set status error }
    return [list $status $::buffer]
}

set files [lsort [glob -nocomplain -directory $snipDir */*.tcl]]
set pass 0; set fail 0; set skipped 0
puts "Running [llength $files] snippet(s) on Tcl [info patchlevel]"
foreach file $files {
    set base [file rootname $file]
    set name "[file tail [file dirname $file]]/[file tail $file]"
    if {[file exists $base.only] && [string trim [readFile $base.only]] ne $version} {
        incr skipped
        continue
    }
    set args [list $file]
    if {[file exists $base.drvlite]} {
        set lib [file join $root drvlite drvlite.tcl]
        if {![file exists $lib]} { incr skipped; puts "SKIP $name (DRV-Lite not built yet)"; continue }
        set args [list [file join $here snippet-host.tcl] $lib $file]
    }
    lassign [runWithTimeout $tclsh $args $timeoutMs] status output
    if {$status eq "timeout"} {
        incr fail; puts "FAIL $name: timed out after ${timeoutMs} ms"; continue
    }
    if {[file exists $base.error]} {
        set want [string trim [readFile $base.error]]
        if {$status ne "error" || [string first $want $output] < 0} {
            incr fail
            puts "FAIL $name: expected an error containing [list $want]\n  status: $status\n  received: [list [trimLines $output]]"
            continue
        }
    } elseif {[file exists $base.expected]} {
        set want [trimLines [readFile $base.expected]]
        set got [trimLines $output]
        if {$status ne "ok" || $got ne $want} {
            incr fail
            puts "FAIL $name\n  expected: [list $want]\n  received: [list $got]"
            continue
        }
    } elseif {$status ne "ok"} {
        incr fail; puts "FAIL $name: script raised an error\n  [list [trimLines $output]]"; continue
    }
    incr pass
    puts "ok   $name"
}
puts "RESULT: [expr {$fail == 0 ? "PASS" : "FAIL"}] $pass passed, $fail failed, $skipped skipped (Tcl [info patchlevel])"
exit [expr {$fail > 0}]
