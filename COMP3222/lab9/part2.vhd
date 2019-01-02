library IEEE;
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;

entity part2 is
    port (
        KEY: in std_ulogic_vector(1 downto 0);
        LEDR: out std_ulogic_vector(9 downto 0)
    );
end part2;

architecture arch of part2 is
    alias enable is KEY(0);
    alias clock is KEY(1);

    signal counter: unsigned(4 downto 0);
    signal input: std_ulogic_vector(8 downto 0);
begin
    process (clock) is
    begin
        if rising_edge(clock) then
            if enable = '0' then
                counter <= "00000";
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;

    rom: entity work.rom port map(
        address => std_logic_vector(counter),
        clock => not clock,
        std_ulogic_vector(q) => input
    );

    processor: entity work.processor port map(
        enable => enable,
        clock => clock,
        run => '1',
        done => LEDR(9),

        DIN => input,
        std_ulogic_vector(DOUT) => LEDR(8 downto 0)
    );
end arch;
