.syntax unified
.cpu cortex-a8
.code 32

.section .text
.global _start
.extern main

_start:
    ldr sp, =0x82100000   @ DDR RAM on BeagleBone

    bl main

hang:
    b hang