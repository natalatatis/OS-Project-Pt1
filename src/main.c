#include "uart.h"

int main(void)
{
    uart_init();

#ifdef QEMU
    uart_puts("Running on QEMU\n");
#else
    uart_puts("Running on BeagleBone\n");
#endif

    while (1);
}