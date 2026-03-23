.section .text
.syntax unified
.code 32
.globl _start
.extern main
.extern timer_irq_handler
.extern __bss_start__
.extern __bss_end__
.extern __os_stack_top

_start:  
// Exception Vector Table
// Must be aligned to 32 bytes (0x20)
.align 5
vector_table:
    b reset_handler      @ 0x00: Reset
    b undefined_handler  @ 0x04: Undefined Instruction
    b swi_handler        @ 0x08: Software Interrupt (SWI)
    b prefetch_handler   @ 0x0C: Prefetch Abort
    b data_handler       @ 0x10: Data Abort
    b .                  @ 0x14: Reserved
    b irq_handler        @ 0x18: IRQ (Interrupt Request)
    b fiq_handler        @ 0x1C: FIQ (Fast Interrupt Request)


// Reset Handler
reset_handler:
    cpsid i                 @ Disable interrupts

    // Setup SVC stack
    mrs r0, cpsr
    bic r0, r0, #0x1F       @ Clear mode bits
    orr r0, r0, #0x13       @ SVC mode
    msr cpsr_c, r0

    ldr sp, =__os_stack_top  @ Load SVC stack pointer

    // Setup IRQ stack
    mrs r0, cpsr
    bic r0, r0, #0x1F       @ Clear mode bits
    orr r0, r0, #0x12       @ IRQ mode
    msr cpsr_c, r0

    ldr sp, =__irq_stack_top @ Load IRQ stack pointer

    // Back to SVC mode for main
    mrs r0, cpsr
    bic r0, r0, #0x1F
    orr r0, r0, #0x13
    msr cpsr_c, r0

    ldr sp, =__os_stack_top

    // Clear BSS
    ldr r0, =__bss_start__
    ldr r1, =__bss_end__
    mov r2, #0

clear_bss:
    cmp r0, r1
    strlt r2, [r0], #4
    blt clear_bss

    dsb
    isb

    // Set vector table
    ldr r0, =vector_table
    mcr p15, 0, r0, c12, c0, 0


    // Jump to C main
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
    sub lr, lr, #4
    stmfd sp!, {r0-r3, lr}  @ Save registers and return address
    bl timer_irq_handler     @ Call the timer IRQ handler
    ldmfd sp!, {r0-r3, lr}  @ Restore context
    subs pc, lr, #04     @ Return from interrupt

fiq_handler:
    b hang

//Memory access helpers
.globl PUT32
PUT32:
    str r1, [r0]
    bx lr

.globl GET32
GET32:
    ldr r0, [r0]
    bx lr

//Enable IRQ
.globl enable_irq
enable_irq:
    mrs r0, cpsr        @ Read CPSR
    bic r0, r0, #0x80   @ Clear I-bit (bit 7)
    msr cpsr_c, r0      @ Write back
    bx lr