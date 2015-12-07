vlib work
vcom -work work ../components/constants.vhd
vcom -work work ../components/fifo.vhd
vcom -work work ../components/read_iq.vhd
vcom -work work ../components/fir.vhd
vcom -work work ../components/fir_complex.vhd
vcom -work work ../components/arithmetic.vhd
vcom -work work ../components/iir.vhd
vcom -work work ../components/gain.vhd

#vsim +notimingchecks -L work work.udp_write_top_tb -wlf vsim.wlf

#add wave -noupdate -group TEST -radix hexadecimal /udp_write_top_tb/*
#add wave -noupdate -group TOP -radix hexadecimal /udp_write_top_tb/top_inst/*
#add wave -noupdate -group WRITER -radix hexadecimal /udp_write_top_tb/top_inst/writer/*
#add wave -noupdate -group INPUT -radix hexadecimal /udp_write_top_tb/top_inst/input_fifo/*
#add wave -noupdate -group OUTPUT -radix hexadecimal /udp_write_top_tb/top_inst/output_fifo/*
#add wave -noupdate -group STATUS -radix hexadecimal /udp_write_top_tb/top_inst/status_fifo/*

#run -all
#run 50 ns

