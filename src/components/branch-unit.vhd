library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library work;
use work.constants.all;

entity branch_unit is
    port (
        branch_op: in branch_op_t;
        branch_in1, branch_in2, branch_offset: in register_t;

        branch_out: out register_t
    );
end branch_unit;

architecture arch of branch_unit is
begin
    process (branch_op, branch_in1, branch_in2, branch_offset) is
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
end arch;
