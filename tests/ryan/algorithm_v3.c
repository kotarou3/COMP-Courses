#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

#include "../irq.h"

uint64_t needle[64];
size_t needleSize;

uint64_t bitArray;

extern uint64_t results;

void readHaystack(uint64_t data) {

    if (data > 0xff)
        exit(0);

    if (data == needle[0]) {
        bitArray |= 1; // bitArray[0] = 1
    }

    for (size_t i = 1; i < needleSize; ++i) {
        bitArray &= ~((data != needle[i]) << i); // bitArray[i] &= (c == needle[i])
    }

    if (bitArray >> (needleSize - 1) & 1) { // if (bitArray[needleSize - 1] == 1)
        ++results;
    }

    bitArray <<= 1;

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
