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

    type raw_file is file of character;

    constant DWIDTH : natural := BYTE;
    constant BUFFER_SIZE : natural := 1024;
    constant PACKET_LENGTH : natural := 1024;

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

    write_input_process : process
        file input_file : text;
        variable char : std_logic_vector(BYTE - 1 downto 0);
        variable count : natural := 0;
        variable ln : line;
        variable line_valid : boolean;
    begin
        wait until (reset = '1');
        wait until (reset = '0');
        file_open (input_file, DATA_IN, read_mode);
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
            count := 0;
            while (count < PACKET_LENGTH and not ENDFILE(input_file)) loop
                readline (input_file, ln);
                while (count < PACKET_LENGTH and line_valid) loop
                    wait until (input_clk = '0');
                    input_wr_en <= '0';
                    status_wr_en <= '0';
                    if (input_full = '0' and status_full = '0') then
                        hread(ln, char, line_valid);
                        if (line_valid) then
                            input_wr_en <= '1';
                            status_wr_en <= '1';
                            din <= char; 
                            status_din <= (others => '0');
                            count := count + 1;
                        end if;
                    end if;
                    wait until (input_clk = '1');
                end loop;
            end loop;
            status_wr_en <= '0';
            wait until (input_clk = '0');
            status_wr_en <= '1';
            status_din <= std_logic_vector(to_unsigned(END_OF_FRAME, STATUS_WIDTH));
            wait until (input_clk = '1');
            wait until (input_clk = '0');
            status_wr_en <= '0';
        end loop;
            file_close (input_file);
            wait;
        end process; 

        -- read_output_process : process
        --     file output_file : raw_file;
        --     variable char : std_logic_vector (BYTE - 1 downto 0);
        --     variable count : natural := 0;
        --     variable ln : line;
        -- begin
        --     wait until (start = '1');
        --     wait until (output_clk = '1');
        --     wait until (output_clk = '0');
        --     -- write pcap header
        --     -- 
        --     file_open (output_file, DATA_OUT, read_mode);
        --     while (not ENDFILE(output_file)) loop
        --         wait until (output_clk = '0');
        --         wait until (output_clk = '1');
        --         wait until (output_clk = '0');
        --         for i in 0 to len loop
        --             wait until (output_clk = '0');
        --             output_rd_en <= '0';
        --             if (output_empty = '0') then
        --                 output_rd_en <= '1';
        --                 wait until (output_clk = '1');
        --                 readline (output_file, ln);
        --                 hread (ln, char);
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
