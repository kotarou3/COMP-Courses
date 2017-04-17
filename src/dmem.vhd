library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library work;
use work.constants.all;

entity dmem is
    port (
        enable: in std_ulogic;
        clock: in std_ulogic;

        address: in address_t;
        data_out: out data_t;

        data_in: in data_t;
        write_enable: in boolean
    );
end dmem;

architecture arch of dmem is
    type memory_t is array(0 to DMEM_SIZE - 1) of data_t;
    signal memory: memory_t := (others => (others => '0'));
begin
    data_out <= memory(to_integer(address) / DATA_WIDTH_BYTES);

    process (enable, clock)
    begin
        if enable = '0' then
            null; -- Do nothing
        elsif falling_edge(clock) then
            -- TODO: These should be exceptions
            assert address < DMEM_SIZE_BYTES report "Out of bounds dmem access" severity error;
            assert address mod DATA_WIDTH_BYTES = 0 report "Unaligned dmem access" severity error;

            if write_enable then
                memory(to_integer(address) / DATA_WIDTH_BYTES) <= data_in;
            end if;
        end if;
    end process;
end arch;
