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
        write_enable: in boolean;

        irq_handler: out address_t;
        irq_ack: out boolean
    );
end dmem;

architecture arch of dmem is
    constant DATA_ZERO: data_t := (others => '0');

    type memory_t is array(0 to DMEM_SIZE - 1) of data_t;
    signal memory: memory_t := (others => DATA_ZERO);
begin
    data_out <= memory(to_integer(address) / DATA_WIDTH_BYTES) when address < DMEM_SIZE_BYTES else (others => 'X');

    irq_handler <= address_t(memory(1));
    irq_ack <= memory(2) /= DATA_ZERO;

    process (enable, clock)
    begin
        if enable = '0' then
            null; -- Do nothing
        elsif rising_edge(clock) then
            -- TODO: These should be exceptions
            assert address < DMEM_SIZE_BYTES report "Out of bounds dmem access" severity error;
            assert address mod DATA_WIDTH_BYTES = 0 report "Unaligned dmem access" severity error;

            if write_enable then
                -- Used to exit the simulation
                assert address /= ADDRESS_ZERO report "Write to null" severity failure;

                memory(to_integer(address) / DATA_WIDTH_BYTES) <= data_in;
            end if;
        elsif falling_edge(clock) then
            memory(2) <= DATA_ZERO;
        end if;
    end process;
end arch;
