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
    signal pc, next_pc, default_next_pc: address_t;
    signal pc_offset: register_t;
    signal inst: instruction_t;

    type next_pc_source_t is (NEXT_PC_DEFAULT, NEXT_PC_BRANCH_OUT, NEXT_PC_ALU_OUT);
    type alu_in1_source_t is (ALU_IN1_RS1_DATA, ALU_IN1_PC, ALU_IN1_ZERO);
    type alu_in2_source_t is (ALU_IN2_RS2_DATA, ALU_IN2_I_IMM, ALU_IN2_S_IMM, ALU_IN2_U_IMM);
    type branch_offset_source_t is (BRANCH_OFFSET_SB_IMM, BRANCH_OFFSET_UJ_IMM);
    type rd_data_source_t is (RD_DATA_DMEM_OUT, RD_DATA_ALU_OUT, RD_DATA_DEFAULT_NEXT_PC);
    type dmem_address_source_t is (DMEM_ADDRESS_ALU_OUT, DMEM_ADDRESS_NONE);

    signal next_pc_source: next_pc_source_t;
    signal alu_in1_source: alu_in1_source_t;
    signal alu_in2_source: alu_in2_source_t;
    signal branch_offset_source: branch_offset_source_t;
    signal rd_data_source: rd_data_source_t;
    signal dmem_address_source: dmem_address_source_t;

    signal alu_op: alu_op_t;
    signal alu_in1, alu_in2: register_t;
    signal alu_out: register_t;

    signal branch_op: branch_op_t;
    signal branch_in1, branch_in2, branch_offset: register_t;
    signal branch_out: register_t;

    signal rs1_data, rs2_data, rd_data: register_t;
    signal rd_write_enable: boolean;

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

    with rd_data_source select rd_data <=
        dmem_out                when RD_DATA_DMEM_OUT,
        alu_out                 when RD_DATA_ALU_OUT,
        signed(default_next_pc) when RD_DATA_DEFAULT_NEXT_PC;

    with next_pc_source select next_pc <=
        default_next_pc             when NEXT_PC_DEFAULT,
        pc + unsigned(branch_out)   when NEXT_PC_BRANCH_OUT,
        unsigned(alu_out)           when NEXT_PC_ALU_OUT;

    with alu_in1_source select alu_in1 <=
        rs1_data    when ALU_IN1_RS1_DATA,
        signed(pc)  when ALU_IN1_PC,
        XLEN_ZERO   when ALU_IN1_ZERO;
    with alu_in2_source select alu_in2 <=
        rs2_data                when ALU_IN2_RS2_DATA,
        instruction_i_imm(inst) when ALU_IN2_I_IMM,
        instruction_s_imm(inst) when ALU_IN2_S_IMM,
        instruction_u_imm(inst) when ALU_IN2_U_IMM;

    dmem_in <= rs2_data;
    with dmem_address_source select dmem_address <=
        unsigned(alu_out)   when DMEM_ADDRESS_ALU_OUT,
        ADDRESS_ZERO        when DMEM_ADDRESS_NONE;

    branch_in1 <= rs1_data;
    branch_in2 <= rs2_data;
    with branch_offset_source select branch_offset <=
        instruction_sb_imm(inst)    when BRANCH_OFFSET_SB_IMM,
        instruction_uj_imm(inst)    when BRANCH_OFFSET_UJ_IMM;

    decoder: process (inst)
    begin
        -- Defaults to prevent latches
        next_pc_source <= NEXT_PC_DEFAULT;
        alu_in1_source <= ALU_IN1_RS1_DATA;
        alu_in2_source <= ALU_IN2_RS2_DATA;
        branch_offset_source <= BRANCH_OFFSET_SB_IMM;
        rd_data_source <= RD_DATA_ALU_OUT;
        dmem_address_source <= DMEM_ADDRESS_NONE;

        rd_write_enable <= false;
        dmem_write_enable <= false;

        alu_op <= ALU_ADD;
        branch_op <= BRANCH_JUMP;

        case instruction_opcode(inst) is
            when OP_LOAD =>
                assert instruction_funct(inst) ?= FUNCT_LD report "Invalid instruction" severity error;
                alu_op <= ALU_ADD;
                alu_in1_source <= ALU_IN1_RS1_DATA;
                alu_in2_source <= ALU_IN2_I_IMM;
                dmem_address_source <= DMEM_ADDRESS_ALU_OUT;
                rd_data_source <= RD_DATA_DMEM_OUT;
                rd_write_enable <= true;

            when OP_STORE =>
                assert instruction_funct(inst) ?= FUNCT_SD report "Invalid instruction" severity error;
                alu_op <= ALU_ADD;
                alu_in1_source <= ALU_IN1_RS1_DATA;
                alu_in2_source <= ALU_IN2_S_IMM;
                dmem_address_source <= DMEM_ADDRESS_ALU_OUT;
                dmem_write_enable <= true;

            when OP_OP_IMM =>
                case? instruction_funct(inst) is
                    when FUNCT_ADDI =>
                        alu_op <= ALU_ADD;
                    when FUNCT_SLTI =>
                        alu_op <= ALU_SLT;
                    when FUNCT_SLTIU =>
                        alu_op <= ALU_SLTU;
                    when FUNCT_XORI =>
                        alu_op <= ALU_XOR;
                    when FUNCT_ORI =>
                        alu_op <= ALU_OR;
                    when FUNCT_ANDI =>
                        alu_op <= ALU_AND;
                    when FUNCT_SLLI =>
                        alu_op <= ALU_SLL;
                    when FUNCT_SRLI =>
                        alu_op <= ALU_SRL;
                    when FUNCT_SRAI =>
                        alu_op <= ALU_SRA;
                    when others =>
                        assert false report "Invalid instruction" severity error;
                end case?;

                alu_in1_source <= ALU_IN1_RS1_DATA;
                alu_in2_source <= ALU_IN2_I_IMM;
                rd_data_source <= RD_DATA_ALU_OUT;
                rd_write_enable <= true;

            when OP_LUI =>
                alu_op <= ALU_ADD;
                alu_in1_source <= ALU_IN1_ZERO;
                alu_in2_source <= ALU_IN2_U_IMM;
                rd_data_source <= RD_DATA_ALU_OUT;
                rd_write_enable <= true;

            when OP_AUIPC =>
                alu_op <= ALU_ADD;
                alu_in1_source <= ALU_IN1_PC;
                alu_in2_source <= ALU_IN2_U_IMM;
                rd_data_source <= RD_DATA_ALU_OUT;
                rd_write_enable <= true;

            when OP_OP =>
                case? instruction_funct(inst) is
                    when FUNCT_ADD =>
                        alu_op <= ALU_ADD;
                    when FUNCT_SUB =>
                        alu_op <= ALU_SUB;
                    when FUNCT_SLL =>
                        alu_op <= ALU_SLL;
                    when FUNCT_SLT =>
                        alu_op <= ALU_SLT;
                    when FUNCT_SLTU =>
                        alu_op <= ALU_SLTU;
                    when FUNCT_XOR =>
                        alu_op <= ALU_XOR;
                    when FUNCT_SRL =>
                        alu_op <= ALU_SRL;
                    when FUNCT_SRA =>
                        alu_op <= ALU_SRA;
                    when FUNCT_OR =>
                        alu_op <= ALU_OR;
                    when FUNCT_AND =>
                        alu_op <= ALU_AND;
                    when others =>
                        assert false report "Invalid instruction" severity error;
                end case?;

                alu_in1_source <= ALU_IN1_RS1_DATA;
                alu_in2_source <= ALU_IN2_RS2_DATA;
                rd_data_source <= RD_DATA_ALU_OUT;
                rd_write_enable <= true;

            when OP_JAL =>
                branch_op <= BRANCH_JUMP;
                branch_offset_source <= BRANCH_OFFSET_UJ_IMM;
                next_pc_source <= NEXT_PC_BRANCH_OUT;

                rd_data_source <= RD_DATA_DEFAULT_NEXT_PC;
                rd_write_enable <= true;

            when OP_JALR =>
                alu_op <= ALU_ADD;
                alu_in1_source <= ALU_IN1_RS1_DATA;
                alu_in2_source <= ALU_IN2_I_IMM;
                next_pc_source <= NEXT_PC_ALU_OUT;

                rd_data_source <= RD_DATA_DEFAULT_NEXT_PC;
                rd_write_enable <= true;

            when OP_BRANCH =>
                case? instruction_funct(inst) is
                    when FUNCT_BEQ =>
                        branch_op <= BRANCH_EQ;
                    when FUNCT_BNE =>
                        branch_op <= BRANCH_NE;
                    when FUNCT_BLT =>
                        branch_op <= BRANCH_LT;
                    when FUNCT_BGE =>
                        branch_op <= BRANCH_GE;
                    when FUNCT_BLTU =>
                        branch_op <= BRANCH_LTU;
                    when FUNCT_BGEU =>
                        branch_op <= BRANCH_GEU;
                    when others =>
                        assert false report "Invalid instruction" severity error;
                end case?;
                branch_offset_source <= BRANCH_OFFSET_SB_IMM;
                next_pc_source <= NEXT_PC_BRANCH_OUT;

            when others =>
                assert false report "Invalid instruction" severity error;
        end case;
    end process;

    alu: process (alu_op, alu_in1, alu_in2)
    begin
        case alu_op is
            when ALU_ADD =>
                alu_out <= alu_in1 + alu_in2;

            when ALU_SUB =>
                alu_out <= alu_in1 - alu_in2;

            when ALU_SLT =>
                alu_out <= XLEN_ONE when alu_in1 < alu_in2 else XLEN_ZERO;

            when ALU_SLTU =>
                alu_out <= XLEN_ONE when unsigned(alu_in1) < unsigned(alu_in2) else XLEN_ZERO;

            when ALU_XOR =>
                alu_out <= alu_in1 xor alu_in2;

            when ALU_OR =>
                alu_out <= alu_in1 or alu_in2;

            when ALU_AND =>
                alu_out <= alu_in1 and alu_in2;

            when ALU_SLL =>
                alu_out <= shift_left(alu_in1, to_integer(alu_in2(5 downto 0)));

            when ALU_SRL =>
                alu_out <= signed(shift_right(unsigned(alu_in1), to_integer(alu_in2(5 downto 0))));

            when ALU_SRA =>
                alu_out <= shift_right(alu_in1, to_integer(alu_in2(5 downto 0)));
        end case;
    end process;

    branch_unit: process (branch_op, branch_in1, branch_in2, branch_offset) is
        variable take_branch: boolean;
    begin
        case branch_op is
            when BRANCH_JUMP =>
                take_branch := true;
            when BRANCH_EQ =>
                take_branch := branch_in1 = branch_in2;
            when BRANCH_NE =>
                take_branch := branch_in1 /= branch_in2;
            when BRANCH_LT =>
                take_branch := branch_in1 < branch_in2;
            when BRANCH_GE =>
                take_branch := branch_in1 >= branch_in2;
            when BRANCH_LTU =>
                take_branch := unsigned(branch_in1) < unsigned(branch_in2);
            when BRANCH_GEU =>
                take_branch := unsigned(branch_in1) >= unsigned(branch_in2);
        end case;

        branch_out <= branch_offset when take_branch else XLEN_ZERO + INSTRUCTION_WIDTH_BYTES;
    end process;

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
end arch;
