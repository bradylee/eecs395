library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants.all;
use work.functions.all;
use work.dependent.all;

entity square is
    port 
    (
        clock : in std_logic;
        reset : in std_logic;
        x_din : in std_logic_vector (WORD_SIZE - 1 downto 0);
        x_empty : in std_logic;
        z_full : in std_logic;
        x_rd_en : out std_logic;
        z_dout : out std_logic_vector (WORD_SIZE - 1 downto 0);
        z_wr_en : out std_logic
    );
end entity;

architecture behavioral of square is
    signal state, next_state : standard_state_type := init;
begin

    square_process : process (state, x_din, x_empty, z_full)
    begin
        next_state <= state;

        x_rd_en <= '0';
        z_wr_en <= '0';
        z_dout <= (others => '0');

        case (state) is
            when init =>
                if (x_empty = '0') then
                    next_state <= exec;
                end if;

            when exec =>
                if (x_empty = '0' and z_full = '0') then
                    x_rd_en <= '1';
                    z_dout <= std_logic_vector(DEQUANTIZE(signed(x_din) * signed(x_din)));
                    z_wr_en <= '1';
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
