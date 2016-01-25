library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants.all;

entity udp_read is
    port
    (
        clock : in std_logic;
        reset : in std_logic;
        input_empty : in std_logic;
        output_full : in std_logic;
        len_full : in std_logic;
        input_dout : in std_logic_vector (BYTE - 1 downto 0);
        output_din : out std_logic_vector (BYTE - 1 downto 0);
        input_rd_en : out std_logic;
        output_wr_en : out std_logic;
        buffer_reset : out std_logic;
        length : out std_logic_vector (UDP_LENGTH_BYTES * BYTE - 1 downto 0);
        valid : out std_logic
    );
end entity;

architecture behavioral of udp_read is
    signal state, next_state : udp_state_type;
    signal byte_count, byte_count_c : natural := 0;
    signal check_word, check_word_c : std_logic_vector (WORD - 1 downto 0);
    signal checksum : std_logic_vector (WORD - 1 downto 0);
    signal sum, sum_c : std_logic_vector (LONG - 1 downto 0);

    signal eth_dst_addr, eth_dst_addr_c : std_logic_vector (ETH_DST_ADDR_BYTES * BYTE - 1 downto 0);
    signal eth_src_addr, eth_src_addr_c : std_logic_vector (ETH_SRC_ADDR_BYTES * BYTE - 1 downto 0);
    signal eth_protocol, eth_protocol_c : std_logic_vector (ETH_PROTOCOL_BYTES * BYTE - 1 downto 0);
    signal ip_version, ip_version_c : std_logic_vector (NIBBLE - 1 downto 0);
    signal ip_header, ip_header_c : std_logic_vector (NIBBLE - 1 downto 0);
    signal ip_type, ip_type_c : std_logic_vector (IP_TYPE_BYTES * BYTE - 1 downto 0);
    signal ip_length, ip_length_c : std_logic_vector (IP_LENGTH_BYTES * BYTE - 1 downto 0);
    signal ip_id, ip_id_c : std_logic_vector (IP_ID_BYTES * BYTE - 1 downto 0);
    signal ip_flag, ip_flag_c : std_logic_vector (IP_FLAG_BYTES * BYTE - 1 downto 0);
    signal ip_time, ip_time_c : std_logic_vector (IP_TIME_BYTES * BYTE - 1 downto 0);
    signal ip_protocol, ip_protocol_c : std_logic_vector (IP_PROTOCOL_BYTES * BYTE - 1 downto 0);
    signal ip_checksum, ip_checksum_c : std_logic_vector (IP_CHECKSUM_BYTES * BYTE - 1 downto 0);
    signal ip_src_addr, ip_src_addr_c : std_logic_vector (IP_SRC_ADDR_BYTES * BYTE - 1 downto 0);
    signal ip_dst_addr, ip_dst_addr_c : std_logic_vector (IP_DST_ADDR_BYTES * BYTE - 1 downto 0);
    signal udp_dst_port, udp_dst_port_c : std_logic_vector (UDP_DST_PORT_BYTES * BYTE - 1 downto 0);
    signal udp_src_port, udp_src_port_c : std_logic_vector (UDP_SRC_PORT_BYTES * BYTE - 1 downto 0);
    signal udp_length, udp_length_c : std_logic_vector (UDP_LENGTH_BYTES * BYTE - 1 downto 0);
    signal udp_checksum, udp_checksum_c : std_logic_vector (UDP_CHECKSUM_BYTES * BYTE - 1 downto 0);
