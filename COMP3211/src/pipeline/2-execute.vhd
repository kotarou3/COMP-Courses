library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library work;
use work.constants.all;

entity pipeline_execute is
    port (
        next_pc: out address_t;
        is_branch: out boolean;

        prev_stage: in idex_t;
        next_stage: out exmem_t
    );
end pipeline_execute;

architecture arch of pipeline_execute is
    signal alu_out, branch_out: register_t;
begin
    is_branch <= prev_stage.is_branch;

    alu: entity work.alu port map(
        alu_op => prev_stage.alu_op,
        alu_in1 => prev_stage.alu_in1,
        alu_in2 => prev_stage.alu_in2,
        alu_out => alu_out
    );

    branch_unit: entity work.branch_unit port map(
        branch_op => prev_stage.branch_op,
        branch_in1 => prev_stage.branch_in1,
        branch_in2 => prev_stage.branch_in2,
        branch_offset => prev_stage.branch_offset,
        branch_out => branch_out
    );

    with prev_stage.next_pc_source select next_pc <=
        prev_stage.default_next_pc              when NEXT_PC_DEFAULT,
        prev_stage.pc + unsigned(branch_out)    when NEXT_PC_BRANCH_OUT,
        unsigned(alu_out)                       when NEXT_PC_ALU_OUT;

    next_stage.default_next_pc <= prev_stage.default_next_pc;

    next_stage.rd <= prev_stage.rd;
    next_stage.rd_data_source <= prev_stage.rd_data_source;
    next_stage.rd_write_enable <= prev_stage.rd_write_enable;

    next_stage.alu_out <= alu_out;

    with prev_stage.dmem_address_source select next_stage.dmem_address <=
        unsigned(alu_out)   when DMEM_ADDRESS_ALU_OUT,
        ADDRESS_ZERO        when DMEM_ADDRESS_NONE;
    next_stage.dmem_in <= prev_stage.dmem_in;
    next_stage.dmem_write_enable <= prev_stage.dmem_write_enable;
end arch;
