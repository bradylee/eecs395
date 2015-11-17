vlib work
vcom -work work ../components/constants.vhd
vcom -work work ../components/fifo.vhd
vcom -work work ../components/udp_write.vhd
#vcom -work work ../components/udp_read_top.vhd
#vcom -work work udp_read_top_tb.vhd

#vsim +notimingchecks -L work work.udp_read_top_tb -wlf vsim.wlf
#
#add wave -noupdate -group TEST -radix hexadecimal /udp_read_top_tb/*
#add wave -noupdate -group TOP -radix hexadecimal /udp_read_top_tb/top_inst/*
#add wave -noupdate -group READER -radix hexadecimal /udp_read_top_tb/top_inst/reader/*
#add wave -noupdate -group INPUT -radix hexadecimal /udp_read_top_tb/top_inst/input_fifo/*
#add wave -noupdate -group OUTPUT -radix hexadecimal /udp_read_top_tb/top_inst/output_fifo/*
#add wave -noupdate -group LENGTH -radix hexadecimal /udp_read_top_tb/top_inst/length_fifo/*

#run -all
#run 3000 ns

