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

// UART
#define UART0_BASE     0x44E09000
#define UART_THR       (UART0_BASE + 0x00)  // Transmit Holding Register
#define UART_LSR       (UART0_BASE + 0x14)  // Line Status Register
#define UART_LSR_THRE  0x20                  // Transmit Holding Register Empty
#define UART_LSR_RXFE  0x10                  // Receive FIFO Empty

// TIMER (DMTimer2)
#define DMTIMER2_BASE 0x48040000

#define TCLR (DMTIMER2_BASE + 0x38)
#define TCRR (DMTIMER2_BASE + 0x3C)
#define TISR (DMTIMER2_BASE + 0x28)
#define TIER (DMTIMER2_BASE + 0x2C)
#define TLDR (DMTIMER2_BASE + 0x40)


// INTC (Interrupt Controller)
#define INTCPS_BASE 0x48200000

#define INTC_MIR_CLEAR2 (INTCPS_BASE + 0xC8)
#define INTC_CONTROL    (INTCPS_BASE + 0x48)
#define INTC_ILR68      (INTCPS_BASE + 0x110)

// CLOCK (Timer2)
#define CM_PER_BASE 0x44E00000
#define CM_PER_TIMER2_CLKCTRL (CM_PER_BASE + 0x80)


#endif

#endif