#ifndef LCD_H
#define LCD_H

#include <stdbool.h>
#include <stdint.h>

void lcdClear();
void lcdClearSection(bool isBottomRow, uint8_t startCol, uint8_t length); // Also moves cursor to the start of the section
void lcdSetCursor(bool isBottomRow, uint8_t col);
void lcdShiftCursor(bool isRight);

void lcdWrite(char c);
void lcdWriteString(const char* str);

void lcdSetup();

#endif
