library IEEE;
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;

entity part4 is
    port (
        CLOCK_50: in std_logic;
        HEX0: out std_logic_vector(6 downto 0)
    );
end part4;

architecture arch of part4 is
    signal counter: unsigned(25 downto 0);
    signal seconds: unsigned(3 downto 0);
begin
    process (CLOCK_50, counter, seconds)
    begin
        if rising_edge(CLOCK_50) then
            if counter >= 50000000 - 1 then
                counter <= counter - (50000000 - 1);
                if seconds >= 10 - 1 then
                    seconds <= seconds - (10 - 1);
                else
                    seconds <= seconds + 1;
                end if;
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;

    out0: entity work.encoder_7seg port map(
        nibble => seconds,
        segments => HEX0
    );
end arch;
