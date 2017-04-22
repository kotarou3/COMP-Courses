library ieee;
use ieee.std_logic_1164.all;

library work;
use work.constants.all;

entity test is
end test;

architecture arch of test is
    signal enable: std_ulogic := '0';
    signal clock: std_ulogic := '0';

    signal irq: std_ulogic := '0';
    signal irq_data: register_t := XLEN_ZERO;
    signal irq_acked: std_ulogic := '0';

    constant IRQ_BUFFER_SIZE: positive := 1000;
    type irq_buffer_t is array(0 to IRQ_BUFFER_SIZE - 1) of register_t;
    signal irq_buffer: irq_buffer_t;

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
    begin
        wait for offset;
        wait for irq_offset;
        for n in 0 to IRQ_BUFFER_SIZE - 1 loop
            irq_data <= irq_buffer(n);
            irq <= '1';
            wait for period;
            irq <= '0';
            wait until irq_acked = '1';
            wait for period;
        end loop;
    end process;
end arch;
