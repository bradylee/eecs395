vlib work
vcom -work work ../components/constants.vhd
vcom -work work ../components/components.vhd
vcom -work work ../components/functions.vhd
vcom -work work ../components/dependent.vhd
vcom -work work ../components/fifo.vhd
vcom -work work ../components/square.vhd
vcom -work work ../components/multiply.vhd
vcom -work work ../components/addsub.vhd
vcom -work work ../components/read_iq.vhd
vcom -work work ../components/gain.vhd
vcom -work work ../components/fir.vhd
vcom -work work ../components/fir_decimated.vhd
vcom -work work ../components/fir_complex.vhd
vcom -work work ../components/iir.vhd
vcom -work work ../components/demodulate.vhd
vcom -work work ../components/radio.vhd
vcom -work work radio_tb.vhd

vsim +notimingchecks -L work work.radio_tb -wlf vsim.wlf

add wave -noupdate -group TEST_BENCH -radix hexadecimal /radio_tb/*
add wave -noupdate -expand -group TOP_LEVEL -radix hexadecimal /radio_tb/top_inst/*
add wave -noupdate -group INPUT_BUFFER -radix hexadecimal /radio_tb/top_inst/input_buffer/*
add wave -noupdate -group INPUT_READ -radix hexadecimal /radio_tb/top_inst/input_read/*
add wave -noupdate -group I_BUFFER -radix hexadecimal /radio_tb/top_inst/i_buffer/*
add wave -noupdate -group Q_BUFFER -radix hexadecimal /radio_tb/top_inst/q_buffer/*
add wave -noupdate -group CHANNEL_FILTER -radix hexadecimal /radio_tb/top_inst/channel_filter/*
add wave -noupdate -group I_FILTERED_BUFFER -radix hexadecimal /radio_tb/top_inst/i_filtered_buffer/*
add wave -noupdate -group Q_FILTERED_BUFFER -radix hexadecimal /radio_tb/top_inst/q_filtered_buffer/*
add wave -noupdate -group DEMODULATOR -radix hexadecimal /radio_tb/top_inst/demodulator/*
add wave -noupdate -group DEMODULATOR -radix hexadecimal /radio_tb/top_inst/demodulator/demod_process/*
add wave -noupdate -group RIGHT_LOW_FILTER -radix hexadecimal /radio_tb/top_inst/right_low_filter/*
add wave -noupdate -group LEFT_BAND_FILTER -radix hexadecimal /radio_tb/top_inst/left_band_filter/*
add wave -noupdate -group PILOT_FILTER -radix hexadecimal /radio_tb/top_inst/pilot_filter/*
add wave -noupdate -group SQUARER -radix hexadecimal /radio_tb/top_inst/squarer/*
add wave -noupdate -group PILOT_SQUARED_FILTER -radix hexadecimal /radio_tb/top_inst/pilot_squared_filter/*

add wave -noupdate -group MULTIPLIER -radix hexadecimal /radio_tb/top_inst/multiplier/*
add wave -noupdate -group LEFT_LOW_FILTER -radix hexadecimal /radio_tb/top_inst/left_low_filter/*
add wave -noupdate -group ADDER_SUBTRACTOR -radix hexadecimal /radio_tb/top_inst/adder_subtractor/*
add wave -noupdate -group DEEMPHASIZE_LEFT -radix hexadecimal /radio_tb/top_inst/deemphasize_left/*
add wave -noupdate -group DEEMPHASIZE_RIGHT -radix hexadecimal /radio_tb/top_inst/deemphasize_right/*
add wave -noupdate -group GAIN_LEFT -radix hexadecimal /radio_tb/top_inst/gain_left/*
add wave -noupdate -group GAIN_RIGHT -radix hexadecimal /radio_tb/top_inst/gain_right/*

#run -all
run 500 ns

configure wave -namecolwidth 325
configure wave -valuecolwidth 100
configure wave -timelineunits ns
WaveRestoreZoom {0 ns} {80 ns}

