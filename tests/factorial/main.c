#include <stdint.h>
#include <stdlib.h>

uint64_t mul(uint64_t a, uint64_t b) {
    uint64_t result = 0;
    while (b != 0) {
        if ((b & 1) != 0)
            result += a;
        a <<= 1;
        b >>= 1;
    }
    return result;
}

uint64_t fact(uint64_t n) {
    if (n == 0 || n == 1)
        return 1;
    return mul(n, fact(n - 1));
}

extern volatile uint64_t results[21];
int main(void) {
    for (size_t n = 0; n <= 20; ++n)
        results[n] = fact(n);
    return 0;
}
