library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;
use work.constants.all;

entity udp_write_top_tb is
    generic
    (
    constant DATA_IN : string (22 downto 1) := "../scripts/data_in.txt";
    constant DATA_OUT : string (24 downto 1) := "../scripts/data_out.pcap";
    constant DATA_COMP : string (23 downto 1) := "../scripts/compare.pcap";
    constant CLOCK_PERIOD : time := 2 ns
);
end entity;

architecture behavior of udp_write_top_tb is

    function to_char (std: std_logic_vector)
    return character is
    begin
        return character'val(to_integer(unsigned(std)));
    end function;

    function to_slv (char: character)
    return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(character'pos(char), 8));
    end function;

    function to_slv (int: integer; size: natural)
    return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(int, size));
    end function;

    type raw_file is file of character;
    type byte_array is array (natural range<>) of std_logic_vector (BYTE - 1 downto 0);

    constant DWIDTH : natural := BYTE;
    constant MAX_PACKET_LENGTH : natural := 1024;
    constant BUFFER_SIZE : natural := MAX_PACKET_LENGTH * 2;

    constant ETH_SRC_ADDR_DEF : std_logic_vector (ETH_SRC_ADDR_BYTES * BYTE - 1 downto 0) := X"0015c509c7fd";
    constant ETH_DST_ADDR_DEF : std_logic_vector (ETH_DST_ADDR_BYTES * BYTE - 1 downto 0) := X"000a3501bf4d";
    constant IP_SRC_ADDR_DEF : std_logic_vector (IP_SRC_ADDR_BYTES * BYTE - 1 downto 0) := X"01020309";
    constant IP_DST_ADDR_DEF : std_logic_vector (IP_DST_ADDR_BYTES * BYTE - 1 downto 0) := X"01020304";
    constant IP_ID_DEF : natural := 8189;
    constant UDP_SRC_PORT_DEF : natural := 10012;
    constant UDP_DST_PORT_DEF : natural := 10012;

    -- clock, reset signals
    signal input_clk : std_logic := '0';
    signal internal_clk : std_logic := '0';
    signal output_clk : std_logic := '0';
    signal reset : std_logic := '0';

    -- data signals
    signal din : std_logic_vector (DWIDTH - 1 downto 0) := (others => '0');
    signal status_din : std_logic_vector (STATUS_WIDTH - 1 downto 0) := (others => '0');
    signal dout : std_logic_vector (DWIDTH - 1 downto 0) := (others => '0');
    signal eth_src_addr : std_logic_vector (ETH_SRC_ADDR_BYTES * BYTE - 1 downto 0) := (others => '0');
    signal eth_dst_addr : std_logic_vector (ETH_DST_ADDR_BYTES * BYTE - 1 downto 0) := (others => '0');
    signal ip_src_addr : std_logic_vector (IP_SRC_ADDR_BYTES * BYTE - 1 downto 0) := (others => '0');
    signal ip_dst_addr : std_logic_vector (IP_DST_ADDR_BYTES * BYTE - 1 downto 0) := (others => '0');
    signal ip_id : std_logic_vector (IP_ID_BYTES * BYTE - 1 downto 0) := (others => '0');
    signal udp_src_port : std_logic_vector (UDP_SRC_PORT_BYTES * BYTE - 1 downto 0) := (others => '0');
    signal udp_dst_port : std_logic_vector (UDP_SRC_PORT_BYTES * BYTE - 1 downto 0) := (others => '0');

    -- data control
    signal input_wr_en : std_logic := '0';
    signal status_wr_en : std_logic := '0';
    signal output_rd_en : std_logic := '0';
    signal input_full : std_logic := '0';
    signal status_full : std_logic := '0';
    signal output_empty : std_logic := '0';

    -- process sync signals
    signal hold_clock : std_logic := '0';
    signal start : std_logic := '0';
    signal done : std_logic := '0';
    signal read_errors : natural := 0;

