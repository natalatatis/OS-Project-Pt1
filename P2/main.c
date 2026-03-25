// PROCESS 2 - prints letters of the alphabet
#include "../Library/stdio.h"

int p2_main(void) {
    char c = 'a';
    int counter = 0;

    while (1) {
        counter++;

        if (counter >= 50000000) {   
            PRINT("----FROM P2: %c\n", c);
            c++;
            if (c > 'z') c = 'a';
            counter = 0;
        }
    }
}