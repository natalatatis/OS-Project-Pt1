/* os.c — with diagnostics added, drop-in replacement */
#include <stdint.h>
#include <stddef.h>
#include "os.h"
#include "pcb.h"

#define NUM_PROCS 2

pcb_t  pcb_array[NUM_PROCS];
pcb_t *current_proc = NULL;
pcb_t *next_proc    = NULL;

extern void PUT32(uint32_t addr, uint32_t value);
extern uint32_t GET32(uint32_t addr);
extern void enable_irq(void);
extern void first_launch(pcb_t *pcb);

typedef enum { PLATFORM_BEAGLE = 0, PLATFORM_QEMU = 1 } platform_t;

#if defined(TARGET_BEAGLE)
static const platform_t current_platform = PLATFORM_BEAGLE;
#elif defined(TARGET_QEMU)
static const platform_t current_platform = PLATFORM_QEMU;
#else
#error "Compile with -DTARGET_BEAGLE or -DTARGET_QEMU"
#endif

typedef struct {
    uint32_t uart_base, uart_tx_reg, uart_status_reg;
    uint32_t uart_tx_ready_mask, uart_tx_ready_value;
    uint32_t timer_base, intc_base, wdt_base;
} hw_config_t;

static const hw_config_t hw_table[] = {
    [PLATFORM_BEAGLE] = {
        .uart_base           = 0x44E09000u,
        .uart_tx_reg         = 0x00u,
        .uart_status_reg     = 0x14u,
        .uart_tx_ready_mask  = 0x20u,
        .uart_tx_ready_value = 0x20u,
        .timer_base          = 0x48040000u,
        .intc_base           = 0x48200000u,
        .wdt_base            = 0x44E35000u
    },
    [PLATFORM_QEMU] = {
        .uart_base           = 0x101F1000u,
        .uart_tx_reg         = 0x00u,
        .uart_status_reg     = 0x18u,
        .uart_tx_ready_mask  = 0x20u,
        .uart_tx_ready_value = 0x00u,
        .timer_base          = 0x101E2000u,
        .intc_base           = 0x10140000u,
        .wdt_base            = 0x00000000u
    }
};

static inline const hw_config_t *hw(void) { return &hw_table[current_platform]; }

/* ============================================================
 * UART
 * ============================================================ */
void os_uart_putc(char c) {
    const hw_config_t *cfg = hw();
    while ((GET32(cfg->uart_base + cfg->uart_status_reg) & cfg->uart_tx_ready_mask)
           != cfg->uart_tx_ready_value) {}
    PUT32(cfg->uart_base + cfg->uart_tx_reg, (uint32_t)c);
}

void os_uart_puts(const char *s) {
    while (*s) {
        if (*s == '\n') os_uart_putc('\r');
        os_uart_putc(*s++);
    }
}

/* Print a uint32 as 8 hex digits */
static void print_hex(uint32_t v) {
    static const char h[] = "0123456789ABCDEF";
    int i;
    os_uart_puts("0x");
    for (i = 7; i >= 0; --i)
        os_uart_putc(h[(v >> (i * 4)) & 0xF]);
}

void os_debug_dump_pcb(pcb_t *pcb) {
    os_uart_puts("[first_launch] PC = ");
    print_hex(pcb->pc);
    os_uart_puts("\n");

    os_uart_puts("[first_launch] SP = ");
    print_hex(pcb->sp);
    os_uart_puts("\n");

    os_uart_puts("[first_launch] CPSR = ");
    print_hex(pcb->cpsr);
    os_uart_puts("\n");
}



static void print_dec(uint32_t v) {
    char buf[12]; int i = 0;
    if (!v) { os_uart_putc('0'); return; }
    while (v) { buf[i++] = '0' + (v % 10); v /= 10; }
    while (i--) os_uart_putc(buf[i]);
}

/* ============================================================
 * Watchdog
 * ============================================================ */
static void watchdog_disable(void) {
    if (current_platform != PLATFORM_BEAGLE) return;
    PUT32(hw()->wdt_base + 0x48u, 0x0000AAAAu);
    while (GET32(hw()->wdt_base + 0x34u)) {}
    PUT32(hw()->wdt_base + 0x48u, 0x00005555u);
    while (GET32(hw()->wdt_base + 0x34u)) {}
}

/* ============================================================
 * Timer
 * ============================================================ */
static void timer_init_beagle(void) {
    const hw_config_t *cfg = hw();
    PUT32(cfg->timer_base + 0x38u, 0);
    PUT32(cfg->timer_base + 0x28u, 0x2u);
    PUT32(cfg->timer_base + 0x40u, 0xFF000000u);
    PUT32(cfg->timer_base + 0x3Cu, 0xFF000000u);
    PUT32(cfg->timer_base + 0x44u, 0x1u);
    PUT32(cfg->timer_base + 0x2Cu, 0x2u);
    PUT32(cfg->timer_base + 0x38u, 0x3u);
}

static void timer_init_qemu(void) {
    const hw_config_t *cfg = hw();
    PUT32(cfg->timer_base + 0x08u, 0);
    PUT32(cfg->timer_base + 0x0Cu, 1);
    PUT32(cfg->timer_base + 0x00u, 1000000u);
    PUT32(cfg->timer_base + 0x08u, 0xE2u);
}

static void timer_init(void) {
    if (current_platform == PLATFORM_BEAGLE) timer_init_beagle();
    else                                      timer_init_qemu();
}

