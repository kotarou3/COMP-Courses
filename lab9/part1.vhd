library IEEE;
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;

entity part1 is
    port (
        SW: in std_ulogic_vector(9 downto 0);
        KEY: in std_ulogic_vector(1 downto 0);
        LEDR: out std_ulogic_vector(9 downto 0)
    );
end part1;

architecture arch of part1 is
begin
    processor: entity work.processor port map(
        enable => KEY(0),
        clock => KEY(1),
        run => SW(9),
        done => LEDR(9),

        DIN => SW(8 downto 0),
        std_ulogic_vector(DOUT) => LEDR(8 downto 0)
    );
end arch;
