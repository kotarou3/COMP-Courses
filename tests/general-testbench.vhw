library ieee;
use ieee.std_logic_1164.all;

entity test is
end test;

architecture arch of test is
    signal enable: std_ulogic := '0';
    signal clock: std_ulogic := '0';
    
    constant period: time := 200 ns;
    constant duty_cycle: real := 0.5;
    constant offset: time := 0 ns;
begin
    uut: entity work.processor port map(
        enable => enable,
        clock => clock,
        
        irq => '0',
        irq_data => (others => '0'),
        irq_acked => open
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
end arch;
