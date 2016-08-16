library IEEE;
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;

entity part5 is
    port (
        SW: in unsigned(7 downto 0);
        KEY: in std_logic_vector(1 downto 0);
        HEX3, HEX2, HEX1, HEX0: out std_logic_vector(6 downto 0)
    );
end part5;

architecture arch of part5 is
    alias reset is KEY(0);
    alias clock is KEY(1);

    alias in1 is SW(7 downto 4);
    alias in0 is SW(3 downto 0);

    type State is (SetA, SetB, Finish);
    signal currentState, nextState: State;

    signal out1, out0: std_logic_vector(6 downto 0);
begin
    process (reset, nextState, clock)
    begin
        if reset = '0' then
            currentState <= SetA;
        elsif rising_edge(clock) then
            currentState <= nextState;
        end if;
    end process;

    process (currentState, out1, out0)
    begin
        case currentState is
            when SetA =>
                HEX3 <= out1;
                HEX2 <= out0;
                HEX1 <= "1111111";
                HEX0 <= "1111111";
                nextState <= SetB;
            when SetB =>
                HEX1 <= out1;
                HEX0 <= out0;
                nextState <= Finish;
            when Finish =>
                nextState <= Finish;
        end case;
    end process;

    with in1 select
        out1 <=
            "1000000" when x"0",
            "1111001" when x"1",
            "0100100" when x"2",
            "0110000" when x"3",
            "0011001" when x"4",
            "0010010" when x"5",
            "0000010" when x"6",
            "1111000" when x"7",
            "0000000" when x"8",
            "0010000" when x"9",
            "0001000" when x"a",
            "0000011" when x"b",
            "1000110" when x"c",
            "0100001" when x"d",
            "0000110" when x"e",
            "0001110" when x"f";

    with in0 select
        out0 <=
            "1000000" when x"0",
            "1111001" when x"1",
            "0100100" when x"2",
            "0110000" when x"3",
            "0011001" when x"4",
            "0010010" when x"5",
            "0000010" when x"6",
            "1111000" when x"7",
            "0000000" when x"8",
            "0010000" when x"9",
            "0001000" when x"a",
            "0000011" when x"b",
            "1000110" when x"c",
            "0100001" when x"d",
            "0000110" when x"e",
            "0001110" when x"f";
end arch;
