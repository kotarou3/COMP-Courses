#ifdef ALL_ASSEMBLY
    #error Including C source when ALL_ASSEMBLY is set
#endif

#include <avr/io.h>

#include "../keypad.h"
#include "../lcd.h"

static uint8_t accumulator;
static uint8_t input;

// Returns remainder in high byte, quotient in low byte
static uint16_t udivmod8(uint8_t dividend, uint8_t divisor) {
    uint8_t quotient = 0;
    uint8_t remainder = 0;

    // Binary long division: http://en.wikipedia.org/wiki/Division_algorithm#Integer_division_.28unsigned.29_with_remainder
    // Modified to be more optimal for AVR
    for (uint8_t i = 0; i < 8; ++i) {
        remainder <<= 1;
        remainder |= dividend >> 7;
        dividend <<= 1;
        quotient <<= 1;
        if (remainder >= divisor) {
            remainder -= divisor;
            quotient |= 1;
        }
    }

    return (remainder << 8) | quotient;
}

static void updateLcdWithAccumulator(uint8_t accumulator) {
    lcdClear();
    lcdSetCursor(false, 0);

    char buf[3]; // Maximum 3 digits for 8 bits
    char* top = buf;
    while (accumulator >= 10) {
        uint16_t divmod = udivmod8(accumulator, 10);
        accumulator = divmod & 0xff;
        *top = (divmod >> 8) + '0';
        ++top;
    }
    *top = accumulator + '0';

    while (top >= buf) {
        lcdWrite(*top);
        --top;
    }

    lcdSetCursor(true, 0);
}

static void onPress(char key) {
    if ('0' <= key && key <= '9') {
        lcdWrite(key);
        input = key - '0' + input * 10;
    } else if (key == '*') {
        accumulator = 0;
        input = 0;
        updateLcdWithAccumulator(0);
    } else if ('A' <= key && key <= 'D') {
        if (key == 'A')
            accumulator += input;
        else if (key == 'B')
            accumulator -= input;
        else if (key == 'C')
            accumulator *= input;
        else if (key == 'D')
            accumulator = udivmod8(accumulator, input) & 0xff;

        input = 0;
        updateLcdWithAccumulator(accumulator);
    }
}

void setup() {
    keypadSetup();
    lcdSetup();

    onKeypadPress(onPress);
    updateLcdWithAccumulator(0);
}
