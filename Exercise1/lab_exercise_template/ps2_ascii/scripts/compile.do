vlib work
vmap work work 

#compilation order is important!
vcom -work work ../rom/src/rom_pkg.vhd
vcom -work work ../rom/src/rom_sync_1r.vhd

vcom -work work src/ps2_ascii_pkg.vhd
vcom -work work src/ps2_ascii.vhd

