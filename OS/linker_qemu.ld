ENTRY(_start)

SECTIONS
{
    . = 0x00000000;

    .vectors : {
        KEEP(*(.vectors))
    }

    . = 0x00010000;

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

    . = ALIGN(8);

    . = . + 0x2000;
    __os_stack_top = .;

    . = . + 0x2000;
    __irq_stack_top = .;
}