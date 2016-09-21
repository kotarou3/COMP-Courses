library IEEE;
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;

entity part1 is
    port (
        CLOCK_50: in std_ulogic;
        SW: in std_ulogic_vector(8 downto 0);
        KEY: in std_ulogic_vector(0 downto 0);

        LEDR: out unsigned(3 downto 0);
        LEDG: out std_ulogic_vector(0 downto 0)
    );
end part1;

architecture arch of part1 is
    alias clock is CLOCK_50;
    alias enable is KEY(0);
    alias input is unsigned(SW(7 downto 0));
    alias start is SW(8);

    signal inputCopy: unsigned(7 downto 0);
    signal counter: integer range 0 to 8;
    signal done: boolean;

    type state_t is (Waiting, Calculating);
    signal state: state_t;
begin
    LEDR <= to_unsigned(counter, 4);
    LEDG(0) <= '1' when done else '0';

    process (clock, enable)
    begin
        if enable = '0' then
            counter <= 0;
            done <= false;
            state <= Waiting;
        elsif rising_edge(clock) then
            if state = Waiting and start = '1' then
                counter <= 0;
                done <= false;
                inputCopy <= input;
                state <= Calculating;
            elsif state = Calculating then
                if inputCopy(0) = '1' then
                    counter <= counter + 1;
                elsif inputCopy = x"00" then
                    done <= true;
                    state <= Waiting;
                end if;

                inputCopy <= inputCopy srl 1;
            end if;
        end if;
    end process;
end arch;
