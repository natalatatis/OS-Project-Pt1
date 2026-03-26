#ifndef OS_API_H
#define OS_API_H

#include <stdint.h>

typedef struct {
    void (*putc)(char);
    void (*puts)(const char *);
} os_api_t;

#if defined(TARGET_BEAGLE)
#define OS_API_ADDR 0x82008000u
#elif defined(TARGET_QEMU)
#define OS_API_ADDR 0x00018000u
#else
#error "Compile with -DTARGET_BEAGLE or -DTARGET_QEMU"
#endif

static inline const os_api_t *os_api_get(void) {
    return (const os_api_t *)OS_API_ADDR;
}

#endif