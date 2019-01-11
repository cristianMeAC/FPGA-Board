vcom -work work tb/tb_util_pkg.vhd
vcom -work work tb/alu_tb.vhd

vsim -novopt -t ps work.alu_tb
