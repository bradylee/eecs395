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
    signal i, q : std_logic_vector (WORD_SIZE - 1 downto 0);
    signal i_filtered, q_filtered : std_logic_vector (WORD_SIZE - 1 downto 0);
begin

    input_read : read_iq
    port map
    (
        clock => clock,
        reset => reset,
        iq_din => signal_din,
        iq_empty => signal_empty,
        i_dout => i,
        q_dout => q
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
        real_din => i,
        imag_din => q,
        real_dout => i_filtered,
        imag_dout => q_filtered
    );

    demodulator : demodulate
    port map
    (
        clock => clock,
        reset => reset,
        real_din => _din,
        imag_din => _din,
        real_empty => _empty,
        imag_empty => _empty,
        demod_full => _full,
        real_rd_en => _rd_en,
        imag_rd_en => _rd_en,
        demod_dout => _dout,
        demod_wr_en => _wr_en
    );

    fir0 : fir
    generic map
    (
        TAPS => ,
        DECIMATION => DECIMATION,
    )
    port map
    (
        clock => clock,
        reset => reset,
        din => _din,
        coeffs => ,
        empty => _empty,
        full => _full,
        rd_en => _rd_en,
        dout => _dout,
        wr_en => _wr_en
    );

    fir1 : fir
    generic map
    (
        TAPS => ,
        DECIMATION => DECIMATION,
    )
    port map
    (
        clock => clock,
        reset => reset,
        din => _din,
        coeffs => ,
        empty => _empty,
        full => _full,
        rd_en => _rd_en,
        dout => _dout,
        wr_en => _wr_en
    );

    square : arithmetic
    generic map
    (
        ACTION => multiply
    )
    port map
    (
        clock => clock,
        reset => reset,
        x_din => _din,
        y_din => _din,
        x_empty => _empty,
        y_empty => _empty,
        z_full => _full,
        x_rd_en => _rd_en,
        y_rd_en => _rd_en,
        z_dout => _dout,
        z_wr_en => _wr_en
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
        x_din => _din,
        y_din => _din,
        x_empty => _empty,
        y_empty => _empty,
        z_full => _full,
        x_rd_en => _rd_en,
        y_rd_en => _rd_en,
        z_dout => _dout,
        z_wr_en => _wr_en
    );

    fir2 : fir
    generic map
    (
        TAPS => ,
        DECIMATION => DECIMATION,
    )
    port map
    (
        clock => clock,
        reset => reset,
        din => _din,
        coeffs => ,
        empty => _empty,
        full => _full,
        rd_en => _rd_en,
        dout => _dout,
        wr_en => _wr_en
    );

    fir3 : fir
    generic map
    (
        TAPS => ,
        DECIMATION => DECIMATION,
    )
    port map
    (
        clock => clock,
        reset => reset,
        din => _din,
        coeffs => ,
        empty => _empty,
        full => _full,
        rd_en => _rd_en,
        dout => _dout,
        wr_en => _wr_en
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
        x_din => _din,
        y_din => _din,
        x_empty => _empty,
        y_empty => _empty,
        z_full => _full,
        x_rd_en => _rd_en,
        y_rd_en => _rd_en,
        z_dout => _dout,
        z_wr_en => _wr_en
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
        x_din => _din,
        y_din => _din,
        x_empty => _empty,
        y_empty => _empty,
        z_full => _full,
        x_rd_en => _rd_en,
        y_rd_en => _rd_en,
        z_dout => _dout,
        z_wr_en => _wr_en
    );

    deemph_left : iir
    generic map
    (
        TAPS => ,
        DECIMATION => DECIMATION
    )
    port map
    (
        clock => clock,
        reset => reset,
        din => _din, 
        x_coeffs => ,
        y_coeffs => ,
        empty => _empty,
        full => _full,
        rd_en => _rd_en,
        dout => _dout,
        wr_en => _wr_en
    );

    deemph_right : iir
    generic map
    (
        TAPS => ,
        DECIMATION => DECIMATION
    )
    port map
    (
        clock => clock,
        reset => reset,
        din => _din, 
        x_coeffs => ,
        y_coeffs => ,
        empty => _empty,
        full => _full,
        rd_en => _rd_en,
        dout => _dout,
        wr_en => _wr_en
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
