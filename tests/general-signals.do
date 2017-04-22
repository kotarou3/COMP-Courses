add wave -noupdate -format Logic -radix hexadecimal /test/enable
add wave -noupdate -format Logic -radix hexadecimal /test/clock
add wave -noupdate -format Literal -radix hexadecimal /test/uut/pc
add wave -noupdate -format Literal -radix hexadecimal /test/uut/next_pc
add wave -noupdate -format Literal -radix hexadecimal /test/uut/id_is_branch
add wave -noupdate -format Literal -radix hexadecimal /test/uut/ex_is_branch
add wave -noupdate -format Literal -radix hexadecimal /test/uut/rs1_data
add wave -noupdate -format Literal -radix hexadecimal /test/uut/id_rs1_data
add wave -noupdate -format Literal -radix hexadecimal /test/uut/rs2_data
add wave -noupdate -format Literal -radix hexadecimal /test/uut/id_rs2_data
add wave -noupdate -format Literal -radix hexadecimal -expand /test/uut/ifid_out
add wave -noupdate -format Literal -radix hexadecimal -expand /test/uut/idex_out
add wave -noupdate -format Literal -radix hexadecimal /test/uut/exmem_out
add wave -noupdate -format Literal -radix hexadecimal /test/uut/memwb_out
add wave -noupdate -format Literal -radix hexadecimal /test/uut/gp_registers/rs1
add wave -noupdate -format Literal -radix hexadecimal /test/uut/gp_registers/rs2
add wave -noupdate -format Literal -radix hexadecimal /test/uut/gp_registers/rd
add wave -noupdate -format Literal -radix hexadecimal /test/uut/gp_registers/write_enable
add wave -noupdate -format Literal -radix hexadecimal /test/uut/dmem/address
add wave -noupdate -format Literal -radix hexadecimal /test/uut/dmem/write_enable
add wave -noupdate -format Literal -radix hexadecimal -expand /test/uut/gp_registers/registers
#add wave -noupdate -format Literal -radix hexadecimal -expand /test/uut/imem/memory
#add wave -noupdate -format Literal -radix hexadecimal -expand /test/uut/dmem/memory
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
WaveRestoreZoom {0 ps} {3 us}
