ENTRY(_start)

SECTIONS
{
    . = 0x82000000;

    .vectors : { *(.vectors) }

    .text : { *(.text*) }

    .rodata : { *(.rodata*) }

    .data : { *(.data*) }

    .bss : {
        __bss_start__ = .;
        *(.bss*)
        *(COMMON)
        __bss_end__ = .;
    }

    
    . = 0x82010000;

    __os_stack_top = 0x82012000;  /* 8KB stack */
}