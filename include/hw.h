#ifndef HW_H
#define HW_H

#ifdef QEMU

//--------------------------------
// QEMU VersatilePB
//--------------------------------

#define UART0_BASE 0x101F1000

#define UART_DR (UART0_BASE + 0x00)
#define UART_FR (UART0_BASE + 0x18)

#define UART_FR_TXFF (1 << 5)
#define UART_FR_RXFE (1 << 4)

#else

//--------------------------------
// BeagleBone Black
//--------------------------------

#define UART0_BASE 0x44E09000

#define UART_THR (UART0_BASE + 0x00)
#define UART_LSR (UART0_BASE + 0x14)

#define UART_LSR_THRE (1 << 5)

#endif

#endif