library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library work;
use work.constants.all;

entity pipeline_memory_access is
    port (
        dmem_address: out address_t;
        dmem_out: in data_t;

        dmem_in: out data_t;
        dmem_write_enable: out boolean;

        prev_stage: in exmem_t;
        next_stage: out memwb_t
    );
end pipeline_memory_access;

architecture arch of pipeline_memory_access is
begin
    dmem_address <= prev_stage.dmem_address;
    dmem_in <= prev_stage.dmem_in;
    dmem_write_enable <= prev_stage.dmem_write_enable;

    next_stage.rd <= prev_stage.rd;
    next_stage.rd_write_enable <= prev_stage.rd_write_enable;

    with prev_stage.rd_data_source select next_stage.rd_data <=
        dmem_out                            when RD_DATA_DMEM_OUT,
        prev_stage.alu_out                  when RD_DATA_ALU_OUT,
        signed(prev_stage.default_next_pc)  when RD_DATA_DEFAULT_NEXT_PC;
end arch;
