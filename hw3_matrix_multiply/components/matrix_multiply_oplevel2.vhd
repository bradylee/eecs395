library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants.all;

entity matrix_multiply is
    generic 
    (
        DWIDTH : natural := 32;
        AWIDTH : natural := 6;
        N : natural := 8
    );
    port 
    (
        signal clock : in std_logic;
        signal reset : in std_logic;
        signal start : in std_logic;
        signal done : out std_logic; 

        signal a_dout : in std_logic_vector (DWIDTH - 1 downto 0);
        signal b_dout : in std_logic_vector (DWIDTH - 1 downto 0);
        signal c_din : out std_logic_vector (DWIDTH - 1 downto 0);

        signal a_rd_addr : out std_logic_vector (AWIDTH - 1 downto 0);
        signal b_rd_addr : out std_logic_vector (AWIDTH - 1 downto 0);
        signal c_wr_addr : out std_logic_vector (AWIDTH - 1 downto 0);
        signal c_wr_en : out std_logic
    );
end entity;

architecture behavioral of matrix_multiply is
    TYPE multiply_state_type is (init, exec);
    signal multiply_state, next_multiply_state : multiply_state_type;
    TYPE load_state_type is (init, exec);
    signal load_state, next_load_state : load_state_type;
    TYPE int_array is array (natural range<>) of std_logic_vector (DWIDTH - 1 downto 0);
    signal row_a, row_a_c : int_array (0 to N - 1);
    signal b, b_c : int_array (0 to N**2 - 1);
    signal row_c, row_c_c : int_array (0 to N - 1);
    signal i, i_c, j, j_c : std_logic_vector (AWIDTH - 1 downto 0);
    signal done_o, done_c : std_logic;
begin
    multiply_process : process (multiply_state, start, done_o, i, j, row_a, b, row_c, row_c_c)
        variable i_temp, j_temp : std_logic_vector (AWIDTH - 1 downto 0);
        variable sum : std_logic_vector (DWIDTH - 1 downto 0);
    begin
        next_multiply_state <= multiply_state;
        done_c <= done_o;
        row_c_c <= row_c;
        c_wr_en <= '0';
        c_din <= (others => '0');
        c_wr_addr <= (others => '0');

        case (multiply_state) is
            when init =>
                if (unsigned(i) = N - 1 and unsigned(j) = N - 1) then
                    done_c <= '0';
                    row_c_c <= (others => (others => '0'));
                    c_wr_addr <= (others => '0');
                    next_multiply_state <= exec;
                end if;

            when exec =>
                c_wr_en <= '1';
                next_multiply_state <= exec;
                done_c <= '0';

                if (unsigned(i) = N - 1 and unsigned(j) = N - 1) then
                    done_c <= '1';
                    next_multiply_state <= init;
                end if;

                for ii in 0 to N - 1 loop
                    sum := (others => '0'); 
                    for jj in 0 to N - 1 loop
                        sum := std_logic_vector(unsigned(sum) + resize(unsigned(row_a(jj)) * unsigned(b(jj*N + ii)), DWIDTH));
                    end loop;
                    row_c_c(ii) <= sum;
                end loop;

                if (unsigned(j) > 0) then
                    row_c_c <= row_c;
                end if;

                c_din <= row_c_c(to_integer(unsigned(j))); 
                c_wr_addr <= std_logic_vector(resize(unsigned(i) * N, AWIDTH) + unsigned(j));

            when others =>
                c_din <= (others => 'X');
                c_wr_addr <= (others => 'X');
                done_c <= 'X';
                next_multiply_state <= init;
        end case;
    end process;

    load_process : process (load_state, start, done_o, i, j, row_a, b, a_dout, b_dout)
        variable i_temp, j_temp : std_logic_vector (AWIDTH - 1 downto 0) := (others => '0');
    begin
        i_c <= i;
        j_c <= j;
        row_a_c <= row_a;
        b_c <= b;
        next_load_state <= load_state;

        a_rd_addr <= (others => '0');
        b_rd_addr <= (others => '0');

        case (load_state) is
            when init => 
                if (start = '1') then
                    b_rd_addr <= (others => '0');
                    b_c <= (others => (others => '0'));
                    next_load_state <= exec;
                end if;

            when exec =>
                next_load_state <= exec;

                j_temp := std_logic_vector(unsigned(j) + 1);
                i_temp := i;
                if (unsigned(j) = N - 1) then
                    j_temp := (others => '0');
                    i_temp := std_logic_vector(unsigned(i) + 1);
                    if (unsigned(i) = N - 1) then
                        i_temp := (others => '0');
                    end if;
                end if;

                i_c <= i_temp;
                j_c <= j_temp;

                b_rd_addr <= std_logic_vector(resize(unsigned(i_temp) * N, AWIDTH) + unsigned(j_temp));
               
                i_temp := std_logic_vector(unsigned(i_temp) + 1);
                if (unsigned(i_temp) = N) then
                    i_temp := (others => '0');
                end if;

                a_rd_addr <= std_logic_vector(resize(unsigned(i_temp) * N, AWIDTH) + unsigned(j_temp)); 
                row_a_c(to_integer(unsigned(j))) <= a_dout;
                b_c(to_integer(resize(unsigned(i) * N, DWIDTH) + unsigned(j))) <= b_dout;

            when others =>
                a_rd_addr <= (others => 'X');
                b_rd_addr <= (others => 'X');
                i_c <= (others => 'X');
                j_c <= (others => 'X');
                next_load_state <= init;
        end case;
    end process;

    clock_process : process (reset, clock)
    begin
        if (reset = '1') then
            multiply_state <= init;
            load_state <= init;
            done_o <= '0';
            i <= (others => '0');
            j <= (others => '0');
        elsif (rising_edge(clock)) then
            multiply_state <= next_multiply_state;
            load_state <= next_load_state;
            done_o <= done_c;
            i <= i_c;
            j <= j_c;
            row_a <= row_a_c;
            b <= b_c;
            row_c <= row_c_c;
        end if;
    end process;

    done <= done_o;
end architecture;
