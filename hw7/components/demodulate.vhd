library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants.all;
use work.functions.all;
use work.dependent.all;

entity demodulate is
    generic
    (
        GAIN : natural := FM_DEMOD_GAIN
    );
    port 
    (
        clock : in std_logic;
        reset : in std_logic;
        real_din : in std_logic_vector (WORD_SIZE - 1 downto 0);
        imag_din : in std_logic_vector (WORD_SIZE - 1 downto 0);
        real_empty : in std_logic;
        imag_empty : in std_logic;
        demod_full : in std_logic;
        real_rd_en : out std_logic;
        imag_rd_en : out std_logic;
        demod_dout : out std_logic_vector (WORD_SIZE - 1 downto 0);
        demod_wr_en : out std_logic
    );
end entity;

architecture behavioral of demodulate is
    type demod_state_type is (init, read, divide, write);
    signal state, next_state : demod_state_type := init;
    signal real_prev, real_prev_c : std_logic_vector (WORD_SIZE - 1 downto 0);
    signal imag_prev, imag_prev_c : std_logic_vector (WORD_SIZE - 1 downto 0);
    signal dividend, dividend_c : signed (WORD_SIZE - 1 downto 0);
    signal divisor, divisor_c : signed (WORD_SIZE - 1 downto 0);
    signal quotient, quotient_c : signed (WORD_SIZE - 1 downto 0);
    signal quad_a, quad_a_c : integer := 0; 
    signal quad_b, quad_b_c : integer := 0;
    signal a, a_c : signed (WORD_SIZE - 1 downto 0) := (others => '0');
    signal b, b_c : signed (WORD_SIZE - 1 downto 0) := (others => '0');
    signal q, q_c : signed (WORD_SIZE - 1 downto 0) := (others => '0');
    signal y, y_c : signed (WORD_SIZE - 1 downto 0) := (others => '0');
begin

    demod_process : process (state, real_prev, imag_prev, dividend, divisor, quotient, quad_a, quad_b, a, b, q, y, real_din, imag_din, real_empty, imag_empty, demod_full)
        variable r, i : signed (WORD_SIZE - 1 downto 0) := (others => '0');
        variable dividend_v, divisor_v : signed (WORD_SIZE - 1 downto 0) := (others => '0');
        variable p : integer := 0;
        variable sign : std_logic := '0';
        variable angle : signed (WORD_SIZE - 1 downto 0) := (others => '0');
    begin
        next_state <= state;
        real_prev_c <= real_prev;
        imag_prev_c <= imag_prev;
        dividend_c <= dividend;
        divisor_c <= divisor;
        quotient_c <= quotient;
        quad_a_c <= quad_a;
        quad_b_c <= quad_b;
        a_c <= a;
        b_c <= b;
        q_c <= q;
        y_c <= y;

        real_rd_en <= '0';
        imag_rd_en <= '0';
        demod_wr_en <= '0';
        demod_dout <= (others => '0');

        dividend_v := (others => '0');
        divisor_v := (others => '0');
        angle := (others => '0');

        case (state) is
            when init =>
                if (real_empty = '0' and imag_empty = '0') then
                    real_prev_c <= (others => '0');
                    imag_prev_c <= (others => '0');
                    dividend_c <= (others => '0');
                    divisor_c <= (others => '0');
                    quotient_c <= (others => '0');
                    a_c <= (others => '0');
                    b_c <= (others => '0');
                    q_c <= (others => '0');
                    quad_a_c <= 0;
                    quad_b_c <= 0; 
                    y_c <= (others => '0');
                    next_state <= read;
                end if;

            when read =>
                if (real_empty = '0') then
                    dividend_c <= (others => '0');
                    divisor_c <= (others => '0');
                    quotient_c <= (others => '0');
                    a_c <= (others => '0');
                    b_c <= (others => '0');
                    q_c <= (others => '0');
                    quad_a_c <= 0;
                    quad_b_c <= 0; 
                    y_c <= (others => '0');

                    real_rd_en <= '1';
                    imag_rd_en <= '1';

                    r := DEQUANTIZE(signed(real_din) * signed(real_prev)) - DEQUANTIZE(-signed(imag_prev) * signed(imag_din));
                    i := DEQUANTIZE(signed(imag_din) * signed(real_prev)) + DEQUANTIZE(-signed(imag_prev) * signed(real_din));
                    y_c <= i;
                    i := abs(i) + 1;

                    real_prev_c <= real_din;
                    imag_prev_c <= imag_din;

                    if (r >= 0) then
                        --angle = QUAD1 - DEQUANTIZE(QUAD1 * DIV(QUANTIZE(r - i), r + i))
                        quad_a_c <= QUAD1;
                        quad_b_c <= QUAD1;
                        dividend_v := QUANTIZE(r - i);
                        divisor_v := r + i;
                    else
                        --angle = QUAD3 - DEQUANTIZE(QUAD3 * DIV(QUANTIZE(r + i), i - r))
                        quad_a_c <= QUAD3; 
                        quad_b_c <= QUAD1;
                        dividend_v := QUANTIZE(r + i);
                        divisor_v := i - r;
                    end if;

                    dividend_c <= dividend_v;
                    divisor_c <= divisor_v;
                    a_c <= abs(dividend_v);
                    b_c <= abs(divisor_v);

                    next_state <= divide;
                end if;

            when divide =>
                if (b = 1) then
                    q_c <= a;
                    a_c <= (others => '0'); 
                end if;

                if (a >= b) then
                    p := GET_MSB(a) - GET_MSB(b);
                    if ((b sll p) > a) then
                        p := p - 1;
                    end if;
                    q_c <= q + (to_signed(1, WORD_SIZE) sll p);
                    a_c <= a - (b sll p);
                else
                    quotient_c <= q; 
                    sign := dividend(WORD_SIZE - 1) xor divisor(WORD_SIZE - 1);
                    if (sign = '1') then
                        quotient_c <= -q; 
                    end if;
                    next_state <= write;
                end if;

            when write =>
                if (demod_full = '0') then
                    angle := quad_a - DEQUANTIZE(quad_b * quotient);
                    if (y < 0) then
                        angle := -angle;
                    end if;
                    demod_dout <= std_logic_vector(DEQUANTIZE(GAIN * angle));
                    demod_wr_en <= '1';
                    next_state <= read;
                end if;

            when others =>
                next_state <= state;

        end case;
    end process;

    clock_process : process (clock, reset)
    begin 
        if (reset = '1') then
            state <= init;
            real_prev <= (others => '0'); 
            imag_prev <= (others => '0'); 
            dividend <= (others => '0');  
            divisor <= (others => '0');  
            quotient <= (others => '0');  
            quad_a <= 0; 
            quad_b <= 0; 
            a <= (others => '0'); 
            b <= (others => '0'); 
            q <= (others => '0'); 
            y <= (others => '0'); 
        elsif (rising_edge(clock)) then
            state <= next_state;
            real_prev <= real_prev_c;
            imag_prev <= imag_prev_c;
            dividend <= dividend_c;
            divisor <= divisor_c;
            quotient <= quotient_c;
            quad_a <= quad_a_c;
            quad_b <= quad_b_c;
            a <= a_c;
            b <= b_c;
            q <= q_c;
            y <= y_c;
        end if;
    end process;

end architecture;
