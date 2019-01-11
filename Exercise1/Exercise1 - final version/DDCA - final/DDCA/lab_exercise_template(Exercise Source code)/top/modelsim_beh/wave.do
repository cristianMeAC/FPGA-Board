onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /top_tb/clk
add wave -noupdate /top_tb/reset_n
add wave -noupdate /top_tb/ps2_keyboard_clk
add wave -noupdate /top_tb/ps2_keyboard_data
add wave -noupdate /top_tb/top_instance/ps2_kbd_cntrl_inst/scancode
add wave -noupdate -radix ascii -childformat {{/top_tb/top_instance/ps2_ascii_inst/ascii(7) -radix ascii} {/top_tb/top_instance/ps2_ascii_inst/ascii(6) -radix ascii} {/top_tb/top_instance/ps2_ascii_inst/ascii(5) -radix ascii} {/top_tb/top_instance/ps2_ascii_inst/ascii(4) -radix ascii} {/top_tb/top_instance/ps2_ascii_inst/ascii(3) -radix ascii} {/top_tb/top_instance/ps2_ascii_inst/ascii(2) -radix ascii} {/top_tb/top_instance/ps2_ascii_inst/ascii(1) -radix ascii} {/top_tb/top_instance/ps2_ascii_inst/ascii(0) -radix ascii}} -expand -subitemconfig {/top_tb/top_instance/ps2_ascii_inst/ascii(7) {-height 16 -radix ascii} /top_tb/top_instance/ps2_ascii_inst/ascii(6) {-height 16 -radix ascii} /top_tb/top_instance/ps2_ascii_inst/ascii(5) {-height 16 -radix ascii} /top_tb/top_instance/ps2_ascii_inst/ascii(4) {-height 16 -radix ascii} /top_tb/top_instance/ps2_ascii_inst/ascii(3) {-height 16 -radix ascii} /top_tb/top_instance/ps2_ascii_inst/ascii(2) {-height 16 -radix ascii} /top_tb/top_instance/ps2_ascii_inst/ascii(1) {-height 16 -radix ascii} /top_tb/top_instance/ps2_ascii_inst/ascii(0) {-height 16 -radix ascii}} /top_tb/top_instance/ps2_ascii_inst/ascii
add wave -noupdate /top_tb/top_instance/ps2_ascii_inst/new_ascii
add wave -noupdate /top_tb/top_instance/ascii_gcinstr_instr/ascii_rd_int
add wave -noupdate /top_tb/top_instance/ascii_gcinstr_instr/ascii_rd_last
add wave -noupdate /top_tb/top_instance/ascii_gcinstr_instr/instr
add wave -noupdate /top_tb/top_instance/gcntrl_inst/current_color
add wave -noupdate -radix ascii /top_tb/top_instance/ascii_gcinstr_instr/ascii_data
add wave -noupdate /top_tb/top_instance/seven_segment_display_instance/color
add wave -noupdate -radix binary -childformat {{/top_tb/top_instance/seven_segment_display_instance/hex0(6) -radix binary} {/top_tb/top_instance/seven_segment_display_instance/hex0(5) -radix binary} {/top_tb/top_instance/seven_segment_display_instance/hex0(4) -radix binary} {/top_tb/top_instance/seven_segment_display_instance/hex0(3) -radix binary} {/top_tb/top_instance/seven_segment_display_instance/hex0(2) -radix binary} {/top_tb/top_instance/seven_segment_display_instance/hex0(1) -radix binary} {/top_tb/top_instance/seven_segment_display_instance/hex0(0) -radix binary}} -expand -subitemconfig {/top_tb/top_instance/seven_segment_display_instance/hex0(6) {-height 16 -radix binary} /top_tb/top_instance/seven_segment_display_instance/hex0(5) {-height 16 -radix binary} /top_tb/top_instance/seven_segment_display_instance/hex0(4) {-height 16 -radix binary} /top_tb/top_instance/seven_segment_display_instance/hex0(3) {-height 16 -radix binary} /top_tb/top_instance/seven_segment_display_instance/hex0(2) {-height 16 -radix binary} /top_tb/top_instance/seven_segment_display_instance/hex0(1) {-height 16 -radix binary} /top_tb/top_instance/seven_segment_display_instance/hex0(0) {-height 16 -radix binary}} /top_tb/top_instance/seven_segment_display_instance/hex0
add wave -noupdate /top_tb/top_instance/seven_segment_display_instance/hex1
add wave -noupdate /top_tb/top_instance/seven_segment_display_instance/hex2
add wave -noupdate -radix binary /top_tb/top_instance/seven_segment_display_instance/hex3
add wave -noupdate /top_tb/top_instance/gcntrl_inst/vd
TreeUpdate [SetDefaultTree]
WaveRestoreCursors
quietly wave cursor active 0
configure wave -namecolwidth 196
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {21 ms}
