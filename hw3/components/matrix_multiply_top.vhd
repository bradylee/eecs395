library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants.all;

entity matrix_multiply_top is
    generic 
    (
        DWIDTH : natural := 32;
        AWIDTH : natural := 6;
        N : natural := 8;
        NUM_BLOCKS : natural := 4
    );
    port 
    (
        signal clock : in std_logic;
        signal reset : in std_logic;
        signal start : in std_logic;
        signal done : out std_logic;

        signal a_din : in std_logic_vector (DWIDTH - 1 downto 0);
        signal b_din : in std_logic_vector (DWIDTH - 1 downto 0);
        signal c_dout : out std_logic_vector (DWIDTH - 1 downto 0);

        signal a_wr_addr : in std_logic_vector (AWIDTH - 1 downto 0);
        signal b_wr_addr : in std_logic_vector (AWIDTH - 1 downto 0);
        signal c_rd_addr : in std_logic_vector (AWIDTH - 1 downto 0);

        signal a_wr_en : in std_logic_vector (NUM_BLOCKS - 1 downto 0);
        signal b_wr_en : in std_logic_vector (NUM_BLOCKS - 1 downto 0)
);
end entity;

architecture behavioral of matrix_multiply_top is
    signal a_dout, b_dout, c_din : std_logic_vector (DWIDTH - 1 downto 0);
    signal a_rd_addr, b_rd_addr, c_wr_addr : std_logic_vector (AWIDTH - 1 downto 0);
    signal c_wr_en : std_logic;
    signal c_wr_en_vec : std_logic_vector (NUM_BLOCKS - 1 downto 0);
begin

    mat_a : component sram
    generic map 
    (
        SIZE => N ** 2,
        DWIDTH => DWIDTH,
        AWIDTH => AWIDTH,
        NUM_BLOCKS => NUM_BLOCKS
    )
    port map 
    (
        clock => clock,
        rd_addr => a_rd_addr,
        wr_addr => a_wr_addr,
        dout => a_dout,
        din => a_din,
        wr_en => a_wr_en 
    );

    mat_b : component sram
    generic map 
    (
        SIZE => N ** 2,
        DWIDTH => DWIDTH,
        AWIDTH => AWIDTH
    )
    port map 
    (
        clock => clock,
        rd_addr => b_rd_addr,
        wr_addr => b_wr_addr,
        dout => b_dout,
        din => b_din,
        wr_en => b_wr_en 
    );

    mat_c : component sram
    generic map 
    (
        SIZE => N ** 2,
        DWIDTH => DWIDTH,
        AWIDTH => AWIDTH
    )
    port map 
    (
        clock => clock,
        rd_addr => c_rd_addr,
        wr_addr => c_wr_addr,
        dout => c_dout,
        din => c_din, 
        wr_en => c_wr_en_vec
    );

    matmul : component matrix_multiply
    generic map
    (
        DWIDTH => DWIDTH,
        AWIDTH => AWIDTH,
        N => N
    )
    port map
    (
        clock => clock, 
        reset => reset, 
        start => start,
        done => done,
        a_dout => a_dout,
        b_dout => b_dout,
        c_din => c_din,
        a_rd_addr => a_rd_addr,
        b_rd_addr => b_rd_addr,
        c_wr_addr => c_wr_addr,
        c_wr_en => c_wr_en
    );

    c_wr_en_vec <= (others => c_wr_en); 

end architecture;
