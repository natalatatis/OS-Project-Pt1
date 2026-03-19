#include "mem.h"
#include "hw.h"
#include "uart.h"

void uart_putc(char c)
{
#ifdef QEMU
    while (GET32(UART_FR) & UART_FR_TXFF);

    if (c == '\n')
        PUT32(UART_DR, '\r');

    PUT32(UART_DR, c);
#else
    while ((GET32(UART_LSR) & UART_LSR_THRE) == 0);
    PUT32(UART_THR, c);
#endif
}

void uart_puts(const char *s)
{
    while (*s)
    {
        if (*s == '\n')
            uart_putc('\r');

        uart_putc(*s++);
    }
}

void uart_init(void)
{
   
}