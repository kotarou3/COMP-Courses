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

    constant INSTRUCTION_NOP: instruction_t := x"00000013";

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
        RD_DATA_ALU_OUT,
        RD_DATA_DMEM_OUT,
        RD_DATA_DEFAULT_NEXT_PC
    );

    type dmem_address_source_t is (
        DMEM_ADDRESS_ALU_OUT,
        DMEM_ADDRESS_NONE
    );

    type ifid_t is record
        pc, default_next_pc: address_t;
        inst: instruction_t;
    end record;

    type idex_t is record
        pc, default_next_pc: address_t;
        next_pc_source: next_pc_source_t;

        alu_op: alu_op_t;
        alu_in1, alu_in2: register_t;

        is_branch: boolean;
        branch_op: branch_op_t;
        branch_in1, branch_in2, branch_offset: register_t;

        rd: natural range 0 to REGISTERS - 1;
        rd_data_source: rd_data_source_t;
        rd_write_enable: boolean;

        dmem_address_source: dmem_address_source_t;
        dmem_in: data_t;
        dmem_write_enable: boolean;
    end record;

    type exmem_t is record
        default_next_pc: address_t;

        rd: natural range 0 to REGISTERS - 1;
        rd_data_source: rd_data_source_t;
        rd_write_enable: boolean;

        alu_out: register_t;

        dmem_address: address_t;
        dmem_in: data_t;
        dmem_write_enable: boolean;
    end record;

    type memwb_t is record
        rd: natural range 0 to REGISTERS - 1;
        rd_data: register_t;
        rd_write_enable: boolean;
    end record;

    constant IFID_ZERO: ifid_t := (
        pc => ADDRESS_ZERO, default_next_pc => ADDRESS_ZERO,
        inst => INSTRUCTION_NOP
    );
    constant IDEX_ZERO: idex_t := (
        pc => ADDRESS_ZERO, default_next_pc => ADDRESS_ZERO,
        next_pc_source => NEXT_PC_DEFAULT,

        alu_op => ALU_ADD,
        alu_in1 => XLEN_ZERO, alu_in2 => XLEN_ZERO,

        is_branch => false,
        branch_op => BRANCH_JUMP,
        branch_in1 => XLEN_ZERO, branch_in2 => XLEN_ZERO, branch_offset => XLEN_ZERO,

        rd => 0,
        rd_data_source => RD_DATA_ALU_OUT,
        rd_write_enable => false,

        dmem_address_source => DMEM_ADDRESS_NONE,
        dmem_in => XLEN_ZERO,
        dmem_write_enable => false
    );
    constant EXMEM_ZERO: exmem_t := (
        default_next_pc => ADDRESS_ZERO,

        rd => 0,
        rd_data_source => RD_DATA_ALU_OUT,
        rd_write_enable => false,

        alu_out => XLEN_ZERO,

        dmem_address => ADDRESS_ZERO,
        dmem_in => XLEN_ZERO,
        dmem_write_enable => false
    );
    constant MEMWB_ZERO: memwb_t := (
        rd => 0,
        rd_data => XLEN_ZERO,
        rd_write_enable => false
    );
end constants;
