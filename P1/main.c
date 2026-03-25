#include "../Library/stdio.h"

int p1_main(void) {
    int n = 0;
    int counter = 0;

    while (1) {
        counter++;

        if (counter >= 50000000) {  
            PRINT("----FROM P1: %d\n", n);
            n = (n + 1) % 10;
            counter = 0;
        }
    }
}