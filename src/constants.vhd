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

    type alu_op_t is (
        ALU_ADD, ALU_SUB,
        ALU_SLT, ALU_SLTU,
        ALU_XOR, ALU_OR, ALU_AND,
        ALU_SLL, ALU_SRL, ALU_SRA
    );

    type branch_op_t is (
        BRANCH_EQ, BRANCH_NE,
        BRANCH_LT, BRANCH_GE,
        BRANCH_LTU, BRANCH_GEU
    );
end constants;
