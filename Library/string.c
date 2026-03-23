#include "string.h"

unsigned int strlen(const char *s) {
    unsigned int len = 0;

    while (s[len] != '\0') {
        len++;
    }

    return len;
}

void *memcpy(void *dest, const void *src, unsigned int n) {
    unsigned char *d = (unsigned char *)dest;
    const unsigned char *s = (const unsigned char *)src;

    while (n--) {
        *d++ = *s++;
    }

    return dest;
}

void *memset(void *dest, int value, unsigned int n) {
    unsigned char *d = (unsigned char *)dest;
    unsigned char v = (unsigned char)value;

    while (n--) {
        *d++ = v;
    }

    return dest;
}

int strcmp(const char *a, const char *b) {
    while (*a && (*a == *b)) {
        a++;
        b++;
    }

    return (unsigned char)*a - (unsigned char)*b;
}