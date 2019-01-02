include ../Makefile.inc

all: imem.hex dmem.hex test

test: imem.hex dmem.hex
	$(MODELSIM) -c -do ../general-test.do <&-

clean:
	rm -f main *.o imem.hex dmem.hex dmem_out.hex transcript vsim.wlf
	rm -rf work

main: main.o ../start.S
	$(CC) -o $@ $+ $(LDFLAGS)

imem.hex: main
	$(OBJCOPY) -O verilog main /dev/stdout | \
		sed -E 's/\b([A-Z0-9]{2}) ([A-Z0-9]{2}) ([A-Z0-9]{2}) ([A-Z0-9]{2})\b/\4\3\2\1/g' | # Encode bytes as LE32 \
		perl -ne 'm/@([A-Z0-9]{8})/ and printf "@%08X\n", hex($$1) / 4 or print' > imem.hex.tmp # Divide addresses by 4
	mv imem.hex.tmp imem.hex

dmem.hex:
	touch dmem.hex # Empty
