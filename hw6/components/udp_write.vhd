library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants.all;

entity udp_write is
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
end entity;

architecture behavioral of udp_write is

    function add_checksum (sum : std_logic_vector (LONG - 1 downto 0); data : std_logic_vector (BYTE - 1 downto 0); count : natural)
    return std_logic_vector is
        variable new_sum : std_logic_vector (LONG - 1 downto 0) := (others => '0');
    begin
        if (count mod 2 = 0) then
            new_sum := std_logic_vector(unsigned(sum) + (resize(unsigned(data), WORD) sll BYTE));
        else
            new_sum := std_logic_vector(unsigned(sum) + unsigned(data));
        end if;
        return new_sum;
    end function;

    signal write_state, write_next_state : write_state_type;
    signal read_state, read_next_state : read_state_type;
    signal eth_protocol : std_logic_vector (ETH_PROTOCOL_BYTES * BYTE - 1 downto 0) := (others => '0');
    signal ip_version_header : std_logic_vector (IP_VERSION_HEADER_BYTES * BYTE - 1 downto 0) := (others => '0');
    signal ip_type : std_logic_vector (IP_TYPE_BYTES * BYTE - 1 downto 0) := (others => '0');
    signal ip_length : std_logic_vector (IP_LENGTH_BYTES * BYTE - 1 downto 0) := (others => '0');
    signal ip_flag : std_logic_vector (IP_FLAG_BYTES * BYTE - 1 downto 0) := (others => '0');
    signal ip_time : std_logic_vector (IP_TIME_BYTES * BYTE - 1 downto 0) := (others => '0');
    signal ip_protocol : std_logic_vector (IP_PROTOCOL_BYTES * BYTE - 1 downto 0) := (others => '0');
    signal ip_checksum, ip_checksum_c : std_logic_vector (IP_CHECKSUM_BYTES * BYTE - 1 downto 0) := (others => '0');
    signal udp_length, udp_length_c : std_logic_vector (UDP_LENGTH_BYTES * BYTE - 1 downto 0) := (others => '0');
    signal length, length_c : std_logic_vector (UDP_LENGTH_BYTES * BYTE - 1 downto 0) := (others => '0');
    signal udp_checksum, udp_checksum_c : std_logic_vector (UDP_CHECKSUM_BYTES * BYTE - 1 downto 0) := (others => '0');
    signal checksum, checksum_c : std_logic_vector (UDP_CHECKSUM_BYTES * BYTE - 1 downto 0) := (others => '0');
    signal current_ready, current_ready_c : std_logic := '0';
    signal current_ack, current_ack_c : std_logic := '0';
    signal ip_sum, ip_sum_c : std_logic_vector (LONG - 1 downto 0) := (others => '0');
    signal udp_sum, udp_sum_c : std_logic_vector (LONG - 1 downto 0) := (others => '0'); 
    signal byte_count, byte_count_c : natural := 0;
    signal buffer_empty, buffer_full : std_logic := '0';
    signal buffer_din, buffer_dout : std_logic_vector (BYTE - 1 downto 0) := (others => '0');
    signal buffer_rd_en, buffer_wr_en : std_logic := '0';
    signal ip_count, ip_count_c : natural := 0;

