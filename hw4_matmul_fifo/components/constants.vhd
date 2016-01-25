library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package constants is

    component fifo is
        generic
        (
            constant DWIDTH : integer := 32;
            constant AWIDTH : integer := 6;
            constant BUFFER_SIZE : integer := 64
        );
        port
        (
            signal rd_clk : in std_logic;
            signal wr_clk : in std_logic;
            signal reset : in std_logic;
            signal rd_en : in std_logic;
            signal wr_en : in std_logic;
            signal din : in std_logic_vector (DWIDTH - 1 downto 0);
            signal dout : out std_logic_vector (DWIDTH - 1 downto 0);
            signal full : out std_logic;
            signal empty : out std_logic
        );
    end component;

    component fifo_multiply is
        generic
        (
            N : natural := 8;
            DWIDTH : natural := 32;
            AWIDTH : natural := 6
        );
        port
        (
            signal rd_clk : in std_logic;
            signal wr_clk : in std_logic;
            signal reset : in std_logic;
            signal a_dout : in std_logic_vector (DWIDTH - 1 downto 0);
            signal b_dout : in std_logic_vector (DWIDTH - 1 downto 0);
            signal c_din : out std_logic_vector (DWIDTH - 1 downto 0);
            signal a_rd_en : out std_logic;
            signal b_rd_en : out std_logic;
            signal c_wr_en : out std_logic;
            signal a_empty : in std_logic;
            signal b_empty : in std_logic;
            signal c_empty : in std_logic;
            signal a_full : in std_logic;
            signal b_full : in std_logic;
            signal c_full : in std_logic;
            signal done : out std_logic
        );
    end component;

    component fifo_multiply_top is
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
    end component;

end package;
