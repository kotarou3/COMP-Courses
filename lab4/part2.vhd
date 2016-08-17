library IEEE;
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;

entity part2 is
    port (
        SW: in std_logic_vector(1 downto 0);
        KEY: in std_logic_vector(0 downto 0);
        HEX1, HEX0: out std_logic_vector(6 downto 0)
    );
end part2;

architecture arch of part2 is
    alias enable is SW(1);
    alias clear is SW(0);
    alias clock is KEY(0);
    signal counter: unsigned(7 downto 0);
begin
    process (enable, clear, counter, clock)
    begin
        if clear = '0' then
            counter <= x"00";
        elsif enable = '1' and rising_edge(clock) then
            counter <= counter + 1;
        end if;
    end process;

    out1: entity work.encoder_7seg port map(
        nibble => counter(7 downto 4),
        segments => HEX1
    );
    out0: entity work.encoder_7seg port map(
        nibble => counter(3 downto 0),
        segments => HEX0
    );
end arch;
