 SECTIONS
 {
   . = 0x0;
   .text : { *(.text.start) *(.text) }
   . = 0x1000;
   .bss : { *(.bss) }
   .data : { *(.data) }
   . = 0x2000;
   .results : { *(.results) }
 }
