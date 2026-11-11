# Recreates the Vivado project in ./vivado from the sources in this repo.
# Usage (from the repo root): vivado -mode batch -source create_project.tcl
set root [file normalize [file dirname [info script]]]
create_project pong [file join $root vivado] -part xc7a35ticsg324-1L -force
set_property target_language VHDL [current_project]
set_property simulator_language VHDL [current_project]

set src [glob -nocomplain [file join $root src *.vhd]]
if {[llength $src]} { add_files -fileset sources_1 $src }
set tb [glob -nocomplain [file join $root sim *.vhd]]
if {[llength $tb]} { add_files -fileset sim_1 $tb }
add_files -fileset constrs_1 [file join $root constraints arty_a7_35.xdc]

# VHDL-2008 for all VHDL files
foreach f [get_files -quiet -filter {FILE_TYPE == VHDL}] { set_property file_type {VHDL 2008} $f }
close_project
