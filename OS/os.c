#include "os.h"
#include "mem.h"
#include "stdio.h"   // ONLY for debugging 
#include "hw.h"


// Watchdog (Beagle only)

#define WDT1_BASE 0x44E35000
#define WDT_WSPR  (WDT1_BASE + 0x48)
#define WDT_WWPS  (WDT1_BASE + 0x34)

static void wdt_wait(void) {
    while (GET32(WDT_WWPS) != 0);
}

void watchdog_disable(void) {
#ifndef QEMU
    PUT32(WDT_WSPR, 0xAAAA);
    wdt_wait();
    PUT32(WDT_WSPR, 0x5555);
    wdt_wait();
#endif
}


// Interrupt Controller Init

void intc_init(void) {

#ifdef QEMU
    // Enable Timer0 interrupt in VIC
    PUT32(VIC_IRQENABLE, (1 << TIMER0_IRQ));

#else
    // BeagleBone INTC
    PUT32(INTC_MIR_CLEAR2, (1 << (68 - 64)));
    PUT32(INTC_ILR68, 0x0);
#endif
}


// Timer Init
void timer_init(void) {

#ifdef QEMU

    // Load value (smaller = faster ticks)
    PUT32(TIMER_LOAD, 0x100000);

    // Enable timer:
    // bit7 = enable
    // bit6 = periodic
    // bit5 = interrupt enable
    PUT32(TIMER_CTRL, (1 << 7) | (1 << 6) | (1 << 5));

#else

    // Enable timer2 clock
    PUT32(CM_PER_TIMER2_CLKCTRL, 0x2);

    // Configure interrupt controller
    intc_init();

    // Stop timer
    PUT32(TCLR, 0x0);

    // Clear pending interrupts
    PUT32(TISR, 0x7);

    // Load ~1 second value
    PUT32(TLDR, 0xFE91CA00);
    PUT32(TCRR, 0xFE91CA00);

    // Enable overflow interrupt
    PUT32(TIER, 0x2);

    // Start timer (auto-reload)
    PUT32(TCLR, 0x3);

#endif

    PRINT("Timer initialized\n");
}


// IRQ Handler (called from assembly)
void timer_irq_handler(void) {

#ifdef QEMU
    // Clear interrupt
    PUT32(TIMER_INTCLR, 1);

#else
    // Clear timer interrupt
    PUT32(TISR, 0x2);

    // Acknowledge interrupt controller
    PUT32(INTC_CONTROL, 0x1);
#endif

    // Clear overflow interrupt
    PUT32(TISR, 0x2);

    //  Write again to ensure it's cleared
    while (GET32(TISR) & 0x2);

    // Acknowledge interrupt controller
    PUT32(INTC_CONTROL, 0x1);

    // Debug output
    PRINT("Tick\n");
}

// MAIN (OS ENTRY POINT)

extern void enable_irq(void);


int main(void) {

    // Disable watchdog (only matters on Beagle)
    watchdog_disable();

    PRINT("OS starting...\n");

    // Initialize hardware
    intc_init();
    timer_init();

    PRINT("Enabling IRQ...\n");
    enable_irq();

    // OS main loop
    while (1) {
        // Idle — everything happens via interrupts
    }

    return 0;
}

