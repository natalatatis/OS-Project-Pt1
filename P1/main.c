//Prints numbers from 0 to 9 with a delay in between
#include "../Library/stdio.h"

static void delay(volatile unsigned int count){
    while(count--);
}

int main(void){
    int n = 0;

    while(1){
        PRINT("----From P1: %d\n", n);

        n++;
        if(n > 9){
            n = 0;
        }

        delay(500000);

    }
}