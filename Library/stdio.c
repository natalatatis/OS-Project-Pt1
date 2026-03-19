#include "stdio.h"

// aqui no incluimos os.h para evitar choques de nombres con READ 
extern void WRITE(const char *s);
extern void uart_gets_input(char *buffer, int max_length);
extern int  uart_atoi(const char *s);
extern void uart_itoa(int num, char *buffer);
extern float uart_atof(const char *s);
extern void  uart_ftoa(float value, char *buffer, int decimals);

static void write_char(char c) {
    char s[2] = {c, '\0'};
    WRITE(s);
}

// PRINT que debe soportar: %s %d %f %%
int PRINT(const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);

    int count = 0;
    char buf[64];

    while (*fmt) {
        if (*fmt != '%') {
            write_char(*fmt++);
            count++;
            continue;
        }

        fmt++; // skip '%'

        if (*fmt == '%') {
            write_char('%');
            fmt++;
            count++;
            continue;
        }

        if (*fmt == 's') {
            const char *s = va_arg(ap, const char *);
            if (!s) s = "(null)";
            WRITE(s);
            while (*s++) count++;
            fmt++;
            continue;
        }

        if (*fmt == 'd') {
            int x = va_arg(ap, int);
            uart_itoa(x, buf);
            WRITE(buf);
            for (int i = 0; buf[i]; i++) count++;
            fmt++;
            continue;
        }

        if (*fmt == 'f') {
            // en varargs, float se promueve a double
            double d = va_arg(ap, double);
            float f = (float)d;

            uart_ftoa(f, buf, 2);   // 2 decimales (para un poco mas de alcance)
            WRITE(buf);
            for (int i = 0; buf[i]; i++) count++;
            fmt++;
            continue;
        }

        // desconocido
        write_char('%'); count++;
        if (*fmt) { write_char(*fmt); count++; fmt++; }
    }

    va_end(ap);
    return count;
}

// READ debe soportar: %s %d %f
// %s: (char* out, int max_len)
// %d: (int* out)
// %f: (float* out)
int READ(const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);

    int assigned = 0;
    char line[64];

    while (*fmt) {
        if (*fmt != '%') { fmt++; continue; }
        fmt++;

        if (*fmt == 's') {
            char *out = va_arg(ap, char *);
            int max_len = va_arg(ap, int);
            uart_gets_input(out, max_len);
            assigned++;
            fmt++;
            continue;
        }

        if (*fmt == 'd') {
            int *out = va_arg(ap, int *);
            uart_gets_input(line, sizeof(line));
            *out = uart_atoi(line);
            assigned++;
            fmt++;
            continue;
        }

        if (*fmt == 'f') {
            float *out = va_arg(ap, float *);
            uart_gets_input(line, sizeof(line));
            *out = uart_atof(line);
            assigned++;
            fmt++;
            continue;
        }

        fmt++;
    }

    va_end(ap);
    return assigned;
}