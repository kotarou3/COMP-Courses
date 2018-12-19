#define _POSIX_C_SOURCE 200809L

#define PRINT_PER_ITERATION 0x400000

#include <limits.h>
#include <stdatomic.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#ifdef __STDC_NO_THREADS__
    // Fall back to pthreads if no C11 threads
    #include "c11threads.h"
#else
    #include <threads.h>
#endif

#define BYTE_SIZE CHAR_BIT
#define BYTE_MAX UCHAR_MAX
#define get_byte_in_int(int, byte) (((int) >> ((byte) * BYTE_SIZE)) & BYTE_MAX)
#define set_byte_in_int(int, byte, val) ((int) & ~(BYTE_MAX << ((byte) * BYTE_SIZE))) | ((val) << ((byte) * BYTE_SIZE))

// We require FIFO consistency on memory, and the closest C provides is
// memory_order_seq_cst in its atomics library. atomic_store and atomic_load
// both use memory_order_seq_cst by default.
typedef uint8_t byte;
typedef _Atomic byte shared_byte;
typedef _Atomic bool shared_bool;

size_t B, k;

shared_bool of1 = ATOMIC_VAR_INIT(false);
shared_bool of2 = ATOMIC_VAR_INIT(false);
shared_byte* c1;
shared_byte* c2;

void read(byte* value) {
    // Read of2:c2 MSB first
    bool overflow = atomic_load(&of2);
    for (size_t b = B; b --> 0; )
        value[b] = atomic_load(&c2[b]);

    // "Comb" through c1 and c2, updating the local counter according to the algorithm
    size_t j = 0;
    for (size_t b = 1; b < B; ++b) {
        byte tmp = atomic_load(&c1[b]);
        if (tmp > value[b]) {
            value[b] = tmp;
            j = b;
        }

        tmp = atomic_load(&c2[b]);
        if (tmp > value[b]) {
            value[b] = tmp;
            j = b;
        }
    }

    if (overflow != atomic_load(&of1))
        j = B;

    // Perform the zeroing outside of the loop so the read is linear in time
    for (size_t b = 0; b < j; ++b)
        value[b] = 0;
}

// Actually "increment and fetch"
void increment(byte* value) {
    read(value);

    // Increment the value
    for (size_t b = 0; b < B; ++b) {
        if (value[b] != BYTE_MAX) {
            ++value[b];
            break;
        } else {
            value[b] = 0;
        }
    }

    // Write updated value LSB first to both counters
    for (size_t b = 0; b < B; ++b) {
        byte tmp = value[b];
        if (atomic_load(&c1[b]) == tmp)
            break;

        atomic_store(&c1[b], tmp);
        if (b == B - 1 && tmp == 0)
            atomic_store(&of1, !atomic_load(&of1));
    }

    for (size_t b = 0; b < B; ++b) {
        byte tmp = value[b];
        if (atomic_load(&c2[b]) == tmp)
            break;

        atomic_store(&c2[b], tmp);
        if (b == B - 1 && tmp == 0)
            atomic_store(&of2, !atomic_load(&of2));
    }
}

void print_counter(const byte* value) {
    printf("0x");
    
    uintmax_t tmp = 0;
    for (size_t b = B; b --> 0; ) {
        tmp = set_byte_in_int(tmp, b, value[b]);
        printf("%02x", value[b]);
    }
    printf(" = %llu\n", tmp); // Hope uintmax_t at least 64-bits
}

int reader(size_t id) {
    for (size_t n = 0; n < k || k == 0; ++n) {
        byte value[B];
        read(value);
        
        if (n % PRINT_PER_ITERATION == 0) {
            printf("[%zu] read #%zu:\t", id, n);
            print_counter(value);
        }
    }

    return 0;
}

int writer(void) {
    for (size_t n = 0; n < k || k == 0; ++n) {
        byte value[B];
        increment(value);
        
        if (n % PRINT_PER_ITERATION == 0) {
            printf("[-] write #%zu:\t", n);
            print_counter(value);
        }
    }

    return 0;
}

int main(int argc, char** argv) {
    if (argc < 4) {
        fprintf(stderr, "Usage: %s R B k\n", argv[0]);
        return 1;
    }

    size_t R;
    if (sscanf(argv[1], "%zu", &R) != 1) {
        fprintf(stderr, "Could not parse argument R\n");
        return 1;
    }
    if (sscanf(argv[2], "%zu", &B) != 1) {
        fprintf(stderr, "Could not parse argument B\n");
        return 1;
    }
    if (sscanf(argv[3], "%zu", &k) != 1) {
        fprintf(stderr, "Could not parse argument k\n");
        return 1;
    }

    printf("Starting with (R, B, k) = (%zu, %zu, %zu)\n", R, B, k);

    thrd_t reader_threads[R];
    thrd_t writer_thread;
    int ret = 1;

    c1 = calloc(B, sizeof(*c1));
    c2 = calloc(B, sizeof(*c2));
    if (!c1 || !c2) {
        fprintf(stderr, "Failed to allocate memory for the counters\n");
        goto fail;
    }
    for (size_t b = 0; b < B; ++b) {
        atomic_init(&c1[b], 0);
        atomic_init(&c2[b], 0);
    }

    for (size_t r = 0; r < R; ++r) {
        if (thrd_create(&reader_threads[r], (thrd_start_t)reader, (void*)r) != thrd_success) {
            fprintf(stderr, "Failed to start reader thread #%zu\n", r);
            while (r --> 0)
                thrd_join(reader_threads[r], NULL);
            goto fail;
        }
    }
    if (thrd_create(&writer_thread, (thrd_start_t)writer, NULL) != thrd_success) {
        fprintf(stderr, "Failed to start writer thread\n");
        goto fail2;
    }

    ret = 0;

    thrd_join(writer_thread, NULL);
fail2:
    for (size_t r = 0; r < R; ++r)
        thrd_join(reader_threads[r], NULL);
fail:
    free(c1);
    free(c2);
    return ret;
}
