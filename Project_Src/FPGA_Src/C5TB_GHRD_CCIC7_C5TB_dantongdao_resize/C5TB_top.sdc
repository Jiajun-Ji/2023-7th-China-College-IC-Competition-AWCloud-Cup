## Generated SDC file "C5TB_top.sdc"

## Copyright (C) 2018  Intel Corporation. All rights reserved.
## Your use of Intel Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Intel Program License 
## Subscription Agreement, the Intel Quartus Prime License Agreement,
## the Intel FPGA IP License Agreement, or other applicable license
## agreement, including, without limitation, that your use is for
## the sole purpose of programming logic devices manufactured by
## Intel and sold by Intel or its authorized distributors.  Please
## refer to the applicable agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 18.1.0 Build 625 09/12/2018 SJ Standard Edition"

## DATE    "Tue Mar 21 13:10:00 2023"

##
## DEVICE  "5CSEBA6U23I7"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {FPGA_CLK1_50} -period 20.000 -waveform { 10.000 20.000 } [get_ports {FPGA_CLK1_50}]


#**************************************************************
# Create Generated Clock
#**************************************************************

create_generated_clock -name {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]} -source [get_pins {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|refclkin}] -duty_cycle 50/1 -multiply_by 12 -divide_by 2 -master_clock {FPGA_CLK1_50} [get_pins {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] 
create_generated_clock -name {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk} -source [get_pins {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|vco0ph[0]}] -duty_cycle 50/1 -multiply_by 1 -divide_by 6 -master_clock {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]} [get_pins {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] 
create_generated_clock -name {pll_inst0|pll_inst_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk} -source [get_pins {pll_inst0|pll_inst_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|vco0ph[0]}] -duty_cycle 50/1 -multiply_by 1 -divide_by 2 -master_clock {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]} [get_pins {pll_inst0|pll_inst_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] 
create_generated_clock -name {pll_inst0|pll_inst_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk} -source [get_pins {pll_inst0|pll_inst_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|vco0ph[0]}] -duty_cycle 50/1 -multiply_by 1 -divide_by 3 -master_clock {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]} [get_pins {pll_inst0|pll_inst_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk}] 


#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

set_clock_uncertainty -rise_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk}] -setup 0.080  
set_clock_uncertainty -rise_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk}] -hold 0.060  
set_clock_uncertainty -rise_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk}] -setup 0.080  
set_clock_uncertainty -rise_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk}] -hold 0.060  
set_clock_uncertainty -rise_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -setup 0.120  
set_clock_uncertainty -rise_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -hold 0.110  
set_clock_uncertainty -rise_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -setup 0.120  
set_clock_uncertainty -rise_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -hold 0.110  
set_clock_uncertainty -fall_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk}] -setup 0.080  
set_clock_uncertainty -fall_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk}] -hold 0.060  
set_clock_uncertainty -fall_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk}] -setup 0.080  
set_clock_uncertainty -fall_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk}] -hold 0.060  
set_clock_uncertainty -fall_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -setup 0.120  
set_clock_uncertainty -fall_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -hold 0.110  
set_clock_uncertainty -fall_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -setup 0.120  
set_clock_uncertainty -fall_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -hold 0.110  
set_clock_uncertainty -rise_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] -setup 0.080  
set_clock_uncertainty -rise_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] -hold 0.060  
set_clock_uncertainty -rise_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] -setup 0.080  
set_clock_uncertainty -rise_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] -hold 0.060  
set_clock_uncertainty -rise_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -setup 0.120  
set_clock_uncertainty -rise_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -hold 0.110  
set_clock_uncertainty -rise_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -setup 0.120  
set_clock_uncertainty -rise_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -hold 0.110  
set_clock_uncertainty -fall_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] -setup 0.080  
set_clock_uncertainty -fall_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] -hold 0.060  
set_clock_uncertainty -fall_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] -setup 0.080  
set_clock_uncertainty -fall_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] -hold 0.060  
set_clock_uncertainty -fall_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -setup 0.120  
set_clock_uncertainty -fall_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -hold 0.110  
set_clock_uncertainty -fall_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -setup 0.120  
set_clock_uncertainty -fall_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -hold 0.110  
set_clock_uncertainty -rise_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk}] -setup 0.120  
set_clock_uncertainty -rise_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk}] -hold 0.110  
set_clock_uncertainty -rise_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk}] -setup 0.120  
set_clock_uncertainty -rise_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk}] -hold 0.110  
set_clock_uncertainty -rise_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] -setup 0.120  
set_clock_uncertainty -rise_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] -hold 0.110  
set_clock_uncertainty -rise_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] -setup 0.120  
set_clock_uncertainty -rise_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] -hold 0.110  
set_clock_uncertainty -rise_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -setup 0.160  
set_clock_uncertainty -rise_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -hold 0.110  
set_clock_uncertainty -rise_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -setup 0.160  
set_clock_uncertainty -rise_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -hold 0.110  
set_clock_uncertainty -fall_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk}] -setup 0.120  
set_clock_uncertainty -fall_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk}] -hold 0.110  
set_clock_uncertainty -fall_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk}] -setup 0.120  
set_clock_uncertainty -fall_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk}] -hold 0.110  
set_clock_uncertainty -fall_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] -setup 0.120  
set_clock_uncertainty -fall_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] -hold 0.110  
set_clock_uncertainty -fall_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] -setup 0.120  
set_clock_uncertainty -fall_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] -hold 0.110  
set_clock_uncertainty -fall_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -setup 0.160  
set_clock_uncertainty -fall_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -rise_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -hold 0.110  
set_clock_uncertainty -fall_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -setup 0.160  
set_clock_uncertainty -fall_from [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -fall_to [get_clocks {pll_inst0|pll_inst_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -hold 0.110  


#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

