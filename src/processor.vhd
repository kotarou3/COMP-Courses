library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library work;
use work.constants.all;

entity processor is
    port (
        enable: in std_ulogic;
        clock: in std_ulogic;

        irq: in std_ulogic;
        irq_data: in register_t;
        irq_acked: out std_ulogic
    );
end processor;

architecture arch of processor is
    type irq_stage_t is (IRQ_NONE, IRQ_DETECTED, IRQ_HANDLING);
    signal irq_stage: irq_stage_t;
    signal irq_handler: address_t;
    signal irq_ack: boolean;

    signal pc, next_pc: address_t;
    signal branch_next_pc: address_t;

    signal id_stall: boolean;

    signal ifid_in, ifid_out: ifid_t;
    signal idex_in, idex_out: idex_t;
    signal exmem_in, exmem_out: exmem_t;
    signal memwb_in, memwb_out: memwb_t;

    signal id_is_branch, ex_is_branch: boolean;

    signal rs1_enable, rs2_enable: boolean;
    signal rs1, rs2, rd: natural range 0 to REGISTERS - 1;
    signal rs1_data, rs2_data, rd_data: register_t;
    signal rd_write_enable: boolean;

    signal id_rs1_data, id_rs2_data: register_t;

    signal imem_address: address_t;
    signal imem_data: instruction_t;

    signal dmem_address: address_t;
    signal dmem_out, dmem_in: data_t;
    signal dmem_write_enable: boolean;
begin
    irq_acked <= '1' when irq_stage = IRQ_NONE else '0';

    process (enable, clock, irq, irq_ack)
        variable if_stall: boolean;
    begin
        if_stall := false;

        if enable = '0' then
            irq_stage <= IRQ_NONE;

            pc <= ADDRESS_ZERO;

            ifid_out <= IFID_ZERO;
            idex_out <= IDEX_ZERO;
            exmem_out <= EXMEM_ZERO;
            memwb_out <= MEMWB_ZERO;
        elsif rising_edge(irq) and irq_stage = IRQ_NONE then
            irq_stage <= IRQ_DETECTED;
        elsif falling_edge(clock) then
            if irq_stage = IRQ_DETECTED then
                pc <= irq_handler;
                irq_stage <= IRQ_HANDLING;

                -- Flush entire pipeline
                ifid_out <= IFID_ZERO;
                idex_out <= IDEX_ZERO;
                exmem_out <= EXMEM_ZERO;

                -- Hijack last stage to write IRQ data to the a0 (x10) register
                memwb_out <= (
                    rd => 10,
                    rd_data => irq_data,
                    rd_write_enable => true
                );
            else
                if id_is_branch or id_stall then
                    if_stall := true;
                elsif ex_is_branch then
                    if_stall := true;
                    pc <= branch_next_pc(branch_next_pc'left downto 1) & '0';
                else
                    pc <= next_pc(next_pc'left downto 1) & '0';
                end if;

                if id_stall then
                    ifid_out <= ifid_out;
                elsif if_stall then
                    ifid_out <= IFID_ZERO;
                else
                    ifid_out <= ifid_in;
                end if;

                if id_stall then
                    idex_out <= IDEX_ZERO;
                else
                    idex_out <= idex_in;
                end if;

                exmem_out <= exmem_in;
                memwb_out <= memwb_in;
            end if;
        elsif rising_edge(irq_ack) then
            irq_stage <= IRQ_NONE;
        end if;
    end process;
    next_pc <= pc + INSTRUCTION_WIDTH_BYTES;

    data_forwarding: process (all)
        variable ex_rs1, ex_rs2, mem_rs1, mem_rs2: boolean;
    begin
        ex_rs1 := rs1_enable and idex_out.rd_write_enable and idex_out.rd /= 0 and idex_out.rd = rs1;
        ex_rs2 := rs2_enable and idex_out.rd_write_enable and idex_out.rd /= 0 and idex_out.rd = rs2;
        mem_rs1 := rs1_enable and exmem_out.rd_write_enable and exmem_out.rd /= 0 and exmem_out.rd = rs1;
        mem_rs2 := rs2_enable and exmem_out.rd_write_enable and exmem_out.rd /= 0 and exmem_out.rd = rs2;

        id_stall <= false;

        if ex_rs1 then
            case idex_out.rd_data_source is
                when RD_DATA_DMEM_OUT =>
                    id_stall <= true;
                when RD_DATA_ALU_OUT =>
                    id_rs1_data <= exmem_in.alu_out;
                when RD_DATA_DEFAULT_NEXT_PC =>
                    id_rs1_data <= signed(exmem_in.default_next_pc);
            end case;
        elsif mem_rs1 then
            id_rs1_data <= memwb_in.rd_data;
        else
            id_rs1_data <= rs1_data;
        end if;

        if ex_rs2 then
            case idex_out.rd_data_source is
                when RD_DATA_DMEM_OUT =>
                    id_stall <= true;
                when RD_DATA_ALU_OUT =>
                    id_rs2_data <= exmem_in.alu_out;
                when RD_DATA_DEFAULT_NEXT_PC =>
                    id_rs2_data <= signed(exmem_in.default_next_pc);
            end case;
        elsif mem_rs2 then
            id_rs2_data <= memwb_in.rd_data;
        else
            id_rs2_data <= rs2_data;
        end if;
    end process;

    gp_registers: entity work.gp_registers port map(
        enable => enable,
        clock => clock,

        rs1 => rs1,
        rs2 => rs2,
        rd => rd,
        write_enable => rd_write_enable,

        rs1_data => rs1_data,
        rs2_data => rs2_data,
        rd_data => rd_data
    );

    imem: entity work.imem port map(
        enable => enable,
        clock => clock,

        address => imem_address,
        data => imem_data
    );

    dmem: entity work.dmem port map(
        enable => enable,
        clock => clock,

        address => dmem_address,
        data_out => dmem_out,

        data_in => dmem_in,
        write_enable => dmem_write_enable,

        irq_handler => irq_handler,
        irq_ack => irq_ack
    );

    pipeline_instruction_fetch: entity work.pipeline_instruction_fetch port map(
        pc => pc,
        default_next_pc => next_pc,

        imem_address => imem_address,
        imem_data => imem_data,

        next_stage => ifid_in
    );

    pipeline_instruction_decode: entity work.pipeline_instruction_decode port map(
        is_branch => id_is_branch,

        rs1_enable => rs1_enable,
        rs2_enable => rs2_enable,
        rs1 => rs1,
        rs2 => rs2,
        rs1_data => id_rs1_data,
        rs2_data => id_rs2_data,

        prev_stage => ifid_out,
        next_stage => idex_in
    );

    pipeline_execute: entity work.pipeline_execute port map(
        next_pc => branch_next_pc,
        is_branch => ex_is_branch,

        prev_stage => idex_out,
        next_stage => exmem_in
    );

    pipeline_memory_access: entity work.pipeline_memory_access port map(
        dmem_address => dmem_address,
        dmem_out => dmem_out,
        dmem_in => dmem_in,
        dmem_write_enable => dmem_write_enable,

        prev_stage => exmem_out,
        next_stage => memwb_in
    );

    pipeline_writeback: entity work.pipeline_writeback port map(
        rd => rd,
        rd_data => rd_data,
        rd_write_enable => rd_write_enable,

        prev_stage => memwb_out
    );
end arch;
