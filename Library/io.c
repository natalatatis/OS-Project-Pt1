#include "io.h"
#include "os_api.h"

void io_putc(char c) {
    os_api_get()->putc(c);
}

void io_puts(const char *s) {
    os_api_get()->puts(s);
}