library IEEE;
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;

entity demo is
    port (
        CLOCK_50: in std_ulogic;
        SW: in std_ulogic_vector(4 downto 0);
        KEY: in std_ulogic_vector(0 downto 0);

        LEDG: out std_ulogic_vector(7 downto 5);
        LEDR: out unsigned(4 downto 0);

        HEX3: out std_ulogic_vector(6 downto 0);
        HEX2: out std_ulogic_vector(6 downto 0);
        HEX1: out std_ulogic_vector(6 downto 0);
        HEX0: out std_ulogic_vector(6 downto 0)
    );
end demo;

architecture arch of demo is
    signal input: integer range 2 to 11;
    signal output: integer range 0 to 26;
begin
    input <= to_integer(unsigned(SW(3 downto 0)));

    player: entity work.blackjack port map (
        clk => CLOCK_50,
        start => KEY(0),

        cardReady => SW(4),
        cardValue => input,

        newCard => LEDG(5),
        score => output,

        lost => LEDG(6),
        finished => LEDG(7)
    );

    inputDisplay: entity work.encoder_7seg port map (
        number => input,
        segments1 => HEX3,
        segments0 => HEX2
    );

    outputDisplay: entity work.encoder_7seg port map (
        number => output,
        segments1 => HEX1,
        segments0 => HEX0
    );
    LEDR <= to_unsigned(output, 5);
end arch;
