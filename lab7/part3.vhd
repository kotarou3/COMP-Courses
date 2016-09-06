library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_misc.all;

entity part3 is
    port (
        SW: in std_ulogic_vector(1 downto 0);
        KEY: in std_ulogic_vector(0 downto 0);
        LEDR: out std_ulogic_vector(3 downto 0);
        LEDG: out std_ulogic_vector(0 downto 0)
    );
end part3;

architecture arch of part3 is
    alias w is SW(1);
    alias enable is SW(0);
    alias clock is KEY(0);
    alias z is LEDG(0);

    signal targetState: std_ulogic;
    signal matchingStateHistory: std_ulogic_vector(3 downto 0);
begin
    LEDR <= matchingStateHistory;
    z <= and_reduce(matchingStateHistory);

    process (clock)
    begin
        if rising_edge(clock) then
            if enable = '1' then
                if w = targetState then
                    matchingStateHistory(3 downto 1) <= matchingStateHistory(2 downto 0);
                    matchingStateHistory(0) <= '1';
                else
                    targetState <= w;
                    matchingStateHistory <= "0001";
                end if;
            else
                matchingStateHistory <= "0000";
            end if;
        end if;
    end process;
end arch;