begin

    eth_src_addr <= ETH_SRC_ADDR_DEF;
    eth_dst_addr <= ETH_DST_ADDR_DEF;
    ip_src_addr <= IP_SRC_ADDR_DEF;
    ip_dst_addr <= IP_DST_ADDR_DEF;
    ip_id <= std_logic_vector(to_unsigned(IP_ID_DEF, IP_ID_BYTES * BYTE));
    udp_src_port <= std_logic_vector(to_unsigned(UDP_SRC_PORT_DEF, UDP_SRC_PORT_BYTES * BYTE));
    udp_dst_port <= std_logic_vector(to_unsigned(UDP_DST_PORT_DEF, UDP_DST_PORT_BYTES * BYTE));

    top_inst : component udp_write_top
    generic map
    (
        DWIDTH => DWIDTH,
        BUFFER_SIZE => BUFFER_SIZE
    )
    port map
    (
        input_clk => input_clk,
        internal_clk => internal_clk,
        output_clk => output_clk,
        reset => reset,
        eth_src_addr => eth_src_addr,
        eth_dst_addr => eth_dst_addr,
        ip_src_addr => ip_src_addr,
        ip_dst_addr => ip_dst_addr,
        ip_id => ip_id,
        udp_src_port => udp_src_port,
        udp_dst_port => udp_dst_port,
        input_wr_en => input_wr_en,
        status_wr_en => status_wr_en,
        output_rd_en => output_rd_en,
        din => din,
        status_din => status_din,
        dout => dout,
        input_full => input_full,
        status_full => status_full,
        output_empty => output_empty
    );

    clock_process : process 
    begin 
        input_clk <= '1';
        internal_clk <= '1';
        output_clk <= '1';
        wait for CLOCK_PERIOD / 2; 
        input_clk <= '0';
        internal_clk <= '0';
        output_clk <= '0';
        wait for CLOCK_PERIOD / 2; 
        if (hold_clock = '1') then
            wait; 
        end if; 
    end process;

    reset_process: process 
    begin reset <= '0'; 
        wait until input_clk = '0'; 
        wait until input_clk = '1'; 
        reset <= '1'; 
        wait until input_clk = '0'; 
        wait until input_clk = '1'; 
        reset <= '0'; 
        wait; 
    end process;

    input_process : process
        file input_file : raw_file;
        --variable char : std_logic_vector (BYTE - 1 downto 0);
        variable char : character;
        variable count : natural := 0;
        variable ln : line;
        variable console : line;
        variable line_valid : boolean := True;
    begin
        wait until (reset = '1');
        wait until (reset = '0');
        file_open(input_file, DATA_IN, read_mode);
        wait until (input_clk = '1');
        start <= '1';
        wait until (input_clk = '0');
        wait until (input_clk = '1');
        start <= '0';
        while (not ENDFILE(input_file)) loop
            status_wr_en <= '0';
            wait until (input_clk = '0');
            status_wr_en <= '1';
            status_din <= std_logic_vector(to_unsigned(START_OF_FRAME, STATUS_WIDTH));
            wait until (input_clk = '1');
            --wait until (input_clk = '0');
            --status_wr_en <= '0';
            --wait until (input_clk = '1');
            count := 0;
            while (count < MAX_PACKET_LENGTH and not ENDFILE(input_file)) loop
                wait until (input_clk = '0');
                input_wr_en <= '0';
                status_wr_en <= '0';
                if (input_full = '0' and status_full = '0') then
                    read (input_file, char);
                    input_wr_en <= '1';
                    status_wr_en <= '1';
                    din <= to_slv(char); 
                    --write(ln, char);
                    --writeline(output, ln);
                    status_din <= "01";
                    count := count + 1;
                    write(ln, count);
                    write(ln, string'(" "));
                    write(ln, char);
                    writeline (output, ln);
                end if;
                wait until (input_clk = '1');
            end loop;
            wait until (input_clk = '0');
            status_wr_en <= '1';
            status_din <= std_logic_vector(to_unsigned(END_OF_FRAME, STATUS_WIDTH));
            wait until (input_clk = '1');
            wait until (input_clk = '0');
            status_wr_en <= '0';
        end loop;
        file_close (input_file);
        write(ln, string'("DONE WITH THAT"));
        writeline(output, ln);
        wait;
    end process; 

    output_process : process
        file output_file : raw_file;
        file compare_file : raw_file;
        variable out_ln : line;
        variable in_ln : line;
        variable out_char : character;
        variable in_char : character;
        variable i : natural := 0;
        variable ip_header_buffer : byte_array (0 to IP_HEADER_LENGTH - 1)  := (others => (others => '0'));
        variable packet_length : std_logic_vector (IP_LENGTH_BYTES * BYTE - 1 downto 0);
    begin
        wait until (start = '1');
        wait until (output_clk = '1');
        wait until (output_clk = '0');
        file_open(output_file, DATA_OUT, write_mode);
        file_open(compare_file, DATA_COMP, read_mode);

        -- write pcap header
        hwrite(out_ln, PCAP_MAGIC_NUMBER); 
        hwrite(out_ln, PCAP_VERSION_MAJOR); 
        hwrite(out_ln, PCAP_VERSION_MINOR); 
        hwrite(out_ln, PCAP_ZONE); 
        hwrite(out_ln, PCAP_SIGFIGS); 
        hwrite(out_ln, PCAP_SNAP_LEN);
        hwrite(out_ln, PCAP_NETWORK);
        -- catch up read

        while (not ENDFILE(compare_file)) loop
            -- get length
            i := 0;
            while (i < IP_HEADER_LENGTH) loop
                output_rd_en <= '0';
                wait until (output_clk = '0');
                if (output_empty = '0') then
                    output_rd_en <= '1';
                    wait until (output_clk = '1');
                    ip_header_buffer(i) := dout;
                    i := i + 1;
                end if;
            end loop;
            writeline(output, out_ln);
            packet_length := ip_header_buffer(IP_HEADER_LENGTH - 1) & ip_header_buffer(IP_HEADER_LENGTH - 2);

            -- catch up on writing 
            for i in 0 to IP_HEADER_LENGTH - 1 loop
                hwrite(out_ln, ip_header_buffer(i));
            --compare
            end loop;
            
            -- finish writing rest of packet
            i := 0;
            while (i < unsigned(packet_length) - IP_HEADER_LENGTH) loop
                output_rd_en <= '0';
                wait until (output_clk = '0');
                if (output_empty = '0') then
                    output_rd_en <= '1';
                    wait until (output_clk = '1');
                    write(out_ln, dout);
                    --compare
                    i := i + 1;
                end if;
            end loop;
        end loop;
        file_close(output_file);
        file_close(compare_file);
        done <= '1';
        wait;
    end process;

    --        for i in 0 to len loop
    --            wait until (output_clk = '0');
    --            output_rd_en <= '0';
    --            if (output_empty = '0') then
    --                output_rd_en <= '1';
    --                wait until (output_clk = '1');
    --                readline (output_file, ln);
    --                hread (ln, char);
    --                 count := count + 1;
    --                 if (unsigned(char) /= unsigned(dout)) then
    --                     read_errors <= read_errors + 1;
    --                     write (ln, string'("Error at line "));
    --                     write (ln, count);
    --                     write (ln, string'(": "));
    --                     hwrite (ln, char);
    --                     write (ln, string'(" != "));
    --                     hwrite (ln, dout);
    --                     writeline (output, ln);
    --                 end if;
    --             else
    --                 wait until (output_clk = '1');
    --             end if;
    --         end loop;
    --     end loop;
    --     file_close (output_file);
    --     done <= '1';
    --     wait;
    -- end process; 

    sync_process : process 
        variable errors : integer := 0; 
        variable warnings : integer := 0; 
        variable start_time : time; 
        variable end_time : time; 
        variable ln : line; 
    begin 
        wait until (start = '1');
        start_time := NOW; 
        write (ln, string'("@ "));
        write (ln, start_time);
        write (ln, string'(": Beginnging simultation ..."));
        writeline (output, ln);
        wait until (done = '1');
        end_time := NOW;
        write (ln, string'("@ "));
        write (ln, end_time);
        write (ln, string'(": Simulation completed."));
        writeline (output, ln);
        errors := read_errors;
        write (ln, string'("Total simulation cycle count: ")); 
        write (ln, (end_time - start_time) / CLOCK_PERIOD);
        writeline (output, ln);
        write (ln, string'("Total error count: "));
        write (ln, errors);
        writeline (output, ln);
        hold_clock <= '1';
        wait; 
    end process;

end architecture;
