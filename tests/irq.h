#ifndef IRQ_H
#define IRQ_H

/*
    IO memory layout as follows:
        0000: Write here to exit simulation
        0008: IRQ Handler address
        0010: Write non-zero here to ack the IRQ
*/

static inline void setIrqHandler(void (*handler)(uint64_t)) {
    *(void (**)(uint64_t))0x0008 = handler;
}

static inline void ackIrq(void) {
    *(volatile uint64_t*)0x0010 = 1;
}

#endif
