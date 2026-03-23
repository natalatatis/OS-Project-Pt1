#include <stdarg.h>
#include "stdio.h"
#include "io.h"

static void reverse(char *str, int len) {
    int i = 0;
    int j = len - 1;

    while (i < j) {
        char tmp = str[i];
        str[i] = str[j];
        str[j] = tmp;
        i++;
        j--;
    }
}

static int utoa_dec(unsigned int value, char *buf) {
    int i = 0;

    if (value == 0u) {
        buf[i++] = '0';
        buf[i] = '\0';
        return i;
    }

    while (value > 0u) {
        buf[i++] = (char)('0' + (value % 10u));
        value /= 10u;
    }

    buf[i] = '\0';
    reverse(buf, i);
    return i;
}

static int itoa_dec(int value, char *buf) {
    int i = 0;
    unsigned int u;

    if (value == 0) {
        buf[i++] = '0';
        buf[i] = '\0';
        return i;
    }

    if (value < 0) {
        buf[i++] = '-';
        u = (unsigned int)(-value);
    } else {
        u = (unsigned int)value;
    }

    {
        char temp[16];
        int j = 0;

        while (u > 0u) {
            temp[j++] = (char)('0' + (u % 10u));
            u /= 10u;
        }

        while (j > 0) {
            buf[i++] = temp[--j];
        }
    }

    buf[i] = '\0';
    return i;
}

static int utoa_hex(unsigned int value, char *buf) {
    static const char hex[] = "0123456789ABCDEF";
    int i = 0;

    if (value == 0u) {
        buf[i++] = '0';
        buf[i] = '\0';
        return i;
    }

    while (value > 0u) {
        buf[i++] = hex[value & 0xFu];
        value >>= 4;
    }

    buf[i] = '\0';
    reverse(buf, i);
    return i;
}

void putc_lib(char c) {
    io_putc(c);
}

void puts_lib(const char *s) {
    io_puts(s);
}

void print_dec(unsigned int value) {
    char buf[16];
    utoa_dec(value, buf);
    io_puts(buf);
}

void print_hex(unsigned int value) {
    char buf[16];
    io_puts("0x");
    utoa_hex(value, buf);
    io_puts(buf);
}

void PRINT(const char *fmt, ...) {
    va_list args;
    va_start(args, fmt);

    while (*fmt) {
        if (*fmt != '%') {
            io_putc(*fmt++);
            continue;
        }

        fmt++;

        switch (*fmt) {
            case 'c': {
                char c = (char)va_arg(args, int);
                io_putc(c);
                break;
            }

            case 's': {
                const char *s = va_arg(args, const char *);
                if (s) {
                    io_puts(s);
                } else {
                    io_puts("(null)");
                }
                break;
            }

            case 'd': {
                char buf[16];
                int value = va_arg(args, int);
                itoa_dec(value, buf);
                io_puts(buf);
                break;
            }

            case 'u': {
                char buf[16];
                unsigned int value = va_arg(args, unsigned int);
                utoa_dec(value, buf);
                io_puts(buf);
                break;
            }

            case 'x': {
                char buf[16];
                unsigned int value = va_arg(args, unsigned int);
                utoa_hex(value, buf);
                io_puts(buf);
                break;
            }

            case '%': {
                io_putc('%');
                break;
            }

            default: {
                io_putc('%');
                io_putc(*fmt);
                break;
            }
        }

        fmt++;
    }

    va_end(args);
}