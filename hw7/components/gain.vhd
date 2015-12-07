library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants.all;

entity gain is
    generic
    (
        MYSTERY : natural := 14
    );
    port 
    (
        clock : in std_logic;
        reset : in std_logic;
        volume : in integer;
        din : in std_logic_vector (WORD_SIZE - 1 downto 0);
        empty : in std_logic;
        full : in std_logic;
        rd_en : out std_logic;
        dout : out std_logic_vector (WORD_SIZE - 1 downto 0);
        wr_en : out std_logic
    );
end entity;

architecture behavioral of gain is
    signal state, next_state : standard_state_type := init;
begin

    gain_process : process (state, din, in_empty)
    begin
        next_state <= state;

        rd_en <= '0';
        wr_en <= '0';
        dout <= (others => '0');

        case (state) is
            when init =>
                if (in_empty = '0') then
                    next_state <= exec;
                end if;

            when exec =>
                if (in_empty = '0') then
                    rd_en <= '1';
                    dout <= std_logic_vector(DEQUANTIZE(unsigned(din) * volume) sll (MYSTERY - FRAC_BITS));
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
        elsif (rising_edge(clock)) then
            state <= next_state;
        end if;
    end process;

end architecture;
