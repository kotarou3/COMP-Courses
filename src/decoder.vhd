library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library work;
use work.constants.all;
use work.instructions.all;

entity decoder is
    port (
        inst: in instruction_t;

        next_pc_source: out next_pc_source_t;

        alu_op: out alu_op_t;
        alu_in1_source: out alu_in1_source_t;
        alu_in2_source: out alu_in2_source_t;

        branch_op: out branch_op_t;
        branch_offset_source: out branch_offset_source_t;

        rd_data_source: out rd_data_source_t;
        rd_write_enable: out boolean;

        dmem_address_source: out dmem_address_source_t;
        dmem_write_enable: out boolean
    );
end decoder;

architecture arch of decoder is
begin
    process (inst)
    begin
        -- Defaults to prevent latches
        next_pc_source <= NEXT_PC_DEFAULT;

        alu_op <= ALU_ADD;
        alu_in1_source <= ALU_IN1_RS1_DATA;
        alu_in2_source <= ALU_IN2_RS2_DATA;

        branch_op <= BRANCH_JUMP;
        branch_offset_source <= BRANCH_OFFSET_SB_IMM;

        rd_data_source <= RD_DATA_ALU_OUT;
        rd_write_enable <= false;

        dmem_address_source <= DMEM_ADDRESS_NONE;
        dmem_write_enable <= false;

        case instruction_opcode(inst) is
            when OP_LOAD =>
                assert instruction_funct(inst) ?= FUNCT_LD report "Invalid instruction" severity error;
                alu_op <= ALU_ADD;
                alu_in1_source <= ALU_IN1_RS1_DATA;
                alu_in2_source <= ALU_IN2_I_IMM;

                dmem_address_source <= DMEM_ADDRESS_ALU_OUT;
                dmem_write_enable <= false;

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
end arch;
