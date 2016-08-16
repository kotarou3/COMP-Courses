library IEEE;
use IEEE.std_logic_1164.all;

entity part4 is
    port (
        D, Clock: in std_logic;
        Qa, Qb, Qc: out std_logic
    );
end part4;

architecture arch of part4 is
begin
    latch: process (D, Clock)
    begin
        if Clock = '1' then
            Qa <= D;
        end if;
    end process;

    risingEdgeFlipFlop: process (D, Clock)
    begin
        if rising_edge(Clock) then
            Qb <= D;
        end if;
    end process;

    fallingEdgeFlipFlop: process (D, Clock)
    begin
        if falling_edge(Clock) then
            Qc <= D;
        end if;
    end process;
end arch;
