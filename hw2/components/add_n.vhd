library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants.all;

entity add_n is
generic (
	constant DWIDTH : integer := 32;
	constant AWIDTH : integer := 6;
	constant NUM_BLOCKS : integer := 4
);
port (
	signal clock : in std_logic;
	signal reset : in std_logic;
	signal start : in std_logic;
	signal done : out std_logic;

	signal x_dout : in std_logic_vector (DWIDTH - 1 downto 0);
	signal y_dout : in std_logic_vector (DWIDTH - 1 downto 0);
	signal x_addr : out std_logic_vector (AWIDTH - 1 downto 0);
	signal y_addr : out std_logic_vector (AWIDTH - 1 downto 0);
	signal z_din : out std_logic_vector (DWIDTH - 1 downto 0);
	signal z_addr : out std_logic_vector (AWIDTH - 1 downto 0);
	signal z_wr_en : out std_logic_vector(NUM_BLOCKS - 1 downto 0)
);
end entity add_n;

architecture behavior of add_n is
	TYPE state_type is (s0, s1);
	signal state, next_state : state_type;
	signal i, i_c : std_logic_vector (AWIDTH - 1 downto 0);
	signal done_o, done_c : std_logic;
begin
	add_n_fsm_process : process(state, y_dout, x_dout, i, done_o, start)
		variable index : std_logic_vector (AWIDTH - 1 downto 0) := (others => '0');
	begin
		z_din <= (others => '0');
		z_wr_en <= (others => '0');
		z_addr <= (others => '0');
		x_addr <= (others => '0');
		y_addr <= (others => '0');
		i_c <= i;
		done_c <= done_o;
		next_state <= state;

		case (state) is
			when s0 =>
				i_c <= (others => '0');
				if (start = '1') then
					done_c <= '0';
					x_addr <= (others => '0');
					y_addr <= (others => '0');
					next_state <= s1;
				end if;
			when s1 =>
				z_din <= std_logic_vector(signed(y_dout) + signed(x_dout));
				z_addr <= i;
				z_wr_en <= (others => '1');
				index := std_logic_vector(unsigned(i) + 1);
				x_addr <= index;
				y_addr <= index;
				i_c <= index;
				if (unsigned(i) >= unsigned(to_signed(-1, AWIDTH))) then -- max unsigned value
					done_c <= '1';
					next_state <= s0;
				else
					next_state <= s1;
				end if;
				
			when others =>
				z_din <= (others => 'X');
				z_wr_en <= (others => 'X');
				z_addr <= (others => 'X');
				x_addr <= (others => 'X');
				y_addr <= (others => 'X');
				i_c <= (others => 'X');
				done_c <= 'X';
				next_state <= s0;
		end case;
	end process;
		
	add_n_reg_process: process(reset, clock) begin
		if (reset = '1') then
			state <= s0;
			i <= (others => '0');
			done_o <= '0';
		elsif (rising_edge(clock)) then
			state <= next_state;
			i <= i_c;
			done_o <= done_c;
		end if;
	end process;
	done <= done_o;
end architecture behavior;