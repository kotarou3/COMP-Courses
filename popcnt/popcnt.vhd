library IEEE;
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;

entity adder is
    port (
        a, b: in unsigned(3 downto 0);
        sum: out unsigned(3 downto 0)
    );
end adder;

architecture arch of adder is
    signal halfSum, carryG, carryP: std_ulogic_vector(3 downto 0);
    signal carry: std_ulogic_vector(3 downto 1);
begin
    halfSum <= std_ulogic_vector(a xor b);
    carryG <= std_ulogic_vector(a and b);
    carryP <= std_ulogic_vector(a or b);

    carry(1) <= carryG(0);
    carry(2) <= carryG(1) or (carryP(1) and carry(1));
    carry(3) <= carryG(2) or (carryP(2) and carry(2));

    sum(0) <= halfSum(0);
    sum(3 downto 1) <= unsigned(halfSum(3 downto 1) xor carry);
end arch;

library IEEE;
use IEEE.numeric_std.all;

entity popcnt is
    port (
        A, B: in unsigned(7 downto 0);
        C: out unsigned(3 downto 0)
    );
end popcnt;

architecture arch of popcnt is
    type clearedBits_t is array (0 to 15) of integer range 0 to 4;
    constant clearedBits: clearedBits_t := (4, 3, 3, 2, 3, 2, 2, 1, 3, 2, 2, 1, 2, 1, 1, 0);

    signal vec: unsigned(7 downto 0);
    signal high, low: integer range 0 to 4;
begin
    vec <= A xor B;

    high <= clearedBits(to_integer(vec(7 downto 4)));
    low <= clearedBits(to_integer(vec(3 downto 0)));

    add: entity work.adder port map(
        a => to_unsigned(high, 4),
        b => to_unsigned(low, 4),
        sum => C
    );
end arch;
