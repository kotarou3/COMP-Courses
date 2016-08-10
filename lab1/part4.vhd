library IEEE;
use IEEE.std_logic_1164.all;

entity part4 is
    port (
        SW: in std_logic_vector(1 downto 0);
        HEX0: out std_logic_vector(6 downto 0)
    );
end part4;

architecture arch of part4 is
begin
    encode: entity work.encoder_7seg port map(
        c => SW,
        segments => HEX0
    );
end arch;
