vcom -2008 ../../src/constants.vhd ../../src/instructions.vhd
vcom -2008 ../../src/components/*.vhd ../../src/pipeline/*.vhd
vcom -2008 ../../src/*.vhd
vcom -2008 ../irq-testbench.vhw
vsim test

add wave -noupdate -format Logic -radix hexadecimal /test/irq
add wave -noupdate -format Literal -radix hexadecimal /test/irq_data
add wave -noupdate -format Logic -radix hexadecimal /test/irq_acked
do ../general-signals.do

mem load -filldata 0 -infile irq-buffer.hex -format hex /test/irq_buffer
mem load -filldata 0 -infile imem.hex -format hex /test/uut/imem/memory
mem load -filldata 0 -infile dmem.hex -format hex /test/uut/dmem/memory

run -all

mem save -outfile dmem_out.hex -format hex /test/uut/dmem/memory -startaddress 1024
exec diff -wu dmem_result.hex dmem_out.hex
echo "Test successful"
