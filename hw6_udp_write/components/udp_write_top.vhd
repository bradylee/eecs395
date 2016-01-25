library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants.all;

entity udp_write_top is
    generic
    (
        DWIDTH : natural := 8;
        BUFFER_SIZE : natural := 1024
    );
    port
    (
        input_clk : in std_logic;
        internal_clk : in std_logic;
        output_clk : in std_logic;
        reset : in std_logic;
        eth_src_addr : in std_logic_vector (ETH_SRC_ADDR_BYTES * BYTE - 1 downto 0);
        eth_dst_addr : in std_logic_vector (ETH_DST_ADDR_BYTES * BYTE - 1 downto 0);
        ip_src_addr : in std_logic_vector (IP_SRC_ADDR_BYTES * BYTE - 1 downto 0);
        ip_dst_addr : in std_logic_vector (IP_DST_ADDR_BYTES * BYTE - 1 downto 0);
        ip_id : in std_logic_vector (IP_ID_BYTES * BYTE - 1 downto 0);
        udp_src_port : in std_logic_vector (UDP_SRC_PORT_BYTES * BYTE - 1 downto 0);
        udp_dst_port : in std_logic_vector (UDP_SRC_PORT_BYTES * BYTE - 1 downto 0);
        input_wr_en : in std_logic;
        status_wr_en : in std_logic;
        output_rd_en : in std_logic;
        din : in std_logic_vector (DWIDTH - 1 downto 0);
        status_din : in std_logic_vector (STATUS_WIDTH - 1 downto 0);
        dout : out std_logic_vector (DWIDTH - 1 downto 0);
        input_full : out std_logic;
        status_full : out std_logic;
        output_empty : out std_logic
    );
end entity;

architecture structural of udp_write_top is
    signal input_dout : std_logic_vector (DWIDTH - 1 downto 0) := (others => '0');
    signal output_din : std_logic_vector (DWIDTH - 1 downto 0) := (others => '0');
    signal input_rd_en : std_logic := '0';
    signal output_wr_en : std_logic := '0';
    signal input_empty : std_logic := '0';
    signal output_full : std_logic := '0';
    signal status_rd_en : std_logic := '0';
    signal status_empty : std_logic := '0';
    signal status_dout :  std_logic_vector (STATUS_WIDTH - 1 downto 0) := (others => '0');
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

    status_fifo : fifo
    generic map
    (
        DWIDTH => STATUS_WIDTH,
        BUFFER_SIZE => BUFFER_SIZE
    )
    port map
    (
        rd_clk => input_clk,
        wr_clk => internal_clk,
        reset => reset,
        rd_en => status_rd_en,
        wr_en => status_wr_en,
        din => status_din,
        dout => status_dout,
        full => status_full,
        empty => status_empty
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
        reset => reset,
        rd_en => output_rd_en,
        wr_en => output_wr_en,
        din => output_din,
        dout => dout,
        full => output_full,
        empty => output_empty
    );

    writer : udp_write
    generic map
    (
        BUFFER_SIZE => BUFFER_SIZE
    )
    port map
    (
        clock => internal_clk,
        reset => reset,
        eth_src_addr => eth_src_addr,
        eth_dst_addr => eth_dst_addr,
        ip_src_addr => ip_src_addr,
        ip_dst_addr => ip_dst_addr,
        ip_id => ip_id,
        udp_src_port => udp_src_port,
        udp_dst_port => udp_dst_port,
        input_empty => input_empty,
        status_empty => status_empty,
        output_full => output_full,
        input_dout => input_dout,
        status_dout => status_dout,
        output_din => output_din,
        input_rd_en => input_rd_en,
        status_rd_en => status_rd_en,
        output_wr_en => output_wr_en
    );

end architecture;
