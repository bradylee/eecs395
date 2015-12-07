library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants.all;

entity fir_complex is
    generic
    (
        --SAMPLES : natural := 65536*4;
        TAPS : natural := 20;
        DECIMATION : natural := 1
    );
    port 
    (
        clock : in std_logic;
        reset : in std_logic;
        real_din : in std_logic_vector (WORD_SIZE - 1 downto 0);
        imag_din : in std_logic_vector (WORD_SIZE - 1 downto 0);
        real_in_empty : in std_logic;
        imag_in_empty : in std_logic;
        real_out_full : in std_logic;
        imag_out_full : in std_logic;
        real_rd_en : out std_logic;
        imag_rd_en : out std_logic;
        real_dout : out std_logic_vector (WORD_SIZE - 1 downto 0);
        imag_dout : out std_logic_vector (WORD_SIZE - 1 downto 0);
        real_wr_en : out std_logic;
        imag_wr_en : out std_logic
    );
end entity;

architecture behavioral of fir_complex is
    --type read_state_type is (read_i, read_q);
    signal state, next_state : standard_state_type := init;
    signal real_buffer, real_buffer_c : quant_array (0 to TAPS - 1);
    signal imag_buffer, imag_buffer_c : quant_array (0 to TAPS - 1);
    signal dec_count, dec_count_c : natural;
begin

    filter_process : process (state, real_buffer, imag_buffer, dec_count, real_din, imag_din, real_in_empty, imag_in_empty)
        variable sum_real, sum_imag : unsigned (WORD_SIZE - 1 downto 0) := (others => '0');
    begin
        next_state <= state;
        real_buffer_c <= real_buffer;
        imag_buffer_c <= imag_buffer;
        dec_count_c <= dec_count;

        real_rd_en <= '0';
        imag_rd_en <= '0';
        real_wr_en <= '0';
        imag_wr_en <= '0';
        real_dout <= (others => '0');
        imag_dout <= (others => '0');

        case (state) is
            when init =>
                if (real_in_empty = '0' and imag_in_empty = '0') then
                    dec_count_c <= 0;
                    next_state <= exec;
                end if;

            when exec =>
                if (real_in_empty = '0' and imag_in_empty = '0') then
                    real_rd_en <= '1';
                    imag_rd_en <= '1';
                    -- shift buffers
                    for i in TAPS - 1 to 1 loop
                        real_buffer_c(i) <= real_buffer(i - 1);
                        imag_buffer_c(i) <= imag_buffer(i - 1);
                    end loop;
                    real_buffer_c(0) <= real_din;
                    imag_buffer_c(0) <= imag_din;
                    dec_count_c <= dec_count + 1;
                    if (dec_count = DECIMATION - 1) then
                        dec_count_c <= 0;

                        for i in 0 to TAPS - 1 loop
                            sum_real := sum_real + DEQUANTIZE(unsigned(CHANNEL_COEFFS_REAL(i)) * unsigned(real_buffer(i)) - unsigned(CHANNEL_COEFFS_IMAG(i)) * unsigned(imag_buffer(i)));
                            sum_imag := sum_imag + DEQUANTIZE(unsigned(CHANNEL_COEFFS_REAL(i)) * unsigned(imag_buffer(i)) - unsigned(CHANNEL_COEFFS_IMAG(i)) * unsigned(real_buffer(i)));
                        end loop;

                        -- TODO: check if output full?
                        real_dout <= std_logic_vector(sum_real);
                        imag_dout <= std_logic_vector(sum_imag);
                        real_wr_en <= '1';
                        imag_wr_en <= '1';
                    end if;


                end if;

            when others =>
                next_state <= state;

        end case;
    end process;

    clock_process : process (clock, reset)
    begin 
        if (reset = '1') then
            state <= init;
            real_buffer <= (others => (others => '0'));
            imag_buffer <= (others => (others => '0'));
            dec_count <= 0;
        elsif (rising_edge(clock)) then
            state <= next_state;
            real_buffer <= real_buffer_c;
            imag_buffer <= imag_buffer_c;
            dec_count <= dec_count_c;
        end if;
    end process;

end architecture;
