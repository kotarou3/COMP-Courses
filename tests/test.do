vcom -2008 ../../src/*.vhd ../processor-testbench.vhw
vsim processor_testbench

add wave -noupdate -format Logic -radix hexadecimal /processor_testbench/enable
add wave -noupdate -format Logic -radix hexadecimal /processor_testbench/clock
add wave -noupdate -format Literal -radix hexadecimal /processor_testbench/uut/pc
add wave -noupdate -format Literal -radix hexadecimal /processor_testbench/uut/next_pc
add wave -noupdate -format Literal -radix hexadecimal /processor_testbench/uut/inst
add wave -noupdate -format Literal -radix hexadecimal /processor_testbench/uut/op_type
add wave -noupdate -format Literal -radix hexadecimal /processor_testbench/uut/gp_registers/rs1
add wave -noupdate -format Literal -radix hexadecimal /processor_testbench/uut/gp_registers/rs2
add wave -noupdate -format Literal -radix hexadecimal /processor_testbench/uut/gp_registers/rd
add wave -noupdate -format Literal -radix hexadecimal /processor_testbench/uut/rd_write_enable
add wave -noupdate -format Literal -radix hexadecimal /processor_testbench/uut/dmem_address
add wave -noupdate -format Literal -radix hexadecimal /processor_testbench/uut/dmem_write_enable
add wave -noupdate -format Literal -radix hexadecimal -expand /processor_testbench/uut/gp_registers/registers
#add wave -noupdate -format Literal -radix hexadecimal -expand /processor_testbench/uut/imem/memory
#add wave -noupdate -format Literal -radix hexadecimal -expand /processor_testbench/uut/dmem/memory
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
WaveRestoreZoom {0 ps} {3 us}

mem load -filldata 0 -infile imem.hex -format hex /processor_testbench/uut/imem/memory
mem load -filldata 0 -infile dmem.hex -format hex /processor_testbench/uut/dmem/memory

run 20us

mem save -outfile dmem_out.hex -format hex /processor_testbench/uut/dmem/memory
exec diff -wu dmem_result.hex dmem_out.hex
echo "Test successful"
