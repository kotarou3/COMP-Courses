    .section .text.start
    .globl _start
_start:
    li sp, 0x2000
    call main

    .globl exit
exit:
    sd zero, 0(zero)
end:
    j end
    
    .section .results
    .globl results
results:
