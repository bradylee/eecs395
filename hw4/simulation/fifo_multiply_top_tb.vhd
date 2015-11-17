library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;
use work.constants.all;

entity fifo_multiply_top_tb is
    generic
    (
    constant X_NAME : string (16 downto 1) := "../scripts/a.txt";
    constant Y_NAME : string (16 downto 1) := "../scripts/b.txt";
    constant Z_NAME : string (16 downto 1) := "../scripts/c.txt";
    constant CLOCK_PERIOD : time := 2 ns;
    constant BUFFER_SIZE : integer := 64
);
end entity;

architecture behavior of fifo_multiply_top_tb is

    constant DWIDTH : integer := 32;
    constant AWIDTH : integer := 6;

    -- clock, reset signals
    signal rd_clk : std_logic := '1';
    signal wr_clk : std_logic := '0';
    signal reset : std_logic := '0';
    signal start : std_logic := '0';
    signal done : std_logic := '0';

    -- memory ports
    signal a_din, b_din : std_logic_vector (DWIDTH - 1 downto 0) := (others => '0');
    signal c_dout : std_logic_vector (DWIDTH - 1 downto 0) := (others => '0');
    signal a_wr_en, b_wr_en : std_logic := '0';
    signal c_rd_en : std_logic := '0';
    signal a_full, b_full : std_logic;
    signal c_empty : std_logic;

    -- process sync signals
    signal hold_clock : std_logic := '0';
    signal a_write_done : std_logic := '0';
    signal b_write_done : std_logic := '0';
    signal c_read_done : std_logic := '0';
    signal c_errors : integer := 0;

