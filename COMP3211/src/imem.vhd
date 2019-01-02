library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library work;
use work.constants.all;

entity imem is
    port (
        enable: in std_ulogic;
        clock: in std_ulogic;

        address: in address_t;
        data: out instruction_t
    );
end imem;

architecture arch of imem is
    type memory_t is array(0 to IMEM_SIZE - 1) of instruction_t;
    signal memory: memory_t := (others => (others => '0'));
begin
    process (enable, clock)
    begin
        if enable = '0' then
            null; -- Do nothing
        elsif rising_edge(clock) then
            -- TODO: These should be exceptions
            assert address < IMEM_SIZE_BYTES report "Out of bounds imem read" severity error;
            assert address mod INSTRUCTION_WIDTH_BYTES = 0 report "Unaligned imem read" severity error;

            data <= memory(to_integer(address) / INSTRUCTION_WIDTH_BYTES);
        end if;
    end process;
end arch;
