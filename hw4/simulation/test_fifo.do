vlib work
vcom -work work ../components/constants.vhd
vcom -work work ../components/fifo.vhd
vcom -work work fifo_tb.vhd

vsim +notimingchecks -L work work.fifo_tb -wlf vsim.wlf

add wave -noupdate -group test -radix hexadecimal /fifo_tb/*
add wave -noupdate -group top -radix hexadecimal /fifo_tb/test_inst/*

run -all
