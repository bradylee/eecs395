library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants.all;

entity sramb is
generic (
	constant SIZE : integer := 1024;
	constant AWIDTH : integer := 10; -- address width
	constant DWIDTH : integer := 32 -- data width
);
port (
	signal clock : in std_logic;
	signal rd_addr : in std_logic_vector (AWIDTH - 1 downto 0);
	signal wr_addr : in std_logic_vector (AWIDTH - 1 downto 0);
	signal wr_en : in std_logic;
	signal dout : out std_logic_vector (DWIDTH - 1 downto 0);
	signal din : std_logic_vector (DWIDTH - 1 downto 0)
);
end entity;

architecture behavior of sramb is
	function to01(input : std_logic_vector)
		return std_logic_vector is
	begin
		return std_logic_vector(to_01(unsigned(input)));
	end to01;

	type ARRAY_SLV is array (natural range<>) of std_logic_vector (DWIDTH - 1 downto 0);
	signal mem : ARRAY_SLV (0 to SIZE - 1);
	signal read_addr : std_logic_vector (AWIDTH - 1 downto 0) := (others => '0');
	
begin
	sramb_write_process : process(clock)
	begin
		if (rising_edge(clock)) then
			if (wr_en = '1') then
				mem(to_integer(unsigned(to01(wr_addr)))) <= to01(din);
			end if;
			read_addr <= rd_addr;
		end if;
	end process sramb_write_process;

	dout <= to01(mem(to_integer(unsigned(to01(read_addr)))));
end architecture;

