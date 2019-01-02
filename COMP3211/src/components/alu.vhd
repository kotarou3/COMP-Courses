library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library work;
use work.constants.all;

entity alu is
    port (
        alu_op: in alu_op_t;
        alu_in1, alu_in2: in register_t;

        alu_out: out register_t
    );
end alu;

architecture arch of alu is
begin
    process (all)
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
end arch;
