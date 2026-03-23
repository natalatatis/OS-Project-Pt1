#include "io.h"

/*
 * Estas funciones viven en OS/os.c
 * y son las que sí tocan el UART real.
 */
extern void os_uart_putc(char c);
extern void os_uart_puts(const char *s);

void io_putc(char c) {
    os_uart_putc(c);
}

void io_puts(const char *s) {
    os_uart_puts(s);
}