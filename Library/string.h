#ifndef STRING_H
#define STRING_H

unsigned int strlen(const char *s);
void *memcpy(void *dest, const void *src, unsigned int n);
void *memset(void *dest, int value, unsigned int n);
int strcmp(const char *a, const char *b);

#endif