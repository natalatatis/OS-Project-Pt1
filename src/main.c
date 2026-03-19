#include "stdio.h"

int main(void)
{
#ifdef QEMU
    const char *msg = "Running on QEMU\n";
#else
    const char *msg = "Running on BeagleBone\n";
#endif

    while (1)
    {
        PRINT(msg);

        // small delay so output is readable
        for (volatile int i = 0; i < 1000000; i++);
    }
}

// Temporary (until real interrupt logic)
void timer_irq_handler() {
    // nothing for now
}