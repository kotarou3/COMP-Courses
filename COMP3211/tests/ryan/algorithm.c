#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

#define MAX_LEN_NEEDLE 64

int main(int argc, char *argv[])  {
    int count = 0;
    char c = getchar();
    char *needle = argv[1];
    int lenNeedle = strlen(needle);
    bool bitArray[MAX_LEN_NEEDLE] = {0};
    while (c != '\n') {
        if (c == needle[0]) {
            bitArray[0] = 1;
        }
        int i;
        for (i = 1; i < MAX_LEN_NEEDLE; i++) {
            bitArray[i] &= (c == needle[i]);
        }
        if (bitArray[lenNeedle-1] == 1) {
            count++;
        }
        for (i = lenNeedle; i > 0; i--){   
            bitArray[i] = bitArray[i-1];
        }
        bitArray[0] = 0;
        printf("     %u    ", count);
        for (i = 0; i < lenNeedle; i++){   
            printf("%u", bitArray[i]);
        }
        printf("\n");
        c = getchar();
    }
    return(EXIT_SUCCESS);
}
