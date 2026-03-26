/* P2 linker script for QEMU */
ENTRY(p2_main)

SECTIONS
{
    . = 0x00200000;
    .text   : { *(.text*)   }
    .rodata : { *(.rodata*) }
    .data   : { *(.data*)   }
    .bss    : {
        __bss_start__ = .;
        *(.bss*) *(COMMON)
        __bss_end__ = .;
    }
    __p2_stack_top = 0x00212000;
}
