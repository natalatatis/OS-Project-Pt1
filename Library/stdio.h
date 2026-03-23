#ifndef STDIO_H
#define STDIO_H

void putc_lib(char c);
void puts_lib(const char *s);
void print_dec(unsigned int value);
void print_hex(unsigned int value);
void PRINT(const char *fmt, ...);

#endif