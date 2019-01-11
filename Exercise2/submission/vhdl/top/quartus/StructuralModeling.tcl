# Copyright (C) 2017  Intel Corporation. All rights reserved.
# Your use of Intel Corporation's design tools, logic functions 
# and other software and tools, and its AMPP partner logic 
# functions, and any output files from any of the foregoing 
# (including device programming or simulation files), and any 
# associated documentation or information are expressly subject 
# to the terms and conditions of the Intel Program License 
# Subscription Agreement, the Intel Quartus Prime License Agreement,
# the Intel MegaCore Function License Agreement, or other 
# applicable license agreement, including, without limitation, 
# that your use is for the sole purpose of programming logic 
# devices manufactured by Intel and sold by Intel or its 
# authorized distributors.  Please refer to the applicable 
# agreement for further details.

# Quartus Prime: Generate Tcl File for Project
# File: StructuralModeling.tcl
# Generated on: Sun Mar 25 23:30:17 2018

# Load Quartus Prime Tcl Project package
package require ::quartus::project

set need_to_close_project 0
set make_assignments 1

# Check that the right project is open
if {[is_project_open]} {
	if {[string compare $quartus(project) "StructuralModeling"]} {
		puts "Project StructuralModeling is not open"
		set make_assignments 0
	}
} else {
	# Only open if not already open
	if {[project_exists StructuralModeling]} {
		project_open -revision StructuralModeling StructuralModeling
	} else {
		project_new -revision StructuralModeling StructuralModeling
	}
	set need_to_close_project 1
}

