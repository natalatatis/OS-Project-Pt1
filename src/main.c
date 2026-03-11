#include "uart.h"

int main(void)
{
    uart_init();

#ifdef QEMU
    const char *msg = "Running on QEMU\n";
#else
    const char *msg = "Running on BeagleBone\n";
#endif

    while (1)
    {
        uart_puts(msg);

        /* small delay so the output is readable */
        for (volatile int i = 0; i < 1000000; i++);
    }
}