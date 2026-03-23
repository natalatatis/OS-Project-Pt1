#ifndef OS_H
#define OS_H

#include <stdint.h>

void os_uart_putc(char c);
void os_uart_puts(const char *s);

void timer_irq_handler(void);
int main(void);

#endif