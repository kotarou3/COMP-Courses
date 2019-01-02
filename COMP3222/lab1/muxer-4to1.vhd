library IEEE;
use IEEE.std_logic_1164.all;

entity muxer_4to1 is
    port (
        s, U, V, W, X: in std_logic_vector(1 downto 0);
        M: out std_logic_vector(1 downto 0)
    );
end muxer_4to1;

architecture arch of muxer_4to1 is
begin
    with s select
        M <=
            U when "00",
            V when "01",
            W when "10",
            X when "11";
end arch;
