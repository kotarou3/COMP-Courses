library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library work;
use work.constants.all;
use work.instructions.all;

entity pipeline_instruction_decode is
    port (
        is_branch: out boolean;

        rs1_enable, rs2_enable: out boolean;
        rs1, rs2: out natural range 0 to REGISTERS - 1;
        rs1_data, rs2_data: in register_t;

        prev_stage: in ifid_t;
        next_stage: out idex_t
    );
end pipeline_instruction_decode;

architecture arch of pipeline_instruction_decode is
    signal inst_imm: register_t;

    signal alu_in1_source: alu_in1_source_t;
    signal alu_in2_source: alu_in2_source_t;
begin
    decoder: entity work.decoder port map(
        inst => prev_stage.inst,
        inst_imm => inst_imm,

        next_pc_source => next_stage.next_pc_source,

        alu_op => next_stage.alu_op,
        alu_in1_source => alu_in1_source,
        alu_in2_source => alu_in2_source,

        rs1_enable => rs1_enable,
        rs2_enable => rs2_enable,

        is_branch => is_branch,
        branch_op => next_stage.branch_op,

        rd_data_source => next_stage.rd_data_source,
        rd_write_enable => next_stage.rd_write_enable,

        dmem_address_source => next_stage.dmem_address_source,
        dmem_write_enable => next_stage.dmem_write_enable
    );

    next_stage.pc <= prev_stage.pc;
    next_stage.default_next_pc <= prev_stage.default_next_pc;

    rs1 <= instruction_rs1(prev_stage.inst);
    rs2 <= instruction_rs2(prev_stage.inst);
    next_stage.rd <= instruction_rd(prev_stage.inst);

    with alu_in1_source select next_stage.alu_in1 <=
        rs1_data                when ALU_IN1_RS1_DATA,
        signed(prev_stage.pc)   when ALU_IN1_PC,
        XLEN_ZERO               when ALU_IN1_ZERO;
    with alu_in2_source select next_stage.alu_in2 <=
        rs2_data    when ALU_IN2_RS2_DATA,
        inst_imm    when ALU_IN2_IMM;

    next_stage.is_branch <= is_branch;
    next_stage.branch_in1 <= rs1_data;
    next_stage.branch_in2 <= rs2_data;
    next_stage.branch_offset <= inst_imm;

    next_stage.dmem_in <= rs2_data;
end arch;
