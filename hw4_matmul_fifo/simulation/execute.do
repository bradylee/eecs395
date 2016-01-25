vlib work
vcom -work work ../components/constants.vhd
vcom -work work ../components/fifo.vhd
vcom -work work ../components/fifo_multiply.vhd
vcom -work work ../components/fifo_multiply_top.vhd
vcom -work work fifo_multiply_top_tb.vhd

vsim +notimingchecks -L work work.fifo_multiply_top_tb -wlf vsim.wlf

add wave -noupdate -group test -radix hexadecimal /fifo_multiply_top_tb/*
add wave -noupdate -group top -radix hexadecimal /fifo_multiply_top_tb/top_inst/*
add wave -noupdate -group multiplier -radix hexadecimal /fifo_multiply_top_tb/top_inst/multiply/*
add wave -noupdate -group A -radix hexadecimal /fifo_multiply_top_tb/top_inst/a_fifo/*
add wave -noupdate -group B -radix hexadecimal /fifo_multiply_top_tb/top_inst/b_fifo/*
add wave -noupdate -group C -radix hexadecimal /fifo_multiply_top_tb/top_inst/c_fifo/*

run -all
