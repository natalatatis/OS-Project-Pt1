ENTRY(_start)

SECTIONS
{
    . = 0x10000;

    .text :
    {
        KEEP(*(.text))
        *(.text*)
        *(.rodata*)
    }

    .data : { *(.data*) }

    .bss :
    {
        *(.bss*)
        *(COMMON)
    }
}