# *************************************************************
# * Author: Nicolas Wainstein, Technion - Israel Institute of Technology
# * 046237 - Introduction to VLSI 
# * Modified 08 Dec 2017
# * Changed driving cell and load
# * Adapted from Erik Brunvand, University of Utah
# * General synthesis script for Synopsys.
# *************************************************************
###############################################################
# Parameters
###############################################################

# Timing and loading information				
set Clk clk                  ;# The name of your clock 
set Period_ns 2              ;# desired clock period (in ns) (sets speed goal)
set InDelay_ns 0.5          ;# delay from clock to inputs valid
set OutDelay_ns 0.5          ;# delay from clock to output valid
set Fanout 1		     	 ;# Fanout

# Library and cells
set Library tsl18fs120_typ   ; # technology lib
set InputBuf bufbd4	     ; # FO4 Buffer 
set OutputBuf bufbd4	     ;

# Area and power constraints
set Area 2000		     ; # Max area

# Define compiler
set useUltra 0               ;# 1 for compile_ultra, 0 for simple compile

###############################################################
# Constraints
###############################################################               
# Define CLK

create_clock -period $Period_ns -waveform {0 1} $Clk

# Define driving gate
set_driving_cell  -library $Library -lib_cell $InputBuf [all_inputs]

# Define load
set std_gate_load [load_of [format "%s%s%s%s%s" $Library "/" $InputBuf "/" I]]
set normal_load  [expr (10 * $std_gate_load)]
set_load $normal_load [all_outputs]

# Input delay
set_input_delay $InDelay_ns -clock $Clk {reset memdata[7] memdata[6] memdata[5] memdata[4] memdata[3] memdata[2] memdata[1] memdata[0]}

# Output delay
set_output_delay $OutDelay_ns -clock $Clk [all_outputs]

# Try to fix hold time issues
#set_fix_hold $Clk

# Fanout
set_max_fanout $Fanout $current_design

# Area max
set_max_area $Area


###############################################################
# Compile and check design
###############################################################
if {  $useUltra == 1 } {
	compile_ultra
} else {
	compile -exact_map
}

check_design
report_constraint -all_violators

###############################################################
# Write report and database
###############################################################
set filebase mips
set filename [format "%s%s" $current_design ".v"]
redirect change_names \
{change_names -rules verilog -hierarchy -verbose }
write -format verilog -hierarchy -output $filename


# Timing constraints file generated from the   
# conditions above - used in the place and route program 
set filename [format "%s%s" $current_design ".sdc"]
write_sdc $filename

# Synopsys database file
set filename [format "%s%s" $current_design ".ddc"]
write -format ddc -hierarchy -o $filename

# Write timing and area reports
set filename [format "%s%s" $current_design ".rep"]
redirect $filename { report_timing -delay_type max}
redirect -append $filename { report_timing -delay_type min}
redirect -append $filename { report_area }
redirect -append $filename {report_constraint -all_violators}


# Write power report
set filename [format "%s%s" $current_design ".pow"]
redirect $filename { report_power }
