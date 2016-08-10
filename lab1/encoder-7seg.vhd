library IEEE;
use IEEE.std_logic_1164.all;

entity encoder_7seg is
    port (
        c: in std_logic_vector(1 downto 0);
        segments: out std_logic_vector(6 downto 0)
    );
end encoder_7seg;

architecture arch of encoder_7seg is
begin
    with c select
        segments <=
            "0100001" when "00", -- 'd'
            "0000110" when "01", -- 'E'
            "1111001" when "10", -- '1'
            "1111111" when "11"; -- ' '
end arch;