begin

    top_inst : component fifo_multiply_top
    generic map
    (
        N => 8,
        BUFFER_SIZE => 64,
        DWIDTH => 32,
        AWIDTH => 6
    )
    port map
    (
        rd_clk => rd_clk,
        wr_clk => wr_clk,
        reset => reset,
        done => done,
        a_din => a_din,
        b_din => b_din,
        c_dout => c_dout,
        a_wr_en => a_wr_en,
        b_wr_en => b_wr_en,
        c_rd_en => c_rd_en,
        a_full => a_full,
        b_full => b_full,
        c_empty => c_empty
    );

    clock_process : process 
    begin 
        rd_clk <= '1';
        wr_clk <= '0'; 
        wait for CLOCK_PERIOD / 2; 
        rd_clk <= '0'; 
        wr_clk <= '1';
        wait for CLOCK_PERIOD / 2; 
        if (hold_clock = '1') then
            wait; 
        end if; 
    end process;

    reset_process: process 
    begin reset <= '0'; 
        wait until rd_clk = '0'; 
        wait until rd_clk = '1'; 
        reset <= '1'; 
        wait until rd_clk = '0'; 
        wait until rd_clk = '1'; 
        reset <= '0'; 
        wait; 
    end process;

    a_write_process : process 
        file a_file : text; 
        variable rdx : std_logic_vector (DWIDTH - 1 downto 0); 
        variable ln1, ln2 : line; 
    begin 
        wait until (reset = '1'); 
        wait until (reset = '0');
        wait until (start = '1');
        write( ln1, string'("@ ") ); 
        write( ln1, NOW ); 
        write( ln1, string'(": Loading file ") ); 
        write( ln1, X_NAME ); 
        write( ln1, string'("...") ); 
        writeline( output, ln1 );
        file_open( a_file, X_NAME, read_mode );
        for x in 0 to (BUFFER_SIZE - 1) loop 
            wait until (wr_clk = '1'); 
            readline( a_file, ln2 ); 
            hread( ln2, rdx ); 
            a_din <= std_logic_vector(resize(unsigned(rdx), DWIDTH)); 
            a_wr_en <= '1'; 
            wait until (wr_clk = '0'); 
        end loop;
        wait until (wr_clk = '1'); 
        a_wr_en <= '0'; 
        file_close( a_file ); 
        --        a_write_done <= '1'; 
        wait; 
    end process a_write_process;

    b_write_process : process 
        file b_file : text; 
        variable rdy : std_logic_vector (DWIDTH - 1 downto 0); 
        variable ln1, ln2 : line; 
    begin 
        wait until (reset = '1'); 
        wait until (reset = '0');
        wait until (start = '1');
        write( ln1, string'("@ ") ); 
        write( ln1, NOW ); 
        write( ln1, string'(": Loading file ") ); 
        write( ln1, Y_NAME ); 
        write( ln1, string'("...") ); 
        writeline( output, ln1 );
        file_open( b_file, Y_NAME, read_mode );
        for y in 0 to (BUFFER_SIZE - 1) loop 
            wait until (wr_clk = '1'); 
            readline( b_file, ln2 ); 
            hread( ln2, rdy ); 
            b_din <= std_logic_vector(resize(unsigned(rdy), DWIDTH)); 
            b_wr_en <= '1';
            wait until (wr_clk = '0'); 
        end loop;
        wait until (wr_clk = '1'); 
        b_wr_en <= '0';
        file_close( b_file ); 
        --        b_write_done <= '1'; 
        wait; 
    end process b_write_process;

    c_read_process : process 
        file c_file : text; 
        variable rdz : std_logic_vector (DWIDTH - 1 downto 0); 
        variable ln1, ln2 : line; 
        variable z : integer := 0; 
        variable c_data_read : std_logic_vector (DWIDTH - 1 downto 0); 
        variable c_data_cmp : std_logic_vector (DWIDTH - 1 downto 0); 
    begin 
        wait until (reset = '1'); 
        wait until (reset = '0'); 
        wait until (rd_clk = '1'); 
        wait until (rd_clk = '0');
        wait until (c_empty = '0');
        write( ln1, string'("@ ") ); 
        write( ln1, NOW ); 
        write( ln1, string'(": Comparing file ") ); 
        write( ln1, Z_NAME ); 
        writeline( output, ln1 );
        file_open( c_file, Z_NAME, read_mode ); 
        for z in 0 to (BUFFER_SIZE - 1) loop
            wait until (rd_clk = '0'); 
            c_rd_en <= '1';
            wait until (rd_clk = '1'); 
            --wait until (rd_clk = '0'); 
            readline( c_file, ln2 );
            hread( ln2, rdz ); 
            c_data_cmp := std_logic_vector(resize(unsigned(rdz), DWIDTH)); 
            c_data_read := c_dout; 
            if ( to_01(unsigned(c_data_read)) /= to_01(unsigned(c_data_cmp)) ) then
                c_errors <= c_errors + 1; 
                write( ln2, string'("@ ") ); 
                write( ln2, NOW ); 
                write( ln2, string'(": ") ); 
                write( ln2, Z_NAME ); 
                write( ln2, string'("(") ); 
                write( ln2, z + 1 ); 
                write( ln2, string'("): ERROR: ") ); 
                hwrite( ln2, c_data_read ); 
                write( ln2, string'(" != ") ); 
                hwrite( ln2, c_data_cmp ); 
                write( ln2, string'(" at address 0x") ); 
                hwrite( ln2, std_logic_vector(to_unsigned(z,32)) ); 
                write( ln2, string'(".") ); 
                writeline( output, ln2 ); 
            end if; 
            --wait until (rd_clk = '1'); 
        end loop;
        file_close(c_file);
        c_read_done <= '1';
        wait;
    end process;

    tb_process : process 
        variable errors : integer := 0; 
        variable warnings : integer := 0; 
        variable start_time : time; 
        variable end_time : time; 
        variable ln1, ln2, ln3, ln4 : line; 
    begin 
        wait until (reset = '1'); 
        wait until (reset = '0'); 
        --        wait until ((a_write_done = '1') and (b_write_done = '1'));
        wait until (wr_clk = '0'); 
        wait until (wr_clk = '1');
        start_time := NOW; 
        write( ln1, string'("@ ") ); 
        write( ln1, start_time ); 
        write( ln1, string'(": Beginning simulation...") ); 
        writeline( output, ln1 );
        start <= '1'; 
        wait until (wr_clk = '0');
        wait until (wr_clk = '1'); 
        start <= '0'; 
        wait until  (done = '1');
        end_time := NOW; 
        write( ln2, string'("@ ") ); 
        write( ln2, end_time ); 
        write( ln2, string'(": Simulation completed.") ); 
        writeline( output, ln2 );
        --        wait until (c_read_done = '1'); 
        wait until (c_empty = '1');
        errors := c_errors;
        write( ln3, string'("Total simulation cycle count: ") ); 
        write( ln3, (end_time - start_time) / CLOCK_PERIOD ); 
        writeline( output, ln3 ); 
        write( ln4, string'("Total error count: ") ); 
        write( ln4, errors ); 
        writeline( output, ln4 );
        hold_clock <= '1'; 
        wait; 
    end process tb_process;

end architecture;
