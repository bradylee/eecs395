library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants.all;
use work.functions.all;

entity addsub is
    port 
    (
        clock : in std_logic;
        reset : in std_logic;
        left_din : in std_logic_vector (WORD_SIZE - 1 downto 0);
        right_din : in std_logic_vector (WORD_SIZE - 1 downto 0);
        left_in_empty : in std_logic;
        right_in_empty : in std_logic;
        left_out_full : in std_logic;
        right_out_full : in std_logic;
        left_in_rd_en : out std_logic;
        right_in_rd_en : out std_logic;
        left_dout : out std_logic_vector (WORD_SIZE - 1 downto 0);
        right_dout : out std_logic_vector (WORD_SIZE - 1 downto 0);
        left_out_wr_en : out std_logic;
        right_out_wr_en : out std_logic
    );
end entity;

architecture behavioral of addsub is
    signal state, next_state : standard_state_type := init;
begin

    add_sub_process : process (state, left_din, right_din, left_in_empty, right_in_empty, left_out_full, right_out_full)
    begin
        next_state <= state;

        left_in_rd_en <= '0';
        right_in_rd_en <= '0';
        left_out_wr_en <= '0';
        right_out_wr_en <= '0';
        left_dout <= (others => '0');
        right_dout <= (others => '0');

        case (state) is
            when init =>
                if (left_in_empty = '0' and right_in_empty = '0') then
                    next_state <= exec;
                end if;

            when exec =>
                if (left_in_empty = '0' and right_in_empty = '0' and left_out_full = '0' and right_out_full = '0') then
                    left_in_rd_en <= '1';
                    right_in_rd_en <= '1';
                    left_dout <= std_logic_vector(signed(right_din) + signed(left_din));
                    right_dout <= std_logic_vector(signed(right_din) - signed(left_din));
                    left_out_wr_en <= '1';
                    right_out_wr_en <= '1';
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
