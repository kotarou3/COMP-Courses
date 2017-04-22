library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

package constants is
    constant XLEN: positive := 64;
    constant REGISTERS: positive := 32;

    constant BYTE_WIDTH: positive := 8;
    constant INSTRUCTION_WIDTH: positive := 32;
    constant IMEM_SIZE_BYTES: positive := 4096;
    constant INSTRUCTION_WIDTH_BYTES: positive := INSTRUCTION_WIDTH / BYTE_WIDTH;
    constant IMEM_SIZE: positive := IMEM_SIZE_BYTES / INSTRUCTION_WIDTH_BYTES;
    constant DATA_WIDTH: positive := XLEN;
    constant DMEM_SIZE_BYTES: positive := 3 * 4096;
    constant DATA_WIDTH_BYTES: positive := DATA_WIDTH / BYTE_WIDTH;
    constant DMEM_SIZE: positive := DMEM_SIZE_BYTES / DATA_WIDTH_BYTES;

    subtype register_t is signed(XLEN - 1 downto 0);
    subtype address_t is unsigned(XLEN - 1 downto 0);
    subtype instruction_t is std_ulogic_vector(INSTRUCTION_WIDTH - 1 downto 0);
    subtype data_t is signed(DATA_WIDTH - 1 downto 0);

    constant XLEN_ZERO: register_t := (others => '0');
    constant XLEN_ONE: register_t := (0 => '1', others => '0');
    constant ADDRESS_ZERO: address_t := (others => '0');

    type next_pc_source_t is (
        NEXT_PC_DEFAULT,
        NEXT_PC_BRANCH_OUT,
        NEXT_PC_ALU_OUT
    );

    type alu_op_t is (
        ALU_ADD, ALU_SUB,
        ALU_SLT, ALU_SLTU,
        ALU_XOR, ALU_OR, ALU_AND,
        ALU_SLL, ALU_SRL, ALU_SRA
    );
    type alu_in1_source_t is (
        ALU_IN1_RS1_DATA,
        ALU_IN1_PC,
        ALU_IN1_ZERO
    );
    type alu_in2_source_t is (
        ALU_IN2_RS2_DATA,
        ALU_IN2_IMM
    );

    type branch_op_t is (
        BRANCH_JUMP,
        BRANCH_EQ, BRANCH_NE,
        BRANCH_LT, BRANCH_GE,
        BRANCH_LTU, BRANCH_GEU
    );

    type rd_data_source_t is (
        RD_DATA_DMEM_OUT,
        RD_DATA_ALU_OUT,
        RD_DATA_DEFAULT_NEXT_PC
    );

    type dmem_address_source_t is (
        DMEM_ADDRESS_ALU_OUT,
        DMEM_ADDRESS_NONE
    );
end constants;
