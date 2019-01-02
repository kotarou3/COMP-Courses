library IEEE;
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;

entity part5 is
    port (
        CLOCK_50: in std_logic;
        HEX3, HEX2, HEX1, HEX0: out std_logic_vector(6 downto 0)
    );
end part5;

architecture arch of part5 is
    signal counter: unsigned(25 downto 0);
    signal output: unsigned(7 downto 0) := b"00011011";
begin
    process (CLOCK_50, counter, output)
    begin
        if rising_edge(CLOCK_50) then
            if counter >= 50000000 - 1 then
                counter <= counter - (50000000 - 1);
                output <= output rol 2;
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;

    encode_char3: entity work.encoder_de1_7seg port map(
        c => output(7 downto 6),
        segments => HEX3
    );
    encode_char2: entity work.encoder_de1_7seg port map(
        c => output(5 downto 4),
        segments => HEX2
    );
    encode_char1: entity work.encoder_de1_7seg port map(
        c => output(3 downto 2),
        segments => HEX1
    );
    encode_char0: entity work.encoder_de1_7seg port map(
        c => output(1 downto 0),
        segments => HEX0
    );
end arch;
