#**************************************************************
# This .sdc file is created by Terasic Tool.
# Users are recommended to modify this file to match users logic.
#**************************************************************

#**************************************************************
# Create Clock
#**************************************************************
create_clock -period "50.000000 MHz" [get_ports CLOCK2_50]
create_clock -period "50.000000 MHz" [get_ports CLOCK3_50]
create_clock -period "50.000000 MHz" [get_ports CLOCK4_50]
create_clock -period "50.000000 MHz" [get_ports CLOCK_50]
create_clock -period "100.000000 MHz" [get_pins SoC_inst|hps_0|fpga_interfaces|clocks_resets|h2f_user1_clk]

# for enhancing USB BlasterII to be reliable, 25MHz
create_clock -name {altera_reserved_tck} -period 40 {altera_reserved_tck}
set_input_delay -clock altera_reserved_tck -clock_fall 3 [get_ports altera_reserved_tdi]
set_input_delay -clock altera_reserved_tck -clock_fall 3 [get_ports altera_reserved_tms]
set_output_delay -clock altera_reserved_tck 3 [get_ports altera_reserved_tdo]

#**************************************************************
# Create Generated Clock
#**************************************************************
derive_pll_clocks



#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************
derive_clock_uncertainty



#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************
#####set_clock_groups -asynchronous -group {CLOCK_50} -group {CLOCK2_50} -group {CLOCK3_50} -group {CLOCK4_50} -group {h2f_user0_clk} -group {h2f_user1_clk}



#**************************************************************
# Set False Path
#**************************************************************
#Button, LED, KEY Asynchronous I/O
set_false_path -from [get_ports {KEY*}] -to *
set_false_path -from [get_ports {SW*} ] -to *
set_false_path -from * -to [get_ports {LEDR*}]
set_false_path -from [get_keepers {sRegAddrSyn*}] -to [get_keepers {sRegContentInt*}]
set_false_path -from [get_keepers {*sFpgaReg*}] -to [get_keepers {sRegContentInt*}]
set_false_path -from [get_keepers {*sHpsReg*}] -to [get_keepers {sRegContentInt*}]
set_false_path -from [get_keepers {*data_out*}] -to [get_keepers {sRegAddrInt*}]



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



#**************************************************************
# Set Load
#**************************************************************
