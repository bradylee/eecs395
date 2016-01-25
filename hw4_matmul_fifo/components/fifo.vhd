library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo is
    generic
    (
        constant DWIDTH : natural := 32;
        constant AWIDTH : natural := 6;
        constant BUFFER_SIZE : natural := 64
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
end entity;

architecture behavioral of fifo is
    type VECTOR_ARRAY is array (natural range <>) of std_logic_vector (DWIDTH - 1 downto 0);
    signal fifo_buffer, fifo_buffer_c : VECTOR_ARRAY (0 to BUFFER_SIZE - 1);
    signal rd_addr, rd_addr_c : std_logic_vector (AWIDTH - 1 downto 0) := (others => '0');
    signal wr_addr, wr_addr_c : std_logic_vector (AWIDTH - 1 downto 0) := (others => '0');
    signal full_o, empty_o : std_logic;
begin

    write_buffer_process : process (fifo_buffer, din, wr_addr, wr_en, full_o)
    begin
        fifo_buffer_c <= fifo_buffer;
        wr_addr_c <= wr_addr;
        if (wr_en = '1' and full_o = '0') then
            fifo_buffer_c(to_integer(unsigned(wr_addr))) <= din;
            wr_addr_c <= std_logic_vector(unsigned(wr_addr) + 1);
            if (unsigned(wr_addr) = BUFFER_SIZE - 1) then
                wr_addr_c <= (others => '0');
            end if;
        end if;
    end process;

    read_buffer_process : process (fifo_buffer, rd_addr, rd_en, empty_o)
    begin
        rd_addr_c <= rd_addr;
        dout <= (others => '0');
        if (rd_en = '1' and empty_o = '0') then
        dout <= fifo_buffer(to_integer(unsigned(rd_addr)));
            rd_addr_c <= std_logic_vector(unsigned(rd_addr) + 1);
            if (unsigned(rd_addr) = BUFFER_SIZE - 1) then
                rd_addr_c <= (others => '0');
            end if;
        end if;
    end process;

    write_clock_process : process (wr_clk, reset)
    begin
        if (reset = '1') then
            wr_addr <= (others => '0');    
        elsif (rising_edge(wr_clk)) then
            wr_addr <= wr_addr_c;
            fifo_buffer <= fifo_buffer_c;
        end if;
    end process;

    read_clock_process : process (rd_clk, reset)
    begin
        if (reset = '1') then
            rd_addr <= (others => '0');
        elsif (rising_edge(rd_clk)) then
            rd_addr <= rd_addr_c;
        end if;
    end process;

    full_o <= '1' when (unsigned(rd_addr) = unsigned(wr_addr) + 1) or (unsigned(rd_addr) = 0 and unsigned(wr_addr) = BUFFER_SIZE - 1) else
              '0';

    empty_o <= '1' when unsigned(wr_addr) = unsigned(rd_addr) else
               '0';

    full <= full_o;
    empty <= empty_o;

end architecture;

