library IEEE;
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;

entity processor is
    port (
        enable: in std_ulogic;
        clock: in std_ulogic;
        run: in std_ulogic;
        done: out std_ulogic;

        DIN: in std_ulogic_vector(8 downto 0);
        DOUT: out unsigned(8 downto 0)
    );
end processor;

architecture arch of processor is
    type instruction_t is record
        operation: integer range 0 to 3;
        destReg: integer range 0 to 7;
        srcReg: integer range 0 to 7;
    end record;

    function to_instruction_t(
        a: std_ulogic_vector(8 downto 0)
    ) return instruction_t is
        variable result: instruction_t;
    begin
        result.operation := to_integer(unsigned(a(8 downto 6)));
        result.destReg := to_integer(unsigned(a(5 downto 3)));
        result.srcReg := to_integer(unsigned(a(2 downto 0)));
        return result;
    end function;

    signal instructionReg: instruction_t;

    type registers_t is array (0 to 7) of unsigned(8 downto 0);
    signal registers: registers_t;

    signal state: integer range 0 to 1;
begin
    process (clock)
        variable instruction: instruction_t;
        variable output: unsigned(8 downto 0);
    begin
        if rising_edge(clock) then
            output := "000000000";

            if enable = '0' then
                for r in registers'range loop
                    registers(r) <= "000000000";
                end loop;
                done <= '0';
                state <= 0;
            else
                case state is
                    when 0 =>
                        if run = '1' then
                            instruction := to_instruction_t(DIN);
                            case instruction.operation is
                                when 0 => -- mv Rdest, Rsrc
                                    output := registers(instruction.srcReg);
                                    registers(instruction.destReg) <= output;
                                    done <= '1';

                                when 1 => -- mvi Rdest, imm9
                                    instructionReg <= instruction;
                                    done <= '0';
                                    state <= 1;

                                when 2 => -- add Rdest, Rsrc
                                    output := registers(instruction.destReg) + registers(instruction.srcReg);
                                    registers(instruction.destReg) <= output;
                                    done <= '1';

                                when 3 => -- sub Rdest, Rsrc
                                    output := registers(instruction.destReg) - registers(instruction.srcReg);
                                    registers(instruction.destReg) <= output;
                                    done <= '1';
                            end case;
                        else
                            done <= '0';
                        end if;

                    when 1 =>
                        assert(instructionReg.operation = 1);
                        output := unsigned(DIN);
                        registers(instructionReg.destReg) <= output;
                        done <= '1';
                        state <= 0;
                end case;
            end if;

            DOUT <= output;
        end if;
    end process;
end arch;