# Make assignments
if {$make_assignments} {
	set_global_assignment -name FAMILY "Cyclone IV E"
	set_global_assignment -name DEVICE EP4CE115F29C7
	set_global_assignment -name TOP_LEVEL_ENTITY top
	set_global_assignment -name ORIGINAL_QUARTUS_VERSION 17.0.0
	set_global_assignment -name PROJECT_CREATION_TIME_DATE "14:29:35  MARCH 12, 2018"
	set_global_assignment -name LAST_QUARTUS_VERSION "17.0.0 Standard Edition"
	set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
	set_global_assignment -name MIN_CORE_JUNCTION_TEMP 0
	set_global_assignment -name MAX_CORE_JUNCTION_TEMP 85
	set_global_assignment -name ERROR_CHECK_FREQUENCY_DIVISOR 1
	set_global_assignment -name EDA_SIMULATION_TOOL "ModelSim (VHDL)"
	set_global_assignment -name EDA_TIME_SCALE "1 ps" -section_id eda_simulation
	set_global_assignment -name EDA_OUTPUT_DATA_FORMAT VHDL -section_id eda_simulation
	set_global_assignment -name POWER_PRESET_COOLING_SOLUTION "23 MM HEAT SINK WITH 200 LFPM AIRFLOW"
	set_global_assignment -name POWER_BOARD_THERMAL_MODEL "NONE (CONSERVATIVE)"
	set_global_assignment -name PARTITION_NETLIST_TYPE SOURCE -section_id Top
	set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id Top
	set_global_assignment -name PARTITION_COLOR 16764057 -section_id Top
	set_global_assignment -name ENABLE_OCT_DONE OFF
	set_global_assignment -name ENABLE_CONFIGURATION_PINS OFF
	set_global_assignment -name ENABLE_BOOT_SEL_PIN OFF
	set_global_assignment -name STRATIXV_CONFIGURATION_SCHEME "PASSIVE SERIAL"
	set_global_assignment -name USE_CONFIGURATION_DEVICE OFF
	set_global_assignment -name CRC_ERROR_OPEN_DRAIN OFF
	set_global_assignment -name CYCLONEII_RESERVE_NCEO_AFTER_CONFIGURATION "USE AS REGULAR IO"
	set_global_assignment -name OUTPUT_IO_TIMING_NEAR_END_VMEAS "HALF VCCIO" -rise
	set_global_assignment -name OUTPUT_IO_TIMING_NEAR_END_VMEAS "HALF VCCIO" -fall
	set_global_assignment -name OUTPUT_IO_TIMING_FAR_END_VMEAS "HALF SIGNAL SWING" -rise
	set_global_assignment -name OUTPUT_IO_TIMING_FAR_END_VMEAS "HALF SIGNAL SWING" -fall
	set_global_assignment -name VHDL_INPUT_VERSION VHDL_2008
	set_global_assignment -name VHDL_SHOW_LMF_MAPPING_MESSAGES OFF
	set_global_assignment -name VHDL_FILE ../../serial_port/src/serial_port.vhd
	set_global_assignment -name VHDL_FILE ../../serial_port/tb/serial_port_tb.vhd
	set_global_assignment -name VHDL_FILE ../../serial_port/src/serial_port_pkg.vhd
	set_global_assignment -name VHDL_FILE ../../serial_port/src/serial_port_tx_fsm.vhd
	set_global_assignment -name VHDL_FILE ../../serial_port/tb/serial_port_rx_fsm_tb.vhd
	set_global_assignment -name VHDL_FILE ../../serial_port/src/serial_port_rx_fsm.vhd
	set_global_assignment -name VHDL_FILE ../tb/top_tb_util_pkg.vhd
	set_global_assignment -name VHDL_FILE ../tb/top_tb.vhd
	set_global_assignment -name VHDL_FILE ../src/top.vhd
	set_global_assignment -name VHDL_FILE ../../graphics_controller/src/framereader/ltm_cntrl.vhd
	set_global_assignment -name VHDL_FILE ../../graphics_controller/src/framereader/framereader.vhd
	set_global_assignment -name VHDL_FILE ../../graphics_controller/src/sram/sram_controller_wb.vhd
	set_global_assignment -name VHDL_FILE ../../graphics_controller/src/wb_arbiter/wb_arbiter.vhd
	set_global_assignment -name VHDL_FILE ../../graphics_controller/src/rasterizer/rasterizer_fsm.vhd
	set_global_assignment -name VHDL_FILE ../../graphics_controller/src/rasterizer/rasterizer.vhd
	set_global_assignment -name VHDL_FILE ../../graphics_controller/src/rasterizer/fb_writer.vhd
	set_global_assignment -name VHDL_FILE ../../seven_segment_display/src/seven_segment_display_pkg.vhd
	set_global_assignment -name VHDL_FILE ../../seven_segment_display/tb/seven_segment_tb.vhd
	set_global_assignment -name VHDL_FILE ../../seven_segment_display/src/seven_segment_display.vhd
	set_global_assignment -name VHDL_FILE ../../graphics_controller/src/wb_arbiter/wb_arbiter_pkg.vhd
	set_global_assignment -name VHDL_FILE ../../graphics_controller/src/sram/sram_pkg.vhd
	set_global_assignment -name VHDL_FILE ../../graphics_controller/src/rasterizer/rasterizer_pkg.vhd
	set_global_assignment -name VHDL_FILE ../../graphics_controller/src/framereader/framereader_pkg.vhd
	set_global_assignment -name VHDL_FILE ../../touch_controller/src/touch_controller.vhd
	set_global_assignment -name VHDL_FILE ../../rom/src/rom_sync_1r.vhd
	set_global_assignment -name VHDL_FILE ../../rom/src/rom_pkg.vhd
	set_global_assignment -name VHDL_FILE ../../ram/src/wb_ram.vhd
	set_global_assignment -name VHDL_FILE ../../ram/src/ram_pkg.vhd
	set_global_assignment -name VHDL_FILE ../../ram/src/fifo_1c1r1w.vhd
	set_global_assignment -name VHDL_FILE ../../ram/src/dp_ram_1c1r1w.vhd
	set_global_assignment -name VHDL_FILE ../../ps2_ascii/src/ps2_ascii_pkg.vhd
	set_global_assignment -name VHDL_FILE ../../ps2_ascii/src/ps2_ascii.vhd
	set_global_assignment -name VHDL_FILE ../../ps2/src/ps2_transceiver_pkg.vhd
	set_global_assignment -name VHDL_FILE ../../ps2/src/ps2_transceiver.vhd
	set_global_assignment -name VHDL_FILE ../../ps2/src/ps2_keyboard_controller_pkg.vhd
	set_global_assignment -name VHDL_FILE ../../ps2/src/ps2_keyboard_controller.vhd
	set_global_assignment -name VHDL_FILE ../../merge_fifo/merge_fifo_pkg.vhd
	set_global_assignment -name VHDL_FILE ../../merge_fifo/merge_fifo.vhd
	set_global_assignment -name VHDL_FILE ../../merge_fifo/alt_fwft_fifo.vhd
	set_global_assignment -name VHDL_FILE ../../math/src/math_pkg.vhd
	set_global_assignment -name VHDL_FILE ../../graphics_controller/src/graphics_controller_pkg.vhd
	set_global_assignment -name VHDL_FILE ../../graphics_controller/src/graphics_controller.vhd
	set_global_assignment -name VHDL_FILE ../../ascii_gcinstr/src/ascii_gcinstr_pkg.vhd
	set_global_assignment -name VHDL_FILE ../../ascii_gcinstr/src/ascii_gcinstr.vhd
	set_global_assignment -name VHDL_FILE ../../synchronizer/src/sync_pkg.vhd
	set_global_assignment -name VHDL_FILE ../../synchronizer/src/sync.vhd
	set_global_assignment -name SDC_FILE ../src/SDC1.sdc
	set_global_assignment -name VHDL_FILE pll.vhd
	set_location_assignment PIN_V24 -to b[7]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to b[7]
	set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to b[7]
	set_location_assignment PIN_P25 -to b[6]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to b[6]
	set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to b[6]
	set_location_assignment PIN_U27 -to b[5]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to b[5]
	set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to b[5]
	set_location_assignment PIN_P26 -to b[4]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to b[4]
	set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to b[4]
	set_location_assignment PIN_R23 -to b[3]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to b[3]
	set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to b[3]
	set_location_assignment PIN_U22 -to b[2]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to b[2]
	set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to b[2]
	set_location_assignment PIN_R22 -to b[1]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to b[1]
	set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to b[1]
	set_location_assignment PIN_V28 -to b[0]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to b[0]
	set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to b[0]
	set_location_assignment PIN_Y2 -to clk
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to clk
	set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to clk
	set_location_assignment PIN_V27 -to den
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to den
	set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to den
	set_location_assignment PIN_V26 -to g[7]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to g[7]
	set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to g[7]
	set_location_assignment PIN_L21 -to g[6]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to g[6]
	set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to g[6]
	set_location_assignment PIN_R27 -to g[5]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to g[5]
	set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to g[5]
	set_location_assignment PIN_L22 -to g[4]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to g[4]
	set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to g[4]
	set_location_assignment PIN_R28 -to g[3]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to g[3]
	set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to g[3]
	set_location_assignment PIN_N25 -to g[2]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to g[2]
	set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to g[2]
	set_location_assignment PIN_V23 -to g[1]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to g[1]
	set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to g[1]
	set_location_assignment PIN_N26 -to g[0]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to g[0]
	set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to g[0]
	set_location_assignment PIN_P28 -to grest
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to grest
	set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to grest
	set_location_assignment PIN_P21 -to hd
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hd
	set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to hd
	set_location_assignment PIN_H22 -to hex0[6]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex0[6]
	set_location_assignment PIN_J22 -to hex0[5]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex0[5]
	set_location_assignment PIN_L25 -to hex0[4]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex0[4]
	set_location_assignment PIN_L26 -to hex0[3]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex0[3]
	set_location_assignment PIN_E17 -to hex0[2]
	set_instance_assignment -name IO_STANDARD "2.5 V" -to hex0[2]
	set_location_assignment PIN_F22 -to hex0[1]
	set_instance_assignment -name IO_STANDARD "2.5 V" -to hex0[1]
	set_location_assignment PIN_G18 -to hex0[0]
	set_instance_assignment -name IO_STANDARD "2.5 V" -to hex0[0]
	set_location_assignment PIN_U24 -to hex1[6]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex1[6]
	set_location_assignment PIN_U23 -to hex1[5]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex1[5]
	set_location_assignment PIN_W25 -to hex1[4]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex1[4]
	set_location_assignment PIN_W22 -to hex1[3]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex1[3]
	set_location_assignment PIN_W21 -to hex1[2]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex1[2]
	set_location_assignment PIN_Y22 -to hex1[1]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex1[1]
	set_location_assignment PIN_M24 -to hex1[0]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex1[0]
	set_location_assignment PIN_W28 -to hex2[6]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex2[6]
	set_location_assignment PIN_W27 -to hex2[5]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex2[5]
	set_location_assignment PIN_Y26 -to hex2[4]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex2[4]
	set_location_assignment PIN_W26 -to hex2[3]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex2[3]
	set_location_assignment PIN_Y25 -to hex2[2]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex2[2]
	set_location_assignment PIN_AA26 -to hex2[1]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex2[1]
	set_location_assignment PIN_AA25 -to hex2[0]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex2[0]
	set_location_assignment PIN_Y19 -to hex3[6]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex3[6]
	set_location_assignment PIN_AF23 -to hex3[5]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex3[5]
	set_location_assignment PIN_AD24 -to hex3[4]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex3[4]
	set_location_assignment PIN_AA21 -to hex3[3]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex3[3]
	set_location_assignment PIN_AB20 -to hex3[2]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex3[2]
	set_location_assignment PIN_U21 -to hex3[1]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex3[1]
	set_location_assignment PIN_V21 -to hex3[0]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex3[0]
	set_location_assignment PIN_AE18 -to hex4[6]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex4[6]
	set_location_assignment PIN_AF19 -to hex4[5]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex4[5]
	set_location_assignment PIN_AE19 -to hex4[4]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex4[4]
	set_location_assignment PIN_AH21 -to hex4[3]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex4[3]
	set_location_assignment PIN_AG21 -to hex4[2]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex4[2]
	set_location_assignment PIN_AA19 -to hex4[1]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex4[1]
	set_location_assignment PIN_AB19 -to hex4[0]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex4[0]
	set_location_assignment PIN_AH18 -to hex5[6]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex5[6]
	set_location_assignment PIN_AF18 -to hex5[5]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex5[5]
	set_location_assignment PIN_AG19 -to hex5[4]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex5[4]
	set_location_assignment PIN_AH19 -to hex5[3]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex5[3]
	set_location_assignment PIN_AB18 -to hex5[2]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex5[2]
	set_location_assignment PIN_AC18 -to hex5[1]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex5[1]
	set_location_assignment PIN_AD18 -to hex5[0]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex5[0]
	set_location_assignment PIN_AC17 -to hex6[6]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex6[6]
	set_location_assignment PIN_AA15 -to hex6[5]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex6[5]
	set_location_assignment PIN_AB15 -to hex6[4]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex6[4]
	set_location_assignment PIN_AB17 -to hex6[3]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex6[3]
	set_location_assignment PIN_AA16 -to hex6[2]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex6[2]
	set_location_assignment PIN_AB16 -to hex6[1]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex6[1]
	set_location_assignment PIN_AA17 -to hex6[0]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex6[0]
	set_location_assignment PIN_AA14 -to hex7[6]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex7[6]
	set_location_assignment PIN_AG18 -to hex7[5]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex7[5]
	set_location_assignment PIN_AF17 -to hex7[4]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex7[4]
	set_location_assignment PIN_AH17 -to hex7[3]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex7[3]
	set_location_assignment PIN_AG17 -to hex7[2]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex7[2]
	set_location_assignment PIN_AE17 -to hex7[1]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex7[1]
	set_location_assignment PIN_AD17 -to hex7[0]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to hex7[0]
	set_location_assignment PIN_R24 -to keys[3]
	set_instance_assignment -name IO_STANDARD "2.5 V" -to keys[3]
	set_location_assignment PIN_N21 -to keys[2]
	set_instance_assignment -name IO_STANDARD "2.5 V" -to keys[2]
	set_location_assignment PIN_M21 -to keys[1]
	set_instance_assignment -name IO_STANDARD "2.5 V" -to keys[1]
	set_location_assignment PIN_M23 -to keys[0]
	set_instance_assignment -name IO_STANDARD "2.5 V" -to keys[0]
	set_location_assignment PIN_R21 -to nclk
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to nclk
	set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to nclk
	set_location_assignment PIN_G6 -to ps2_clk
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to ps2_clk
	set_location_assignment PIN_H5 -to ps2_data
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to ps2_data
	set_location_assignment PIN_J26 -to r[7]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to r[7]
	set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to r[7]
	set_location_assignment PIN_T25 -to r[6]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to r[6]
	set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to r[6]
	set_location_assignment PIN_L27 -to r[5]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to r[5]
	set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to r[5]
	set_location_assignment PIN_T26 -to r[4]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to r[4]
	set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to r[4]
	set_location_assignment PIN_L28 -to r[3]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to r[3]
	set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to r[3]
	set_location_assignment PIN_U25 -to r[2]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to r[2]
	set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to r[2]
	set_location_assignment PIN_V25 -to r[1]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to r[1]
	set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to r[1]
	set_location_assignment PIN_U26 -to r[0]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to r[0]
	set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to r[0]
	set_location_assignment PIN_G12 -to rx
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to rx
	set_location_assignment PIN_P27 -to sda
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sda
	set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to sda
	set_location_assignment PIN_T8 -to sram_addr[19]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sram_addr[19]
	set_location_assignment PIN_AB8 -to sram_addr[18]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sram_addr[18]
	set_location_assignment PIN_AB9 -to sram_addr[17]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sram_addr[17]
	set_location_assignment PIN_AC11 -to sram_addr[16]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sram_addr[16]
	set_location_assignment PIN_AB11 -to sram_addr[15]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sram_addr[15]
	set_location_assignment PIN_AA4 -to sram_addr[14]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sram_addr[14]
	set_location_assignment PIN_AC3 -to sram_addr[13]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sram_addr[13]
	set_location_assignment PIN_AB4 -to sram_addr[12]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sram_addr[12]
	set_location_assignment PIN_AD3 -to sram_addr[11]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sram_addr[11]
	set_location_assignment PIN_AF2 -to sram_addr[10]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sram_addr[10]
	set_location_assignment PIN_T7 -to sram_addr[9]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sram_addr[9]
	set_location_assignment PIN_AF5 -to sram_addr[8]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sram_addr[8]
	set_location_assignment PIN_AC5 -to sram_addr[7]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sram_addr[7]
	set_location_assignment PIN_AB5 -to sram_addr[6]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sram_addr[6]
	set_location_assignment PIN_AE6 -to sram_addr[5]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sram_addr[5]
	set_location_assignment PIN_AB6 -to sram_addr[4]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sram_addr[4]
	set_location_assignment PIN_AC7 -to sram_addr[3]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sram_addr[3]
	set_location_assignment PIN_AE7 -to sram_addr[2]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sram_addr[2]
	set_location_assignment PIN_AD7 -to sram_addr[1]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sram_addr[1]
	set_location_assignment PIN_AB7 -to sram_addr[0]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sram_addr[0]
	set_location_assignment PIN_AF8 -to sram_ce_n
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sram_ce_n
	set_location_assignment PIN_AG3 -to sram_dq[15]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sram_dq[15]
	set_location_assignment PIN_AF3 -to sram_dq[14]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sram_dq[14]
	set_location_assignment PIN_AE4 -to sram_dq[13]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sram_dq[13]
	set_location_assignment PIN_AE3 -to sram_dq[12]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sram_dq[12]
	set_location_assignment PIN_AE1 -to sram_dq[11]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sram_dq[11]
	set_location_assignment PIN_AE2 -to sram_dq[10]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sram_dq[10]
	set_location_assignment PIN_AD2 -to sram_dq[9]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sram_dq[9]
	set_location_assignment PIN_AD1 -to sram_dq[8]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sram_dq[8]
	set_location_assignment PIN_AF7 -to sram_dq[7]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sram_dq[7]
	set_location_assignment PIN_AH6 -to sram_dq[6]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sram_dq[6]
	set_location_assignment PIN_AG6 -to sram_dq[5]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sram_dq[5]
	set_location_assignment PIN_AF6 -to sram_dq[4]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sram_dq[4]
	set_location_assignment PIN_AH4 -to sram_dq[3]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sram_dq[3]
	set_location_assignment PIN_AG4 -to sram_dq[2]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sram_dq[2]
	set_location_assignment PIN_AF4 -to sram_dq[1]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sram_dq[1]
	set_location_assignment PIN_AH3 -to sram_dq[0]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sram_dq[0]
	set_location_assignment PIN_AD4 -to sram_lb_n
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sram_lb_n
	set_location_assignment PIN_AD5 -to sram_oe_n
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sram_oe_n
	set_location_assignment PIN_AC4 -to sram_ub_n
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sram_ub_n
	set_location_assignment PIN_AE8 -to sram_we_n
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sram_we_n
	set_location_assignment PIN_Y23 -to switches[17]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to switches[17]
	set_location_assignment PIN_Y24 -to switches[16]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to switches[16]
	set_location_assignment PIN_AA22 -to switches[15]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to switches[15]
	set_location_assignment PIN_AA23 -to switches[14]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to switches[14]
	set_location_assignment PIN_AA24 -to switches[13]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to switches[13]
	set_location_assignment PIN_AB23 -to switches[12]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to switches[12]
	set_location_assignment PIN_AB24 -to switches[11]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to switches[11]
	set_location_assignment PIN_AC24 -to switches[10]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to switches[10]
	set_location_assignment PIN_AB25 -to switches[9]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to switches[9]
	set_location_assignment PIN_AC25 -to switches[8]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to switches[8]
	set_location_assignment PIN_AB26 -to switches[7]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to switches[7]
	set_location_assignment PIN_AD26 -to switches[6]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to switches[6]
	set_location_assignment PIN_AC26 -to switches[5]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to switches[5]
	set_location_assignment PIN_AB27 -to switches[4]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to switches[4]
	set_location_assignment PIN_AD27 -to switches[3]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to switches[3]
	set_location_assignment PIN_AC27 -to switches[2]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to switches[2]
	set_location_assignment PIN_AC28 -to switches[1]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to switches[1]
	set_location_assignment PIN_AB28 -to switches[0]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to switches[0]
	set_location_assignment PIN_U28 -to vd
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to vd
	set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to vd
	set_location_assignment PIN_E21 -to ledg[0]
	set_instance_assignment -name IO_STANDARD "2.5 V" -to ledg[0]
	set_location_assignment PIN_E22 -to ledg[1]
	set_instance_assignment -name IO_STANDARD "2.5 V" -to ledg[1]
	set_location_assignment PIN_E25 -to ledg[2]
	set_instance_assignment -name IO_STANDARD "2.5 V" -to ledg[2]
	set_location_assignment PIN_E24 -to ledg[3]
	set_instance_assignment -name IO_STANDARD "2.5 V" -to ledg[3]
	set_location_assignment PIN_H21 -to ledg[4]
	set_instance_assignment -name IO_STANDARD "2.5 V" -to ledg[4]
	set_location_assignment PIN_G20 -to ledg[5]
	set_instance_assignment -name IO_STANDARD "2.5 V" -to ledg[5]
	set_location_assignment PIN_G22 -to ledg[6]
	set_instance_assignment -name IO_STANDARD "2.5 V" -to ledg[6]
	set_location_assignment PIN_G21 -to ledg[7]
	set_instance_assignment -name IO_STANDARD "2.5 V" -to ledg[7]
	set_location_assignment PIN_F17 -to ledg[8]
	set_instance_assignment -name IO_STANDARD "2.5 V" -to ledg[8]
	set_location_assignment PIN_G9 -to tx
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to tx
	set_instance_assignment -name PARTITION_HIERARCHY root_partition -to | -section_id Top

	# Commit assignments
	export_assignments

	# Close project
	if {$need_to_close_project} {
		project_close
	}
}
