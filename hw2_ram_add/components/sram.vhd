library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants.all;

entity sram is
generic (
	constant SIZE : integer := 1024;
	constant DWIDTH : integer := 32;
	constant AWIDTH : integer := 10;
	constant NUM_BLOCKS : integer := 4
);
port (
	signal clock : in std_logic;
	signal rd_addr : in std_logic_vector (AWIDTH - 1 downto 0);
	signal wr_addr : in std_logic_vector (AWIDTH - 1 downto 0);
	signal wr_en : in std_logic_vector (NUM_BLOCKS - 1 downto 0);
	signal dout : out std_logic_vector (DWIDTH - 1 downto 0);
	signal din : in std_logic_vector (DWIDTH - 1 downto 0)
);
end entity;

architecture behavior of sram is
	constant BLOCK_WIDTH : integer := DWIDTH / NUM_BLOCKS;
begin
	sram_block : for i in 0 to NUM_BLOCKS - 1 generate
		sramb_instance : component sramb
		generic map (
			size => SIZE,
			AWIDTH => AWIDTH,
			DWIDTH => BLOCK_WIDTH
		)
		port map (
			clock => clock,
			din => din((BLOCK_WIDTH * (i + 1)) - 1 downto 8*i),
			rd_addr => rd_addr(AWIDTH - 1 downto 0),
			wr_addr => wr_addr(AWIDTH - 1 downto 0),
			wr_en => wr_en(i),
			dout => dout((BLOCK_WIDTH * (i + 1)) - 1 downto 8*i)
		);
	end generate sram_block;		
end architecture;