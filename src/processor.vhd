library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library work;
use work.constants.all;

entity processor is
    port (
        enable: in std_ulogic;
        clock: in std_ulogic;

        irq: in std_ulogic;
        irq_data: in register_t;
        irq_acked: out std_ulogic
    );
end processor;

architecture arch of processor is
    signal irq_handler: address_t;
    signal irq_ack: boolean;

    signal dmem_address: address_t;
    signal dmem_out, dmem_in: data_t;
    signal dmem_write_enable: boolean;
begin
    core: entity work.core port map(
        enable => enable,
        clock => clock,

        irq => irq,
        irq_data => irq_data,
        irq_acked => irq_acked,

        irq_handler => irq_handler,
        irq_ack => irq_ack,

        dmem_address => dmem_address,
        dmem_out => dmem_out,
        dmem_in => dmem_in,
        dmem_write_enable => dmem_write_enable
    );

    dmem: entity work.dmem port map(
        enable => enable,
        clock => clock,

        address => dmem_address,
        data_out => dmem_out,

        data_in => dmem_in,
        write_enable => dmem_write_enable,

        irq_handler => irq_handler,
        irq_ack => irq_ack
    );
end arch;
