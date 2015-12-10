library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants.all;

package components is

    component fifo is
        generic
        (
            constant DWIDTH : integer := 32;
            constant BUFFER_SIZE : integer := 32
        );
        port
        (
            signal rd_clk : in std_logic;
            signal wr_clk : in std_logic;
            signal reset : in std_logic;
            signal rd_en : in std_logic;
            signal wr_en : in std_logic;
            signal din : in std_logic_vector ((DWIDTH - 1) downto 0);
            signal dout : out std_logic_vector ((DWIDTH - 1) downto 0);
            signal full : out std_logic;
            signal empty : out std_logic
        );
    end component;

    component addsub is
        port 
        (
            clock : in std_logic;
            reset : in std_logic;
            left_din : in std_logic_vector (WORD_SIZE - 1 downto 0);
            right_din : in std_logic_vector (WORD_SIZE - 1 downto 0);
            left_in_empty : in std_logic;
            right_in_empty : in std_logic;
            left_out_full : in std_logic;
            right_out_full : in std_logic;
            left_in_rd_en : out std_logic;
            right_in_rd_en : out std_logic;
            left_dout : out std_logic_vector (WORD_SIZE - 1 downto 0);
            right_dout : out std_logic_vector (WORD_SIZE - 1 downto 0);
            left_out_wr_en : out std_logic;
            right_out_wr_en : out std_logic
        );
    end component;

    component demodulate is
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
    end component;

    component fir_decimated is
        generic
        (
            TAPS : natural := 20;
            DECIMATION : natural := 8
        );
        port 
        (
            clock : in std_logic;
            reset : in std_logic;
            din : in std_logic_vector (WORD_SIZE - 1 downto 0);
            coeffs : in quant_array (0 to TAPS - 1);
            in_empty : in std_logic;
            out_full : in std_logic;
            in_rd_en : out std_logic;
            dout : out std_logic_vector (WORD_SIZE - 1 downto 0);
            out_wr_en : out std_logic
        );
    end component;

    component multiply is
        port 
        (
            clock : in std_logic;
            reset : in std_logic;
            x_din : in std_logic_vector (WORD_SIZE - 1 downto 0);
            y_din : in std_logic_vector (WORD_SIZE - 1 downto 0);
            x_empty : in std_logic;
            y_empty : in std_logic;
            z_full : in std_logic;
            x_rd_en : out std_logic;
            y_rd_en : out std_logic;
            z_dout : out std_logic_vector (WORD_SIZE - 1 downto 0);
            z_wr_en : out std_logic
        );
    end component;

    component read_iq is
        port 
        (
            clock : in std_logic;
            reset : in std_logic;
            iq_din : in std_logic_vector (WORD_SIZE - 1 downto 0);
            iq_empty : in std_logic;
            i_full : in std_logic;
            q_full : in std_logic;
            iq_rd_en : out std_logic;
            i_wr_en : out std_logic;
            q_wr_en : out std_logic;
            i_dout : out std_logic_vector (WORD_SIZE - 1 downto 0);
            q_dout : out std_logic_vector (WORD_SIZE - 1 downto 0)
        );
    end component;

    component fir_complex is
        generic
        (
            TAPS : natural := 20
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
            real_in_rd_en : out std_logic;
            imag_in_rd_en : out std_logic;
            real_dout : out std_logic_vector (WORD_SIZE - 1 downto 0);
            imag_dout : out std_logic_vector (WORD_SIZE - 1 downto 0);
            real_out_wr_en : out std_logic;
            imag_out_wr_en : out std_logic
        );
    end component;

    component fir is
        generic
        (
            TAPS : natural := 20
        );
        port 
        (
            clock : in std_logic;
            reset : in std_logic;
            din : in std_logic_vector (WORD_SIZE - 1 downto 0);
            coeffs : in quant_array (0 to TAPS - 1);
            in_empty : in std_logic;
            out_full : in std_logic;
            in_rd_en : out std_logic;
            dout : out std_logic_vector (WORD_SIZE - 1 downto 0);
            out_wr_en : out std_logic
        );
    end component;

    component gain is
        generic
        (
            MYSTERY : natural := 14
        );
        port 
        (
            clock : in std_logic;
            reset : in std_logic;
            volume : in integer;
            din : in std_logic_vector (WORD_SIZE - 1 downto 0);
            in_empty : in std_logic;
            out_full : in std_logic;
            in_rd_en : out std_logic;
            dout : out std_logic_vector (WORD_SIZE - 1 downto 0);
            out_wr_en : out std_logic
        );
    end component;

    component iir is
        generic
        (
            TAPS : natural := 20
        );
        port 
        (
            clock : in std_logic;
            reset : in std_logic;
            din : in std_logic_vector (WORD_SIZE - 1 downto 0);
            x_coeffs : in quant_array (0 to TAPS - 1);
            y_coeffs : in quant_array (0 to TAPS - 1);
            in_empty : in std_logic;
            out_full : in std_logic;
            in_rd_en : out std_logic;
            dout : out std_logic_vector (WORD_SIZE - 1 downto 0);
            out_wr_en : out std_logic
        );
    end component;

    component square is
        port 
        (
            clock : in std_logic;
            reset : in std_logic;
            x_din : in std_logic_vector (WORD_SIZE - 1 downto 0);
            x_empty : in std_logic;
            z_full : in std_logic;
            x_rd_en : out std_logic;
            z_dout : out std_logic_vector (WORD_SIZE - 1 downto 0);
            z_wr_en : out std_logic
        );
    end component;

    component radio is
        generic
        (
            INPUT_BUFFER_SIZE : natural := 64;
            I_BUFFER_SIZE : natural := 64;
            Q_BUFFER_SIZE : natural := 64;
            I_FILTERED_BUFFER_SIZE : natural := 64;
            Q_FILTERED_BUFFER_SIZE : natural := 64;
            PRE_PILOT_BUFFER_SIZE : natural := 64;
            PILOT_FILTERED_BUFFER_SIZE : natural := 64;
            PILOT_SQUARED_BUFFER_SIZE : natural := 64;
            PILOT_BUFFER_SIZE : natural := 64;
            LEFT_CHANNEL_BUFFER_SIZE : natural := 64;
            LEFT_BAND_BUFFER_SIZE : natural := 64;
            LEFT_MULTIPLIED_BUFFER_SIZE : natural := 64;
            LEFT_LOW_BUFFER_SIZE : natural := 64;
            RIGHT_CHANNEL_BUFFER_SIZE : natural := 64;
            RIGHT_LOW_BUFFER_SIZE : natural := 64;
            LEFT_EMPH_BUFFER_SIZE : natural := 64;
            RIGHT_EMPH_BUFFER_SIZE : natural := 64;
            LEFT_DEEMPH_BUFFER_SIZE : natural := 64;
            RIGHT_DEEMPH_BUFFER_SIZE : natural := 64;
            LEFT_GAIN_BUFFER_SIZE : natural := 64;
            RIGHT_GAIN_BUFFER_SIZE : natural := 64
        );
        port 
        (
            clock : in std_logic;
            reset : in std_logic;
            volume : in integer;
            din : in std_logic_vector (WORD_SIZE - 1 downto 0);
            input_wr_en : in std_logic;
            left_rd_en : in std_logic;
            right_rd_en : in std_logic;
            input_full : out std_logic;
            left : out std_logic_vector (WORD_SIZE - 1 downto 0);
            right : out std_logic_vector (WORD_SIZE - 1 downto 0);
            left_empty : out std_logic;
            right_empty : out std_logic
        );
    end component;

end package;
