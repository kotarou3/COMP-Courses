library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library work;
use work.constants.all;
use work.instructions.all;

entity processor is
    port (
        enable: in std_ulogic;
        clock: in std_ulogic
    );
end processor;

architecture arch of processor is
    signal pc, default_next_pc: address_t;
    signal inst: instruction_t;

    signal next_pc_source: next_pc_source_t;
    signal next_pc: address_t;

    signal alu_op: alu_op_t;
    signal alu_in1_source: alu_in1_source_t;
    signal alu_in2_source: alu_in2_source_t;
    signal alu_in1, alu_in2: register_t;
    signal alu_out: register_t;

    signal branch_op: branch_op_t;
    signal branch_offset_source: branch_offset_source_t;
    signal branch_in1, branch_in2, branch_offset: register_t;
    signal branch_out: register_t;

    signal rd_data_source: rd_data_source_t;
    signal rs1_data, rs2_data, rd_data: register_t;
    signal rd_write_enable: boolean;

    signal dmem_address_source: dmem_address_source_t;
    signal dmem_address: address_t;
    signal dmem_in, dmem_out: data_t;
    signal dmem_write_enable: boolean;
begin
    program_counter: process (enable, clock)
    begin
        if enable = '0' then
            pc <= ADDRESS_ZERO;
            default_next_pc <= ADDRESS_ZERO;
        elsif falling_edge(clock) then
            pc <= next_pc(next_pc'left downto 1) & '0';
            default_next_pc <= next_pc + INSTRUCTION_WIDTH_BYTES;
        end if;
    end process;
    with next_pc_source select next_pc <=
        default_next_pc             when NEXT_PC_DEFAULT,
        pc + unsigned(branch_out)   when NEXT_PC_BRANCH_OUT,
        unsigned(alu_out)           when NEXT_PC_ALU_OUT;

    decoder: entity work.decoder port map(
        inst => inst,

        next_pc_source => next_pc_source,

        alu_op => alu_op,
        alu_in1_source => alu_in1_source,
        alu_in2_source => alu_in2_source,

        branch_op => branch_op,
        branch_offset_source => branch_offset_source,

        rd_data_source => rd_data_source,
        rd_write_enable => rd_write_enable,

        dmem_address_source => dmem_address_source,
        dmem_write_enable => dmem_write_enable
    );

    alu: entity work.alu port map(
        alu_op => alu_op,
        alu_in1 => alu_in1,
        alu_in2 => alu_in2,
        alu_out => alu_out
    );
    with alu_in1_source select alu_in1 <=
        rs1_data    when ALU_IN1_RS1_DATA,
        signed(pc)  when ALU_IN1_PC,
        XLEN_ZERO   when ALU_IN1_ZERO;
    with alu_in2_source select alu_in2 <=
        rs2_data                when ALU_IN2_RS2_DATA,
        instruction_i_imm(inst) when ALU_IN2_I_IMM,
        instruction_s_imm(inst) when ALU_IN2_S_IMM,
        instruction_u_imm(inst) when ALU_IN2_U_IMM;

    branch_unit: entity work.branch_unit port map(
        branch_op => branch_op,
        branch_in1 => rs1_data,
        branch_in2 => rs2_data,
        branch_offset => branch_offset,
        branch_out => branch_out
    );
    branch_in1 <= rs1_data;
    branch_in2 <= rs2_data;
    with branch_offset_source select branch_offset <=
        instruction_sb_imm(inst)    when BRANCH_OFFSET_SB_IMM,
        instruction_uj_imm(inst)    when BRANCH_OFFSET_UJ_IMM;

    gp_registers: entity work.gp_registers port map(
        enable => enable,
        clock => clock,

        rs1 => instruction_rs1(inst),
        rs2 => instruction_rs2(inst),
        rd => instruction_rd(inst),
        write_enable => rd_write_enable,

        rs1_data => rs1_data,
        rs2_data => rs2_data,
        rd_data => rd_data
    );
    with rd_data_source select rd_data <=
        dmem_out                when RD_DATA_DMEM_OUT,
        alu_out                 when RD_DATA_ALU_OUT,
        signed(default_next_pc) when RD_DATA_DEFAULT_NEXT_PC;

    imem: entity work.imem port map(
        enable => enable,
        clock => clock,

        address => pc,
        data => inst
    );

    dmem: entity work.dmem port map(
        enable => enable,
        clock => clock,

        address => dmem_address,
        data_out => dmem_out,

        data_in => dmem_in,
        write_enable => dmem_write_enable
    );
    dmem_in <= rs2_data;
    with dmem_address_source select dmem_address <=
        unsigned(alu_out)   when DMEM_ADDRESS_ALU_OUT,
        ADDRESS_ZERO        when DMEM_ADDRESS_NONE;
end arch;
