library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package constants is

    component sramb is
        generic 
        (
            constant SIZE : integer := 1024;
            constant AWIDTH : integer := 10; -- address width
            constant DWIDTH : integer := 32 -- data width
        );
        port 
        (
            signal clock : in std_logic;
            signal rd_addr : in std_logic_vector (AWIDTH - 1 downto 0);
            signal wr_addr : in std_logic_vector (AWIDTH - 1 downto 0);
            signal din : in std_logic_vector (DWIDTH - 1 downto 0);
            signal dout : out std_logic_vector (DWIDTH - 1 downto 0);
            signal wr_en : in std_logic
        );
    end component;

    component sram is
        generic 
        (
            constant SIZE : integer := 1024;
            constant DWIDTH : integer := 32;
            constant AWIDTH : integer := 10;
            constant NUM_BLOCKS : integer := 4
        );
        port 
        (
            signal clock : in std_logic;
            signal rd_addr : in std_logic_vector (AWIDTH - 1 downto 0);
            signal wr_addr : in std_logic_vector (AWIDTH - 1 downto 0);
            signal din : in std_logic_vector (DWIDTH - 1 downto 0);
            signal dout : out std_logic_vector (DWIDTH - 1 downto 0);
            signal wr_en : in std_logic_vector (NUM_BLOCKS - 1 downto 0)
        );
    end component;

    component matrix_multiply is
        generic
        (
            DWIDTH : natural := 32;
            AWIDTH : natural := 6;
            N : natural := 8
        );
        port
        (
            signal clock : in std_logic;
            signal reset : in std_logic;
            signal start : in std_logic;
            signal done : out std_logic;

            signal a_dout : in std_logic_vector (DWIDTH - 1 downto 0);
            signal b_dout : in std_logic_vector (DWIDTH - 1 downto 0);
            signal c_din : out std_logic_vector (DWIDTH - 1 downto 0);

            signal a_rd_addr : out std_logic_vector (AWIDTH - 1 downto 0);
            signal b_rd_addr : out std_logic_vector (AWIDTH - 1 downto 0);
            signal c_wr_addr : out std_logic_vector (AWIDTH - 1 downto 0);
            signal c_wr_en : out std_logic
        );
    end component;

    component matrix_multiply_top is
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
    end component;
end package;
