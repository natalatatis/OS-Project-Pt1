.section .vectors, "ax"
.syntax unified
.cpu arm926ej-s
.code 32
.globl _start
.globl vector_table

.extern main
.extern __bss_start__
.extern __bss_end__
.extern __os_stack_top

.align 5
vector_table:
    b reset_handler        @ 0x00: Reset
    b undefined_handler    @ 0x04: Undefined Instruction
    b swi_handler          @ 0x08: SWI
    b prefetch_handler     @ 0x0C: Prefetch Abort
    b data_handler         @ 0x10: Data Abort
    b .                    @ 0x14: Reserved
    b irq_handler          @ 0x18: IRQ
    b fiq_handler          @ 0x1C: FIQ

.section .text, "ax"
_start:
reset_handler:
    /* Disable IRQs */
    mrs r0, cpsr        @ Read CPSR
    orr r0, r0, #0x80   @ Set I-bit (disable IRQ)
    msr cpsr_c, r0      @ Write back

    /* Set SVC mode stack */
    mrs r0, cpsr
    bic r0, r0, #0x1F
    orr r0, r0, #0x13   @ SVC mode
    msr cpsr_c, r0
    ldr sp, =__os_stack_top

    /* Clear BSS */
    ldr r0, =__bss_start__
    ldr r1, =__bss_end__
    mov r2, #0

clear_bss:
    cmp r0, r1
    strlt r2, [r0], #4
    blt clear_bss

    /* Jump to main() */
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

irq_handler:
    b hang

fiq_handler:
    b hang

/* Memory access helpers */
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
    bx lr  /* No-op on QEMU for now */