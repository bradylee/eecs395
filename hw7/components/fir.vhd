library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants.all;

entity fir is
    generic
    (
        TAPS : natural := 20;
        DECIMATION : natural := 1
    );
    port 
    (
        clock : in std_logic;
        reset : in std_logic;
        din : in std_logic_vector (WORD_SIZE - 1 downto 0);
        coeffs : in quant_array (0 to TAPS - 1);
        empty : in std_logic;
        full : in std_logic;
        rd_en : out std_logic;
        dout : out std_logic_vector (WORD_SIZE - 1 downto 0);
        wr_en : out std_logic
    );
end entity;

architecture behavioral of fir is
    signal state, next_state : standard_state_type := init;
    signal data_buffer, data_buffer_c : quant_array (0 to TAPS - 1);
    signal dec_count, dec_count_c : natural;
begin

    filter_process : process (state, data_buffer, dec_count, din, empty)
        variable sum : unsigned (WORD_SIZE - 1 downto 0) := (others => '0');
    begin
        next_state <= state;
        data_buffer_c <= data_buffer;
        dec_count_c <= dec_count;

        rd_en <= '0';
        wr_en <= '0';
        dout <= (others => '0');

        case (state) is
            when init =>
                if (empty = '0') then
                    dec_count_c <= 0;
                    next_state <= exec;
                end if;

            when exec =>
                if (empty = '0') then
                    rd_en <= '1';
                    -- shift buffers
                    for i in TAPS - 1 to 1 loop
                        data_buffer_c(i) <= data_buffer(i - 1);
                    end loop;
                    data_buffer_c(0) <= din;

                    dec_count_c <= dec_count + 1;
                    if (dec_count = DECIMATION - 1) then
                        dec_count_c <= 0;

                        for i in 0 to TAPS - 1 loop
                            sum := sum + DEQUANTIZE(unsigned(coeffs(TAPS - 1 - i)) * unsigned(data_buffer(i)));
                        end loop;

                        -- TODO: check if output full?
                        dout <= std_logic_vector(sum);
                        wr_en <= '1';
                    end if;
                end if;

            when others =>
                next_state <= state;

        end case;
    end process;

    clock_process : process (clock, reset)
    begin 
        if (reset = '1') then
            state <= init;
            data_buffer <= (others => (others => '0'));
            dec_count <= 0;
        elsif (rising_edge(clock)) then
            state <= next_state;
            data_buffer <= data_buffer_c;
            dec_count <= dec_count_c;
        end if;
    end process;

end architecture;
