library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package constants is

    constant LONG : natural := 32;
    constant WORD : natural := 16;
    constant BYTE : natural := 8;
    constant NIBBLE : natural := 4;

    constant START_OF_FRAME : natural := 16#02#;
    constant END_OF_FRAME : natural := 16#03#;
    constant STATUS_WIDTH : natural := 2;

    constant IP_ID_DEF : natural := 8189;

    constant IP_PROTOCOL_DEF : natural := 16#0800#;
    constant IP_VERSION_DEF : natural := 16#4#;
    constant IP_HEADER_LENGTH_DEF : natural := 16#5#;
    constant IP_TYPE_DEF : natural := 16#0#;
    constant IP_FLAG_DEF : natural := 16#4#;
    constant TIME_TO_LIVE : natural := 16#e#;
    constant UDP_PROTOCOL_DEF : natural := 16#11#;

    constant PCAP_GLOBAL_HEADER_BYTES : natural := 24;
    constant PCAP_DATA_HEADER_BYTES : natural := 16;
    constant PCAP_DATA_LENGTH_BYTES : natural := 4;

    constant ETH_DST_ADDR_BYTES : natural := 6;
    constant ETH_SRC_ADDR_BYTES : natural := 6;
    constant ETH_PROTOCOL_BYTES : natural := 2;
    constant IP_VERSION_HEADER_BYTES : natural := 1;
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

    constant PCAP_MAGIC_NUMBER_BYTES : natural := 32;
    constant PCAP_VERSION_MAJOR_BYTES : natural := 16;
    constant PCAP_VERSION_MINOR_BYTES : natural := 16;
    constant PCAP_ZONE_BYTES : natural := 32;
    constant PCAP_SIGFIGS_BYTES : natural := 32;
    constant PCAP_SNAP_LEN_BYTES : natural := 32;
    constant PCAP_NETWORK_BYTES : natural := 32;

    constant PCAP_MAGIC_NUMBER : std_logic_vector (PCAP_MAGIC_NUMBER_BYTES - 1 downto 0) := X"a1b2c3d4";
    constant PCAP_VERSION_MAJOR : std_logic_vector (PCAP_VERSION_MAJOR_BYTES - 1 downto 0) := X"0002";
    constant PCAP_VERSION_MINOR : std_logic_vector (PCAP_VERSION_MINOR_BYTES - 1 downto 0) := X"0004";
    constant PCAP_ZONE : std_logic_vector (PCAP_ZONE_BYTES - 1 downto 0) := (others => '0');
    constant PCAP_SIGFIGS : std_logic_vector (PCAP_SIGFIGS_BYTES - 1 downto 0) := (others => '0');
    constant PCAP_SNAP_LEN : std_logic_vector (PCAP_SNAP_LEN_BYTES - 1 downto 0) := std_logic_vector(to_unsigned(65536, PCAP_SNAP_LEN_BYTES));
    constant PCAP_NETWORK : std_logic_vector (PCAP_NETWORK_BYTES - 1 downto 0) := X"00000001";

    constant PACKET_LENGTH : natural := ETH_DST_ADDR_BYTES + ETH_SRC_ADDR_BYTES + ETH_PROTOCOL_BYTES + IP_VERSION_HEADER_BYTES + IP_TYPE_BYTES + IP_LENGTH_BYTES + IP_ID_BYTES + IP_FLAG_BYTES + IP_TIME_BYTES + IP_PROTOCOL_BYTES + IP_CHECKSUM_BYTES + IP_SRC_ADDR_BYTES + IP_DST_ADDR_BYTES + UDP_DST_PORT_BYTES + UDP_SRC_PORT_BYTES + UDP_LENGTH_BYTES + UDP_CHECKSUM_BYTES;

    constant IP_PROTOCOL_LENGTH : natural := IP_VERSION_HEADER_BYTES + IP_TYPE_BYTES + IP_LENGTH_BYTES + IP_ID_BYTES + IP_FLAG_BYTES + IP_TIME_BYTES + IP_PROTOCOL_BYTES + IP_CHECKSUM_BYTES + IP_SRC_ADDR_BYTES + IP_DST_ADDR_BYTES;

    constant IP_HEADER_LENGTH : natural := ETH_DST_ADDR_BYTES + ETH_SRC_ADDR_BYTES + ETH_PROTOCOL_BYTES + IP_VERSION_HEADER_BYTES + IP_TYPE_BYTES + IP_LENGTH_BYTES;

    type write_state_type is (init, write_eth_dst_addr, write_eth_src_addr, write_eth_protocol, write_ip_version_header, write_ip_type, wait_for_length, write_ip_length, write_ip_id, write_ip_flag, write_ip_time, write_ip_protocol, calc_ip_checksum, write_ip_checksum, write_ip_src_addr, write_ip_dst_addr, write_udp_dst_port, write_udp_src_port, write_udp_length, write_udp_checksum, write_udp_data);

    type read_state_type is (init, exec, calc_checksum, idle);

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

    component udp_write is
        generic
        (
            BUFFER_SIZE : natural := 1024
        );
        port
        (
            clock : in std_logic;
            reset : in std_logic;
            eth_src_addr : in std_logic_vector (ETH_SRC_ADDR_BYTES * BYTE - 1 downto 0);
            eth_dst_addr : in std_logic_vector (ETH_DST_ADDR_BYTES * BYTE - 1 downto 0);
            ip_src_addr : in std_logic_vector (IP_SRC_ADDR_BYTES * BYTE - 1 downto 0);
            ip_dst_addr : in std_logic_vector (IP_DST_ADDR_BYTES * BYTE - 1 downto 0);
            ip_id : in std_logic_vector (IP_ID_BYTES * BYTE - 1 downto 0);
            udp_src_port : in std_logic_vector (UDP_SRC_PORT_BYTES * BYTE - 1 downto 0);
            udp_dst_port : in std_logic_vector (UDP_SRC_PORT_BYTES * BYTE - 1 downto 0);
            input_empty : in std_logic;
            status_empty : in std_logic;
            output_full : in std_logic;
            input_dout : in std_logic_vector (BYTE - 1 downto 0);
            status_dout : in std_logic_vector (STATUS_WIDTH - 1 downto 0) := (others => '0');
            output_din : out std_logic_vector (BYTE - 1 downto 0);
            input_rd_en : out std_logic;
            status_rd_en : out std_logic;
            output_wr_en : out std_logic
        );
    end component;

    component udp_write_top is
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
    end component;


end package;
