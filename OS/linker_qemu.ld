ENTRY(_start)

SECTIONS
{
    /* =========================
       Vector table
       ========================= */
    . = 0x00000000;
    .vectors : {
        KEEP(*(.vectors))
    }

    /* =========================
       OS API (FIXED ADDRESS)
       ========================= */
    . = 0x00008000;
    .os_api : {
        KEEP(*(.os_api))
    }

    /* =========================
       OS code/data
       ========================= */
    . = 0x00010000;

    .text : {
        *start.o(.text*)
        *os.o(.text*)
    }

    .rodata : {
        *start.o(.rodata*)
        *os.o(.rodata*)
    }

    .data : {
        *start.o(.data*)
        *os.o(.data*)
    }

    .bss : {
        __bss_start__ = .;
        *start.o(.bss*)
        *os.o(.bss*)
        *(COMMON)
        __bss_end__ = .;
    }

    /* =========================
       OS stacks
       ========================= */
    __irq_stack_top__ = 0x0001A000;
    __os_stack_top__  = 0x0001B000;

    /* =========================
       PROCESS 1 (REAL CODE)
       ========================= */
    . = 0x00100000;

    p1_start = .;

    .p1_text : {
        build/p1_combined.o(.text*)
    }

    .p1_rodata : {
        build/p1_combined.o(.rodata*)
    }

    .p1_data : {
        build/p1_combined.o(.data*)
    }

    .p1_bss : {
        build/p1_combined.o(.bss*)
    }

    /* =========================
       PROCESS 2
       ========================= */
    . = 0x00200000;

    p2_start = .;

    .p2_text : {
        build/p2_combined.o(.text*)
    }

    .p2_rodata : {
        build/p2_combined.o(.rodata*)
    }

    .p2_data : {
        build/p2_combined.o(.data*)
    }

    .p2_bss : {
        build/p2_combined.o(.bss*)
    }
}