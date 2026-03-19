#include "stdio.h"
#include "uart.h"

// Function to send a string via UART 
void PRINT(const char *s) {
    while (*s) {
        uart_putc(*s++);
    }
}