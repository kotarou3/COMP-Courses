library IEEE;
use IEEE.std_logic_1164.all;

entity t_flip_flop is
    port  (
        T, clock, clear: in std_logic;
        Q: inout std_logic
    );
end t_flip_flop;

architecture arch of t_flip_flop is
begin
    process (T, Q, clock, clear)
    begin
        if clear = '1' then
            Q <= '0';
        elsif rising_edge (clock) and T = '1' then
            Q <= not Q;
        end if;
    end process;
end arch;

library IEEE;
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;

entity part1 is
    port  (
        SW: in std_logic_vector (1 downto 0);
        KEY: in std_logic_vector (0 downto 0);
        HEX1, HEX0: out std_logic_vector (6 downto 0)
    );
end part1;

architecture arch of part1 is
    alias enable is SW (1);
    alias clear is SW (0);
    alias clock is KEY (0);

    signal counter: unsigned (7 downto 0);
    signal T: std_logic_vector (7 downto 0);
begin
    T (0) <= enable;
    T (1) <= T (0) and counter (0);
    T (2) <= T (1) and counter (1);
    T (3) <= T (2) and counter (2);
    T (4) <= T (3) and counter (3);
    T (5) <= T (4) and counter (4);
    T (6) <= T (5) and counter (5);
    T (7) <= T (6) and counter (6);

    counter0: entity work.t_flip_flop port map (
        T => T (0),
        clock => clock,
        clear => not clear,
        Q => counter (0)
    );
    counter1: entity work.t_flip_flop port map (
        T => T (1),
        clock => clock,
        clear => not clear,
        Q => counter (1)
    );
    counter2: entity work.t_flip_flop port map (
        T => T (2),
        clock => clock,
        clear => not clear,
        Q => counter (2)
    );
    counter3: entity work.t_flip_flop port map (
        T => T (3),
        clock => clock,
        clear => not clear,
        Q => counter (3)
    );
    counter4: entity work.t_flip_flop port map (
        T => T (4),
        clock => clock,
        clear => not clear,
        Q => counter (4)
    );
    counter5: entity work.t_flip_flop port map (
        T => T (5),
        clock => clock,
        clear => not clear,
        Q => counter (5)
    );
    counter6: entity work.t_flip_flop port map (
        T => T (6),
        clock => clock,
        clear => not clear,
        Q => counter (6)
    );
    counter7: entity work.t_flip_flop port map (
        T => T (7),
        clock => clock,
        clear => not clear,
        Q => counter (7)
    );

    out1: entity work.encoder_7seg port map (
        nibble => counter (7 downto 4),
        segments => HEX1
    );
    out0: entity work.encoder_7seg port map (
        nibble => counter (3 downto 0),
        segments => HEX0
    );
end arch;
