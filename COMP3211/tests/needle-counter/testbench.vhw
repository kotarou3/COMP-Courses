library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

library work;
use work.constants.all;

entity test is
end test;

architecture arch of test is
    file needle_file: text open read_mode is "needle.txt";
    file haystack_file: text open read_mode is "haystack.txt";

    signal enable: std_ulogic := '0';
    signal clock: std_ulogic := '0';

    signal irq: std_ulogic := '0';
    signal irq_data: register_t := XLEN_ZERO;
    signal irq_acked: std_ulogic := '0';

    constant period: time := 200 ns;
    constant duty_cycle: real := 0.5;
    constant offset: time := 0 ns;
    constant irq_offset: time := 100 * period;
begin
    uut: entity work.processor port map(
        enable => enable,
        clock => clock,

        irq => irq,
        irq_data => irq_data,
        irq_acked => irq_acked
    );

    process
    begin
        wait for offset;
        enable <= '1';
        loop
            clock <= '0';
            wait for (period - (period * duty_cycle));
            clock <= '1';
            wait for (period * duty_cycle);
        end loop;
    end process;

    process
        variable buffer_line: line;
        variable buffer_char: character;
    begin
        wait for offset;
        wait for irq_offset;

        if not endfile(needle_file) then
            readline(needle_file, buffer_line);
            while buffer_line'length /= 0 loop
                read(buffer_line, buffer_char);

                irq_data <= to_signed(character'pos(buffer_char), XLEN);
                irq <= '1';
                wait for period;
                irq <= '0';
                wait until irq_acked = '1';
                wait for period;
            end loop;
        end if;

        irq_data <= to_signed(-1, XLEN);
        irq <= '1';
        wait for period;
        irq <= '0';
        wait until irq_acked = '1';
        wait for period;

        if not endfile(haystack_file) then
            readline(haystack_file, buffer_line);
            while buffer_line'length /= 0 loop
                read(buffer_line, buffer_char);

                irq_data <= to_signed(character'pos(buffer_char), XLEN);
                irq <= '1';
                wait for period;
                irq <= '0';
                wait until irq_acked = '1';
                wait for period;
            end loop;
        end if;

        irq_data <= to_signed(-1, XLEN);
        irq <= '1';
        wait for period;
        irq <= '0';
        wait until irq_acked = '1';
        wait for period;
    end process;
end arch;
