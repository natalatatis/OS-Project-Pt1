.syntax unified
.cpu arm926ej-s
.code 32

.section .text
.global _start
.extern main

_start:

    /* setup stack */
    ldr sp, =0x80000

    bl main

hang:
    b hang