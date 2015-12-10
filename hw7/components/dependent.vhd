library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants.all;
use work.functions.all;

package dependent is
    constant QUAD_RATE : natural := ADC_RATE / USRP_DECIM;
    constant AUDIO_RATE : natural := QUAD_RATE / AUDIO_DECIM;
    constant AUDIO_SAMPLES : natural := SAMPLES / AUDIO_DECIM;

    constant QUAD1 : integer := 804; --to_integer(signed(QUANTIZE_F(PI / 4.0)));
    constant QUAD3 : integer := 2412; --to_integer(signed(QUANTIZE_F(3.0 * PI / 4.0)));
    constant VOLUME_LEVEL : integer := to_integer(signed(QUANTIZE_F(1.0)));
    constant FM_DEMOD_GAIN : integer := 758; --to_integer(signed(QUANTIZE_F(real(QUAD_RATE) / (2.0 * PI * MAX_DEV))));
    constant IIR_X_COEFFS : quant_array (0 to IIR_COEFF_TAPS - 1) := (x"000000b2", x"000000b2"); --(QUANTIZE_F(W_PP / (1.0 + W_PP)), QUANTIZE_F(W_PP / (1.0 + W_PP)));
    constant IIR_Y_COEFFS : quant_array (0 to IIR_COEFF_TAPS - 1) := ((others => '0'), x"fffffd66"); --(QUANTIZE_F(0.0), QUANTIZE_F((W_PP - 1.0) / (W_PP + 1.0)));
end package;
