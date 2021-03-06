#ifdef ALL_ASSEMBLY
    #error Including C source when ALL_ASSEMBLY is set
#endif

#include <stdint.h>
#include <avr/io.h>
#include <avr/pgmspace.h>

#include "events.h"
#include "keypad.h"

#define KEYPAD(reg) reg##L
#define KEYPAD_ROW0 PL0
#define KEYPAD_ROW1 PL1
#define KEYPAD_ROW2 PL2
#define KEYPAD_ROW3 PL3
#define KEYPAD_COL0 PL4
#define KEYPAD_COL1 PL5
#define KEYPAD_COL2 PL6
#define KEYPAD_COL3 PL7
#define KEYPAD_ROWS ((1 << KEYPAD_ROW0) | (1 << KEYPAD_ROW1) | (1 << KEYPAD_ROW2) | (1 << KEYPAD_ROW3))
#define KEYPAD_COLS (~KEYPAD_ROWS)

#define KEYPAD_INT(reg, ...) reg##0##__VA_ARGS__
#define KEYPAD_INT_PINS(reg) reg##B

static const char keymap[4][4] PROGMEM = {
    {'1', '2', '3', 'A'},
    {'4', '5', '6', 'B'},
    {'7', '8', '9', 'C'},
    {'*', '0', '#', 'D'}
};

static void (*onKeypadPressCallback)(char);

static void onPress() {
    // Don't trigger any interrupts while strobing the keypad
    KEYPAD_INT(PCMSK) = 0;

    // Pull low each row one by one to find which buttons are pressed
    uint8_t row = 0;
    KEYPAD(PORT) = (~(1 << KEYPAD_ROW0) & KEYPAD_ROWS) | KEYPAD_COLS;
    __builtin_avr_delay_cycles(2);
    uint8_t input = ~KEYPAD(PIN) & KEYPAD_COLS;

    if (!input) {
        row = 1;
        KEYPAD(PORT) = (~(1 << KEYPAD_ROW1) & KEYPAD_ROWS) | KEYPAD_COLS;
        __builtin_avr_delay_cycles(2);
        input = ~KEYPAD(PIN) & KEYPAD_COLS;
    }

    if (!input) {
        row = 2;
        KEYPAD(PORT) = (~(1 << KEYPAD_ROW2) & KEYPAD_ROWS) | KEYPAD_COLS;
        __builtin_avr_delay_cycles(2);
        input = ~KEYPAD(PIN) & KEYPAD_COLS;
    }

    if (!input) {
        row = 3;
        KEYPAD(PORT) = (~(1 << KEYPAD_ROW3) & KEYPAD_ROWS) | KEYPAD_COLS;
        __builtin_avr_delay_cycles(2);
        input = ~KEYPAD(PIN) & KEYPAD_COLS;
    }

    // Restore the keypad's state
    KEYPAD(PORT) = KEYPAD_COLS;
    KEYPAD_INT(PCMSK) = 0xff;

    // Decode the column
    uint8_t col = 0;
    if (input & (1 << KEYPAD_COL0))
        col = 0;
    else if (input & (1 << KEYPAD_COL1))
        col = 1;
    else if (input & (1 << KEYPAD_COL2))
        col = 2;
    else if (input & (1 << KEYPAD_COL3))
        col = 3;

    // Call the callback
    onKeypadPressCallback(pgm_read_byte(&keymap[row][col]));
}

void onKeypadPress(void (*callback)(char)) {
    onKeypadPressCallback = callback;
    onDebouncedInterrupt(KEYPAD_INT(PCINT, _vect_num), (void (*)(uint8_t))onPress);
}

void keypadSetup() {
    KEYPAD(DDR) = KEYPAD_ROWS;
    KEYPAD(PORT) = KEYPAD_COLS; // Rows pulled low; Columns pulled high

    KEYPAD_INT_PINS(DDR) = 0;
    KEYPAD_INT_PINS(PORT) = 0xff;
    KEYPAD_INT(PCMSK) = 0xff;
    PCICR = 1 << KEYPAD_INT(PCIE);
}
