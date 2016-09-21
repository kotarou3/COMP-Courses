library IEEE;
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;

entity part2 is
    port (
        CLOCK_50: in std_ulogic;
        SW: in std_ulogic_vector(8 downto 0);
        KEY: in std_ulogic_vector(0 downto 0);

        LEDR: out unsigned(4 downto 0);
        LEDG: out std_ulogic_vector(0 downto 0)
    );
end part2;

architecture arch of part2 is
    alias clock is CLOCK_50;
    alias enable is KEY(0);
    alias input is unsigned(SW(7 downto 0));
    alias start is SW(8);

    signal inputCopy: unsigned(7 downto 0);
    signal minAddress, maxAddress: integer range 0 to 32;
    signal resultAddress: integer range 0 to 31;
    signal found: boolean;

    signal midAddress: integer range 0 to 31;
    signal mid: unsigned(7 downto 0);

    type state_t is (Waiting, Finding);
    signal state: state_t;
begin
    LEDR(4 downto 0) <= to_unsigned(resultAddress, 5);
    LEDG(0) <= '1' when found else '0';

    rom: entity work.rom port map(
        clock => not clock,
        address => std_logic_vector(to_unsigned(midAddress, 5)),
        unsigned(q) => mid
    );

    process (clock)
        variable minAddress_var, maxAddress_var: integer range 0 to 32;
    begin
        if rising_edge(clock) then
            if enable = '0' then
                resultAddress <= 0;
                found <= false;
                state <= Waiting;
            elsif state = Waiting and start = '1' then
                resultAddress <= 0;
                found <= false;
                inputCopy <= input;

                minAddress <= 0;
                maxAddress <= 32;
                midAddress <= 16;

                state <= Finding;
            elsif state = Finding then
                if mid < inputCopy then
                    minAddress_var := midAddress + 1;
                    maxAddress_var := maxAddress;
                elsif inputCopy < mid then
                    minAddress_var := minAddress;
                    maxAddress_var := midAddress;
                else
                    minAddress_var := midAddress;
                    maxAddress_var := midAddress;
                end if;

                if minAddress_var = maxAddress_var then
                    found <= mid = inputCopy;
                    resultAddress <= minAddress_var;
                    state <= Waiting;
                else
                    midAddress <= (minAddress_var + maxAddress_var) / 2;
                end if;

                minAddress <= minAddress_var;
                maxAddress <= maxAddress_var;
            end if;
        end if;
    end process;
end arch;
