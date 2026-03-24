
    .syntax unified
    .code 32
    .globl _start
    .globl PUT32
    .globl GET32
    .globl enable_irq
    .extern main
    .extern timer_irq_handler   /* void timer_irq_handler  */
    .extern current_proc        /* pcb_t *current_proc  */
    .extern next_proc           /* pcb_t *next_proc */


    .extern __bss_start__
    .extern __bss_end__
    .extern __os_stack_top
    .extern __irq_stack_top


 //PCB field offsets  — must match struct PCB in pcb.h exactly

    .equ PCB_PID,   0
    .equ PCB_SP,    4
    .equ PCB_PC,    8
    .equ PCB_LR,    12
    .equ PCB_R0,    16
    .equ PCB_CPSR,  68
    .equ PCB_STATE, 72

    .equ STATE_READY,   1   /* must match proc_state_t READY   */
    .equ STATE_RUNNING, 2   /* must match proc_state_t RUNNING */


    .section .text
    .align 5        

_start:

vector_table:
    b reset_handler         /* 0x00  Reset                  */
    b undefined_handler     /* 0x04  Undefined Instruction  */
    b swi_handler           /* 0x08  SVC / SWI              */
    b prefetch_handler      /* 0x0C  Prefetch Abort         */
    b data_handler          /* 0x10  Data Abort             */
    b .                     /* 0x14  Reserved               */
    b irq_handler           /* 0x18  IRQ                    */
    b fiq_handler           /* 0x1C  FIQ                    */

// Reset handler
reset_handler:
    cpsid i                 /* disable IRQs while setting up */

    /* Set up IRQ-mode stack */
    mrs r0, cpsr
    bic r0, r0, #0x1F
    orr r0, r0, #0x12       /* IRQ mode */
    msr cpsr_c, r0
    ldr sp, =__irq_stack_top

    /* Back to SVC mode, set up OS stack */
    mrs r0, cpsr
    bic r0, r0, #0x1F
    orr r0, r0, #0x13       /* SVC mode */
    msr cpsr_c, r0
    ldr sp, =__os_stack_top

    /* Clear .bss */
    ldr r0, =__bss_start__
    ldr r1, =__bss_end__
    mov r2, #0
clear_bss:
    cmp r0, r1
    strlt r2, [r0], #4
    blt clear_bss
    dsb
    isb

    /* Install vector table via VBAR */
    ldr r0, =vector_table
    mcr p15, 0, r0, c12, c0, 0
    isb

    bl main

hang:
    b hang

// IRQ handler
irq_handler:
    /* Adjust LR so it points to the instruction that was running. */
    sub lr, lr, #4


    stmfd sp!, {r0-r12, lr}    

    /* ---- Get current_proc pointer */
    ldr r0, =current_proc
    ldr r0, [r0]                /* r0 = current_proc               */
    cmp r0, #0
    beq .Lno_save               /* NULL on very first tick         */

    /* ---- Copy R0-R12 from IRQ stack into pcb->registers[]. ---- */
    ldr r1, [sp, #0]  
    ldr r1, [sp, #4]  
    ldr r1, [sp, #8]  
    ldr r1, [sp, #12] 
    ldr r1, [sp, #16] 
    ldr r1, [sp, #20] 
    ldr r1, [sp, #24]
    ldr r1, [sp, #28] 
    ldr r1, [sp, #32] 
    ldr r1, [sp, #36] 
    ldr r1, [sp, #40] 
    ldr r1, [sp, #44] 
    ldr r1, [sp, #48] 

    /* ---- Save PC (interrupted instruction address). ----------- */
    ldr r1, [sp, #52]          
    str r1, [r0, #PCB_PC]

    /* ---- Save SVC-mode SP and LR by switching modes briefly. -- */
    mrs r3, cpsr                /* save current IRQ-mode CPSR      */
    bic r2, r3, #0x1F
    orr r2, r2, #0x13           /* SVC mode; I-bit stays set  */
    msr cpsr_c, r2              /* enter SVC mode  */

    str sp, [r0, #PCB_SP]       
    str lr, [r0, #PCB_LR]      

    msr cpsr_c, r3              /* back to IRQ mode */

    mrs r1, spsr
    str r1, [r0, #PCB_CPSR]

    mov r1, #STATE_READY
    str r1, [r0, #PCB_STATE]


.Lno_save:
    /* ---- Call C handler */
    and r4, sp, #4
    sub sp, sp, r4
    push {r4, lr}

    bl timer_irq_handler

    pop {r4, lr}
    add sp, sp, r4

    /* Restore next process context. */
    ldr r0, =next_proc
    ldr r0, [r0]                /* r0 = next_proc pointer  */

    /* Process is running */
    mov r1, #STATE_RUNNING
    str r1, [r0, #PCB_STATE]

    ldr r1, [r0, #PCB_CPSR]
    msr spsr_cxsf, r1

    /* Restore SVC SP and LR. */
    mrs r3, cpsr
    bic r2, r3, #0x1F
    orr r2, r2, #0x13           /* SVC mode */
    msr cpsr_c, r2

    ldr sp, [r0, #PCB_SP]      
    ldr lr, [r0, #PCB_LR]       

    msr cpsr_c, r3              /* back to IRQ mode */


    ldr lr, [r0, #PCB_PC]

    add r1, r0, #PCB_R0
    ldmia r1, {r0-r12}

    add sp, sp, #56            

    movs pc, lr


 // Stubs for unused exceptions

undefined_handler:
swi_handler:
prefetch_handler:
data_handler:
fiq_handler:
    b hang



PUT32:
    str r1, [r0]
    bx  lr

GET32:
    ldr r0, [r0]
    bx  lr


 // Enable IRQ  
enable_irq:
    mrs r0, cpsr
    bic r0, r0, #0x80
    msr cpsr_c, r0
    bx  lr
    