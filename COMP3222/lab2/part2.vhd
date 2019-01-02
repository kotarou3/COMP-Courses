library IEEE;
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;

entity part2 is
    port (
        SW: in unsigned(3 downto 0);
        HEX1, HEX0: out std_logic_vector(6 downto 0)
    );
end part2;

architecture arch of part2 is
    signal bcd: std_logic_vector(7 downto 0);
begin
    bcd <= "0000" & std_logic_vector(bin) when bin < 10 else "0001" & std_logic_vector(bin - 10);

    encode_bcd1: entity work.encoder_7seg port map(
        bcd => bcd(7 downto 4),
        segments => HEX1
    );
    encode_bcd0: entity work.encoder_7seg port map(
        bcd => bcd(3 downto 0),
        segments => HEX0
    );
end arch;
