library IEEE;
use IEEE.std_logic_1164.all;

entity part2 is
    port (
        SW: in std_ulogic_vector(1 downto 0);
        KEY: in std_ulogic_vector(0 downto 0);
        LEDR: out std_ulogic_vector(3 downto 0);
        LEDG: out std_ulogic_vector(0 downto 0)
    );
end part2;

architecture arch of part2 is
    alias w is SW(1);
    alias clear is SW(0);
    alias clock is KEY(0);
    alias z is LEDG(0);

    type State is (A, B, C, D, E, F, G, H, I);
    signal currentState, nextState: State;

    function ternaryIf(cond: boolean; ifTrue: State; ifFalse: State) return State is
    begin
        if cond then
            return ifTrue;
        else
            return ifFalse;
        end if;
    end function;
begin
    with currentState select
        LEDR <=
            "0000" when A,
            "0001" when B,
            "0010" when C,
            "0011" when D,
            "0100" when E,
            "0101" when F,
            "0110" when G,
            "0111" when H,
            "1000" when I;

    process (clock)
    begin
        if rising_edge(clock) then
            if clear = '0' then
                currentState <= A;
            else
                currentState <= nextState;
            end if;
        end if;
    end process;

    process (currentState)
    begin
        if currentState = E or currentState = I then
            z <= '1';
        else
            z <= '0';
        end if;

        case currentState is
            when A =>
                nextState <= ternaryIf(w = '0', B, F);
            when B =>
                nextState <= ternaryIf(w = '0', C, F);
            when C =>
                nextState <= ternaryIf(w = '0', D, F);
            when D =>
                nextState <= ternaryIf(w = '0', E, F);
            when E =>
                nextState <= ternaryIf(w = '0', E, F);
            when F =>
                nextState <= ternaryIf(w = '1', G, B);
            when G =>
                nextState <= ternaryIf(w = '1', H, B);
            when H =>
                nextState <= ternaryIf(w = '1', I, B);
            when I =>
                nextState <= ternaryIf(w = '1', I, B);
        end case;
    end process;
end arch;
