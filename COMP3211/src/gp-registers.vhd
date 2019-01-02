library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library work;
use work.constants.all;

entity gp_registers is
    port (
        enable: in std_ulogic;
        clock: in std_ulogic;

        rs1, rs2, rd: in natural range 0 to REGISTERS - 1;
        rs1_data, rs2_data: out register_t;
        rd_data: in register_t;
        write_enable: in boolean
    );
end gp_registers;

architecture arch of gp_registers is
    type registers_t is array(0 to REGISTERS - 1) of register_t;
    signal registers: registers_t;
begin
    rs1_data <= registers(rs1);
    rs2_data <= registers(rs2);

    process (enable, clock)
    begin
        if enable = '0' then
            registers <= (others => (others => '0'));
        elsif rising_edge(clock) then
            if rd /= 0 and write_enable then
                registers(rd) <= rd_data;
            end if;
        end if;
    end process;
end arch;
