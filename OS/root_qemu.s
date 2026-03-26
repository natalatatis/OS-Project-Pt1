
    .syntax unified
    .cpu    arm926ej-s
    .code   32

    .globl _start
    .globl PUT32
    .globl GET32
    .globl enable_irq
    .globl first_launch

    .extern main
    .extern timer_irq_handler
    .extern current_proc
    .extern next_proc
    .extern os_uart_puts
    .extern os_uart_putc

    .extern __bss_start__
    .extern __bss_end__
    .extern __os_stack_top
    .extern __irq_stack_top


 // PCB offsets 

    .equ PCB_PID,   0
    .equ PCB_SP,    4
    .equ PCB_PC,    8
    .equ PCB_LR,    12
    .equ PCB_R0,    16
    .equ PCB_CPSR,  68
    .equ PCB_STATE, 72

    .equ STATE_READY,   1
    .equ STATE_RUNNING, 2

// Vector table
    .section .vectors, "ax"

_start:
vector_table:
    b reset_handler         /* 0x00  Reset              */
    b undefined_handler     /* 0x04  Undefined          */
    b swi_handler           /* 0x08  SVC/SWI            */
    b prefetch_handler      /* 0x0C  Prefetch Abort     */
    b data_handler          /* 0x10  Data Abort         */
    b .                     /* 0x14  Reserved           */
    b irq_handler           /* 0x18  IRQ                */
    b fiq_handler           /* 0x1C  FIQ                */

// Reset handler
    .section .text, "ax"

reset_handler:
    mrs r0, cpsr
    orr r0, r0, #0x80
    msr cpsr_c, r0                /* disable IRQ */

    /* Set up IRQ-mode stack */
    mrs r0, cpsr
    bic r0, r0, #0x1F
    orr r0, r0, #0x12       /* IRQ mode */
    msr cpsr_c, r0
    ldr sp, =__irq_stack_top

    /* Set up SVC-mode stack */
    mrs r0, cpsr
    bic r0, r0, #0x1F
    orr r0, r0, #0x13       /* SVC mode*/
    msr cpsr_c, r0
    ldr sp, =__os_stack_top

    /* Clear .bss */
    ldr r0, =__bss_start__
    ldr r1, =__bss_end__
    mov r2, #0
clear_bss:
    cmp  r0, r1
    strlt r2, [r0], #4
    blt  clear_bss


    bl main

hang:
    b hang


first_launch:
    mov r4, r0

    ldr r0, =msg_fl_enter
    bl  os_uart_puts

    mov r1, #STATE_RUNNING
    str r1, [r4, #PCB_STATE]

    ldr r1, [r4, #PCB_CPSR]
    msr spsr_cxsf, r1

    ldr sp, [r4, #PCB_SP]
    ldr lr, [r4, #PCB_LR]

    add r1, r4, #PCB_R0
    ldmia r1, {r0-r12}

    movs pc, lr


irq_handler:
    sub lr, lr, #4
    stmfd sp!, {r0-r12, lr}

    /* Save current process */
    ldr r0, =current_proc
    ldr r0, [r0]
    cmp r0, #0
    beq .Lno_save

    add r2, r0, #PCB_R0
    ldr r1, [sp, #0]  ; str r1, [r2, #0]
    ldr r1, [sp, #4]  ; str r1, [r2, #4]
    ldr r1, [sp, #8]  ; str r1, [r2, #8]
    ldr r1, [sp, #12] ; str r1, [r2, #12]
    ldr r1, [sp, #16] ; str r1, [r2, #16]
    ldr r1, [sp, #20] ; str r1, [r2, #20]
    ldr r1, [sp, #24] ; str r1, [r2, #24]
    ldr r1, [sp, #28] ; str r1, [r2, #28]
    ldr r1, [sp, #32] ; str r1, [r2, #32]
    ldr r1, [sp, #36] ; str r1, [r2, #36]
    ldr r1, [sp, #40] ; str r1, [r2, #40]
    ldr r1, [sp, #44] ; str r1, [r2, #44]
    ldr r1, [sp, #48] ; str r1, [r2, #48]

    ldr r1, [sp, #52]
    str r1, [r0, #PCB_PC]

    mrs r3, cpsr
    bic r2, r3, #0x1F
    orr r2, r2, #0x13
    msr cpsr_c, r2
    str sp, [r0, #PCB_SP]
    str lr, [r0, #PCB_LR]
    msr cpsr_c, r3

    mrs r1, spsr
    str r1, [r0, #PCB_CPSR]

    mov r1, #STATE_READY
    str r1, [r0, #PCB_STATE]

.Lno_save:
    and r4, sp, #4
    sub sp, sp, r4
    push {r4, lr}
    bl timer_irq_handler
    pop {r4, lr}
    add sp, sp, r4

    /* Restore next process */
    ldr r0, =next_proc
    ldr r0, [r0]

    mov r1, #STATE_RUNNING
    str r1, [r0, #PCB_STATE]

    ldr r1, [r0, #PCB_CPSR]
    msr spsr_cxsf, r1

    mrs r3, cpsr
    bic r2, r3, #0x1F
    orr r2, r2, #0x13
    msr cpsr_c, r2
    ldr sp, [r0, #PCB_SP]
    ldr lr, [r0, #PCB_LR]
    msr cpsr_c, r3

    ldr lr, [r0, #PCB_PC]

    add r1, r0, #PCB_R0
    ldmia r1, {r0-r12}

    add sp, sp, #56

    movs pc, lr


undefined_handler:
    push {r0, lr}
    ldr  r0, =msg_undef
    bl   os_uart_puts
    pop  {r0, lr}
    b hang

swi_handler:
prefetch_handler:
data_handler:
fiq_handler:
    b hang

// Memory
PUT32:
    str r1, [r0]
    bx  lr

GET32:
    ldr r0, [r0]
    bx  lr

enable_irq:
    mrs r0, cpsr
    bic r0, r0, #0x80
    msr cpsr_c, r0
    bx  lr


    .section .rodata
msg_fl_enter:
    .asciz "[first_launch] entering\n"
msg_undef:
    .asciz "[UNDEF EXCEPTION]\n"
    