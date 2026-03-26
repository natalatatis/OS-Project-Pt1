// Hardware adresses for QEMU VersatilePB and BEAGLEBONE BLACK
/*
#ifndef HW_H
#define HW_H

#ifdef QEMU


// QEMU VersatilePB

// UART
#define UART0_BASE 0x101F1000

#define UART_DR (UART0_BASE + 0x00)
#define UART_FR (UART0_BASE + 0x18)

#define UART_FR_TXFF (1 << 5)
#define UART_FR_RXFE (1 << 4)



// TIMER (SP804)

#define TIMER0_BASE 0x101E2000

#define TIMER_LOAD   (TIMER0_BASE + 0x00)
#define TIMER_VALUE  (TIMER0_BASE + 0x04)
#define TIMER_CTRL   (TIMER0_BASE + 0x08)
#define TIMER_INTCLR (TIMER0_BASE + 0x0C)
#define TIMER_RIS    (TIMER0_BASE + 0x10)
#define TIMER_MIS    (TIMER0_BASE + 0x14)
#define TIMER_BGLOAD (TIMER0_BASE + 0x18)



// VIC (Interrupt Controller)

#define VIC_BASE        0x10140000

#define VIC_IRQENABLE   (VIC_BASE + 0x10)
#define VIC_INTENCLEAR  (VIC_BASE + 0x14)
#define VIC_VECTADDR    (VIC_BASE + 0x30)

// Vectored interrupt slot 0 (NEW)
#define VIC_VECTADDR0   (VIC_BASE + 0x100)
#define VIC_VECTCNTL0   (VIC_BASE + 0x200)

// Timer IRQ number (Timer0 = IRQ 4 in VersatilePB)
#define TIMER0_IRQ 4

#else

//----------------------------------------------------------

//--------------------------------
// BeagleBone Black
//--------------------------------

// UART
#define UART0_BASE     0x44E09000
#define UART_THR       (UART0_BASE + 0x00)  
#define UART_LSR       (UART0_BASE + 0x14)  
#define UART_LSR_THRE  0x20                  
#define UART_LSR_RXFE  0x10                  

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

*/