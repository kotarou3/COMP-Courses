library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_misc.all;

entity part1 is
    port (
        SW: in std_ulogic_vector(1 downto 0);
        KEY: in std_ulogic_vector(0 downto 0);
        LEDR: out std_ulogic_vector(8 downto 0);
        LEDG: out std_ulogic_vector(0 downto 0)
    );
end part1;

architecture arch of part1 is
    alias w is SW(1);
    alias notClear is SW(0);
    alias clock is KEY(0);
    alias z is LEDG(0);

    signal y: std_ulogic_vector(8 downto 0) := "000000000";
begin
    LEDR <= y;
    z <= y(4) or y(8);

    process (clock)
    begin
        if rising_edge(clock) then
            y(0) <= notClear;

            y(1) <= notClear and not w and (not y(0) or or_reduce(y(8 downto 5)));
            y(2) <= notClear and not w and y(1);
            y(3) <= notClear and not w and y(2);
            y(4) <= notClear and not w and or_reduce(y(4 downto 3));

            y(5) <= notClear and w and (not y(0) or or_reduce(y(4 downto 1)));
            y(6) <= notClear and w and y(5);
            y(7) <= notClear and w and y(6);
            y(8) <= notClear and w and or_reduce(y(8 downto 7));
        end if;
    end process;
end arch;
