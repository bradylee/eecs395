library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package constants is

    constant WORD_SIZE : natural := 32;
    constant FRAC_BITS : natural := 10;

    type quant_array is array (natural range <>) of std_logic_vector (WORD_SIZE - 1 downto 0); 
    type standard_state_type is (init, exec, idle, term);

    -- Deemphasis IIR Filter Coefficients: 
    constant IIR_COEFF_TAPS : natural := 2;
    --constant IIR_Y_COEFFS quant_array (0 to _COEFF_TAPS) := {QUANTIZE_F(0.0f)", QUANTIZE_F((W_PP - 1.0f) / (W_PP + 1.0f))};
    --constant IIR_X_COEFFS quant_array (0 to _COEFF_TAPS) := {QUANTIZE_F(W_PP / (1.0f + W_PP))", QUANTIZE_F(W_PP / (1.0f + W_PP))};

    -- Channel low-pass complex filter coefficients @ 0kHz to 80kHz
    constant CHANNEL_COEFF_TAPS : natural := 20;
    constant CHANNEL_COEFFS_REAL : quant_array (0 to CHANNEL_COEFF_TAPS - 1) := (       
    x"00000001", x"00000008", x"fffffff3", x"00000009", x"0000000b", x"ffffffd3", x"00000045", x"ffffffd3",
    x"ffffffb1", x"00000257", x"00000257", x"ffffffb1", x"ffffffd3", x"00000045", x"ffffffd3", x"0000000b",
    x"00000009", x"fffffff3", x"00000008", x"00000001");

    constant CHANNEL_COEFFS_IMAG : quant_array (0 to CHANNEL_COEFF_TAPS - 1) := (       
    x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000",
    x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000",
    x"00000000", x"00000000", x"00000000", x"00000000");

    -- L+R low-pass filter coefficients @ 15kHz
    constant AUDIO_LPR_COEFF_TAPS : natural := 32;
    constant AUDIO_LPR_COEFFS : quant_array (0 to AUDIO_LPR_COEFF_TAPS - 1) := (       
    x"fffffffd", x"fffffffa", x"fffffff4", x"ffffffed", x"ffffffe5", x"ffffffdf", x"ffffffe2", x"fffffff3",
    x"00000015", x"0000004e", x"0000009b", x"000000f9", x"0000015d", x"000001be", x"0000020e", x"00000243",
    x"00000243", x"0000020e", x"000001be", x"0000015d", x"000000f9", x"0000009b", x"0000004e", x"00000015",
    x"fffffff3", x"ffffffe2", x"ffffffdf", x"ffffffe5", x"ffffffed", x"fffffff4", x"fffffffa", x"fffffffd");

    -- L-R low-pass filter coefficients @ 15kHz", gain := 60
    constant AUDIO_LMR_COEFF_TAPS : natural := 32;
    constant AUDIO_LMR_COEFFS : quant_array (0 to AUDIO_LMR_COEFF_TAPS - 1) := (
    x"fffffffd", x"fffffffa", x"fffffff4", x"ffffffed", x"ffffffe5", x"ffffffdf", x"ffffffe2", x"fffffff3",
    x"00000015", x"0000004e", x"0000009b", x"000000f9", x"0000015d", x"000001be", x"0000020e", x"00000243",
    x"00000243", x"0000020e", x"000001be", x"0000015d", x"000000f9", x"0000009b", x"0000004e", x"00000015",
    x"fffffff3", x"ffffffe2", x"ffffffdf", x"ffffffe5", x"ffffffed", x"fffffff4", x"fffffffa", x"fffffffd");

    -- Pilot tone band-pass filter @ 19kHz
    constant BP_PILOT_COEFF_TAPS : natural := 32;
    constant BP_PILOT_COEFFS : quant_array (0 to BP_PILOT_COEFF_TAPS - 1) := (
    x"0000000e", x"0000001f", x"00000034", x"00000048", x"0000004e", x"00000036", x"fffffff8", x"ffffff98",
    x"ffffff2d", x"fffffeda", x"fffffec3", x"fffffefe", x"ffffff8a", x"0000004a", x"0000010f", x"000001a1",
    x"000001a1", x"0000010f", x"0000004a", x"ffffff8a", x"fffffefe", x"fffffec3", x"fffffeda", x"ffffff2d",
    x"ffffff98", x"fffffff8", x"00000036", x"0000004e", x"00000048", x"00000034", x"0000001f", x"0000000e");

    -- L-R band-pass filter @ 23kHz to 53kHz
    constant BP_LMR_COEFF_TAPS : natural := 32;
    constant BP_LMR_COEFFS : quant_array (0 to BP_LMR_COEFF_TAPS - 1) := (
    x"00000000", x"00000000", x"fffffffc", x"fffffff9", x"fffffffe", x"00000008", x"0000000c", x"00000002",
    x"00000003", x"0000001e", x"00000030", x"fffffffc", x"ffffff8c", x"ffffff58", x"ffffffc3", x"0000008a",
    x"0000008a", x"ffffffc3", x"ffffff58", x"ffffff8c", x"fffffffc", x"00000030", x"0000001e", x"00000003",
    x"00000002", x"0000000c", x"00000008", x"fffffffe", x"fffffff9", x"fffffffc", x"00000000", x"00000000");

    -- High pass filter @ 0Hz removes noise after pilot tone is squared
    constant HP_COEFF_TAPS : natural := 32;
    constant HP_COEFFS : quant_array (0 to HP_COEFF_TAPS - 1) := (
    x"ffffffff", x"00000000", x"00000000", x"00000002", x"00000004", x"00000008", x"0000000b", x"0000000c",
    x"00000008", x"ffffffff", x"ffffffee", x"ffffffd7", x"ffffffbb", x"ffffff9f", x"ffffff87", x"ffffff76",
    x"ffffff76", x"ffffff87", x"ffffff9f", x"ffffffbb", x"ffffffd7", x"ffffffee", x"ffffffff", x"00000008",
    x"0000000c", x"0000000b", x"00000008", x"00000004", x"00000002", x"00000000", x"00000000", x"ffffffff");

end package;
