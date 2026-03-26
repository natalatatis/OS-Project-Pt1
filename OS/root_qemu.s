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
.extern __os_stack_top__
.extern __irq_stack_top__

.equ PCB_PID,   0
.equ PCB_SP,    4
.equ PCB_PC,    8
.equ PCB_LR,    12
.equ PCB_R0,    16
.equ PCB_CPSR,  68
.equ PCB_STATE, 72

.equ STATE_READY,   1
.equ STATE_RUNNING, 2

// ============================================================
// Vector Table
// ============================================================
.section .vectors, "ax"
_start:
vector_table:
    b reset_handler         /* 0x00 Reset */
    b undefined_handler     /* 0x04 Undefined */
    b swi_handler           /* 0x08 SWI */
    b prefetch_handler      /* 0x0C Prefetch Abort */
    b data_handler          /* 0x10 Data Abort */
    b .                     /* 0x14 Reserved */
    b irq_handler           /* 0x18 IRQ */
    b fiq_handler           /* 0x1C FIQ */

// ============================================================
// Reset Handler
// ============================================================
.section .text, "ax"
reset_handler:
    /* Disable IRQ */
    mrs r0, cpsr
    orr r0, r0, #0x80
    msr cpsr_c, r0

    /* IRQ stack */
    mrs r0, cpsr
    bic r0, r0, #0x1F
    orr r0, r0, #0x12       /* IRQ mode */
    msr cpsr_c, r0
    ldr sp, =__irq_stack_top__

    /* SVC stack */
    mrs r0, cpsr
    bic r0, r0, #0x1F
    orr r0, r0, #0x13       /* SVC mode */
    msr cpsr_c, r0
    ldr sp, =__os_stack_top__

    /* Clear .bss */
    ldr r0, =__bss_start__
    ldr r1, =__bss_end__
    mov r2, #0
clear_bss:
    cmp  r0, r1
    strlt r2, [r0], #4
    blt  clear_bss

    /* Start C main */
    bl main

hang:
hang_loop:
    nop
    b hang_loop

// ============================================================
// Launch first process
// ============================================================
first_launch:
    ldr r0, =msg_fl_enter
    bl  os_uart_puts

    /* r1 = current_proc */
    ldr r1, =current_proc
    ldr r1, [r1]

    /* state = RUNNING */
    mov r2, #STATE_RUNNING
    str r2, [r1, #PCB_STATE]

    /* Restore CPSR into SPSR */
    ldr r2, [r1, #PCB_CPSR]
    msr spsr_cxsf, r2

    /* Restore registers r0–r12 */
    add r2, r1, #PCB_R0
    ldmia r2, {r0-r12}

    /* Restore SP and LR */
    ldr sp, [r1, #PCB_SP]
    ldr lr, [r1, #PCB_PC]   /* LR = entry point */

    
    movs pc, lr             /* switch mode + jump */
// ============================================================
// IRQ Handler
// ============================================================
irq_handler:
    sub lr, lr, #4
    stmfd sp!, {r0-r12, lr}        /* Save CPU registers */

    /* Save current process state */
    ldr r0, =current_proc
    ldr r0, [r0]
    cmp r0, #0
    beq .Lno_save

    add r2, r0, #PCB_R0
    stmia sp!, {r0-r12}             /* Save GPRs on stack */
    ldmia sp!, {r0-r12}             /* Restore GPRs to PCB (simplified) */

    /* Save SP, LR, CPSR */
    mrs r3, cpsr
    bic r2, r3, #0x1F
    orr r2, r2, #0x13
    msr cpsr_c, r2
    str sp, [r0, #PCB_SP]
    str lr, [r0, #PCB_LR]
    msr cpsr_c, r3
    mrs r1, spsr
    str r1, [r0, #PCB_CPSR]
    mov r2, #STATE_READY
    str r2, [r0, #PCB_STATE]

.Lno_save:
    /* Call C timer handler */
    push {lr}
    bl timer_irq_handler
    pop {lr}

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
    movs pc, lr

// ============================================================
// Exception Stubs
// ============================================================
undefined_handler:
    push {r0, lr}
    ldr r0, =msg_undef
    bl  os_uart_puts
    pop {r0, lr}
    b hang_loop

swi_handler:
prefetch_handler:
data_handler:
fiq_handler:
    b hang_loop

// ============================================================
// Memory helpers
// ============================================================
PUT32:
    str r1, [r0]
    bx lr

GET32:
    ldr r0, [r0]
    bx lr

enable_irq:
    mrs r0, cpsr
    bic r0, r0, #0x80
    msr cpsr_c, r0
    bx lr

// ============================================================
// Read-only data
// ============================================================
.section .rodata
msg_fl_enter:
    .asciz "[first_launch] entering\n"

msg_undef:
    .asciz "[UNDEF EXCEPTION]\n"