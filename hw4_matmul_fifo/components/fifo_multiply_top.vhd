library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants.all;

entity fifo_multiply_top is
    generic
    (
        N : natural := 8;
        BUFFER_SIZE : natural := 64;
        DWIDTH : natural := 32;
        AWIDTH : natural := 6
    );
    port
    (
        signal rd_clk : in std_logic;
        signal wr_clk : in std_logic;
        signal reset : in std_logic;
        signal done : out std_logic;

        signal a_din : in std_logic_vector (DWIDTH - 1 downto 0);
        signal b_din : in std_logic_vector (DWIDTH - 1 downto 0);
        signal c_dout : out std_logic_vector (DWIDTH - 1 downto 0);

        signal a_wr_en : in std_logic;
        signal b_wr_en : in std_logic;
        signal c_rd_en : in std_logic;

        signal a_full : out std_logic;
        signal b_full : out std_logic;
        signal c_empty : out std_logic 
    );
end entity;

architecture behavioral of fifo_multiply_top is
    signal a_dout, b_dout : std_logic_vector (DWIDTH - 1 downto 0);
    signal c_din : std_logic_vector (DWIDTH - 1 downto 0);
    signal a_rd_en, b_rd_en : std_logic;
    signal c_wr_en : std_logic;
    signal a_empty, b_empty : std_logic;
    signal c_empty_o : std_logic;
    signal a_full_o, b_full_o : std_logic;
    signal c_full : std_logic;
begin

    a_fifo : component fifo
    generic map
    (
        BUFFER_SIZE => BUFFER_SIZE,
        DWIDTH => DWIDTH,
        AWIDTH => AWIDTH
    )
    port map
    (
        rd_clk => rd_clk,
        wr_clk => wr_clk,
        reset => reset,
        rd_en => a_rd_en,
        wr_en => a_wr_en,
        din => a_din,
        dout => a_dout,
        full => a_full_o,
        empty => a_empty
    );

    b_fifo : component fifo
    generic map
    (
        BUFFER_SIZE => BUFFER_SIZE,
        DWIDTH => DWIDTH,
        AWIDTH => AWIDTH
    )
    port map
    (
        rd_clk => rd_clk,
        wr_clk => wr_clk,
        reset => reset,
        rd_en => b_rd_en,
        wr_en => b_wr_en,
        din => b_din,
        dout => b_dout,
        full => b_full_o,
        empty => b_empty
    );

    c_fifo : component fifo
    generic map
    (
        BUFFER_SIZE => BUFFER_SIZE,
        DWIDTH => DWIDTH,
        AWIDTH => AWIDTH
    )
    port map
    (
        rd_clk => rd_clk,
        wr_clk => wr_clk,
        reset => reset,
        rd_en => c_rd_en,
        wr_en => c_wr_en,
        din => c_din,
        dout => c_dout,
        full => c_full,
        empty => c_empty_o
    );

    multiply : component fifo_multiply
    generic map
    (
        N => N,
        DWIDTH => DWIDTH,
        AWIDTH => AWIDTH
    )
    port map
    (
        rd_clk => rd_clk,
        wr_clk => wr_clk,
        reset => reset,
        a_dout => a_dout,
        b_dout => b_dout,
        c_din => c_din,
        a_rd_en => a_rd_en,
        b_rd_en => b_rd_en,
        c_wr_en => c_wr_en,
        a_empty => a_empty,
        b_empty => b_empty,
        c_empty => c_empty_o,
        a_full => a_full_o,
        b_full => b_full_o,
        c_full => c_full,
        done => done
    );

    a_full <= a_full_o;
    b_full <= b_full_o;
    c_empty <= c_empty_o;

end architecture;
