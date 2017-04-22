vcom -2008 ../../src/constants.vhd ../../src/instructions.vhd
vcom -2008 ../../src/components/*.vhd ../../src/pipeline/*.vhd
vcom -2008 ../../src/*.vhd
vcom -2008 ../processor-testbench.vhw
vsim processor_testbench

add wave -noupdate -format Logic -radix hexadecimal /processor_testbench/enable
add wave -noupdate -format Logic -radix hexadecimal /processor_testbench/clock
add wave -noupdate -format Literal -radix hexadecimal /processor_testbench/uut/pc
add wave -noupdate -format Literal -radix hexadecimal /processor_testbench/uut/next_pc
add wave -noupdate -format Literal -radix hexadecimal /processor_testbench/uut/id_is_branch
add wave -noupdate -format Literal -radix hexadecimal /processor_testbench/uut/ex_is_branch
add wave -noupdate -format Literal -radix hexadecimal /processor_testbench/uut/rs1_data
add wave -noupdate -format Literal -radix hexadecimal /processor_testbench/uut/id_rs1_data
add wave -noupdate -format Literal -radix hexadecimal /processor_testbench/uut/rs2_data
add wave -noupdate -format Literal -radix hexadecimal /processor_testbench/uut/id_rs2_data
add wave -noupdate -format Literal -radix hexadecimal -expand /processor_testbench/uut/ifid_out
add wave -noupdate -format Literal -radix hexadecimal -expand /processor_testbench/uut/idex_out
add wave -noupdate -format Literal -radix hexadecimal /processor_testbench/uut/exmem_out
add wave -noupdate -format Literal -radix hexadecimal /processor_testbench/uut/memwb_out
add wave -noupdate -format Literal -radix hexadecimal /processor_testbench/uut/gp_registers/rs1
add wave -noupdate -format Literal -radix hexadecimal /processor_testbench/uut/gp_registers/rs2
add wave -noupdate -format Literal -radix hexadecimal /processor_testbench/uut/gp_registers/rd
add wave -noupdate -format Literal -radix hexadecimal /processor_testbench/uut/gp_registers/write_enable
add wave -noupdate -format Literal -radix hexadecimal /processor_testbench/uut/dmem/address
add wave -noupdate -format Literal -radix hexadecimal /processor_testbench/uut/dmem/write_enable
add wave -noupdate -format Literal -radix hexadecimal -expand /processor_testbench/uut/gp_registers/registers
#add wave -noupdate -format Literal -radix hexadecimal -expand /processor_testbench/uut/imem/memory
#add wave -noupdate -format Literal -radix hexadecimal -expand /processor_testbench/uut/dmem/memory
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
WaveRestoreZoom {0 ps} {3 us}

mem load -filldata 0 -infile imem.hex -format hex /processor_testbench/uut/imem/memory
mem load -filldata 0 -infile dmem.hex -format hex /processor_testbench/uut/dmem/memory

run -all

mem save -outfile dmem_out.hex -format hex /processor_testbench/uut/dmem/memory -startaddress 1024
exec diff -wu dmem_result.hex dmem_out.hex
echo "Test successful"
