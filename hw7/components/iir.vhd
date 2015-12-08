library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants.all;

entity iir is
    generic
    (
        TAPS : natural := 20
    );
    port 
    (
        clock : in std_logic;
        reset : in std_logic;
        din : in std_logic_vector (WORD_SIZE - 1 downto 0);
        x_coeffs : in quant_array (0 to TAPS - 1);
        y_coeffs : in quant_array (0 to TAPS - 1);
        empty : in std_logic;
        full : in std_logic;
        rd_en : out std_logic;
        dout : out std_logic_vector (WORD_SIZE - 1 downto 0);
        wr_en : out std_logic
    );
end entity;

architecture behavioral of iir is
    signal state, next_state : standard_state_type := init;
    signal x_buffer, x_buffer_c : quant_array (0 to TAPS - 1);
    signal y_buffer, y_buffer_c : quant_array (0 to TAPS - 1);
begin

    filter_process : process (state, x_buffer, y_buffer, din, in_empty)
        variable sum_x, sum_y : unsigned (WORD_SIZE - 1 downto 0) := (others => '0');
    begin
        next_state <= state;
        x_buffer_c <= x_buffer;
        y_buffer_c <= y_buffer;

        rd_en <= '0';
        wr_en <= '0';
        dout <= (others => '0');

        case (state) is
            when init =>
                if (in_empty = '0') then
                    next_state <= exec;
                end if;

            when exec =>
                if (in_empty = '0' and out_full = '0') then
                    rd_en <= '1';

                    -- shift x buffer
                    for i in TAPS - 1 to 1 loop
                        x_buffer_c(i) <= x_buffer(i - 1);
                    end loop;
                    x_buffer_c(0) <= din; 

                    for i in 0 to TAPS - 1 loop
                        sum_x := sum_x + DEQUANTIZE(unsigned(x_coeffs(i)) * unsigned(x_buffer(i)));
                        sum_y := sum_y + DEQUANTIZE(unsigned(y_coeffs(i)) * unsigned(y_buffer(i)));
                    end loop;

                    -- shift y buffer
                    for i in TAPS - 1 to 1 loop
                        y_buffer_c(i) <= y_buffer(i - 1);
                    end loop;
                    y_buffer_c(0) <= std_logic_vector(unsigned(sum_x) + unsigned(sum_y)); 

                    dout <= y_buffer(TAPS - 1);
                    wr_en <= '1';
                end if;

            when others =>
                next_state <= state;

        end case;
    end process;

    clock_process : process (clock, reset)
    begin 
        if (reset = '1') then
            state <= init;
            x_buffer <= (others => (others => '0'));
            y_buffer <= (others => (others => '0'));
        elsif (rising_edge(clock)) then
            state <= next_state;
            x_buffer <= x_buffer_c;
            y_buffer <= y_buffer_c;
        end if;
    end process;

end architecture;
