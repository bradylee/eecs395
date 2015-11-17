library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo_multiply is
    generic
    (
        N : natural := 8;
        DWIDTH : natural := 32;
        AWIDTH : natural := 6
    );
    port
    (
        signal rd_clk : in std_logic;
        signal wr_clk : in std_logic;
        signal reset : in std_logic;
        signal a_dout : in std_logic_vector (DWIDTH - 1 downto 0);
        signal b_dout : in std_logic_vector (DWIDTH - 1 downto 0);
        signal c_din : out std_logic_vector (DWIDTH - 1 downto 0);
        signal a_rd_en : out std_logic;
        signal b_rd_en : out std_logic;
        signal c_wr_en : out std_logic;
        signal a_empty : in std_logic;
        signal b_empty : in std_logic;
        signal c_empty : in std_logic;
        signal a_full : in std_logic;
        signal b_full : in std_logic;
        signal c_full : in std_logic;
        signal done : out std_logic
    );
end entity;

architecture behavioral of fifo_multiply is
    type fsm_process_type is (init, exec);
    signal state_a_rd, next_state_a_rd : fsm_process_type;
    signal state_b_rd, next_state_b_rd : fsm_process_type;
    signal state_c_wr, next_state_c_wr : fsm_process_type;
    type VECTOR_ARRAY is array (natural range <>) of std_logic_vector (DWIDTH - 1 downto 0);
    signal a_mat, a_mat_c : VECTOR_ARRAY (0 to N*N - 1);
    signal b_mat, b_mat_c : VECTOR_ARRAY (0 to N*N - 1);
    signal a_index, a_index_c : std_logic_vector (AWIDTH - 1 downto 0);
    signal b_index, b_index_c : std_logic_vector (AWIDTH - 1 downto 0);
    signal i, i_c, j, j_c : std_logic_vector (AWIDTH - 1 downto 0);
    signal done_o, done_c : std_logic;
    signal a_ready, a_ready_c, b_ready, b_ready_c : std_logic;
    signal c_start : std_logic;
begin

    a_rd_process : process (state_a_rd, a_ready, a_empty, a_dout, a_mat, a_index, done_o) is
    begin
        next_state_a_rd <= state_a_rd;
        a_mat_c <= a_mat;
        a_index_c <= a_index;
        a_rd_en <= '0';
        a_ready_c <= a_ready;

        case (state_a_rd) is
            when init =>
                a_rd_en <= '0';
                if (a_empty = '0') then
                    a_index_c <= (others => '0');
                    a_mat_c <= (others => (others => '0'));
                    next_state_a_rd <= exec;
                    a_ready_c <= '0';
                end if;

            when exec =>
                next_state_a_rd <= exec;
                if (a_empty = '0') then
                    a_rd_en <= '1';
                    if (unsigned(a_index) = N*N - 1) then
                        --a_index_c <= (others => '0');
                        next_state_a_rd <= init;
                        a_ready_c <= '1';
                    else
                        a_index_c <= std_logic_vector(unsigned(a_index) + 1);
                    end if;
                    a_mat_c(to_integer(unsigned(a_index))) <= a_dout;
                end if;
        end case;
    end process;

    b_rd_process : process (state_b_rd, b_ready, b_empty, b_dout, b_mat, b_index) is
    begin
        next_state_b_rd <= state_b_rd;
        b_mat_c <= b_mat;
        b_index_c <= b_index;
        b_rd_en <= '0';
        b_ready_c <= b_ready;

        case (state_b_rd) is
            when init =>
                b_rd_en <= '0';
                if (b_empty = '0') then
                    b_index_c <= (others => '0');
                    b_mat_c <= (others => (others => '0'));
                    next_state_b_rd <= exec;
                    b_ready_c <= '0';
                end if;

            when exec =>
                next_state_b_rd <= exec;
                if (b_empty = '0') then
                    b_rd_en <= '1';
                    if (unsigned(b_index) = N*N - 1) then
                        --b_index_c <= (others => '0');
                        next_state_b_rd <= init;
                        b_ready_c <= '1';
                    else
                        b_index_c <= std_logic_vector(unsigned(b_index) + 1);
                    end if;
                    b_mat_c(to_integer(unsigned(b_index))) <= b_dout;
                end if;
        end case;
    end process;

    c_wr_process : process (state_c_wr, a_ready, b_ready, done_o, c_full, a_index, b_index, a_empty, b_empty, i, j, a_mat, b_mat) is
        variable sum : std_logic_vector (DWIDTH - 1 downto 0);
    begin
        next_state_c_wr <= state_c_wr;
        c_din <= (others => '0');
        c_wr_en <= '0';
        i_c <= i;
        j_c <= j;
        done_c <= done_o;

        case (state_c_wr) is
            when init => 
                done_c <= '0';
                c_wr_en <= '0';
                if (a_ready = '1' and b_ready = '1') then
                --if (unsigned(a_index) = N*N - 1 and unsigned(b_index) = N*N - 1 and a_empty = '1' and b_empty = '1') then
                    --if (unsigned(a_index) = N*N - 1 and unsigned(b_index) = N*N - 1 and (a_rd_en = '1' or b_rd_en = '1')) then
                    i_c <= (others => '0');
                    j_c <= (others => '0');
                    next_state_c_wr <= exec;
                end if;

            when exec =>
                next_state_c_wr <= exec;
                done_c <= '0';
                if (c_full = '0') then
                    c_wr_en <= '1';
                    j_c <= std_logic_vector(unsigned(j) + 1);
                    if (unsigned(j) = N - 1) then
                        j_c <= (others => '0');
                        i_c <= std_logic_vector(unsigned(i) + 1);
                        if (unsigned(i) = N - 1) then
                            i_c <= (others => '0');
                            done_c <= '1';
                            next_state_c_wr <= init;
                        end if;
                    end if;

                    sum := (others => '0');
                    for ii in 0 to N - 1 loop
                        sum := std_logic_vector(unsigned(sum) + resize(unsigned(a_mat(to_integer(unsigned(i) * N + ii))) * unsigned(b_mat(to_integer(ii * N + unsigned(j)))), DWIDTH));
                    end loop;
                    c_din <= sum;
                end if;
        end case;
    end process;

    rd_clock_process : process (rd_clk, reset) is
    begin
        if (reset = '1') then
            state_a_rd <= init;
            state_b_rd <= init;
            a_index <= (others => '0');
            b_index <= (others => '0');
            a_ready <= '0';
            b_ready <= '0';
        elsif (rising_edge(rd_clk)) then
            state_a_rd <= next_state_a_rd;
            state_b_rd <= next_state_b_rd;
            a_index <= a_index_c;
            b_index <= b_index_c;
            a_mat <= a_mat_c;
            b_mat <= b_mat_c;
            a_ready <= a_ready_c;
            b_ready <= b_ready_c;
        end if;
    end process;

    wr_clock_process : process (wr_clk, reset) is
    begin
        if (reset = '1') then
            done_o <= '0';
            state_c_wr <= init;
            i <= (others => '0');
            j <= (others => '0');
        elsif (rising_edge(wr_clk)) then
            done_o <= done_c;
            state_c_wr <= next_state_c_wr;
            i <= i_c;
            j <= j_c;
        end if;
    end process;

    done <= done_o;

end architecture;
