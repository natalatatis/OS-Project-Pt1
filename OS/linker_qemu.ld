ENTRY(_start)

SECTIONS
{
    /*  Vector table  */
    . = 0x00000000;
    .vectors : {
        KEEP(*(.vectors))
    }

    /* ---- OS code/data ---- */
    . = 0x00010000;
    .text : {
        *(.text*)
    }

    .rodata : {
        *(.rodata*)
    }

    . = 0x00018000;
    .os_api : {
        KEEP(*(.os_api))
    }

    .data : {
        *(.data*)
    }

    .bss : {
        __bss_start__ = .;
        *(.bss*)
        *(COMMON)
        __bss_end__ = .;
    }

    /* OS stacks */
    __irq_stack_top = 0x0001A000;
    __os_stack_top  = 0x0001B000;

    /* P1 binary embedded at 0x00100000 */
    . = 0x00100000;
    .p1_image : {
        KEEP(*(.p1_image))
    }

    /* P2 binary embedded at 0x00200000  */
    . = 0x00200000;
    .p2_image : {
        KEEP(*(.p2_image))
    }
}
