library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants.all;
use work.functions.all;
use work.dependent.all;

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
    signal state, next_state : standard_state_type := init;
begin

    read_process : process (state, iq_din, iq_empty, i_full, q_full)
        variable i : std_logic_vector (WORD_SIZE - 1 downto 0);
        variable q : std_logic_vector (WORD_SIZE - 1 downto 0);
        constant SHORT : natural := WORD_SIZE/2;
        constant BYTE : natural := SHORT/2;
    begin
        next_state <= state;

        iq_rd_en <= '0';
        i_wr_en <= '0';
        q_wr_en <= '0';
        i_dout <= (others => '0');
        q_dout <= (others => '0');

        i := (others => '0');
        q := (others => '0');

        case (state) is
            when init => 
                if (iq_empty = '0') then
                    next_state <= exec;
                end if;

            when exec =>
                if (iq_empty = '0' and i_full = '0' and q_full = '0') then
                    iq_rd_en <= '1';

                    -- read i
                    --i(BYTE*2 - 1 downto BYTE) := iq_din(BYTE*3 - 1 downto BYTE*2);
                    --i(BYTE - 1 downto 0) := iq_din(BYTE*4 - 1 downto BYTE*3);
                    i(SHORT - 1 downto 0) := iq_din(WORD_SIZE - 1 downto SHORT);
                    i(WORD_SIZE - 1 downto SHORT) := (others => i(SHORT - 1)); -- sign extend
                    i_dout <= std_logic_vector(QUANTIZE(signed(i)));
                    i_wr_en <= '1';

                    -- read q
                    --q(BYTE*2 - 1 downto BYTE) := iq_din(BYTE - 1 downto 0);
                    --q(BYTE - 1 downto 0) := iq_din(BYTE*2 - 1 downto BYTE);
                    q(SHORT - 1 downto 0) := iq_din(SHORT - 1 downto 0);
                    q(WORD_SIZE - 1 downto SHORT) := (others => q(SHORT - 1)); -- sign extend
                    q_dout <= std_logic_vector(QUANTIZE(signed(q)));
                    q_wr_en <= '1';
                end if;

            when others =>
                next_state <= init;

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
