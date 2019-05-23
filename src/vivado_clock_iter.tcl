# ----------------------------------------------------------------------------
# --
# -- Title    : TCL Script for parse XDC Timing constraints
# -- Author   : Alexander Kapitanov
# -- E-mail   : kapitanov@insys.ru
# --
# ---------------------------------------------------------------------------- 
# --
# -- Description :
# -- 
# -- 0. Find TCL script and set PATH $ TOP variables
# -- 1. Open project, launch synthesis, report clock interaction 
# -- 2. Parse log file "timing_report"
# -- 3. Create list of Clock1 and Clock2
# -- 4. Check clocks properties
# -- 5. Create FALSE_PATH constraints
# -- 6. Reset synthesis and report 
# --
# -- Script can set FALSE_PATH to UNSAFE clock groups
# --
# ----------------------------------------------------------------------------
#
# MIT License
# 
# Copyright (c) 2016 Alexander Kapitanov
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in 
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# ---------------------------------------------------------------------------- 
# Useful Procedures and Functions are here
# ----------------------------------------------------------------------------

# findFiles can find files in subdirs and add it into a list
proc findFiles { basedir pattern } {

    # Fix the directory name, this ensures the directory name is in the
    # native format for the platform and contains a final directory seperator
    set basedir [string trimright [file join [file normalize $basedir] { }]]
    set fileList {}
    array set myArray {}
    
    # Look in the current directory for matching files, -type {f r}
    # means ony readable normal files are looked at, -nocomplain stops
    # an error being thrown if the returned list is empty

    foreach fileName [glob -nocomplain -type {f r} -path $basedir $pattern] {
        lappend fileList $fileName
    }   
    
    # Now look for any sub direcories in the current directory
    foreach dirName [glob -nocomplain -type {d  r} -path $basedir *] {
        # Recusively call the routine on the sub directory and append any
        # new files to the results
        # put $dirName
        set subDirList [findFiles $dirName $pattern]
        if { [llength $subDirList] > 0 } {
            foreach subDirFile $subDirList {
                
                #set SizeStr [string length $dirName]
                #set NewFile [string range $subDirFile $SizeStr+1 end]
                lappend fileList $subDirFile
            }
        }
    }
    return $fileList
}
# ----------------------------------------------------------------------------

# Stage 0: Find TCL script and set PATH $ TOP variables
# report_property -all [get_fileset sim_1]
set TclPath [file dirname [file normalize [info script]]]
set PrjDir [string range $TclPath 0 [string last / $TclPath]-1]

set FindTop [findFiles $PrjDir/vivado/ "*.xpr"]
puts $FindTop


# Stage 1: Open project, launch synthesis, report clock interaction 
# open_project $FindTop # IF VIVADO RUNS IN TCL-MODE
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1
open_run synth_1 -name synth_1
report_clock_interaction -delay_type min_max -significant_digits 3 -name timing_1 -file $PrjDir/vivado/timing_report.txt


# Stage 2: Parse log file "timing_report"
set TestRpt $PrjDir/vivado/timing_report.txt

set TestRptId [open $TestRpt r]
set TestTime [read $TestRptId]
set lines [split $TestTime "\n"]

set var1 ""
set var2 ""
foreach line $lines {   
    set values [regexp -all -inline {\S+} $line]
    if {[lindex $values end] == "(unsafe)"} {
        lappend var1 [list [lindex $values 0]]
        lappend var2 [list [lindex $values 1]]  
    }
}
close $TestRptId

# Stage 3: Create list of Clock1 and Clock2
set varx {}
for {set i 0} {$i < [llength $var1]} {incr i} {
    set x1 [lindex $var1 $i]
    set y1 [string trim $x1 "{}"]
    # set zz [string trim $yy "{}"] 
    lappend varx $y1
}
puts $varx

set vary {}
for {set i 0} {$i < [llength $var2]} {incr i} {
    set x2 [lindex $var2 $i]
    set y2 [string trim $x2 "{}"]
    lappend vary $y2
}
puts $vary


# Stage 4: Check clocks properties
set GroupClk1 {}
set ClassClk1 {}
set GroupClk1 [get_property SOURCE_PINS [get_clocks $varx]]
set ClassClk1 [get_property IS_GENERATED [get_clocks $varx]]
puts $GroupClk1

set GroupClk2 {}
set ClassClk2 {}
set GroupClk2 [get_property SOURCE_PINS [get_clocks $vary]]
set ClassClk2 [get_property IS_GENERATED [get_clocks $vary]]
puts $GroupClk2

if {$GroupClk1 > 0} {
    puts "FOUND UNSAFE CLOCK GROUPS!"
}
# Stage 5: Create FALSE_PATH constraints
for {set i 0} {$i < [llength $GroupClk1]} {incr i} {
    # puts "[lindex $GroupClk1 $i] and [lindex $GroupClk2 $i]"
    if {[lindex $ClassClk1 $i] == 0} {
        if {[lindex $ClassClk2 $i] == 0} {  
            set_false_path -from [get_clocks [lindex $GroupClk1 $i]] -to [get_clocks [lindex $GroupClk2 $i]]
        } else {
            set_false_path -from [get_clocks [lindex $GroupClk1 $i]] -to [get_clocks -of_objects [get_pins [lindex $GroupClk2 $i]]]
        }
    } else { 
        if {[lindex $ClassClk2 $i] == 0} {  
            set_false_path -from [get_clocks -of_objects [get_pins [lindex $GroupClk1 $i]]] -to [get_clocks [lindex $GroupClk2 $i]]
        } else {
            set_false_path -from [get_clocks -of_objects [get_pins [lindex $GroupClk1 $i]]] -to [get_clocks -of_objects [get_pins [lindex $GroupClk2 $i]]]
        }   
    }   
}

# Stage 6: Reset synthesis and report 
save_constraints
close_design
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1
open_run synth_1 -name synth_1
report_clock_interaction -delay_type min_max -significant_digits 3 -name timing_1 -file $PrjDir/vivado/timing_report.txt

puts "UNSAFE CLOCK GROUPS HAS BEEN IGNORED!"

# close_project # IF VIVADO RUNS IN TCL-MODE