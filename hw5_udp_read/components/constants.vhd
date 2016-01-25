library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package constants is

    -- constants
    constant LONG : natural := 32;
    constant WORD : natural := 16;
    constant BYTE : natural := 8;
    constant NIBBLE : natural := 4;

    constant START_OF_FRAME : natural := 16#02#;
    constant END_OF_FRAME : natural := 16#03#;

    constant IP_PROTOCOL_DEF : natural := 16#0800#;
    constant IP_VERSION_DEF : natural := 16#4#;
    constant IP_HEADER_LENGTH_DEF : natural := 16#5#;
    constant IP_TYPE_DEF : natural := 16#0#;
    constant IP_FLAGS_DEF : natural := 16#4#;
    constant TIME_TO_LIVE : natural := 16#e#;
    constant UDP_PROTOCOL_DEF : natural := 16#11#;

    constant PCAP_GLOBAL_HEADER_BYTES : natural := 24;
    constant PCAP_DATA_HEADER_BYTES : natural := 16;
    constant PCAP_DATA_LENGTH_BYTES : natural := 4;
    constant ETH_DST_ADDR_BYTES : natural := 6;
    constant ETH_SRC_ADDR_BYTES : natural := 6;
    constant ETH_PROTOCOL_BYTES : natural := 2;
    constant IP_VERSION_HEADER_BYTES : natural := 1;
    --    constant IP_VERSION_BYTES : natural := 1;
    --    constant IP_HEADER_BYTES : natural := 1;
    constant IP_TYPE_BYTES : natural := 1;
    constant IP_LENGTH_BYTES : natural := 2;
    constant IP_ID_BYTES : natural := 2;
    constant IP_FLAG_BYTES : natural := 2;
    constant IP_TIME_BYTES : natural := 1;
    constant IP_PROTOCOL_BYTES : natural := 1;
    constant IP_CHECKSUM_BYTES : natural := 2;
    constant IP_SRC_ADDR_BYTES : natural := 4;
    constant IP_DST_ADDR_BYTES : natural := 4;
    constant UDP_DST_PORT_BYTES : natural := 2;
    constant UDP_SRC_PORT_BYTES : natural := 2;
    constant UDP_LENGTH_BYTES : natural := 2;
    constant UDP_CHECKSUM_BYTES : natural := 2;

    constant UDP_SUBLENGTH : natural := UDP_CHECKSUM_BYTES + UDP_LENGTH_BYTES + UDP_DST_PORT_BYTES + UDP_SRC_PORT_BYTES;

    -- type declarations
    type udp_state_type is (init, read_eth_dst_addr, read_eth_src_addr, read_eth_protocol, read_ip_version_header, read_ip_type, read_ip_length, read_ip_id, read_ip_flag, read_ip_time, read_ip_protocol, read_ip_checksum, read_ip_src_addr, read_ip_dst_addr, read_udp_dst_port, read_udp_src_port, read_udp_length, read_udp_checksum, read_udp_data, write_udp_data);

    -- component declarations

    component fifo is
        generic
        (
            constant DWIDTH : natural := 32;
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
    end component;

    component udp_read is
        port
        (
            clock : in std_logic;
            reset : in std_logic;
            input_empty : in std_logic;
            output_full : in std_logic;
            len_full : in std_logic;
            input_dout : in std_logic_vector (BYTE - 1 downto 0);
            output_din : out std_logic_vector (BYTE - 1 downto 0);
            length : out std_logic_vector (UDP_LENGTH_BYTES * BYTE - 1 downto 0);
            input_rd_en : out std_logic;
            output_wr_en : out std_logic;
            buffer_reset : out std_logic;
            valid : out std_logic
        );
    end component;

    component udp_read_top is
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
    end component;

end package;
