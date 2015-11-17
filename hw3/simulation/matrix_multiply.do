vlib work
vcom -work work ../components/constants.vhd
vcom -work work ../components/sramb.vhd
vcom -work work ../components/sram.vhd
vcom -work work ../components/matrix_multiply.vhd
vcom -work work ../components/matrix_multiply_top.vhd
vcom -work work matrix_multiply_top_tb.vhd

vsim +notimingchecks -L work work.matrix_multiply_top_tb -wlf vsim.wlf

add wave -noupdate -group test -radix hexadecimal /matrix_multiply_top_tb/*
add wave -noupdate -group top -radix hexadecimal /matrix_multiply_top_tb/matrix_multiply_top_inst/*
add wave -noupdate -group multiplier -radix hexadecimal /matrix_multiply_top_tb/matrix_multiply_top_inst/matmul/*
add wave -noupdate -group A -radix hexadecimal /matrix_multiply_top_tb/matrix_multiply_top_inst/mat_a/*
add wave -noupdate -group B -radix hexadecimal /matrix_multiply_top_tb/matrix_multiply_top_inst/mat_b/*
add wave -noupdate -group C -radix hexadecimal /matrix_multiply_top_tb/matrix_multiply_top_inst/mat_c/*

run -all
