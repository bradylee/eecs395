library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants.all;

entity read_iq is
    port 
    (
        clock : in std_logic;
        reset : in std_logic;
        iq_din : in std_logic_vector (WORD_SIZE - 1 downto 0);
        iq_empty : in std_logic;
        i_full : in std_logic;
        q_full : in std_logic;
        iq_rd_en : out std_logic;
        i_wr_en : out std_logic;
        q_wr_en : out std_logic;
        i_dout : out std_logic_vector (WORD_SIZE - 1 downto 0);
        q_dout : out std_logic_vector (WORD_SIZE - 1 downto 0)
    );
end entity;

architecture behavioral of read_iq is
    type read_state_type is (read_i, read_q);
    signal state, next_state : read_state_type := read_i;
begin

    read_process : process (state)
    begin
        next_state <= state;
        iq_rd_en <= '0';
        i_wr_en <= '0';
        q_wr_en <= '0';
        i_dout <= (others => '0');
        q_dout <= (others => '0');

        case (state) is
            when read_i =>
                if (iq_empty = '0' and i_full = '0') then
                    iq_rd_en <= '1';
                    i_dout <= QUANTIZE(iq_din);
                    i_wr_en <= '1';
                    next_state <= read_q;
                end if;

            when read_q =>
                if (iq_empty = '0' and q_full = '0') then
                    iq_rd_en <= '1';
                    q_dout <= QUANTIZE(iq_din);
                    q_wr_en <= '1';
                    next_state <= read_i;
                end if;

            when others =>
                next_state <= read_i;

        end case;
    end process;

    clock_process : process (clock, reset)
    begin 
        if (reset = '1') then
            state <= read_i;
        elsif (rising_edge(clock)) then
            state <= next_state;
        end if;
    end process;

end architecture;
