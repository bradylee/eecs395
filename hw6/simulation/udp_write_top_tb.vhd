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

    -- clock, reset signals
    signal input_clk :  std_logic := '1';
    signal internal_clk : std_logic := '1';
    signal output_clk : std_logic := '1';
    signal reset : std_logic := '0';

    -- data signals
    signal din : std_logic_vector (DWIDTH - 1 downto 0) := (others => '0');
    signal dout : std_logic_vector (DWIDTH - 1 downto 0) := (others => '0');
    signal length : std_logic_vector (UDP_LENGTH_BYTES * BYTE - 1 downto 0);
    signal input_wr_en : std_logic := '0';
    signal output_rd_en : std_logic := '0';
    signal input_full : std_logic := '0';
    signal output_empty : std_logic := '0';

    -- process sync signals
    signal hold_clock : std_logic := '0';
    signal start : std_logic := '0';
    signal done : std_logic := '0';
    signal read_errors : natural := 0;

begin

    top_inst : component udp_read_top
    generic map
    (
        DWIDTH => DWIDTH,
        BUFFER_SIZE => BUFFER_SIZE,
        LENGTH_BUFFER_SIZE => 16
    )
    port map
    (
        input_clk => input_clk,
        internal_clk => internal_clk,
        output_clk => output_clk,
        reset => reset,
        input_wr_en => input_wr_en,
        output_rd_en => output_rd_en,
        len_rd_en => len_rd_en,
        din => din,
        dout => dout,
        length => length,
        input_full => input_full,
        output_empty => output_empty,
        len_empty => len_empty
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
        file input_file : raw_file;
        variable char : character;
        variable count : natural := 0;
        variable ln : line;
        variable packet_length : std_logic_vector (PCAP_DATA_LENGTH_BYTES * BYTE - 1 downto 0) := (others => '0');
    begin
        wait until (reset = '1');
        wait until (reset = '0');
        file_open (input_file, DATA_IN, read_mode);
        -- read and discard global pcap header
        for i in 0 to PCAP_GLOBAL_HEADER_BYTES - 1 loop
            read (input_file, char);
        --hwrite (ln, to_slv(char));
        --writeline (output, ln);
        end loop;
        wait until (input_clk = '1');
        start <= '1';
        wait until (input_clk = '0');
        wait until (input_clk = '1');
        start <= '0';
        while (not ENDFILE(input_file)) loop
            -- get packet length
            for i in 0 to PCAP_DATA_HEADER_BYTES - 1 loop
                read (input_file, char);
                packet_length := to_slv(char) & packet_length(PCAP_DATA_LENGTH_BYTES * BYTE - 1 downto BYTE);
            end loop;
            report integer'image(to_integer(unsigned(packet_length)));
            input_wr_en <= '0';
            wait until (input_clk = '0');
            input_wr_en <= '1';
            din <= std_logic_vector(to_unsigned(START_OF_FRAME, DWIDTH));
            wait until (input_clk = '1');
            count := 0;
            while (count < unsigned(packet_length) and not ENDFILE(input_file)) loop
                wait until (input_clk = '0');
                input_wr_en <= '0';
                if (input_full = '0') then
                    count := count + 1;
                    input_wr_en <= '1';
                    read (input_file, char);
                    din <= to_slv(char);
                end if;
                wait until (input_clk = '1');
            end loop;
        end loop;
        file_close (input_file);
        wait;
    end process; 

    read_output_process : process
        file output_file : text;
        variable char : std_logic_vector (BYTE - 1 downto 0);
        variable count : natural := 0;
        variable len : natural := 0;
        variable ln : line;
    begin
        wait until (start = '1');
        wait until (output_clk = '1');
        wait until (output_clk = '0');
        file_open (output_file, DATA_OUT, read_mode);
        while (not ENDFILE(output_file)) loop
            len_rd_en <= '0';
            wait until (len_empty = '0');
            wait until (output_clk = '0');
            len_rd_en <= '1';
            wait until (output_clk = '1');
            len := to_integer(unsigned(length));
            wait until (output_clk = '0');
            len_rd_en <= '0';
            for i in 0 to len loop
                wait until (output_clk = '0');
                output_rd_en <= '0';
                if (output_empty = '0') then
                    output_rd_en <= '1';
                    wait until (output_clk = '1');
                    readline (output_file, ln);
                    hread (ln, char);
                    count := count + 1;
                    if (unsigned(char) /= unsigned(dout)) then
                        read_errors <= read_errors + 1;
                        write (ln, string'("Error at line "));
                        write (ln, count);
                        write (ln, string'(": "));
                        hwrite (ln, char);
                        write (ln, string'(" != "));
                        hwrite (ln, dout);
                        writeline (output, ln);
                    end if;
                else
                    wait until (output_clk = '1');
                end if;
            end loop;
        end loop;
        file_close (output_file);
        done <= '1';
        wait;
    end process; 

    --    read_output_process : process
    --        file output_file : text;
    --        variable char : std_logic_vector (BYTE - 1 downto 0);
    --        variable count : natural;
    --        variable ln : line;
    --    begin
    --        wait until (start = '1');
    --        wait until (output_clk = '1');
    --        wait until (output_clk = '0');
    --        file_open (output_file, DATA_OUT, read_mode);
    --        while (not ENDFILE(output_file)) loop
    --            wait until (output_clk = '0');
    --            output_rd_en <= '0';
    --            if (output_empty = '0') then
    --                output_rd_en <= '1';
    --                readline (output_file, ln);
    --                hread (ln, char);
    --                wait until (output_clk = '1');
    --                count := count + 1;
    --                if (unsigned(char) /= unsigned(dout)) then
    --                    read_errors <= read_errors + 1;
    --                    write (ln, string'("Error at line "));
    --                    write (ln, count);
    --                    write (ln, string'(": "));
    --                    hwrite (ln, char);
    --                    write (ln, string'(" != "));
    --                    hwrite (ln, dout);
    --                    writeline (output, ln);
    --                end if;
    --            else
    --                wait until (output_clk = '1');
    --            end if;
    --        end loop;
    --        file_close (output_file);
    --        done <= '1';
    --        wait;
    --    end process; 

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
