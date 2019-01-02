CC = riscv64-unknown-linux-gnu-gcc
CFLAGS = -std=c11 -Wall -Wextra -pedantic -Os -march=rv64g
LDFLAGS = -nostdlib -T ../linker.ld -march=rv64g

OBJCOPY = riscv64-unknown-linux-gnu-objcopy

MODELSIM = ~/ModelSim-16.1/modelsim_ase/linux/vsim

.PHONY: all test clean

%.o: %.c
	$(CC) $< -c -o $@ $(CFLAGS)