static void timer_ack(void) {
    const hw_config_t *cfg = hw();
    if (current_platform == PLATFORM_BEAGLE) {
        PUT32(cfg->timer_base + 0x28u, 0x2u);
        while (GET32(cfg->timer_base + 0x34u) & 1u) {}
    } else {
        PUT32(cfg->timer_base + 0x0Cu, 1u);
    }
}

/* ============================================================
 * INTC
 * ============================================================ */
static void intc_init_beagle(void) {
    PUT32(hw()->intc_base + 0x48u, 0x1u);
    PUT32(hw()->intc_base + 0xC8u, (1u << 4));
}

static void intc_init_qemu(void) {
    PUT32(hw()->intc_base + 0x0Cu, 0);
    PUT32(hw()->intc_base + 0x10u, (1u << 4));
}

static void intc_init(void) {
    if (current_platform == PLATFORM_BEAGLE) intc_init_beagle();
    else                                      intc_init_qemu();
}

static void intc_eoi(void) {
    if (current_platform == PLATFORM_BEAGLE)
        PUT32(hw()->intc_base + 0x48u, 0x1u);
    else
        PUT32(hw()->intc_base + 0x30u, 0);
}

/* ============================================================
 * PCB setup
 * ============================================================ */
#define P1_ENTRY     0x82100000u
#define P2_ENTRY     0x82200000u
#define P1_STACK_TOP 0x82112000u
#define P2_STACK_TOP 0x82212000u

static void setup_initial_stack(pcb_t *pcb,
                                 unsigned int stack_top,
                                 unsigned int entry_point,
                                 int pid)
{
    int i;
    for (i = 0; i < 13; i++) pcb->registers[i] = 0;
    pcb->pid   = pid;
    pcb->sp    = stack_top;
    pcb->pc    = entry_point;
    pcb->lr    = entry_point;
    pcb->cpsr  = 0x13u;        /* SVC mode, IRQs enabled */
    pcb->state = READY;
}

/* ============================================================
 * Verify a memory region looks executable (non-zero word at base)
 * ============================================================ */
static void verify_process_memory(const char *name, uint32_t base) {
    uint32_t word0 = GET32(base);
    uint32_t word1 = GET32(base + 4);
    os_uart_puts(name);
    os_uart_puts(" first words: ");
    print_hex(word0);
    os_uart_putc(' ');
    print_hex(word1);
    os_uart_putc('\n');

    if (word0 == 0x00000000u && word1 == 0x00000000u) {
        os_uart_puts("  WARNING: looks like zeros — not loaded!\n");
    } else {
        os_uart_puts("  OK: non-zero content found\n");
    }
}

/* ============================================================
 * main
 * ============================================================ */
int main(void) {
    watchdog_disable();

    os_uart_puts("OS booting...\nPlatform: ");
    os_uart_puts(current_platform == PLATFORM_BEAGLE ? "BEAGLE\n" : "QEMU\n");

    os_uart_puts("UART base : "); print_hex(hw()->uart_base);  os_uart_puts("\n");
    os_uart_puts("Timer base: "); print_hex(hw()->timer_base); os_uart_puts("\n");
    os_uart_puts("INTC base : "); print_hex(hw()->intc_base);  os_uart_puts("\n");

    /* ---- Verify P1 and P2 are actually in RAM ---- */
    os_uart_puts("\n--- Memory check ---\n");
    verify_process_memory("P1 @ 0x82100000", P1_ENTRY);
    verify_process_memory("P2 @ 0x82200000", P2_ENTRY);
    os_uart_puts("--------------------\n\n");

    intc_init();
    timer_init();

    /* PCBs before enabling IRQs */
    setup_initial_stack(&pcb_array[0], P1_STACK_TOP, P1_ENTRY, 1);
    setup_initial_stack(&pcb_array[1], P2_STACK_TOP, P2_ENTRY, 2);

    os_uart_puts("PCB[0]: pid="); print_dec(pcb_array[0].pid);
    os_uart_puts(" pc="); print_hex(pcb_array[0].pc);
    os_uart_puts(" sp="); print_hex(pcb_array[0].sp);
    os_uart_puts(" lr="); print_hex(pcb_array[0].lr);
    os_uart_puts(" cpsr="); print_hex(pcb_array[0].cpsr);
    os_uart_puts("\n");

    os_uart_puts("PCB[1]: pid="); print_dec(pcb_array[1].pid);
    os_uart_puts(" pc="); print_hex(pcb_array[1].pc);
    os_uart_puts(" sp="); print_hex(pcb_array[1].sp);
    os_uart_puts(" lr="); print_hex(pcb_array[1].lr);
    os_uart_puts(" cpsr="); print_hex(pcb_array[1].cpsr);
    os_uart_puts("\n");

    current_proc = &pcb_array[0];
    next_proc    = &pcb_array[1];

    enable_irq();
    os_uart_puts("IRQs enabled\n");
    os_uart_puts("Calling first_launch for P1...\n");

    first_launch(current_proc);

    os_uart_puts("ERROR: first_launch returned!\n");
    while (1) { __asm__("wfi"); }
    return 0;
}

/* ============================================================
 * timer_irq_handler
 * ============================================================ */
void timer_irq_handler(void) {
    timer_ack();
    intc_eoi();

    os_uart_puts("[C-IRQ] switching from PID ");
    print_dec(current_proc->pid);

    next_proc = (current_proc->pid == 1) ? &pcb_array[1] : &pcb_array[0];
    current_proc = next_proc;

    os_uart_puts(" to PID ");
    print_dec(current_proc->pid);
    os_uart_puts("\n");
}