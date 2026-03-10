#include "mem.h"
#include "hw.h"
#include "uart.h"

void uart_putc(char c)
{

#ifdef QEMU

    while (GET32(UART_FR) & (1 << 5));   // TXFF

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
    // For simplicity, we assume the UART is already initialized by the bootloader.
    // In a real implementation, you would configure baud rate, data bits, stop bits, etc.
}