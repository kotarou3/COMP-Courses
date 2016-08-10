library IEEE;
use IEEE.std_logic_1164.all;

entity part3 is
    port (
        SW: in std_logic_vector(9 downto 0);
        LEDR: out std_logic_vector(9 downto 0);
        LEDG: out std_logic_vector(1 downto 0)
    );
end part3;

architecture arch of part3 is
begin
    LEDR <= SW;
    mux: entity work.muxer_4to1 port map(
        s => SW(9 downto 8),
        U => SW(5 downto 4),
        V => SW(3 downto 2),
        W => SW(1 downto 0),
        X => SW(1 downto 0),
        M => LEDG
    );
end arch;
