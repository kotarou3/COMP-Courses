#define temp t0
#define count s0
#define char_index s1
#define char s2
#define bit_array s3
#define len_needle s4

.global _start

.macro  compare_char  from=1, to=63
    lbu temp, \from(zero) // Get next byte of needle
    xor temp, char, temp // Should be zero if char == needle[i]
    sltu temp, zero, temp // Sets first bit of temp to 1 if the previous result was non-zero
    slli temp, temp, \from
    sub temp, zero, temp // One's complement step 1
    addi temp, temp, -1 // One's complement step 2
    and bit_array, bit_array, temp    
    .if \to-\from
		compare_char "(\from+1)",\to
    .endif
.endm
	
.text

_start:
	addi char_index, zero, 64 // Bytes 0-63 of memory are for needle, haystack starts from 64
_count_loop: // Count the length of the needle
	lbu temp, 0(len_needle) // Get first byte of needle
	beq temp, zero, _main_loop // Null terminator character
	addi len_needle, len_needle, 1
	beq zero, zero, _count_loop	
_main_loop:
    lbu char, 0(char_index) // Load next character of haystack
    beq char, zero, _end // Null character signifying end of string
    lbu temp, 0(zero) // Get first byte of needle
    bne char, temp, _next1 // char != first letter of neelde
    ori bit_array, bit_array, 0x0001 // Set first bit in bit_array
_next1:
	compare_char // Compares remaining 63 needle characters
	srl temp, bit_array, len_needle // Set as 1 if bit_array[len_needle-1] == 1
	add count, count, temp
	slli bit_array, bit_array, 1
	addi char_index, char_index, 1
    beq zero, zero, _main_loop // Jump to _main_loop
_end:
	nop
