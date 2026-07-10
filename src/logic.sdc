
create_clock -period 20.000 -name clock -waveform {0.000 10.000} [get_ports {clock}]
create_clock -period 33.333 -name if_clock -waveform {0.000 16.667} [get_ports {ifclk_i}]
create_clock -period 3.333 -name clock_ddr -waveform {0.000 1.667} [get_nets {ddr3_clock}]
create_clock -period 13.332 -name clock_ui -waveform {0.000 6.667} [get_pins {u_axi4_ddr_unit/u_ddr3_control/gw3_top/u_GW_DDR3_PHY_MC/u_ddr_phy_top/fclkdiv/CLKOUT}]
create_clock -period 10.000 -name clock_sample -waveform {0.000 5.000} [get_nets {sample_clock}]

set_false_path -from [get_clocks {clock}] -to [get_clocks {clock_ddr}]
set_false_path -from [get_clocks {clock}] -to [get_clocks {clock_ui}] 
set_false_path -from [get_clocks {clock}] -to [get_clocks {if_clock}] 
set_false_path -from [get_clocks {clock}] -to [get_clocks {clock_sample}] 

set_false_path -from [get_clocks {clock_sample}] -to [get_clocks {clock_ddr}]
set_false_path -from [get_clocks {clock_sample}] -to [get_clocks {clock_ui}] 
set_false_path -from [get_clocks {clock_sample}] -to [get_clocks {if_clock}] 
set_false_path -from [get_clocks {clock_sample}] -to [get_clocks {clock}] 
					 
					 
set_false_path -from [get_clocks {if_clock}] -to [get_clocks {clock_ddr}]
set_false_path -from [get_clocks {if_clock}] -to [get_clocks {clock_ui}] 
set_false_path -from [get_clocks {if_clock}] -to [get_clocks {clock_sample}]
set_false_path -from [get_clocks {if_clock}] -to [get_clocks {clock}]
					 
					 
set_false_path -from [get_clocks {clock_ui}] -to [get_clocks {clock_ddr}]
set_false_path -from [get_clocks {clock_ui}] -to [get_clocks {if_clock}]
set_false_path -from [get_clocks {clock_ui}] -to [get_clocks {clock_sample}]
set_false_path -from [get_clocks {clock_ui}] -to [get_clocks {clock}]
					 
set_false_path -from [get_clocks {clock_ddr}] -to [get_clocks {clock_ui}]
set_false_path -from [get_clocks {clock_ddr}] -to [get_clocks {if_clock}]
set_false_path -from [get_clocks {clock_ddr}] -to [get_clocks {clock_sample}]
set_false_path -from [get_clocks {clock_ddr}] -to [get_clocks {clock}]

set_input_delay -clock [get_clocks {if_clock}] -max -clock_fall 10.0 [get_ports {ctl0_i}]
set_input_delay -clock [get_clocks {if_clock}] -min -clock_fall 2.0  [get_ports {ctl0_i}]

set_input_delay -clock [get_clocks {if_clock}] -max -clock_fall 10.0 [get_ports {ctl1_i}]
set_input_delay -clock [get_clocks {if_clock}] -min -clock_fall 2.0  [get_ports {ctl1_i}]

set_output_delay -clock [get_clocks {if_clock}] -max -clock_fall 6.5 [get_ports {d0_io d1_io d2_io d3_io d4_io d5_io d6_io d7_io d8_io d9_io d10_io d11_io d12_io d13_io d14_io d15_io}]
set_output_delay -clock [get_clocks {if_clock}] -min -clock_fall 0.0 [get_ports {d0_io d1_io d2_io d3_io d4_io d5_io d6_io d7_io d8_io d9_io d10_io d11_io d12_io d13_io d14_io d15_io}]
set_output_delay -clock [get_clocks {if_clock}] -max -clock_fall 7.0 [get_ports {data_valid_o}]
set_output_delay -clock [get_clocks {if_clock}] -min -clock_fall 0.0 [get_ports {data_valid_o}]