begin

    buffer_fifo : fifo
    generic map
    (
        DWIDTH => BYTE,
        BUFFER_SIZE => BUFFER_SIZE
    )
    port map
    (
        rd_clk => clock,
        wr_clk => clock,
        reset => reset,
        rd_en => buffer_rd_en,
        wr_en => buffer_wr_en,
        din => buffer_din,
        dout => buffer_dout,
        full => buffer_full,
        empty => buffer_empty
    );

    eth_protocol <= std_logic_vector(to_unsigned(IP_PROTOCOL_DEF, ETH_PROTOCOL_BYTES * BYTE));
    ip_version_header <= std_logic_vector(to_unsigned(IP_VERSION_DEF, NIBBLE) & to_unsigned(IP_HEADER_LENGTH_DEF, NIBBLE));
    ip_type <= std_logic_vector(to_unsigned(IP_TYPE_DEF, IP_TYPE_BYTES * BYTE));
    ip_length <= std_logic_vector(unsigned(udp_length) + PACKET_LENGTH);
    ip_flag <= std_logic_vector(to_unsigned(IP_FLAG_DEF, IP_FLAG_BYTES * BYTE));
    ip_time <= std_logic_vector(to_unsigned(TIME_TO_LIVE, IP_TIME_BYTES * BYTE));
    ip_protocol <= std_logic_vector(to_unsigned(UDP_PROTOCOL_DEF, IP_PROTOCOL_BYTES * BYTE));

    write_output_process : process (write_state, byte_count, ip_sum, udp_length, udp_checksum, length, checksum, current_ack, current_ready, input_empty, buffer_empty, output_full, eth_protocol, ip_version_header, ip_type, ip_length, ip_flag, ip_time, ip_protocol, ip_checksum, ip_src_addr, ip_dst_addr, eth_src_addr, eth_dst_addr, udp_src_port, udp_dst_port, ip_id, ip_count, buffer_dout)
        variable din : std_logic_vector (BYTE - 1 downto 0) := (others => '0');
        variable ip_sum_v : std_logic_vector (LONG - 1 downto 0) := (others => '0');
        variable ip_count_v : natural := 0;
    begin
        write_next_state <= write_state;
        byte_count_c <= byte_count;
        ip_sum_c <= ip_sum;
        ip_checksum_c <= ip_checksum;
        udp_length_c <= udp_length;
        udp_checksum_c <= udp_checksum;
        current_ack_c <= '0';
        ip_count_c <= ip_count;
        ip_count_v := ip_count;

        output_wr_en <= '0';
        buffer_rd_en <= '0';
        output_din <= (others => '0');

        case (write_state) is
            when init =>
                byte_count_c <= 0;
                if (input_empty = '0') then
                    write_next_state <= write_eth_dst_addr;
                    ip_count_v := 0;
                    ip_sum_v := (others => '0');
                    for i in IP_SRC_ADDR_BYTES downto 1 loop
                        ip_sum_v := add_checksum(ip_sum_v, IP_SRC_ADDR(i * BYTE - 1 downto (i - 1) * BYTE), ip_count_v);
                        ip_count_v := ip_count_v + 1;
                    end loop;
                    for i in IP_DST_ADDR_BYTES downto 1 loop
                        ip_sum_v := add_checksum(ip_sum_v, IP_DST_ADDR(i * BYTE - 1 downto (i - 1) * BYTE), ip_count_v);
                        ip_count_v := ip_count_v + 1;
                    end loop;
                    ip_sum_c <= ip_sum_v;
                end if;

            when write_eth_dst_addr =>
                if (output_full = '0') then
                    output_wr_en <= '1';
                    output_din <= eth_dst_addr(ETH_DST_ADDR_BYTES * BYTE - BYTE * byte_count - 1 downto ETH_DST_ADDR_BYTES * BYTE - BYTE * (byte_count + 1));
                    byte_count_c <= byte_count + 1;
                    if (byte_count = ETH_DST_ADDR_BYTES - 1) then
                        byte_count_c <= 0;
                        write_next_state <= write_eth_src_addr;
                    end if;
                end if;

            when write_eth_src_addr =>
                if (output_full = '0') then
                    output_wr_en <= '1';
                    output_din <= eth_src_addr(ETH_SRC_ADDR_BYTES * BYTE - BYTE * byte_count - 1 downto ETH_SRC_ADDR_BYTES * BYTE - BYTE * (byte_count + 1));
                    byte_count_c <= byte_count + 1;
                    if (byte_count = ETH_SRC_ADDR_BYTES - 1) then
                        byte_count_c <= 0;
                        write_next_state <= write_eth_protocol;
                    end if;
                end if;

            when write_eth_protocol =>
                if (output_full = '0') then
                    output_wr_en <= '1';
                    output_din <= eth_protocol(ETH_PROTOCOL_BYTES * BYTE - BYTE * byte_count - 1 downto ETH_PROTOCOL_BYTES * BYTE - BYTE * (byte_count + 1));
                    byte_count_c <= byte_count + 1;
                    if (byte_count = ETH_PROTOCOL_BYTES - 1) then
                        byte_count_c <= 0;
                        write_next_state <= write_ip_version_header;
                    end if;
                end if;

            when write_ip_version_header =>
                if (output_full = '0') then
                    output_wr_en <= '1';
                    din := ip_version_header(IP_VERSION_HEADER_BYTES * BYTE - BYTE * byte_count - 1 downto IP_VERSION_HEADER_BYTES * BYTE - BYTE * (byte_count + 1));
                    output_din <= din;
                    ip_sum_c <= add_checksum(ip_sum, din, ip_count_v);
                    ip_count_v := ip_count_v + 1;
                    byte_count_c <= byte_count + 1;
                    if (byte_count = IP_VERSION_HEADER_BYTES - 1) then
                        byte_count_c <= 0;
                        write_next_state <= write_ip_type;
                    end if;
                end if;

            when write_ip_type =>
                if (output_full = '0') then
                    output_wr_en <= '1';
                    din := ip_type(IP_TYPE_BYTES * BYTE - BYTE * byte_count - 1 downto IP_TYPE_BYTES * BYTE - BYTE * (byte_count + 1));
                    output_din <= din;
                    ip_sum_c <= add_checksum(ip_sum, din, ip_count_v);
                    ip_count_v := ip_count_v + 1;
                    byte_count_c <= byte_count + 1;
                    if (byte_count = IP_TYPE_BYTES - 1) then
                        byte_count_c <= 0;
                        write_next_state <= wait_for_length;
                    end if;
                end if;

            when wait_for_length =>
                if (current_ready = '1') then
                    udp_length_c <= length;
                    udp_checksum_c <= checksum;
                    current_ack_c <= '1';
                    write_next_state <= write_ip_length;
                end if;

            when write_ip_length =>
                if (current_ready = '1' and output_full = '0') then
                    output_wr_en <= '1';
                    din := ip_length(IP_LENGTH_BYTES * BYTE - BYTE * byte_count - 1 downto IP_LENGTH_BYTES * BYTE - BYTE * (byte_count + 1));
                    output_din <= din;
                    ip_sum_c <= add_checksum(ip_sum, din, ip_count_v);
                    ip_count_v := ip_count_v + 1;
                    byte_count_c <= byte_count + 1;
                    if (byte_count = IP_LENGTH_BYTES - 1) then
                        byte_count_c <= 0;
                        write_next_state <= write_ip_id;
                    end if;
                end if;

            when write_ip_id =>
                if (output_full = '0') then
                    output_wr_en <= '1';
                    din := ip_id(IP_ID_BYTES * BYTE - BYTE * byte_count - 1 downto IP_ID_BYTES * BYTE - BYTE * (byte_count + 1));
                    output_din <= din;
                    ip_sum_c <= add_checksum(ip_sum, din, ip_count_v);
                    ip_count_v := ip_count_v + 1;
                    byte_count_c <= byte_count + 1;
                    if (byte_count = IP_ID_BYTES - 1) then
                        byte_count_c <= 0;
                        write_next_state <= write_ip_flag;
                    end if;
                end if;

            when write_ip_flag =>
                if (output_full = '0') then
                    output_wr_en <= '1';
                    din := ip_flag(IP_FLAG_BYTES * BYTE - BYTE * byte_count - 1 downto IP_FLAG_BYTES * BYTE - BYTE * (byte_count + 1));
                    output_din <= din;
                    ip_sum_c <= add_checksum(ip_sum, din, ip_count_v);
                    ip_count_v := ip_count_v + 1;
                    byte_count_c <= byte_count + 1;
                    if (byte_count = IP_FLAG_BYTES - 1) then
                        byte_count_c <= 0;
                        write_next_state <= write_ip_time;
                    end if;
                end if;

            when write_ip_time =>
                if (output_full = '0') then
                    output_wr_en <= '1';
                    din := ip_time(IP_TIME_BYTES * BYTE - BYTE * byte_count - 1 downto IP_TIME_BYTES * BYTE - BYTE * (byte_count + 1));
                    output_din <= din;
                    ip_sum_c <= add_checksum(ip_sum, din, ip_count_v);
                    ip_count_v := ip_count_v + 1;
                    byte_count_c <= byte_count + 1;
                    if (byte_count = IP_TIME_BYTES - 1) then
                        byte_count_c <= 0;
                        write_next_state <= write_ip_protocol;
                    end if;
                end if;

            when write_ip_protocol =>
                if (output_full = '0') then
                    output_wr_en <= '1';
                    din := ip_protocol(IP_PROTOCOL_BYTES * BYTE - BYTE * byte_count - 1 downto IP_PROTOCOL_BYTES * BYTE - BYTE * (byte_count + 1));
                    output_din <= din;
                    ip_sum_c <= add_checksum(ip_sum, din, ip_count_v);
                    ip_count_v := ip_count_v + 1;
                    byte_count_c <= byte_count + 1;
                    if (byte_count = IP_PROTOCOL_BYTES - 1) then
                        byte_count_c <= 0;
                        write_next_state <= calc_ip_checksum;
                    end if;
                end if;

            when calc_ip_checksum =>
                ip_sum_c <= std_logic_vector(resize(unsigned(ip_sum(LONG - 1 downto WORD)) + unsigned(ip_sum(WORD - 1 downto 0)), ip_sum'length));
                if (unsigned(ip_sum(LONG - 1 downto WORD)) = 0) then
                    write_next_state <= write_ip_checksum;
                    ip_checksum_c <= not ip_sum(WORD - 1 downto 0);
                end if;

            when write_ip_checksum =>
                if (output_full = '0') then
                    output_wr_en <= '1';
                    din := ip_checksum(IP_CHECKSUM_BYTES * BYTE - BYTE * byte_count - 1 downto IP_CHECKSUM_BYTES * BYTE - BYTE * (byte_count + 1));
                    output_din <= din;
                    ip_sum_c <= add_checksum(ip_sum, din, ip_count_v);
                    ip_count_v := ip_count_v + 1;
                    byte_count_c <= byte_count + 1;
                    if (byte_count = IP_CHECKSUM_BYTES - 1) then
                        byte_count_c <= 0;
                        write_next_state <= write_ip_src_addr;
                    end if;
                end if;

            when write_ip_src_addr =>
                if (output_full = '0') then
                    output_wr_en <= '1';
                    din := ip_src_addr(IP_SRC_ADDR_BYTES * BYTE - BYTE * byte_count - 1 downto IP_SRC_ADDR_BYTES * BYTE - BYTE * (byte_count + 1));
                    output_din <= din;
                    ip_sum_c <= add_checksum(ip_sum, din, ip_count_v);
                    ip_count_v := ip_count_v + 1;
                    byte_count_c <= byte_count + 1;
                    if (byte_count = IP_SRC_ADDR_BYTES - 1) then
                        byte_count_c <= 0;
                        write_next_state <= write_ip_dst_addr;
                    end if;
                end if;

            when write_ip_dst_addr =>
                if (output_full = '0') then
                    output_wr_en <= '1';
                    din := ip_dst_addr(IP_DST_ADDR_BYTES * BYTE - BYTE * byte_count - 1 downto IP_DST_ADDR_BYTES * BYTE - BYTE * (byte_count + 1));
                    output_din <= din;
                    ip_sum_c <= add_checksum(ip_sum, din, ip_count_v);
                    ip_count_v := ip_count_v + 1;
                    byte_count_c <= byte_count + 1;
                    if (byte_count = IP_DST_ADDR_BYTES - 1) then
                        byte_count_c <= 0;
                        write_next_state <= write_udp_dst_port;
                    end if;
                end if;

            when write_udp_dst_port =>
                if (output_full = '0') then
                    output_wr_en <= '1';
                    output_din <= udp_dst_port(UDP_DST_PORT_BYTES * BYTE - BYTE * byte_count - 1 downto UDP_DST_PORT_BYTES * BYTE - BYTE * (byte_count + 1));
                    byte_count_c <= byte_count + 1;
                    if (byte_count = UDP_DST_PORT_BYTES - 1) then
                        byte_count_c <= 0;
                        write_next_state <= write_udp_src_port;
                    end if;
                end if;

            when write_udp_src_port =>
                if (output_full = '0') then
                    output_wr_en <= '1';
                    output_din <= udp_src_port(UDP_SRC_PORT_BYTES * BYTE - BYTE * byte_count - 1 downto UDP_SRC_PORT_BYTES * BYTE - BYTE * (byte_count + 1));
                    byte_count_c <= byte_count + 1;
                    if (byte_count = UDP_SRC_PORT_BYTES - 1) then
                        byte_count_c <= 0;
                        write_next_state <= write_udp_length;
                    end if;
                end if;

            when write_udp_length =>
                if (output_full = '0') then
                    output_wr_en <= '1';
                    output_din <= udp_length(UDP_LENGTH_BYTES * BYTE - BYTE * byte_count - 1 downto UDP_LENGTH_BYTES * BYTE - BYTE * (byte_count + 1));
                    byte_count_c <= byte_count + 1;
                    if (byte_count = UDP_LENGTH_BYTES - 1) then
                        byte_count_c <= 0;
                        write_next_state <= write_udp_checksum;
                    end if;
                end if;

            when write_udp_checksum =>
                if (output_full = '0') then
                    output_wr_en <= '1';
                    output_din <= udp_checksum(UDP_CHECKSUM_BYTES * BYTE - BYTE * byte_count - 1 downto UDP_CHECKSUM_BYTES * BYTE - BYTE * (byte_count + 1));
                    byte_count_c <= byte_count + 1;
                    if (byte_count = UDP_CHECKSUM_BYTES - 1) then
                        byte_count_c <= 0;
                        write_next_state <= write_udp_data;
                    end if;
                end if;

            when write_udp_data =>
                if (output_full = '0' and buffer_empty = '0') then
                    output_wr_en <= '1';
                    buffer_rd_en <= '1';
                    output_din <= buffer_dout;
                    byte_count_c <= byte_count + 1;
                    if (byte_count = unsigned(udp_length) - 1) then
                        write_next_state <= init;
                    end if;
                end if;

            when others =>
                write_next_state <= init;

        end case;
        ip_count_c <= ip_count_v;
    end process;

    read_input_process : process (read_state, udp_sum, length, ip_src_addr, ip_dst_addr, ip_protocol, ip_length, udp_dst_port, udp_src_port, input_empty, checksum, current_ready, status_empty, status_dout, buffer_full, input_dout, current_ack)
    begin
        read_next_state <= read_state;
        udp_sum_c <= udp_sum;
        length_c <= length;
        checksum_c <= checksum;
        current_ready_c <= current_ready;

        status_rd_en <= '0';
        input_rd_en <= '0';
        buffer_wr_en <= '0';
        buffer_din <= (others => '0');

        case (read_state) is
            when init => 
                if (status_empty = '0') then
                    status_rd_en <= '1';
                    if (unsigned(status_dout) = START_OF_FRAME) then
                        udp_sum_c <= std_logic_vector(unsigned(ip_src_addr) + unsigned(ip_dst_addr) + unsigned(ip_protocol) + unsigned(ip_length) + unsigned(udp_dst_port) + unsigned(udp_src_port));
                        read_next_state <= exec;
                    end if;
                end if;

            when exec =>
                status_rd_en <= '1';
                if (input_empty = '0' and buffer_full = '0') then
                    read_next_state <= exec;
                    if (unsigned(status_dout) = END_OF_FRAME) then
                        read_next_state <= calc_checksum;
                        udp_sum_c <= std_logic_vector(unsigned(udp_sum) + unsigned(length));
                    else
                        input_rd_en <= '1';
                        buffer_wr_en <= '1';
                        buffer_din <= input_dout;
                        udp_sum_c <= add_checksum(udp_sum, input_dout, to_integer(unsigned(length)));
                        length_c <= std_logic_vector(unsigned(length) + 1);
                    end if;
                end if;

            when calc_checksum =>
                read_next_state <= calc_checksum;
                udp_sum_c <= std_logic_vector(resize(unsigned(udp_sum(LONG - 1 downto WORD)) + unsigned(udp_sum(WORD - 1 downto 0)), udp_sum'length));
                if (unsigned(udp_sum(LONG - 1 downto WORD)) = 0) then
                    read_next_state <= idle;
                    current_ready_c <= '1';
                    checksum_c <= not udp_sum(WORD - 1 downto 0);
                end if;

            when idle =>
                read_next_state <= idle;
                current_ready_c <= '1';
                if (current_ack = '1') then
                    read_next_state <= init;
                end if;

            when others =>
                read_next_state <= init;

        end case;
    end process;

    clock_process : process (clock, reset)
    begin
        if (reset = '1') then
            write_state <= init;
            read_state <= init;
            byte_count <= 0;
            ip_sum <= (others => '0');
            ip_checksum <= (others => '0'); 
            udp_length <= (others => '0');
            udp_checksum <= (others => '0'); 
            udp_sum <= (others => '0'); 
            length <= (others => '0'); 
            checksum <= (others => '0'); 
            current_ack <= '0';
            current_ready <= '0';
            ip_count <= 0;
        elsif (rising_edge(clock)) then
            write_state <= write_next_state; 
            read_state <= read_next_state;
            byte_count <= byte_count_c;
            ip_sum <= ip_sum_c;
            ip_checksum <= ip_checksum_c;
            udp_length <= udp_length_c; 
            udp_checksum <= udp_checksum_c; 
            udp_sum <= udp_sum_c; 
            length <= length_c; 
            checksum <= checksum_c; 
            current_ack <= current_ack_c; 
            current_ready <= current_ready_c; 
            ip_count <= ip_count_c;
        end if;
    end process;

end architecture;