begin

    read_udp_process : process (state, byte_count, sum, eth_dst_addr, eth_src_addr, eth_protocol, ip_version, ip_header, ip_type, ip_length, ip_id, ip_flag, ip_time, ip_protocol, ip_checksum, ip_src_addr, ip_dst_addr, udp_dst_port, udp_src_port, udp_length, udp_checksum, check_word, input_empty, output_full, input_dout)
        variable ip_version_v : std_logic_vector (NIBBLE - 1 downto 0) := (others => '0');
        variable sum_v : std_logic_vector (LONG - 1 downto 0) := (others => '0');
        variable checksum_v : std_logic_vector (WORD - 1 downto 0) := (others => '0');
    begin

        next_state <= state;
        byte_count_c <= byte_count;
        sum_c <= sum;
        eth_dst_addr_c <= eth_dst_addr;
        eth_src_addr_c <= eth_src_addr;
        eth_protocol_c <= eth_protocol;
        ip_version_c <= ip_version;
        ip_header_c <= ip_header;
        ip_type_c <= ip_type;
        ip_length_c <= ip_length;
        ip_id_c <= ip_id;
        ip_flag_c <= ip_flag;
        ip_time_c <= ip_time;
        ip_protocol_c <= ip_protocol;
        ip_checksum_c <= ip_checksum;
        ip_src_addr_c <= ip_src_addr;
        ip_dst_addr_c <= ip_dst_addr;
        udp_dst_port_c <= udp_dst_port;
        udp_src_port_c <= udp_src_port;
        udp_length_c <= udp_length;
        udp_checksum_c <= udp_checksum;
        check_word_c <= check_word;

        input_rd_en <= '0';
        output_wr_en <= '0';
        valid <= '0';
        output_din <= (others => '0');
        buffer_reset <= '0';
        checksum <= (others => '0');

        ip_version_v := (others => '0');
        sum_v := (others => '0');
        checksum_v := (others => '0');

        case (state) is
            when init =>
                byte_count_c <= 0;
                sum_c <= (others => '0');
                eth_dst_addr_c <= (others => '0');
                eth_src_addr_c <= (others => '0');
                eth_protocol_c <= (others => '0');
                ip_version_c <= (others => '0');
                ip_header_c <= (others => '0');
                ip_type_c <= (others => '0');
                ip_length_c <= (others => '0');
                ip_id_c <= (others => '0');
                ip_flag_c <= (others => '0');
                ip_time_c <= (others => '0');
                ip_protocol_c <= (others => '0');
                ip_checksum_c <= (others => '0');
                ip_src_addr_c <= (others => '0');
                ip_dst_addr_c <= (others => '0');
                udp_dst_port_c <= (others => '0');
                udp_src_port_c <= (others => '0');
                udp_length_c <= (others => '0');
                udp_checksum_c <= (others => '0');
                check_word_c <= (others => '0');
                if (input_empty = '0') then
                    input_rd_en <= '1';
                    if (unsigned(input_dout) = START_OF_FRAME) then
                        next_state <= read_eth_dst_addr;
                    end if;
                end if;

            when read_eth_dst_addr =>
                eth_dst_addr_c <= eth_dst_addr;
                if (input_empty = '0') then
                    input_rd_en <= '1';
                    eth_dst_addr_c <= std_logic_vector(unsigned(eth_dst_addr) sll BYTE) or std_logic_vector(resize(unsigned(input_dout), ETH_DST_ADDR_BYTES * BYTE));
                    byte_count_c <= byte_count + 1;
                    if (byte_count = ETH_DST_ADDR_BYTES - 1) then
                        byte_count_c <= 0;
                        next_state <= read_eth_src_addr;
                    end if;
                end if;

            when read_eth_src_addr =>
                eth_src_addr_c <= eth_src_addr;
                if (input_empty = '0') then
                    input_rd_en <= '1';
                    eth_src_addr_c <= std_logic_vector(unsigned(eth_src_addr) sll BYTE) or std_logic_vector(resize(unsigned(input_dout), ETH_SRC_ADDR_BYTES * BYTE));
                    byte_count_c <= byte_count + 1;
                    if (byte_count = ETH_SRC_ADDR_BYTES - 1) then
                        byte_count_c <= 0;
                        next_state <= read_eth_protocol;
                    end if;
                end if;

            when read_eth_protocol =>
                eth_protocol_c <= eth_protocol;
                if (input_empty = '0') then
                    input_rd_en <= '1';
                    eth_protocol_c <= std_logic_vector(unsigned(eth_protocol) sll BYTE) or std_logic_vector(resize(unsigned(input_dout), ETH_PROTOCOL_BYTES * BYTE));
                    byte_count_c <= byte_count + 1;
                    if (byte_count = ETH_PROTOCOL_BYTES - 1) then
                        byte_count_c <= 0;
                        next_state <= read_ip_version_header;
                    end if;
                end if;

            when read_ip_version_header =>
                ip_version_c <= ip_version;
                if (input_empty = '0') then
                    input_rd_en <= '1';
                    ip_version_v := input_dout(BYTE - 1 downto NIBBLE);
                    ip_version_c <= ip_version_v;
                    ip_header_c <= input_dout(NIBBLE - 1 downto 0);
                    byte_count_c <= 0;
                    next_state <= read_ip_type;
                    if (unsigned(eth_protocol) /= IP_PROTOCOL_DEF) then
                        next_state <= init;
                    end if;
                end if;

            when read_ip_type =>
                ip_type_c <= ip_type;
                if (input_empty = '0') then
                    input_rd_en <= '1';
                    ip_type_c <= std_logic_vector(unsigned(ip_type) sll BYTE) or std_logic_vector(resize(unsigned(input_dout), IP_TYPE_BYTES * BYTE));
                    byte_count_c <= byte_count + 1;
                    if (byte_count = IP_TYPE_BYTES - 1) then
                        byte_count_c <= 0;
                        next_state <= read_ip_length;
                        if (unsigned(ip_version_v) /= IP_VERSION_DEF) then
                            next_state <= init;
                        end if;
                    end if;
                end if;

            when read_ip_length =>
                ip_length_c <= ip_length;
                if (input_empty = '0') then
                    input_rd_en <= '1';
                    ip_length_c <= std_logic_vector(unsigned(ip_length) sll BYTE) or std_logic_vector(resize(unsigned(input_dout), IP_LENGTH_BYTES * BYTE));
                    byte_count_c <= byte_count + 1;
                    if (byte_count = IP_LENGTH_BYTES - 1) then
                        byte_count_c <= 0;
                        next_state <= read_ip_id;
                    end if;
                end if;

            when read_ip_id =>
                ip_id_c <= ip_id;
                if (input_empty = '0') then
                    input_rd_en <= '1';
                    ip_id_c <= std_logic_vector(unsigned(ip_id) sll BYTE) or std_logic_vector(resize(unsigned(input_dout), IP_ID_BYTES * BYTE));
                    byte_count_c <= byte_count + 1;
                    if (byte_count = IP_ID_BYTES - 1) then
                        byte_count_c <= 0;
                        next_state <= read_ip_flag;
                        sum_c <= std_logic_vector(unsigned(sum) + unsigned(ip_length) - 20);
                    end if;
                end if;

            when read_ip_flag =>
                ip_flag_c <= ip_flag;
                if (input_empty = '0') then
                    input_rd_en <= '1';
                    ip_flag_c <= std_logic_vector(unsigned(ip_flag) sll BYTE) or std_logic_vector(resize(unsigned(input_dout), IP_FLAG_BYTES * BYTE));
                    byte_count_c <= byte_count + 1;
                    if (byte_count = IP_FLAG_BYTES - 1) then
                        byte_count_c <= 0;
                        next_state <= read_ip_time;
                    end if;
                end if;

            when read_ip_time =>
                ip_time_c <= ip_time;
                if (input_empty = '0') then
                    input_rd_en <= '1';
                    ip_time_c <= std_logic_vector(unsigned(ip_time) sll BYTE) or std_logic_vector(resize(unsigned(input_dout), IP_TIME_BYTES * BYTE));
                    byte_count_c <= byte_count + 1;
                    if (byte_count = IP_TIME_BYTES - 1) then
                        byte_count_c <= 0;
                        next_state <= read_ip_protocol;
                    end if;
                end if;

            when read_ip_protocol =>
                ip_protocol_c <= ip_protocol;
                if (input_empty = '0') then
                    input_rd_en <= '1';
                    ip_protocol_c <= std_logic_vector(unsigned(ip_protocol) sll BYTE) or std_logic_vector(resize(unsigned(input_dout), IP_PROTOCOL_BYTES * BYTE));
                    byte_count_c <= byte_count + 1;
                    if (byte_count = IP_PROTOCOL_BYTES - 1) then
                        byte_count_c <= 0;
                        next_state <= read_ip_checksum;
                    end if;
                end if;

            when read_ip_checksum =>
                ip_checksum_c <= ip_checksum;
                if (input_empty = '0') then
                    input_rd_en <= '1';
                    ip_checksum_c <= std_logic_vector(unsigned(ip_checksum) sll BYTE) or std_logic_vector(resize(unsigned(input_dout), IP_CHECKSUM_BYTES * BYTE));
                    byte_count_c <= byte_count + 1;
                    if (byte_count = IP_CHECKSUM_BYTES - 1) then
                        byte_count_c <= 0;
                        next_state <= read_ip_src_addr;
                        sum_c <= std_logic_vector(unsigned(sum) + unsigned(ip_protocol));
                        if (unsigned(ip_protocol) /= UDP_PROTOCOL_DEF) then
                            next_state <= init;
                        end if;
                    end if;
                end if;

            when read_ip_src_addr =>
                ip_src_addr_c <= ip_src_addr;
                if (input_empty = '0') then
                    input_rd_en <= '1';
                    ip_src_addr_c <= std_logic_vector(unsigned(ip_src_addr) sll BYTE) or std_logic_vector(resize(unsigned(input_dout), IP_SRC_ADDR_BYTES * BYTE));
                    byte_count_c <= byte_count + 1;
                    if (byte_count = IP_SRC_ADDR_BYTES - 1) then
                        byte_count_c <= 0;
                        next_state <= read_ip_dst_addr;
                    end if;
                end if;

            when read_ip_dst_addr =>
                ip_dst_addr_c <= ip_dst_addr;
                if (input_empty = '0') then
                    input_rd_en <= '1';
                    ip_dst_addr_c <= std_logic_vector(unsigned(ip_dst_addr) sll BYTE) or std_logic_vector(resize(unsigned(input_dout), IP_DST_ADDR_BYTES * BYTE));
                    byte_count_c <= byte_count + 1;
                    if (byte_count = IP_DST_ADDR_BYTES - 1) then
                        byte_count_c <= 0;
                        next_state <= read_udp_dst_port;
                        sum_c <= std_logic_vector(unsigned(sum) + unsigned(ip_src_addr(LONG - 1 downto WORD)) + unsigned(ip_src_addr(WORD - 1 downto 0)));
                    end if;
                end if;

            when read_udp_dst_port =>
                udp_dst_port_c <= udp_dst_port;
                if (input_empty = '0') then
                    input_rd_en <= '1';
                    udp_dst_port_c <= std_logic_vector(unsigned(udp_dst_port) sll BYTE) or std_logic_vector(resize(unsigned(input_dout), UDP_DST_PORT_BYTES * BYTE));
                    byte_count_c <= byte_count + 1;
                    if (byte_count = UDP_DST_PORT_BYTES - 1) then
                        byte_count_c <= 0;
                        next_state <= read_udp_src_port;
                        sum_c <= std_logic_vector(unsigned(sum) + unsigned(ip_dst_addr(LONG - 1 downto WORD)) + unsigned(ip_dst_addr(WORD - 1 downto 0)));
                    end if;
                end if;

            when read_udp_src_port =>
                udp_src_port_c <= udp_src_port;
                if (input_empty = '0') then
                    input_rd_en <= '1';
                    udp_src_port_c <= std_logic_vector(unsigned(udp_src_port) sll BYTE) or std_logic_vector(resize(unsigned(input_dout), UDP_SRC_PORT_BYTES * BYTE));
                    byte_count_c <= byte_count + 1;
                    if (byte_count = UDP_SRC_PORT_BYTES - 1) then
                        byte_count_c <= 0;
                        next_state <= read_udp_length;
                        sum_c <= std_logic_vector(unsigned(sum) + unsigned(udp_dst_port));
                    end if;
                end if;

            when read_udp_length =>
                udp_length_c <= udp_length;
                if (input_empty = '0') then
                    input_rd_en <= '1';
                    udp_length_c <= std_logic_vector(unsigned(udp_length) sll BYTE) or std_logic_vector(resize(unsigned(input_dout), UDP_LENGTH_BYTES * BYTE));
                    byte_count_c <= byte_count + 1;
                    if (byte_count = UDP_LENGTH_BYTES - 1) then
                        byte_count_c <= 0;
                        next_state <= read_udp_checksum;
                        sum_c <= std_logic_vector(unsigned(sum) + unsigned(udp_src_port));
                    end if;
                end if;

            when read_udp_checksum =>
                udp_checksum_c <= udp_checksum;
                if (input_empty = '0') then
                    input_rd_en <= '1';
                    udp_checksum_c <= std_logic_vector(unsigned(udp_checksum) sll BYTE) or std_logic_vector(resize(unsigned(input_dout), UDP_CHECKSUM_BYTES * BYTE));
                    byte_count_c <= byte_count + 1;
                    if (byte_count = UDP_CHECKSUM_BYTES - 1) then
                        byte_count_c <= 0;
                        next_state <= read_udp_data;
                        sum_c <= std_logic_vector(unsigned(sum) + unsigned(udp_length));
                    end if;
                end if;

            when read_udp_data =>
                output_wr_en <= '0';
                output_din <= (others => '0');
                sum_v := sum;
                if (input_empty = '0' and output_full = '0') then
                    input_rd_en <= '1';
                    output_wr_en <= '1';
                    output_din <= input_dout;
                    byte_count_c <= byte_count + 1;
                    check_word_c <= check_word(BYTE - 1 downto 0) & input_dout;
                    if (byte_count mod 2 = 0) then
                        sum_v := std_logic_vector(unsigned(sum) + resize(unsigned(check_word), LONG));
                    end if;
                    if (byte_count = unsigned(udp_length) - UDP_SUBLENGTH - 1) then
                        byte_count_c <= 0;
                        next_state <= write_udp_data;
                        if (unsigned(udp_length) mod 2 = 0) then
                            --sum_v := std_logic_vector(unsigned(sum_v) + resize(unsigned(check_word(BYTE - 1 downto 0) & input_dout), LONG));
                            sum_v := std_logic_vector(unsigned(sum_v) + unsigned(check_word(BYTE - 1 downto 0) & input_dout));
                        else
                            --sum_v := std_logic_vector(unsigned(sum_v) + resize(unsigned(input_dout), LONG));
                            sum_v := std_logic_vector(unsigned(sum_v) + unsigned(input_dout));
                        end if;
                    end if;
                    sum_c <= sum_v;
                end if;

            when write_udp_data =>
                next_state <= init;
                sum_v := std_logic_vector(resize(unsigned(sum(LONG - 1 downto WORD)) + unsigned(sum(WORD - 1 downto 0)), LONG));
                sum_c <= sum_v;
                if (unsigned(sum_v(LONG - 1 downto WORD)) = 0) then
                    checksum_v := sum_v(WORD - 1 downto 0);
                    checksum_v := not checksum_v;
                    checksum <= checksum_v;
                    if (unsigned(checksum_v) = unsigned(udp_checksum)) then
                        valid <= '1';
                    else
                        buffer_reset <= '1';
                    end if;
                else
                    next_state <= write_udp_data;
                end if;

            when others =>
                next_state <= init;
        end case;
    end process;

    clock_process : process (clock, reset)
    begin
        if (reset = '1') then
            state <= init;
            byte_count <= 0;
            sum <= (others => '0');
            eth_dst_addr <= (others => '0');
            eth_src_addr <= (others => '0');
            eth_protocol <= (others => '0');
            ip_version <= (others => '0');
            ip_header <= (others => '0');
            ip_type <= (others => '0');
            ip_length <= (others => '0');
            ip_id <= (others => '0');
            ip_flag <= (others => '0');
            ip_time <= (others => '0');
            ip_protocol <= (others => '0');
            ip_checksum <= (others => '0');
            ip_src_addr <= (others => '0');
            ip_dst_addr <= (others => '0');
            udp_dst_port <= (others => '0');
            udp_src_port <= (others => '0');
            udp_length <= (others => '0');
            udp_checksum <= (others => '0');
            check_word <= (others => '0');
        elsif (rising_edge(clock)) then
            state <= next_state;
            byte_count <= byte_count_c;
            sum <= sum_c;
            eth_dst_addr <= eth_dst_addr_c;
            eth_src_addr <= eth_src_addr_c;
            eth_protocol <= eth_protocol_c;
            ip_version <= ip_version_c;
            ip_header <= ip_header_c;
            ip_type <= ip_type_c;
            ip_length <= ip_length_c;
            ip_id <= ip_id_c;
            ip_flag <= ip_flag_c;
            ip_time <= ip_time_c;
            ip_protocol <= ip_protocol_c;
            ip_checksum <= ip_checksum_c;
            ip_src_addr <= ip_src_addr_c;
            ip_dst_addr <= ip_dst_addr_c;
            udp_dst_port <= udp_dst_port_c;
            udp_src_port <= udp_src_port_c;
            udp_length <= udp_length_c;
            udp_checksum <= udp_checksum_c;
            check_word <= check_word_c;
        end if;
    end process;

    length <= std_logic_vector(unsigned(udp_length) - UDP_SUBLENGTH);

end architecture;
