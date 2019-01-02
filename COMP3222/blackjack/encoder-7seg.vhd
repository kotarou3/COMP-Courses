library IEEE;
use IEEE.std_logic_1164.all;

entity encoder_7seg is
    port (
        number: in integer range 0 to 29;
        segments1: out std_ulogic_vector(6 downto 0);
        segments0: out std_ulogic_vector(6 downto 0)
    );
end encoder_7seg;

architecture arch of encoder_7seg is
    signal digit1: integer range 0 to 9;
    signal digit0: integer range 0 to 9;
begin
    process (number)
    begin
        if number >= 20 then
            digit1 <= 2;
            digit0 <= number - 20;
        elsif number >= 10 then
            digit1 <= 1;
            digit0 <= number - 10;
        else
            digit1 <= 0;
            digit0 <= number;
        end if;
    end process;

    with digit1 select
        segments1 <=
            "1111111" when 0, -- blank
            "1111001" when 1,
            "0100100" when 2,
            "0110000" when 3,
            "0011001" when 4,
            "0010010" when 5,
            "0000010" when 6,
            "1111000" when 7,
            "0000000" when 8,
            "0010000" when 9;

    with digit0 select
        segments0 <=
            "1000000" when 0,
            "1111001" when 1,
            "0100100" when 2,
            "0110000" when 3,
            "0011001" when 4,
            "0010010" when 5,
            "0000010" when 6,
            "1111000" when 7,
            "0000000" when 8,
            "0010000" when 9;
end arch;
