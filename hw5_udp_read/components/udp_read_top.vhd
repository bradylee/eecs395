library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants.all;

entity udp_read_top is
    generic
    (
        DWIDTH : natural := 8;
        BUFFER_SIZE : natural := 1024;
        LENGTH_BUFFER_SIZE : natural := 16
    );
    port
    (
        input_clk : in std_logic;
        internal_clk : in std_logic;
        output_clk : in std_logic;
        reset : in std_logic;
        input_wr_en : in std_logic;
        output_rd_en : in std_logic;
        len_rd_en : in std_logic;
        din : in std_logic_vector (DWIDTH - 1 downto 0);
        dout : out std_logic_vector (DWIDTH - 1 downto 0);
        length : out std_logic_vector (UDP_LENGTH_BYTES * BYTE - 1 downto 0);
        input_full : out std_logic;
        output_empty : out std_logic;
        len_empty : out std_logic
    );
end entity;

architecture structural of udp_read_top is
    constant LENGTH_DWIDTH : natural := UDP_LENGTH_BYTES * BYTE;
    signal input_dout : std_logic_vector (DWIDTH - 1 downto 0) := (others => '0');
    signal output_din : std_logic_vector (DWIDTH - 1 downto 0) := (others => '0');
    signal len_din : std_logic_vector (LENGTH_DWIDTH - 1 downto 0) := (others => '0');
    signal input_rd_en : std_logic := '0';
    signal output_wr_en : std_logic := '0';
    signal input_empty : std_logic := '0';
    signal output_full : std_logic := '0';
    signal output_reset : std_logic := '0';
    signal buffer_reset : std_logic := '0';
    signal len_full : std_logic := '0';
    signal valid : std_logic := '0';
begin

    input_fifo : fifo
    generic map
    (
        DWIDTH => DWIDTH,
        BUFFER_SIZE => BUFFER_SIZE
    )
    port map
    (
        rd_clk => input_clk,
        wr_clk => internal_clk,
        reset => reset,
        rd_en => input_rd_en,
        wr_en => input_wr_en,
        din => din,
        dout => input_dout,
        full => input_full,
        empty => input_empty
    );

    output_fifo : fifo
    generic map
    (
        DWIDTH => DWIDTH,
        BUFFER_SIZE => BUFFER_SIZE
    )
    port map
    (
        rd_clk => internal_clk,
        wr_clk => output_clk,
        reset => output_reset,
        rd_en => output_rd_en,
        wr_en => output_wr_en,
        din => output_din,
        dout => dout,
        full => output_full,
        empty => output_empty
    );

    length_fifo : fifo
    generic map
    (
        DWIDTH => LENGTH_DWIDTH,
        BUFFER_SIZE => LENGTH_BUFFER_SIZE
    )
    port map
    (
        rd_clk => internal_clk,
        wr_clk => output_clk,
        reset => reset,
        rd_en => len_rd_en,
        wr_en => valid,
        din => len_din,
        dout => length,
        full => len_full,
        empty => len_empty
    );

    reader : udp_read
    port map
    (
        clock => internal_clk,
        reset => reset,
        input_empty => input_empty,
        output_full => output_full,
        len_full => len_full,
        input_dout => input_dout,
        output_din => output_din,
        length => len_din,
        input_rd_en => input_rd_en,
        output_wr_en => output_wr_en,
        buffer_reset => buffer_reset,
        valid => valid
    );

    output_reset <= reset or buffer_reset;

end architecture;
