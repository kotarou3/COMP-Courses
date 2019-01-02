library IEEE;
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;

entity part4 is
    port (
        CLOCK_24: in std_ulogic_vector(0 downto 0);
        SW: in std_ulogic_vector(2 downto 0);
        KEY: in std_ulogic_vector(1 downto 0);
        LEDR: out std_ulogic_vector(0 downto 0)
    );
end part4;

architecture arch of part4 is
    alias clock is CLOCK_24(0);
    alias letter is unsigned(SW(2 downto 0));
    alias start is KEY(1);
    alias asyncReset is KEY(0);
    alias output is LEDR(0);

    signal outputLength: integer range 0 to 4;
    signal outputBuffer: std_ulogic_vector(3 downto 0);

    signal currentCounter: integer range 0 to 36000000;
    signal targetCounter: integer range 0 to 36000000;

    type State is (Reset, Waiting, Light, Dark);
    signal currentState, nextState: State;

    procedure encodeMorse(
        outputLength: out integer range 0 to 4;
        outputBuffer: out std_ulogic_vector(3 downto 0)
    ) is
    begin
        case to_integer(letter) is
            when 0 => -- A
                outputLength := 2;
                outputBuffer := "01XX";
            when 1 => -- B
                outputLength := 4;
                outputBuffer := "1000";
            when 2 => -- C
                outputLength := 4;
                outputBuffer := "1010";
            when 3 => -- D
                outputLength := 3;
                outputBuffer := "100X";
            when 4 => -- E
                outputLength := 1;
                outputBuffer := "0XXX";
            when 5 => -- F
                outputLength := 4;
                outputBuffer := "0010";
            when 6 => -- G
                outputLength := 3;
                outputBuffer := "110X";
            when 7 => -- H
                outputLength := 4;
                outputBuffer := "1111";
            when others =>
                outputLength := 0;
                outputBuffer := "XXXX";
        end case;
    end procedure;

    procedure updateTargetCounter(
        isLongPause: in std_ulogic
    ) is
    begin
        if isLongPause = '1' then
            targetCounter <= 36000000;
        else
            targetCounter <= 12000000;
        end if;

        currentCounter <= 0;
    end procedure;
begin
    process (asyncReset, clock)
    begin
        if asyncReset = '0' then
            currentState <= Reset;
        elsif rising_edge(clock) then
            currentState <= nextState;
        end if;
    end process;

    process (clock)
        variable outputLength_var: integer range 0 to 4;
        variable outputBuffer_var: std_ulogic_vector(3 downto 0);
    begin
        if rising_edge(clock) then
            case currentState is
                when Reset =>
                    output <= '0';
                    nextState <= Waiting;

                when Waiting =>
                    output <= '0';

                    if start = '0' then
                        encodeMorse(outputLength_var, outputBuffer_var);

                        if outputLength_var > 0 then
                            updateTargetCounter(outputBuffer_var(3));
                            nextState <= Light;

                            outputLength <= outputLength_var;
                            outputBuffer <= outputBuffer_var;
                        end if;
                    end if;

                when Light =>
                    output <= '1';

                    if currentCounter = targetCounter then
                        if outputLength > 1 then
                            updateTargetCounter('0');
                            nextState <= Dark;
                        else
                            nextState <= Waiting;
                        end if;

                        outputLength <= outputLength - 1;
                        outputBuffer <= std_ulogic_vector(unsigned(outputBuffer) sll 1);
                    else
                        currentCounter <= currentCounter + 1;
                    end if;

                when Dark =>
                    output <= '0';

                    if currentCounter = targetCounter then
                        updateTargetCounter(outputBuffer(3));
                        nextState <= Light;
                    else
                        currentCounter <= currentCounter + 1;
                    end if;
            end case;
        end if;
    end process;
end arch;
