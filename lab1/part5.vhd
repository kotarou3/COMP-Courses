library IEEE;
use IEEE.std_logic_1164.all;

entity part5 is
    port (
        SW: in std_logic_vector(9 downto 0);
        HEX2, HEX1, HEX0: out std_logic_vector(6 downto 0)
    );
end part5;

architecture arch of part5 is
    alias rotation is SW(9 downto 8);
    alias in2 is SW(5 downto 4);
    alias in1 is SW(3 downto 2);
    alias in0 is SW(1 downto 0);

    signal char2, char1, char0: std_logic_vector(1 downto 0);
begin
    mux_char2: entity work.muxer_4to1 port map(
        s => rotation,
        U => in2, V => in1, W => in0, X => in0,
        M => char2
    );
    mux_char1: entity work.muxer_4to1 port map(
        s => rotation,
        U => in1, V => in0, W => in2, X => in2,
        M => char1
    );
    mux_char0: entity work.muxer_4to1 port map(
        s => rotation,
        U => in0, V => in2, W => in1, X => in1,
        M => char0
    );

    encode_char2: entity work.encoder_7seg port map(
        c => char2,
        segments => HEX2
    );
    encode_char1: entity work.encoder_7seg port map(
        c => char1,
        segments => HEX1
    );
    encode_char0: entity work.encoder_7seg port map(
        c => char0,
        segments => HEX0
    );
end arch;
