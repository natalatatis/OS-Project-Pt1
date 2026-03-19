//Prints letters from a to z with a delay in between
#include "stdio.h"

static void delay(volatile unsigned int count){
    while(count--);
}

int main(void){
    char c = 'a';

    while(1){
        PRINT("----From P2: %c\n", c);

        c++;
        if(c > 'z'){
            c = 'a';
        }

        delay(500000);

    }
}