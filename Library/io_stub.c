// #include <stdint.h>
// #include "io.h"

// /* BeagleBone UART0 */
// #define UART0_BASE 0x44E09000u
// #define UART_THR   0x00u
// #define UART_LSR   0x14u
// #define UART_TX_READY 0x20u

// static inline void PUT32(uint32_t addr, uint32_t val) {
//     *(volatile uint32_t *)addr = val;
// }

// static inline uint32_t GET32(uint32_t addr) {
//     return *(volatile uint32_t *)addr;
// }

// void io_putc(char c) {
//     while ((GET32(UART0_BASE + UART_LSR) & UART_TX_READY) != UART_TX_READY);
//     PUT32(UART0_BASE + UART_THR, (uint32_t)c);
// }

// void io_puts(const char *s) {
//     while (*s) {
//         if (*s == '\n') io_putc('\r');
//         io_putc(*s++);
//     }
// }