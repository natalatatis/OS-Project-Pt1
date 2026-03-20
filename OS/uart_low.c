#include "os.h"
#include "hw.h"


// UART PUT CHAR
void uart_putc(char c) {

#ifdef QEMU
    // Wait until TX not full
    while (GET32(UART_FR) & UART_FR_TXFF);
    PUT32(UART_DR, c);

#else
    // BeagleBone
    while ((GET32(UART_LSR) & UART_LSR_THRE) == 0);
    PUT32(UART_THR, c);

#endif
}


// UART GET CHAR
char uart_getc(void) {

#ifdef QEMU
    while (GET32(UART_FR) & UART_FR_RXFE);
    return (char)(GET32(UART_DR) & 0xFF);

#else
    while ((GET32(UART_LSR) & UART_LSR_RXFE) != 0);
    return (char)(GET32(UART_THR) & 0xFF);

#endif
}