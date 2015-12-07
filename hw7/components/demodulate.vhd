library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants.all;

entity demodulate is
    --generic
    --(
    --    GAIN : natural := 20 -- TODO: not correct default
    --);
    port 
    (
        clock : in std_logic;
        reset : in std_logic;
        real_din : in std_logic_vector (WORD_SIZE - 1 downto 0);
        imag_din : in std_logic_vector (WORD_SIZE - 1 downto 0);
        real_empty : in std_logic;
        imag_empty : in std_logic;
        demod_full : out std_logic;
        real_rd_en : out std_logic;
        imag_rd_en : out std_logic;
        demod_dout : out std_logic_vector (WORD_SIZE - 1 downto 0);
        demod_wr_en : in std_logic
    );
end entity;

architecture behavioral of demodulate is
    signal state, next_state : standard_state_type := init;
    signal real_prev, real_prev_c : std_logic_vector (WORD_SIZE - 1 downto 0);
    signal imag_prev, imag_prev_c : std_logic_vector (WORD_SIZE - 1 downto 0);
begin

    filter_process : process (state, real_din, imag_din, real_empty, imag_empty)
        variable r, i : std_logic_vector (WORD_SIZE - 1 downto 0) := (others => '0');
    begin
        next_state <= state;

        real_rd_en <= '0';
        imag_rd_en <= '0';
        demod_wr_en <= '0';
        demod_dout <= (others => '0');

        case (state) is
            when init =>
                if (real_empty = '0' and imag_empty = '0') then
                    real_prev <= (others => '0');
                    imag_prev <= (others => '0');
                    next_state <= exec;
                end if;

            when exec =>
                if (real_empty = '0' and imag_empty = '0') then
                    real_rd_en <= '1';
                    imag_rd_en <= '1';

                    r = DEQUANTIZE(unsigned(real_din) * unsigned(real_prev)) + DEQUANTIZE(unsigned(imag_din) * unsigned(imag_prev));
                    i = DEQUANTIZE(unsigned(imag_din) * unsigned(real_prev)) - DEQUANTIZE(unsigned(real_din) * unsigned(imag_prev));

                    demod_dout <= DEQUANTIZE(gain * QARCTAN(i, r));

                -- QARCTAN
                -- const int quad1 = QUANTIZE_F(PI / 4.0);
                -- const int quad3 = QUANTIZE_F(3.0 * PI / 4.0);

                -- int abs_y = abs(y) + 1;
                -- int angle = 0;
                -- int r = 0;

                -- if ( x >= 0 ) 
                -- {
                -- r = QUANTIZE_I(x - abs_y) / (x + abs_y);
                -- angle = quad1 - DEQUANTIZE(quad1 * r);
                -- } 
                -- else 
                -- {
                -- r = QUANTIZE_I(x + abs_y) / (abs_y - x);
                -- angle = quad3 - DEQUANTIZE(quad1 * r);
                -- }

                -- return ((y < 0) ? -angle : angle);     // negate if in quad III or IV

                end if;

            when others =>
                next_state <= state;

        end case;
    end process;

    clock_process : process (clock, reset)
    begin 
        if (reset = '1') then
            state <= init;
            real_buffer <= (others => (others => '0'));
            imag_buffer <= (others => (others => '0'));
            dec_count <= 0;
        elsif (rising_edge(clock)) then
            state <= next_state;
            real_buffer <= real_buffer_c;
            imag_buffer <= imag_buffer_c;
            dec_count <= dec_count_c;
        end if;
    end process;

end architecture;
