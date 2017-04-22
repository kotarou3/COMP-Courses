library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library work;
use work.constants.all;
use work.instructions.all;

entity decoder is
    port (
        inst: in instruction_t;
        inst_imm: out register_t;

        next_pc_source: out next_pc_source_t;

        alu_op: out alu_op_t;
        alu_in1_source: out alu_in1_source_t;
        alu_in2_source: out alu_in2_source_t;

        rs1_enable, rs2_enable: out boolean;

        is_branch: out boolean;
        branch_op: out branch_op_t;

        rd_data_source: out rd_data_source_t;
        rd_write_enable: out boolean;

        dmem_address_source: out dmem_address_source_t;
        dmem_write_enable: out boolean
    );
end decoder;

architecture arch of decoder is
    type inst_type_t is (INST_TYPE_R, INST_TYPE_I, INST_TYPE_S, INST_TYPE_SB, INST_TYPE_U, INST_TYPE_UJ);
    signal inst_type: inst_type_t;
begin
    process (inst, inst_type)
    begin
        case inst_type is
            when INST_TYPE_R =>
                inst_imm <= XLEN_ZERO;
                rs1_enable <= true;
                rs2_enable <= true;

            when INST_TYPE_I =>
                inst_imm <= instruction_i_imm(inst);
                rs1_enable <= true;
                rs2_enable <= false;

            when INST_TYPE_S =>
                inst_imm <= instruction_s_imm(inst);
                rs1_enable <= true;
                rs2_enable <= true;

            when INST_TYPE_SB =>
                inst_imm <= instruction_sb_imm(inst);
                rs1_enable <= true;
                rs2_enable <= true;

            when INST_TYPE_U =>
                inst_imm <= instruction_u_imm(inst);
                rs1_enable <= false;
                rs2_enable <= false;

            when INST_TYPE_UJ =>
                inst_imm <= instruction_uj_imm(inst);
                rs1_enable <= false;
                rs2_enable <= false;
        end case;
    end process;

    is_branch <= next_pc_source /= NEXT_PC_DEFAULT;

    process (inst)
    begin
        -- Defaults to prevent latches
        next_pc_source <= NEXT_PC_DEFAULT;

        alu_op <= ALU_ADD;
        alu_in1_source <= ALU_IN1_RS1_DATA;
        alu_in2_source <= ALU_IN2_RS2_DATA;

        branch_op <= BRANCH_JUMP;

        rd_data_source <= RD_DATA_ALU_OUT;
        rd_write_enable <= false;

        dmem_address_source <= DMEM_ADDRESS_NONE;
        dmem_write_enable <= false;

        case instruction_opcode(inst) is
            when OP_LOAD =>
                assert instruction_funct(inst) ?= FUNCT_LD report "Invalid instruction" severity error;
                inst_type <= INST_TYPE_I;

                alu_op <= ALU_ADD;
                alu_in1_source <= ALU_IN1_RS1_DATA;
                alu_in2_source <= ALU_IN2_IMM;

                dmem_address_source <= DMEM_ADDRESS_ALU_OUT;
                dmem_write_enable <= false;

                rd_data_source <= RD_DATA_DMEM_OUT;
                rd_write_enable <= true;

            when OP_STORE =>
                assert instruction_funct(inst) ?= FUNCT_SD report "Invalid instruction" severity error;
                inst_type <= INST_TYPE_S;

                alu_op <= ALU_ADD;
                alu_in1_source <= ALU_IN1_RS1_DATA;
                alu_in2_source <= ALU_IN2_IMM;

                dmem_address_source <= DMEM_ADDRESS_ALU_OUT;
                dmem_write_enable <= true;

            when OP_OP_IMM =>
                inst_type <= INST_TYPE_I;

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
                alu_in2_source <= ALU_IN2_IMM;

                rd_data_source <= RD_DATA_ALU_OUT;
                rd_write_enable <= true;

            when OP_LUI =>
                inst_type <= INST_TYPE_U;

                alu_op <= ALU_ADD;
                alu_in1_source <= ALU_IN1_ZERO;
                alu_in2_source <= ALU_IN2_IMM;

                rd_data_source <= RD_DATA_ALU_OUT;
                rd_write_enable <= true;

            when OP_AUIPC =>
                inst_type <= INST_TYPE_U;

                alu_op <= ALU_ADD;
                alu_in1_source <= ALU_IN1_PC;
                alu_in2_source <= ALU_IN2_IMM;

                rd_data_source <= RD_DATA_ALU_OUT;
                rd_write_enable <= true;

            when OP_OP =>
                inst_type <= INST_TYPE_R;

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
                inst_type <= INST_TYPE_UJ;

                branch_op <= BRANCH_JUMP;
                next_pc_source <= NEXT_PC_BRANCH_OUT;

                rd_data_source <= RD_DATA_DEFAULT_NEXT_PC;
                rd_write_enable <= true;

            when OP_JALR =>
                inst_type <= INST_TYPE_I;

                alu_op <= ALU_ADD;
                alu_in1_source <= ALU_IN1_RS1_DATA;
                alu_in2_source <= ALU_IN2_IMM;

                next_pc_source <= NEXT_PC_ALU_OUT;

                rd_data_source <= RD_DATA_DEFAULT_NEXT_PC;
                rd_write_enable <= true;

            when OP_BRANCH =>
                inst_type <= INST_TYPE_SB;

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
                next_pc_source <= NEXT_PC_BRANCH_OUT;

            when others =>
                assert false report "Invalid instruction" severity error;
        end case;
    end process;
end arch;
