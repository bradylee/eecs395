library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants.all;

entity radio is
    generic
    (
        BUFFER_SIZE : integer := 2048;
        DECIMATION : integer := 1
    );
    port 
    (
        clock : in std_logic;
        reset : in std_logic;
        volume : in integer;
        signal_din : in std_logic_vector (WORD_SIZE - 1 downto 0);
        signal_empty : in std_logic;
        left_full : in std_logic;
        right_full : in std_logic;
        signal_rd_en : out std_logic;
        left_dout : out std_logic_vector (WORD_SIZE - 1 downto 0);
        right_dout : out std_logic_vector (WORD_SIZE - 1 downto 0);
        left_wr_en : out std_logic;
        right_wr_en : out std_logic;
);
end entity;

architecture structural of radio is
    signal i_din, i_dout : std_logic_vector (WORD_SIZE - 1 downto 0);
    signal q_din, q_dout : std_logic_vector (WORD_SIZE - 1 downto 0);
    signal i_empty, i_full : std_logic;
    signal q_empty, q_full : std_logic;
    signal i_rd_en, i_wr_en : std_logic;
    signal q_rd_en, q_wr_en : std_logic;
    signal i_filtered : std_logic_vector (WORD_SIZE - 1 downto 0);
    signal q_filtered : std_logic_vector (WORD_SIZE - 1 downto 0);
    signal demodulated : std_logic_vector (WORD_SIZE - 1 downto 0);
    signal demod_wr_en : std_logic;
    signal pre_pilot_dout : std_logic_vector (WORD_SIZE - 1 downto 0);
    signal pre_pilot_empty, pre_pilot_full : std_logic;
    signal pre_pilot_rd_en, pre_pilot_wr_en : std_logic;
    signal pilot_filtered : std_logic_vector (WORD_SIZE - 1 downto 0);
    signal pilot_squared : std_logic_vector (WORD_SIZE - 1 downto 0);
    signal post_pilot_din : std_logic_vector (WORD_SIZE - 1 downto 0);
    signal pilot : std_logic_vector (WORD_SIZE - 1 downto 0);
    signal post_pilot_empty, post_pilot_full : std_logic;
    signal post_pilot_rd_en, post_pilot_wr_en : std_logic;
    signal left_channel_dout : std_logic_vector (WORD_SIZE - 1 downto 0);
    signal left_channel_empty, left_channel_full : std_logic;
    signal left_channel_rd_en, left_channel_wr_en : std_logic;
    signal left_band : std_logic_vector (WORD_SIZE - 1 downto 0);
    signal left_multiplied : std_logic_vector (WORD_SIZE - 1 downto 0);
    signal left_low : std_logic_vector (WORD_SIZE - 1 downto 0);
    signal right_channel_dout : std_logic_vector (WORD_SIZE - 1 downto 0);
    signal right_channel_empty, right_channel_full : std_logic;
    signal right_channel_rd_en, right_channel_wr_en : std_logic;
    signal right_low : std_logic_vector (WORD_SIZE - 1 downto 0);
    signal left_emph : std_logic_vector (WORD_SIZE - 1 downto 0);
    signal right_emph : std_logic_vector (WORD_SIZE - 1 downto 0);
    signal left_deemph : std_logic_vector (WORD_SIZE - 1 downto 0);
    signal right_deemph : std_logic_vector (WORD_SIZE - 1 downto 0);
