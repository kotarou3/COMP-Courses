library IEEE;
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;

entity part4 is
    port (
        SW: in std_logic_vector(8 downto 0);
        HEX3, HEX2, HEX1, HEX0: out std_logic_vector(6 downto 0);
        LEDR: out std_logic_vector(8 downto 0);
        LEDG: out std_logic_vector(7 downto 7)
    );
end part4;

architecture arch of part4 is
    alias in_carry is SW(8);
    alias in_bcd1 is SW(7 downto 4);
    alias in_bcd0 is SW(3 downto 0);

    signal out_bcd: std_logic_vector(7 downto 0);
    alias out_bcd1 is out_bcd(7 downto 4);
    alias out_bcd0 is out_bcd(3 downto 0);
begin
    LEDR <= SW;

    display_in_bcd1: entity work.encoder_7seg port map(
        bcd => in_bcd1,
        segments => HEX3
    );
    display_in_bcd0: entity work.encoder_7seg port map(
        bcd => in_bcd0,
        segments => HEX2
    );

    process (in_bcd1, in_bcd0)
        variable sum: unsigned(4 downto 0);
    begin
        if unsigned(in_bcd1) > 9 or unsigned(in_bcd0) > 9 then
            LEDG(7) <= '1';
            out_bcd <= "11111111";
        else
            LEDG(7) <= '0';

            sum := unsigned("0" & in_bcd1) + unsigned(in_bcd0) + unsigned'("" & in_carry);
            if sum > 9 then
                sum := sum + 6;
            end if;
            out_bcd <= "000" & std_logic_vector(sum);
        end if;
    end process;

    display_out_bcd1: entity work.encoder_7seg port map(
        bcd => out_bcd1,
        segments => HEX1
    );
    display_out_bcd0: entity work.encoder_7seg port map(
        bcd => out_bcd0,
        segments => HEX0
    );
end arch;
