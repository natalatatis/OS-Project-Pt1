//Prints numbers from 0 to 9 with a delay in between
#include "../Library/io.h"


int p1_main(void){
    while(1){
        io_putc('1');
    }
}

/*
extern unsigned int __bss_start__;
extern unsigned int __bss_end__;

static void clear_bss(void) {
    unsigned int *p = &__bss_start__;
    while (p < &__bss_end__) {
        *p++ = 0;
    }
}

static void delay(volatile unsigned int count){
    while(count--);
}
int p1_main(void){
    clear_bss();   

    PRINT(">>> ENTERED P1 HEHE <<< \n");

    while(1){
        PRINT("P1 alive\n");
        for (volatile int i = 0; i < 1000000; i++);
    }
}
*/
