library IEEE;
use IEEE.std_logic_1164.all;

entity part2 is
    port (
        SW: in std_logic_vector(1 downto 0);
        LEDR: out std_logic_vector(0 downto 0)
    );
end part2;

architecture arch of part2 is
    signal S, S_g, R, R_g, Qa, Qb: std_logic;

    attribute keep: boolean;
    attribute keep of S, S_g, R, R_g, Qa, Qb: signal is true;

    alias D is SW(0);
    alias Clk is SW(1);
    alias Q is LEDR(0);
begin
    S <= D;
    R <= not D;

    S_g <= S nand Clk;
    R_g <= R nand Clk;

    Qa <= S_g nand Qb;
    Qb <= R_g nand Qa;

    Q <= Qa;
end arch;
