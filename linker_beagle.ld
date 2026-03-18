ENTRY(_start)

SECTIONS
{
    . = 0x82000000;

    /* Vector table */
    .vectors : {
        *(.vectors)
    }

    .text : {
        *(.text*)
    }

    .rodata : {
        *(.rodata*)
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

    /* Define stack  */
    . = ALIGN(8);
    __os_stack_top = . + 0x2000;  /* 8 KB stack */
}