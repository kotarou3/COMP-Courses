all: counter
clean:
	rm -f counter

counter: counter.c c11threads.h
	gcc counter.c -o counter -std=c11 -Wall -Wextra -pedantic -O3 -lpthread
