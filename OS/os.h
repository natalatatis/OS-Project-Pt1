#ifndef OS_H
#define OS_H

// memory access
void PUT32(unsigned int addr, unsigned int value);
unsigned int GET32(unsigned int addr);

// uart
void uart_putc(char c);
char uart_getc(void);

// timer
void timer_init(void);
void timer_irq_handler(void);

// interrupt controller
void intc_init(void);

// watchdog
void disable_watchdog(void);

// irq enable
void enable_irq(void);

#endif