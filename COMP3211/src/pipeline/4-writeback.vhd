library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library work;
use work.constants.all;

entity pipeline_writeback is
    port (
        rd: out natural range 0 to REGISTERS - 1;
        rd_data: out register_t;
        rd_write_enable: out boolean;

        prev_stage: in memwb_t
    );
end pipeline_writeback;

architecture arch of pipeline_writeback is
begin
    rd <= prev_stage.rd;
    rd_data <= prev_stage.rd_data;
    rd_write_enable <= prev_stage.rd_write_enable;
end arch;
