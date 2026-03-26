/* P1 linker script for QEMU */
ENTRY(p1_main)

SECTIONS
{
    . = 0x00100000;
    .text   : { *(.text*)   }
    .rodata : { *(.rodata*) }
    .data   : { *(.data*)   }
    .bss    : {
        __bss_start__ = .;
        *(.bss*) *(COMMON)
        __bss_end__ = .;
    }
    __p1_stack_top = 0x00112000;
}
