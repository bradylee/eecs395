onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group TEST -radix hexadecimal /radio_tb/clock
add wave -noupdate -expand -group TEST -radix hexadecimal /radio_tb/reset
add wave -noupdate -expand -group TEST -radix hexadecimal /radio_tb/volume
add wave -noupdate -expand -group TEST -radix hexadecimal /radio_tb/din
add wave -noupdate -expand -group TEST -radix hexadecimal /radio_tb/input_wr_en
add wave -noupdate -expand -group TEST -radix hexadecimal /radio_tb/left_rd_en
add wave -noupdate -expand -group TEST -radix hexadecimal /radio_tb/right_rd_en
add wave -noupdate -expand -group TEST -radix hexadecimal /radio_tb/input_full
add wave -noupdate -expand -group TEST -radix hexadecimal /radio_tb/left
add wave -noupdate -expand -group TEST -radix hexadecimal /radio_tb/right
add wave -noupdate -expand -group TEST -radix hexadecimal /radio_tb/left_empty
add wave -noupdate -expand -group TEST -radix hexadecimal /radio_tb/right_empty
add wave -noupdate -expand -group TEST -radix hexadecimal /radio_tb/hold_clock
add wave -noupdate -expand -group TEST -radix hexadecimal /radio_tb/start
add wave -noupdate -expand -group TEST -radix hexadecimal /radio_tb/done
add wave -noupdate -expand -group TEST -radix hexadecimal /radio_tb/errors
add wave -noupdate -expand -group TEST -radix hexadecimal /radio_tb/in_count
add wave -noupdate -expand -group TEST -radix hexadecimal /radio_tb/out_count
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {4264 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 201
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {67625 ps}
