library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library work;
use work.constants.all;

package instructions is
    constant INSTRUCTION_NOP: instruction_t := x"00000013";

    subtype opcode_t is std_ulogic_vector(6 downto 0);
    constant OP_LOAD:   opcode_t := "0000011";
    constant OP_OP_IMM: opcode_t := "0010011";
    constant OP_AUIPC:  opcode_t := "0010101";
    constant OP_STORE:  opcode_t := "0100011";
    constant OP_OP:     opcode_t := "0110011";
    constant OP_LUI:    opcode_t := "0110111";
    constant OP_BRANCH: opcode_t := "1100011";
    constant OP_JALR:   opcode_t := "1100111";
    constant OP_JAL:    opcode_t := "1101111";

    subtype funct_t is std_ulogic_vector(9 downto 0);
    -- OP_BRANCH
    constant FUNCT_JALR:    funct_t := "-------000";
    constant FUNCT_BEQ:     funct_t := "-------000";
    constant FUNCT_BNE:     funct_t := "-------001";
    constant FUNCT_BLT:     funct_t := "-------100";
    constant FUNCT_BGE:     funct_t := "-------101";
    constant FUNCT_BLTU:    funct_t := "-------110";
    constant FUNCT_BGEU:    funct_t := "-------111";
    -- OP_LOAD
    --constant FUNCT_LB:      funct_t := "-------000";
    --constant FUNCT_LH:      funct_t := "-------001";
    --constant FUNCT_LW:      funct_t := "-------010";
    constant FUNCT_LD:      funct_t := "-------011";
    --constant FUNCT_LBU:     funct_t := "-------100";
    --constant FUNCT_LHU:     funct_t := "-------101";
    --constant FUNCT_LWU:      funct_t := "-------110";
    -- OP_STORE
    --constant FUNCT_SB:      funct_t := "-------000";
    --constant FUNCT_SH:      funct_t := "-------001";
    --constant FUNCT_SW:      funct_t := "-------010";
    constant FUNCT_SD:      funct_t := "-------011";
    -- OP_OP_IMM
    constant FUNCT_ADDI:    funct_t := "-------000";
    constant FUNCT_SLTI:    funct_t := "-------010";
    constant FUNCT_SLTIU:   funct_t := "-------011";
    constant FUNCT_XORI:    funct_t := "-------100";
    constant FUNCT_ORI:     funct_t := "-------110";
    constant FUNCT_ANDI:    funct_t := "-------111";
    constant FUNCT_SLLI:    funct_t := "0000000001";
    constant FUNCT_SRLI:    funct_t := "0000000101";
    constant FUNCT_SRAI:    funct_t := "0100000101";
    -- OP_OP
    constant FUNCT_ADD:     funct_t := "0000000000";
    constant FUNCT_SUB:     funct_t := "0100000000";
    constant FUNCT_SLL:     funct_t := "0000000001";
    constant FUNCT_SLT:     funct_t := "0000000010";
    constant FUNCT_SLTU:    funct_t := "0000000011";
    constant FUNCT_XOR:     funct_t := "0000000100";
    constant FUNCT_SRL:     funct_t := "0000000101";
    constant FUNCT_SRA:     funct_t := "0100000101";
    constant FUNCT_OR:      funct_t := "0000000110";
    constant FUNCT_AND:     funct_t := "0000000111";

    -- Note: Only LD and SD of RV64I is implemented

    function instruction_i_imm(instruction: instruction_t) return register_t;
    function instruction_s_imm(instruction: instruction_t) return register_t;
    function instruction_sb_imm(instruction: instruction_t) return register_t;
    function instruction_u_imm(instruction: instruction_t) return register_t;
    function instruction_uj_imm(instruction: instruction_t) return register_t;

    function instruction_rd(instruction: instruction_t) return natural;
    function instruction_rs1(instruction: instruction_t) return natural;
    function instruction_rs2(instruction: instruction_t) return natural;
    function instruction_funct(instruction: instruction_t) return funct_t;
    function instruction_opcode(instruction: instruction_t) return opcode_t;
end instructions;

package body instructions is
    function instruction_i_imm(instruction: instruction_t) return register_t is
    begin
        return resize(signed(instruction(31 downto 20)), XLEN);
    end function;

    function instruction_s_imm(instruction: instruction_t) return register_t is
    begin
        return resize(signed(instruction(31 downto 25) & instruction(11 downto 7)), XLEN);
    end function;

    function instruction_sb_imm(instruction: instruction_t) return register_t is
    begin
        return resize(signed(instruction(31) & instruction(7) & instruction(30 downto 25) & instruction(11 downto 8) & '0'), XLEN);
    end function;

    function instruction_u_imm(instruction: instruction_t) return register_t is
    begin
        return resize(signed(instruction(31 downto 12) & x"000"), XLEN);
    end function;

    function instruction_uj_imm(instruction: instruction_t) return register_t is
    begin
        return resize(signed(instruction(31) & instruction(19 downto 12) & instruction(20) & instruction(30 downto 21) & '0'), XLEN);
    end function;

    function instruction_rd(instruction: instruction_t) return natural is
    begin
        return to_integer(unsigned(instruction(11 downto 7)));
    end function;

    function instruction_rs1(instruction: instruction_t) return natural is
    begin
        return to_integer(unsigned(instruction(19 downto 15)));
    end function;

    function instruction_rs2(instruction: instruction_t) return natural is
    begin
        return to_integer(unsigned(instruction(24 downto 20)));
    end function;

    function instruction_funct(instruction: instruction_t) return funct_t is
    begin
        return instruction(31 downto 25) & instruction(14 downto 12);
    end function;

    function instruction_opcode(instruction: instruction_t) return opcode_t is
    begin
        return instruction(6 downto 0);
    end function;
end package body;
