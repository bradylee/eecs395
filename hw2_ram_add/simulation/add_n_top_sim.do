vlib work
vcom -work work ../components/constants.vhd
vcom -work work ../components/sramb.vhd
vcom -work work ../components/sram.vhd
vcom -work work ../components/add_n.vhd
vcom -work work ../components/add_n_top.vhd
vcom -work work add_n_top_tb.vhd
vsim +notimingchecks -L work work.add_n_top_tb -wlf vsim.wlf

add wave -noupdate -group add_n_top_tb
add wave -noupdate -group add_n_top_tb -radix hexadecimal /add_n_top_tb/*
add wave -noupdate -group add_n_top_tb/add_n_top_inst
add wave -noupdate -group add_n_top_tb/add_n_top_inst -radix hexadecimal /add_n_top_tb/add_n_top_inst/*
add wave -noupdate -group add_n_top_tb/add_n_top_inst/add_n_inst
add wave -noupdate -group add_n_top_tb/add_n_top_inst/add_n_inst -radix hexadecimal /add_n_top_tb/add_n_top_inst/add_n_inst/*
add wave -noupdate -group add_n_top_tb/add_n_top_inst/x_inst
add wave -noupdate -group add_n_top_tb/add_n_top_inst/x_inst -radix hexadecimal /add_n_top_tb/add_n_top_inst/x_inst/*
add wave -noupdate -group add_n_top_tb/add_n_top_inst/y_inst
add wave -noupdate -group add_n_top_tb/add_n_top_inst/y_inst -radix hexadecimal /add_n_top_tb/add_n_top_inst/y_inst/*
add wave -noupdate -group add_n_top_tb/add_n_top_inst/z_inst
add wave -noupdate -group add_n_top_tb/add_n_top_inst/z_inst -radix hexadecimal /add_n_top_tb/add_n_top_inst/z_inst/*

run -all
