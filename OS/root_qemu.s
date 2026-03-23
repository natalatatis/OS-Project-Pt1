.section .vectors, "ax"
.syntax unified
.cpu arm926ej-s
.code 32
.globl _start
.globl vector_table

.extern main
.extern timer_irq_handler
.extern __bss_start__
.extern __bss_end__
.extern __os_stack_top
.extern __irq_stack_top

.align 5
vector_table:
    b reset_handler
    b undefined_handler
    b swi_handler
    b prefetch_handler
    b data_handler
    b .
    b irq_handler
    b fiq_handler

.section .text, "ax"
_start:
reset_handler:
    @ Disable IRQs (ARMv5-compatible way)
    mrs r0, cpsr
    orr r0, r0, #0x80
    msr cpsr_c, r0

    @ Enter SVC mode
    mrs r0, cpsr
    bic r0, r0, #0x1F
    orr r0, r0, #0x13
    msr cpsr_c, r0
    ldr sp, =__os_stack_top

    @ Set IRQ mode stack
    mrs r0, cpsr
    bic r0, r0, #0x1F
    orr r0, r0, #0x12
    msr cpsr_c, r0
    ldr sp, =__irq_stack_top

    @ Back to SVC mode
    mrs r0, cpsr
    bic r0, r0, #0x1F
    orr r0, r0, #0x13
    msr cpsr_c, r0
    ldr sp, =__os_stack_top

    @ Clear BSS
    ldr r0, =__bss_start__
    ldr r1, =__bss_end__
    mov r2, #0

clear_bss:
    cmp r0, r1
    strlt r2, [r0], #4
    blt clear_bss

    @ Memory barriers are not needed here on ARM926
    @ and can be omitted for compatibility

    @ Jump to C
    bl main

hang:
    b hang

undefined_handler:
    b hang

swi_handler:
    b hang

prefetch_handler:
    b hang

data_handler:
    b hang

fiq_handler:
    b hang

irq_handler:
    sub lr, lr, #4
    stmdb sp!, {r0-r12, lr}
    bl timer_irq_handler
    ldmia sp!, {r0-r12, lr}
    subs pc, lr, #0

.globl PUT32
PUT32:
    str r1, [r0]
    bx lr

.globl GET32
GET32:
    ldr r0, [r0]
    bx lr

.globl enable_irq
enable_irq:
    mrs r0, cpsr
    bic r0, r0, #0x80
    msr cpsr_c, r0
    bx lr