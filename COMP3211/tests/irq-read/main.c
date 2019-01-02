#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

#include "../irq.h"

#define MAX_RESULTS (4096 / sizeof(uint64_t))

extern uint64_t results[MAX_RESULTS];
void irqHandler(uint64_t data) {
    static size_t n;

    results[n] = data;
    ++n;

    if (n == MAX_RESULTS)
        exit(0);

    ackIrq();
    while (true)
        ;
}

int main(void) {
    setIrqHandler(irqHandler);
    while (true)
        ;
}
