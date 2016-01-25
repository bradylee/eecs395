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
    TYPE state_type is (init, exec);
    signal state, next_state : state_type;
    signal i, i_c, j, j_c, k, k_c : std_logic_vector (AWIDTH - 1 downto 0);
    signal done_o, done_c : std_logic;
    signal sum, sum_c : std_logic_vector (DWIDTH - 1 downto 0);
begin
    matrix_multiply_fsm_process : process (state, a_dout, b_dout, start, done_o, i, j, k, sum)
        variable i_temp, j_temp, k_temp : std_logic_vector (AWIDTH - 1 downto 0);
        variable sum_new, sum_temp : std_logic_vector (DWIDTH - 1 downto 0);
    begin
        i_c <= i;
        j_c <= j;
        k_c <= k;
        done_c <= done_o;
        next_state <= state;
        sum_c <= sum;

        a_rd_addr <= (others => '0');
        b_rd_addr <= (others => '0');
        c_wr_addr <= (others => '0');
        c_din <= (others => '0');
        c_wr_en <= '0';

        case (state) is
            when init =>
                i_c <= (others => '0');
                j_c <= (others => '0');
                k_c <= (others => '0');
                if (start = '1') then
                    done_c <= '0';
                    a_rd_addr <= (others => '0');
                    b_rd_addr <= (others => '0');
                    sum_c <= (others => '0');
                    next_state <= exec;
                end if;

            when exec =>
                c_wr_en <= '1';
                next_state <= exec;
                done_c <= '0';

                i_temp := i;
                j_temp := j;

                --TODO: test mod new vs comp old
                k_temp := std_logic_vector(unsigned(k) + 1);
                if (unsigned(k) = N - 1) then
                    k_temp := (others => '0');
                    j_temp := std_logic_vector(unsigned(j) + 1);
                    if (unsigned(j) = N - 1) then
                        j_temp := (others => '0');
                        i_temp := std_logic_vector(unsigned(i) + 1);
                        if (unsigned(i) = N - 1) then
                            next_state <= init;
                            done_c <= '1';
                        end if;
                    end if;
                end if;

                k_c <= k_temp;
                j_c <= j_temp;
                i_c <= i_temp;

                --TODO: test slice vs resize
                a_rd_addr <= std_logic_vector(resize(unsigned(i_temp) * N, AWIDTH) + unsigned(k_temp));
                b_rd_addr <= std_logic_vector(resize(unsigned(k_temp) * N, AWIDTH) + unsigned(j_temp));
                sum_new := std_logic_vector(resize(unsigned(a_dout) * unsigned(b_dout), DWIDTH));
                if (unsigned(k) = 0) then
                    sum_temp := sum_new;
                else
                    sum_temp := std_logic_vector(unsigned(sum) + unsigned(sum_new));
                end if;
                c_wr_addr <= std_logic_vector(resize(unsigned(i) * N, AWIDTH) + unsigned(j));
                sum_c <= sum_temp;
                c_din <= sum_temp;

            when others =>
                a_rd_addr <= (others => 'X');
                b_rd_addr <= (others => 'X');
                c_wr_addr <= (others => 'X');
                c_wr_en <= 'X';
                c_din <= (others => 'X');
                i_c <= (others => 'X');
                j_c <= (others => 'X');
                k_c <= (others => 'X');
                done_c <= 'X';
                next_state <= init;
        end case;
    end process;

    matrix_multiply_clock : process (reset, clock)
    begin
        if (reset = '1') then
            state <= init;
            done_o <= '0';
            i <= (others => '0');
            j <= (others => '0');
            k <= (others => '0');
            sum <= (others => '0');
        elsif (rising_edge(clock)) then
            state <= next_state;
            done_o <= done_c;
            i <= i_c;
            j <= j_c;
            k <= k_c;
            sum <= sum_c;
        end if;
    end process;
    done <= done_o;
end architecture;
