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

    type op_type_t is (OP_TYPE_MEMORY, OP_TYPE_ALU, OP_TYPE_JUMP, OP_TYPE_BRANCH, OP_TYPE_OTHER);
    signal op_type: op_type_t;
    signal decoder_next_pc: address_t;
    signal decoder_rd_data: register_t;

    type alu_in2_type_t is (ALU_IN2_REG, ALU_IN2_I_IMM, ALU_IN2_S_IMM);
    signal alu_in2_type: alu_in2_type_t;
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
            pc <= (others => '0');
            default_next_pc <= (others => '0');
        elsif falling_edge(clock) then
            pc <= next_pc(next_pc'left downto 1) & '0';
            default_next_pc <= next_pc + INSTRUCTION_WIDTH_BYTES;
        end if;
    end process;

    with op_type select rd_data <=
        dmem_out        when OP_TYPE_MEMORY,
        alu_out         when OP_TYPE_ALU,
        decoder_rd_data when others;

    with op_type select next_pc <=
        decoder_next_pc                         when OP_TYPE_JUMP,
        default_next_pc + unsigned(branch_out)  when OP_TYPE_BRANCH,
        default_next_pc                         when others;

    alu_in1 <= rs1_data;
    with alu_in2_type select alu_in2 <=
        rs2_data                when ALU_IN2_REG,
        instruction_i_imm(inst) when ALU_IN2_I_IMM,
        instruction_s_imm(inst) when ALU_IN2_S_IMM;

    dmem_in <= rs2_data;
    dmem_address <= unsigned(alu_out) when op_type = OP_TYPE_MEMORY else (others => '0');

    branch_in1 <= rs1_data;
    branch_in2 <= rs2_data;
    branch_offset <= instruction_sb_imm(inst);

    decoder: process (inst, rs1_data)
    begin
        dmem_write_enable <= false;
        rd_write_enable <= false;
        op_type <= OP_TYPE_OTHER;

        case instruction_opcode(inst) is
            when OP_LOAD =>
                assert instruction_funct(inst) = FUNCT_LD report "Invalid instruction" severity error;
                op_type <= OP_TYPE_MEMORY;
                alu_op <= ALU_ADD;
                alu_in2_type <= ALU_IN2_I_IMM;
                rd_write_enable <= true;

            when OP_STORE =>
                assert instruction_funct(inst) = FUNCT_SD report "Invalid instruction" severity error;
                op_type <= OP_TYPE_MEMORY;
                alu_op <= ALU_ADD;
                alu_in2_type <= ALU_IN2_S_IMM;
                dmem_write_enable <= true;

            when OP_OP_IMM =>
                case instruction_funct(inst) is
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
                end case;

                alu_in2_type <= ALU_IN2_I_IMM;
                rd_write_enable <= true;
                op_type <= OP_TYPE_ALU;

            when OP_LUI =>
                decoder_rd_data <= instruction_u_imm(inst);
                rd_write_enable <= true;

            when OP_AUIPC =>
                decoder_rd_data <= signed(pc) + instruction_u_imm(inst);
                rd_write_enable <= true;

            when OP_OP =>
                case instruction_funct(inst) is
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
                end case;

                alu_in2_type <= ALU_IN2_REG;
                rd_write_enable <= true;
                op_type <= OP_TYPE_ALU;

            when OP_JAL =>
                decoder_rd_data <= signed(default_next_pc);
                decoder_next_pc <= unsigned(signed(default_next_pc) + instruction_uj_imm(inst));
                rd_write_enable <= true;
                op_type <= OP_TYPE_JUMP;

            when OP_JALR =>
                assert instruction_funct(inst) = FUNCT_JALR report "Invalid instruction" severity error;
                decoder_rd_data <= signed(default_next_pc);
                decoder_next_pc <= unsigned(rs1_data + instruction_i_imm(inst));
                rd_write_enable <= true;
                op_type <= OP_TYPE_JUMP;

            when OP_BRANCH =>
                case instruction_funct(inst) is
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
                end case;
                op_type <= OP_TYPE_BRANCH;

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

        branch_out <= branch_offset when take_branch else XLEN_ZERO;
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
