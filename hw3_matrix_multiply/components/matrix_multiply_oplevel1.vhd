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
    TYPE int_array is array (0 to N - 1) of std_logic_vector (DWIDTH - 1 downto 0);
    signal row_a, col_b, row_a_c, col_b_c : int_array; 
    signal i, i_c, j, j_c, k, k_c : std_logic_vector (AWIDTH - 1 downto 0);
    signal done_o, done_c : std_logic;
begin

    --    get_sums : for i in 0 to N - 1 generate
    --        first_sum: if i = 0 generate
    --            sums(i) <= resize(unsigned(row_a(i)) * unsigned(row_b(i)), DWIDTH);
    --        end generate;
    --        other_sums: if i > 0 generate
    --            sums(i) <= resize(unsigned(row_a(i)) * unsigned(row_b(i)), DWIDTH) + sums(i - 1);
    --        end generate;
    --    end generate;

    multiply_process : process (multiply_state, start, done_o, i, j, k, row_a_c, col_b_c)
        variable i_temp, j_temp : std_logic_vector (AWIDTH - 1 downto 0);
        variable sum : std_logic_vector (DWIDTH - 1 downto 0);
    begin
        i_c <= i;
        j_c <= j;
        done_c <= done_o;
        next_multiply_state <= multiply_state;

        c_wr_addr <= (others => '0');
        c_din <= (others => '0');
        c_wr_en <= '0';

        case (multiply_state) is
            when init =>
                i_c <= (others => '0');
                j_c <= (others => '0');
                if (start = '1') then
                    done_c <= '0';
                    next_multiply_state <= exec;
                end if;

            when exec =>
                next_multiply_state <= exec;
                done_c <= '0';
                c_wr_addr <= std_logic_vector(resize(unsigned(i) * N, AWIDTH) + unsigned(j));
                c_wr_en <= '0';

                sum := (others => '0'); 
                for ii in 0 to N - 1 loop
                    sum := std_logic_vector(unsigned(sum) + resize(unsigned(row_a_c(ii)) * unsigned(col_b_c(ii)), DWIDTH));
                end loop;
                c_din <= sum;

                if (unsigned(k) = N - 1) then
                    c_wr_en <= '1';
                    j_c <= std_logic_vector(unsigned(j) + 1);
                    if (unsigned(j) = N - 1) then
                        j_c <= (others => '0');
                        i_c <= std_logic_vector(unsigned(i) + 1);
                        if (unsigned(i) = N - 1) then
                            i_c <= (others => '0');
                            done_c <= '1';
                            next_multiply_state <= init;
                        end if;
                    end if;
                end if;

            when others =>
                c_wr_addr <= (others => 'X');
                c_wr_en <= 'X';
                c_din <= (others => 'X');
                i_c <= (others => 'X');
                j_c <= (others => 'X');
                done_c <= 'X';
                next_multiply_state <= init;
        end case;
    end process;

    load_process : process (load_state, start, done_o, i_c, j_c, k, row_a, col_b, a_dout, b_dout)
        variable k_temp : std_logic_vector (AWIDTH - 1 downto 0) := (others => '0');
    begin
        k_c <= k;
        next_load_state <= load_state;
        a_rd_addr <= (others => '0');
        b_rd_addr <= (others => '0');
        row_a_c <= row_a;
        col_b_c <= col_b;

        case (load_state) is
            when init => 
                k_c <= (others => '0');
                if (start = '1') then
                    a_rd_addr <= (others => '0');
                    b_rd_addr <= (others => '0');
                    next_load_state <= exec;
                    row_a_c <= (others => (others => '0'));
                    col_b_c <= (others => (others => '0'));
                end if;

            when exec =>
                k_temp := std_logic_vector(unsigned(k) + 1);
                if (unsigned(k) = N - 1) then
                    k_temp := (others => '0');
                end if;
                k_c <= k_temp;
                row_a_c(to_integer(unsigned(k))) <= a_dout;
                col_b_c(to_integer(unsigned(k))) <= b_dout;
                a_rd_addr <= std_logic_vector(resize(unsigned(i_c) * N, AWIDTH) + unsigned(k_temp));
                b_rd_addr <= std_logic_vector(resize(unsigned(k_temp) * N, AWIDTH) + unsigned(j_c));
                next_load_state <= exec;
                if (done_o = '1') then
                    next_load_state <= init;
                end if;

            when others =>
                a_rd_addr <= (others => 'X');
                b_rd_addr <= (others => 'X');
                k_c <= (others => 'X');
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
            k <= (others => '0');
        elsif (rising_edge(clock)) then
            multiply_state <= next_multiply_state;
            load_state <= next_load_state;
            done_o <= done_c;
            i <= i_c;
            j <= j_c;
            k <= k_c;
            row_a <= row_a_c;
            col_b <= col_b_c;
        end if;
    end process;

    done <= done_o;
end architecture;
