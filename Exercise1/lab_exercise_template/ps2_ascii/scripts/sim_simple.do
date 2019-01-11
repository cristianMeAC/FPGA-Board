


#first compile testbench and utility package
vcom -work work tb/tb_util_pkg.vhd
vcom -work work tb/ps2_ascii_tb_simple.vhd

#start simulation
vsim -t ps work.ps2_ascii_tb_simple


