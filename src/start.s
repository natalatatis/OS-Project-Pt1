.section .text
.global _start
.extern main

_start:

    ldr sp, =0x800000   @ set stack pointer somewhere safe

    bl main

hang:
    b hang