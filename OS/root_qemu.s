.syntax unified
.cpu arm926ej-s
.code 32

.section .text
.global _start
.extern main
.extern timer_irq_handler

_start:
 // Vector table (exception handlers)
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


  // RESET

reset_handler:

    /* Set stack */
    ldr sp, =0x80000

    /* Set vector base address (VBAR) */
    ldr r0, =vector_table
    mcr p15, 0, r0, c12, c0, 0

    /* Jump to C */
    bl main

hang:
    b hang

      
  // UNUSED EXCEPTIONS

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


   // IRQ HANDLER
irq_handler:
    push {r0-r12, lr}     /* Save context */

    bl timer_irq_handler  /* Call C handler */

    pop {r0-r12, lr}      /* Restore */

    subs pc, lr, #4       /* Return from IRQ */

.global enable_irq
enable_irq:
    mrs r0, cpsr        @ Read CPSR
    bic r0, r0, #0x80   @ Clear I-bit (enable IRQ)
    msr cpsr_c, r0      @ Write back
    bx lr

  // MEMORY ACCESS HELPERS
 
.global PUT32
PUT32:
    str r1, [r0]
    bx lr

.global GET32
GET32:
    ldr r0, [r0]
    bx lr