#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>


int main(int argc, char *argv[])  {
    uint64_t count = 0x0000;
    uint64_t bitArray = 0x0000;
    char c = getchar();
    char *needle = argv[1];
    int lenNeedle = strlen(needle);
    while (c != '\n') {
        if (c == needle[0]) {
            bitArray |= 1; // bitArray[0] = 1
        }
        for (size_t i = 1; i < lenNeedle; ++i) {
            bitArray &= ~((c != needle[i]) << i); // bitArray[i] &= (c == needle[i])
        }
        if (bitArray >> (lenNeedle-1) & 1) { // if (bitArray[lenNeedle-1] == 1)
            count++;
        }
        bitArray <<= 1;
        printf("     %u     ", (unsigned int)count);
         for (size_t i = lenNeedle; i != 0; --i){   
            printf("%u", (unsigned int)((bitArray >> (i - 1)) & 1));
        }
        printf("\n");
        c = getchar();
    }
    return(EXIT_SUCCESS);
}
