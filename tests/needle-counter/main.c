#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

#include "../irq.h"

uint64_t needle[64];
size_t needleSize;

uint64_t rollingHaystack[64];

extern uint64_t results;

bool checkMatch(void) {
    for (size_t n = 0; n < needleSize; ++n)
        if (rollingHaystack[n] != needle[n])
            return false;
    return true;
}

void readHaystack(uint64_t data) {
    static size_t haystackSize;

    if (data > 0xff)
        exit(0);

    if (haystackSize < needleSize) {
        rollingHaystack[haystackSize] = data;
        ++haystackSize;
    } else {
        for (size_t n = 1; n < haystackSize; ++n)
            rollingHaystack[n - 1] = rollingHaystack[n];
        rollingHaystack[haystackSize - 1] = data;
    }

    if (checkMatch())
        ++results;

    ackIrq();
    while (true)
        ;
}

void readNeedle(uint64_t data) {
    if (data < 0x100) {
        needle[needleSize] = data;
        ++needleSize;
    } else {
        setIrqHandler(readHaystack);
    }

    ackIrq();
    while (true)
        ;
}

int main(void) {
    setIrqHandler(readNeedle);
    while (true)
        ;
}
