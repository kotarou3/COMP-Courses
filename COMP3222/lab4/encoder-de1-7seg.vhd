library IEEE;
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;

entity encoder_de1_7seg is
    port (
        c: in unsigned(1 downto 0);
        segments: out std_logic_vector(6 downto 0)
    );
end encoder_de1_7seg;

architecture arch of encoder_de1_7seg is
begin
    with c select
        segments <=
            "0100001" when b"00", -- 'd'
            "0000110" when b"01", -- 'E'
            "1111001" when b"10", -- '1'
            "1111111" when b"11"; -- ' '
end arch;
