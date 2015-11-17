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
    signal a_mat, a_mat_c, b_mat, b_mat_c : int_array (0 to N*N - 1);
    signal i, i_c : std_logic_vector (AWIDTH - 1 downto 0);
    signal done_o, done_c : std_logic;
    signal c_mat_o : int_array (0 to N*N - 1);
begin
    multiply_process : process (multiply_state, start, done_o, i, a_mat, b_mat)
        variable sum : std_logic_vector (DWIDTH - 1 downto 0);
        variable c_mat : int_array (0 to N*N - 1);
    begin
        next_multiply_state <= multiply_state;
        done_c <= done_o;
        c_wr_en <= '0';
        c_din <= (others => '0');
        c_wr_addr <= (others => '0');
        c_mat_o <= (others => (others => '0'));

        case (multiply_state) is
            when init =>
                c_wr_en <= '0';
                if (unsigned(i) = N*N - 1) then
                    done_c <= '0';
                    c_wr_addr <= (others => '0');
                    next_multiply_state <= exec;
                end if;

            when exec =>
                next_multiply_state <= exec;
                done_c <= '0';
                c_wr_en <= '1';

                for ii in 0 to N - 1 loop
                    for jj in 0 to N - 1 loop
                        sum := (others => '0'); 
                        for kk in 0 to N - 1 loop
                            sum := std_logic_vector(unsigned(sum) + resize(unsigned(a_mat(ii*N + kk)) * unsigned(b_mat(kk*N + jj)), DWIDTH));
                        end loop;
                        c_mat(ii*N + jj) := sum;
                    end loop;
                end loop;

                c_mat_o <= c_mat;

                c_din <= c_mat(to_integer(unsigned(i))); 
                c_wr_addr <= std_logic_vector(unsigned(i));
                
                if (unsigned(i) = N*N - 1) then
                    done_c <= '1';
                    next_multiply_state <= init;
                end if;

            when others =>
                c_din <= (others => 'X');
                c_wr_addr <= (others => 'X');
                done_c <= 'X';
                next_multiply_state <= init;
        end case;
    end process;

    load_process : process (load_state, start, done_o, i, a_mat, b_mat, a_dout, b_dout)
        variable i_temp : std_logic_vector (AWIDTH - 1 downto 0) := (others => '0');
    begin
        i_c <= i;
        a_mat_c <= a_mat;
        b_mat_c <= b_mat;
        next_load_state <= load_state;

        a_rd_addr <= (others => '0');
        b_rd_addr <= (others => '0');

        case (load_state) is
            when init => 
                if (start = '1') then
                    a_rd_addr <= (others => '0');
                    b_rd_addr <= (others => '0');
                    a_mat_c <= (others => (others => '0'));
                    b_mat_c <= (others => (others => '0'));
                    next_load_state <= exec;
                end if;

            when exec =>
                next_load_state <= exec;

                i_temp := std_logic_vector(unsigned(i) + 1);
                if (unsigned(i) = N*N - 1) then
                    i_temp := (others => '0');
                end if;
                i_c <= i_temp;

                a_rd_addr <= std_logic_vector(unsigned(i_temp));
                b_rd_addr <= std_logic_vector(unsigned(i_temp));
                
                a_mat_c(to_integer(unsigned(i))) <= a_dout;
                b_mat_c(to_integer(unsigned(i))) <= b_dout;

                if (done_o = '1') then
                    next_load_state <= init;
                end if;

            when others =>
                a_rd_addr <= (others => 'X');
                b_rd_addr <= (others => 'X');
                a_mat_c <= (others => (others => 'X'));
                b_mat_c <= (others => (others => 'X'));
                i_c <= (others => 'X');
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
        elsif (rising_edge(clock)) then
            multiply_state <= next_multiply_state;
            load_state <= next_load_state;
            done_o <= done_c;
            i <= i_c;
            a_mat <= a_mat_c;
            b_mat <= b_mat_c;
        end if;
    end process;

    done <= done_o;
end architecture;
