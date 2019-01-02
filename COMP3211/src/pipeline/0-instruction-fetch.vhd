library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library work;
use work.constants.all;

entity pipeline_instruction_fetch is
    port (
        pc, default_next_pc: in address_t;

        imem_address: out address_t;
        imem_data: in instruction_t;

        next_stage: out ifid_t
    );
end pipeline_instruction_fetch;

architecture arch of pipeline_instruction_fetch is
begin
    imem_address <= pc;

    next_stage.pc <= pc;
    next_stage.default_next_pc <= default_next_pc;
    next_stage.inst <= imem_data;
end arch;