begin

    input_read : read_iq
    port map
    (
        clock => clock,
        reset => reset,
        iq_din => signal_din,
        iq_empty => signal_empty,
        i_full => i_full,
        q_full => q_full,
        iq_rd_en => signal_rd_en,
        i_wr_en => i_wr_en,
        q_wr_en => q_wr_en,
        i_dout => i_din,
        q_dout => q_din
    );

    i_buffer : fifo
    generic map
    (
        DWIDTH => WORD_SIZE,
        BUFFER_SIZE => BUFFER_SIZE
    )
    port map
    (
        rd_clk => clock,
        wr_clk => clock,
        reset => reset,
        rd_en => i_rd_en,
        wr_en => i_wr_en,
        din => i_din,
        dout => i_dout,
        full => i_full,
        empty => i_empty
    );

    q_buffer : fifo
    generic map
    (
        DWIDTH => WORD_SIZE,
        BUFFER_SIZE => BUFFER_SIZE
    )
    port map
    (
        rd_clk => clock,
        wr_clk => clock,
        reset => reset,
        rd_en => q_rd_en,
        wr_en => q_wr_en,
        din => q_din,
        dout => q_dout,
        full => q_full,
        empty => q_empty
    );

    channel_filter : fir_complex
    generic map
    (
        TAPS => CHANNEL_COEFF_TAPS,
        DECIMATION => DECIMATION
    )
    port map
    (
        clock => clock,
        reset => reset,
        real_din => i_dout,
        imag_din => q_dout,
        real_in_empty => i_empty,
        imag_in_empty => q_empty,
        -- out full
        real_rd_en => i_rd_en,
        imag_rd_en => q_rd_en,
        real_dout => i_filtered,
        imag_dout => q_filtered
        -- wr_en
    );

    demodulator : demodulate
    port map
    (
        clock => clock,
        reset => reset,
        real_din => i_filtered,
        imag_din => q_filtered,
        --real_empty => _empty,
        --imag_empty => _empty,
        --demod_full => _full,
        --real_rd_en => _rd_en,
        --imag_rd_en => _rd_en,
        demod_dout => demodulated,
        demod_wr_en => demod_wr_en
    );

    pre_pilot_buffer : fifo
    generic map
    (
        DWIDTH => WORD_SIZE,
        BUFFER_SIZE => BUFFER_SIZE
    )
    port map
    (
        rd_clk => clock,
        wr_clk => clock,
        reset => reset,
        rd_en => pre_pilot_rd_en,
        wr_en => pre_pilot_wr_en,
        din => demodulated,
        dout => pre_pilot_dout,
        full => pre_pilot_full,
        empty => pre_pilot_empty
    );

    pilot_filter : fir
    generic map
    (
        TAPS => BP_PILOT_COEFF_TAPS,
        DECIMATION => DECIMATION,
    )
    port map
    (
        clock => clock,
        reset => reset,
        din => pre_pilot_dout,
        coeffs => BP_PILOT_COEFFS,
        empty => pre_pilot_empty,
        full => '0',
        rd_en => pre_pilot_rd_en,
        dout => pilot_filtered,
        wr_en => '-'
    );

    squarer : arithmetic
    generic map
    (
        ACTION => multiply
    )
    port map
    (
        clock => clock,
        reset => reset,
        x_din => pilot_filtered,
        y_din => pilot_filtered,
        x_empty => '0',
        y_empty => '0',
        z_full => '0',
        x_rd_en => '-',
        y_rd_en => '-',
        z_dout => pilot_squared,
        z_wr_en => '-'
    );

    pilot_squared_filter : fir
    generic map
    (
        TAPS => HP_COEFF_TAPS,
        DECIMATION => DECIMATION,
    )
    port map
    (
        clock => clock,
        reset => reset,
        din => pilot_squared,
        coeffs => HP_COEFFS,
        empty => '0',
        full => post_pilot_full,
        rd_en => '-',
        dout => post_pilot_din,
        wr_en => post_pilot_wr_en
    );

    post_pilot_buffer : fifo
    generic map
    (
        DWIDTH => WORD_SIZE,
        BUFFER_SIZE => BUFFER_SIZE
    )
    port map
    (
        rd_clk => clock,
        wr_clk => clock,
        reset => reset,
        rd_en => post_pilot_rd_en,
        wr_en => post_pilot_wr_en,
        din => post_pilot_din,
        dout => pilot,
        full => post_pilot_full,
        empty => post_pilot_empty
    );

    left_channel_buffer : fifo
    generic map
    (
        DWIDTH => WORD_SIZE,
        BUFFER_SIZE => BUFFER_SIZE
    )
    port map
    (
        rd_clk => clock,
        wr_clk => clock,
        reset => reset,
        rd_en => left_channel_rd_en,
        wr_en => left_channel_wr_en,
        din => demodulated,
        dout => left_channel_dout,
        full => left_channel_full,
        empty => left_channel_empty
    );

    left_band_filter : fir
    generic map
    (
        TAPS => BP_LMR_COEFF_TAPS,
        DECIMATION => DECIMATION,
    )
    port map
    (
        clock => clock,
        reset => reset,
        din => left_channel_dout,
        coeffs => BP_LMR_COEFFS,
        empty => left_channel_empty,
        full => '0',
        rd_en => left_channel_rd_en,
        dout => left_band,
        wr_en => '-' 
    );

    multiplier : arithmetic
    generic map
    (
        ACTION => multiply
    )
    port map
    (
        clock => clock,
        reset => reset,
        x_din => left_band,
        y_din => pilot,
        x_empty => '0',
        y_empty => '0',
        z_full => '0',
        x_rd_en => '-',
        y_rd_en => '-',
        z_dout => left_multiplied,
        z_wr_en => '-'
    );

    left_low_filter : fir
    generic map
    (
        TAPS => ,
        DECIMATION => DECIMATION,
    )
    port map
    (
        clock => clock,
        reset => reset,
        din => left_multiplied,
        coeffs => ,
        empty => '0',
        full => '0',
        rd_en => '-',
        dout => left_low,
        wr_en => '-'
    );

    right_channel_buffer : fifo
    generic map
    (
        DWIDTH => WORD_SIZE,
        BUFFER_SIZE => BUFFER_SIZE
    )
    port map
    (
        rd_clk => clock,
        wr_clk => clock,
        reset => reset,
        rd_en => right_channel_rd_en,
        wr_en => right_channel_wr_en,
        din => demodulated,
        dout => right_channel_dout,
        full => right_channel_full,
        empty => right_channel_empty
    );

    right_low_filter : fir
    generic map
    (
        TAPS => ,
        DECIMATION => DECIMATION,
    )
    port map
    (
        clock => clock,
        reset => reset,
        din => right_channel_dout,
        coeffs => ,
        empty => right_channel_empty,
        full => '0',
        rd_en => right_channel_rd_en,
        dout => right_low,
        wr_en => '-'
    );

    adder : arithmetic
    generic map
    (
        ACTION => add
    )
    port map
    (
        clock => clock,
        reset => reset,
        x_din => left_low,
        y_din => right_low,
        x_empty => '0',
        y_empty => '0',
        z_full => '0',
        x_rd_en => '-',
        y_rd_en => '-',
        z_dout => left_emph,
        z_wr_en => '-'
    );

    subtractor : arithmetic
    generic map
    (
        ACTION => subtract 
    )
    port map
    (
        clock => clock,
        reset => reset,
        x_din => left_low,
        y_din => right_low,
        x_empty => '0',
        y_empty => '0',
        z_full => '0',
        x_rd_en => '-',
        y_rd_en => '-',
        z_dout => right_emph,
        z_wr_en => '-'
    );

    deemphasize_left : iir
    generic map
    (
        TAPS => IIR_COEFF_TAPS,
        DECIMATION => DECIMATION
    )
    port map
    (
        clock => clock,
        reset => reset,
        din => left_emph, 
        x_coeffs => IIR_X_COEFFS,
        y_coeffs => IIR_Y_COEFFS,
        empty => '0',
        full => '0',
        rd_en => '-',
        dout => left_deemph,
        wr_en => '-'
    );

    deemphasize_right : iir
    generic map
    (
        TAPS => IIR_COEFF_TAPS,
        DECIMATION => DECIMATION
    )
    port map
    (
        clock => clock,
        reset => reset,
        din => right_emph, 
        x_coeffs => IIR_X_COEFFS,
        y_coeffs => IIR_Y_COEFFS,
        empty => '0',
        full => '0',
        rd_en => '-',
        dout => right_deemph,
        wr_en => '-'
    );

    gain_left : gain
    port map
    (
        clock => clock,
        reset => reset,
        volume => volume,
        din => _din,
        empty => _empty,
        full => left_full,
        rd_en => _rd_en,
        dout => left_dout,
        wr_en => left_wr_en
    );

    gain_right : gain
    port map
    (
        clock => clock,
        reset => reset,
        volume => volume,
        din => _din,
        empty => _empty,
        full => right_full,
        rd_en => _rd_en,
        dout => right_dout,
        wr_en => right_wr_en
    );

end architecture;
