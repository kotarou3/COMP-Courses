add wave -noupdate -format Logic -radix hexadecimal /test/enable
add wave -noupdate -format Logic -radix hexadecimal /test/clock
add wave -noupdate -format Literal -radix hexadecimal /test/uut/core/pc
add wave -noupdate -format Literal -radix hexadecimal /test/uut/core/next_pc
add wave -noupdate -format Literal -radix hexadecimal /test/uut/core/id_is_branch
add wave -noupdate -format Literal -radix hexadecimal /test/uut/core/ex_is_branch
add wave -noupdate -format Literal -radix hexadecimal /test/uut/core/rs1_data
add wave -noupdate -format Literal -radix hexadecimal /test/uut/core/id_rs1_data
add wave -noupdate -format Literal -radix hexadecimal /test/uut/core/rs2_data
add wave -noupdate -format Literal -radix hexadecimal /test/uut/core/id_rs2_data
add wave -noupdate -format Literal -radix hexadecimal -expand /test/uut/core/ifid_out
add wave -noupdate -format Literal -radix hexadecimal -expand /test/uut/core/idex_out
add wave -noupdate -format Literal -radix hexadecimal /test/uut/core/exmem_out
add wave -noupdate -format Literal -radix hexadecimal /test/uut/core/memwb_out
add wave -noupdate -format Literal -radix hexadecimal /test/uut/core/gp_registers/rs1
add wave -noupdate -format Literal -radix hexadecimal /test/uut/core/gp_registers/rs2
add wave -noupdate -format Literal -radix hexadecimal /test/uut/core/gp_registers/rd
add wave -noupdate -format Literal -radix hexadecimal /test/uut/core/gp_registers/write_enable
add wave -noupdate -format Literal -radix hexadecimal /test/uut/dmem/address
add wave -noupdate -format Literal -radix hexadecimal /test/uut/dmem/write_enable
add wave -noupdate -format Literal -radix hexadecimal -expand /test/uut/core/gp_registers/registers
#add wave -noupdate -format Literal -radix hexadecimal -expand /test/uut/core/imem/memory
#add wave -noupdate -format Literal -radix hexadecimal -expand /test/uut/core/dmem/memory
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
WaveRestoreZoom {0 ps} {3 us}
