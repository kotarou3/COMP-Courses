all: lse
clean:
	rm -f lse

lse: lse.c
	mpicc lse.c -o lse -std=c11 -Wall -Wextra -pedantic -O3
