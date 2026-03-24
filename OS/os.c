#include <stdint.h>
#include <stddef.h>  
#include "os.h"
#include "pcb.h"
#include "mem.h"

#define NUM_PROCS 2



pcb_t pcb_array[NUM_PROCS]; //P1 and P2
pcb_t *current_proc = NULL;
pcb_t *next_proc = NULL;


extern void enable_irq(void);

typedef enum {
    PLATFORM_BEAGLE = 0,
    PLATFORM_QEMU   = 1
} platform_t;

#if defined(TARGET_BEAGLE)
static const platform_t current_platform = PLATFORM_BEAGLE;
#elif defined(TARGET_QEMU)
static const platform_t current_platform = PLATFORM_QEMU;
#else
#error "Compile with TARGET_BEAGLE or TARGET_QEMU"
#endif

typedef struct {
    uint32_t uart_base;
    uint32_t uart_tx_reg;
    uint32_t uart_status_reg;
    uint32_t uart_tx_ready_mask;
    uint32_t uart_tx_ready_value;

    uint32_t timer_base;
    uint32_t intc_base;
    uint32_t wdt_base;
} hw_config_t;

static const hw_config_t hw_table[] = {
    [PLATFORM_BEAGLE] = {
        .uart_base               = 0x44E09000u, /* UART0 */
        .uart_tx_reg             = 0x00u,       /* THR */
        .uart_status_reg         = 0x14u,       /* LSR */
        .uart_tx_ready_mask      = 0x20u,       /* THRE */
        .uart_tx_ready_value     = 0x20u,

        .timer_base              = 0x48040000u, /* DMTimer2 */
        .intc_base               = 0x48200000u, /* AM335x INTC */
        .wdt_base                = 0x44E35000u  /* WDT1 */
    },

    [PLATFORM_QEMU] = {
        .uart_base               = 0x101F1000u, /* PL011 */
        .uart_tx_reg             = 0x00u,       /* DR */
        .uart_status_reg         = 0x18u,       /* FR */
        .uart_tx_ready_mask      = 0x20u,       /* TXFF */
        .uart_tx_ready_value     = 0x00u,       /* ready when TXFF == 0 */

        .timer_base              = 0x101E2000u, /* SP804 Timer0 */
        .intc_base               = 0x10140000u, /* VIC */
        .wdt_base                = 0x00000000u
    }
};

static inline const hw_config_t *hw(void) {
    return &hw_table[current_platform];
}

static volatile uint32_t g_tick_count = 0;

static void delay(volatile uint32_t count) {
    while (count--) {
        __asm__ volatile ("nop");
    }
}

/* =========================
 * UART low-level
 * ========================= */

static void uart_init_beagle(void) {
    /* Minimal: often already configured by bootloader */
}

static void uart_init_qemu(void) {
    /* Minimal: PL011 usually usable as-is in QEMU */
}

static void uart_init(void) {
    if (current_platform == PLATFORM_BEAGLE) {
        uart_init_beagle();
    } else {
        uart_init_qemu();
    }
}

void os_uart_putc(char c) {
    const hw_config_t *cfg = hw();

    while ((GET32(cfg->uart_base + cfg->uart_status_reg) & cfg->uart_tx_ready_mask)
            != cfg->uart_tx_ready_value) {
    }

    PUT32(cfg->uart_base + cfg->uart_tx_reg, (uint32_t)c);
}

void os_uart_puts(const char *s) {
    while (*s) {
        if (*s == '\n') {
            os_uart_putc('\r');
        }
        os_uart_putc(*s++);
    }
}

static void uart_put_hex(uint32_t value) {
    static const char hex[] = "0123456789ABCDEF";
    int i;

    os_uart_puts("0x");
    for (i = 7; i >= 0; --i) {
        os_uart_putc(hex[(value >> (i * 4)) & 0xF]);
    }
}

static void uart_put_dec(uint32_t value) {
    char buf[16];
    int i = 0;

    if (value == 0u) {
        os_uart_putc('0');
        return;
    }

    while (value > 0u && i < (int)sizeof(buf)) {
        buf[i++] = (char)('0' + (value % 10u));
        value /= 10u;
    }

    while (i > 0) {
        os_uart_putc(buf[--i]);
    }
}

/* =========================
 * Watchdog
 * ========================= */

static void watchdog_disable(void) {
    if (current_platform != PLATFORM_BEAGLE) {
        return;
    }

    {
        const hw_config_t *cfg = hw();
        const uint32_t WSPR = 0x48u;
        const uint32_t WWPS = 0x34u;

        PUT32(cfg->wdt_base + WSPR, 0x0000AAAAu);
        while (GET32(cfg->wdt_base + WWPS) != 0u) {
        }

        PUT32(cfg->wdt_base + WSPR, 0x00005555u);
        while (GET32(cfg->wdt_base + WWPS) != 0u) {
        }
    }
}

/* =========================
 * Timer
 * ========================= */

static void timer_init_beagle(void) {
    const hw_config_t *cfg = hw();

    const uint32_t IRQSTATUS     = 0x28u; /* TISR */
    const uint32_t IRQENABLE_SET = 0x2Cu; /* TIER */
    const uint32_t TCLR          = 0x38u;
    const uint32_t TCRR          = 0x3Cu;
    const uint32_t TLDR          = 0x40u;
    const uint32_t TTGR          = 0x44u;

    const uint32_t reload_value  = 0xFF000000u;

    PUT32(cfg->timer_base + TCLR, 0x00000000u);
    PUT32(cfg->timer_base + IRQSTATUS, 0x00000002u);

    PUT32(cfg->timer_base + TLDR, reload_value);
    PUT32(cfg->timer_base + TCRR, reload_value);
    PUT32(cfg->timer_base + TTGR, 0x00000001u);

    PUT32(cfg->timer_base + IRQENABLE_SET, 0x00000002u);

    /* ST=1, AR=1 */
    PUT32(cfg->timer_base + TCLR, 0x00000003u);
}

static void timer_init_qemu(void) {
    const hw_config_t *cfg = hw();

    const uint32_t TIMER_LOAD    = 0x00u;
    const uint32_t TIMER_CONTROL = 0x08u;
    const uint32_t TIMER_INTCLR  = 0x0Cu;

    PUT32(cfg->timer_base + TIMER_CONTROL, 0x00000000u);
    PUT32(cfg->timer_base + TIMER_INTCLR,  0x00000001u);

    PUT32(cfg->timer_base + TIMER_LOAD, 1000000u);

    /* enable | periodic | irq enable | 32-bit */
    PUT32(cfg->timer_base + TIMER_CONTROL, 0x000000E2u);
}

static void timer_init(void) {
    if (current_platform == PLATFORM_BEAGLE) {
        timer_init_beagle();
    } else {
        timer_init_qemu();
    }
}

static void timer_ack(void) {
    const hw_config_t *cfg = hw();

    if (current_platform == PLATFORM_BEAGLE) {
        const uint32_t IRQSTATUS = 0x28u;
        const uint32_t TWPS      = 0x34u;

        PUT32(cfg->timer_base + IRQSTATUS, 0x00000002u);

        // wait for write to complete
        while (GET32(cfg->timer_base + TWPS) & (1 << 0)) {
        }
    } else {
        const uint32_t TIMER_INTCLR = 0x0Cu;
        PUT32(cfg->timer_base + TIMER_INTCLR, 0x00000001u);
    }
}

/* =========================
 * Interrupt controller
 * ========================= */

static void intc_init_beagle(void) {
    const hw_config_t *cfg = hw();

    const uint32_t MIR_CLEAR2 = 0xC8u;
    const uint32_t CONTROL    = 0x48u;

    PUT32(cfg->intc_base + CONTROL, 0x00000001u);

    /* DMTimer2 = IRQ 68 => bank 2, bit 4 */
    PUT32(cfg->intc_base + MIR_CLEAR2, (1u << 4));
}

static void intc_init_qemu(void) {
    const hw_config_t *cfg = hw();

    const uint32_t VIC_INT_SELECT = 0x0Cu;
    const uint32_t VIC_INT_ENABLE = 0x10u;

    PUT32(cfg->intc_base + VIC_INT_SELECT, 0x00000000u);
    PUT32(cfg->intc_base + VIC_INT_ENABLE, (1u << 4));
}

static void intc_init(void) {
    if (current_platform == PLATFORM_BEAGLE) {
        intc_init_beagle();
    } else {
        intc_init_qemu();
    }
}

static void intc_eoi(void) {
    const hw_config_t *cfg = hw();

    if (current_platform == PLATFORM_BEAGLE) {
        const uint32_t CONTROL = 0x48u;
        PUT32(cfg->intc_base + CONTROL, 0x00000001u);
    } else {
        const uint32_t VIC_VECT_ADDR = 0x30u;
        PUT32(cfg->intc_base + VIC_VECT_ADDR, 0x00000000u);
    }
}

// PCB Setup
static void setup_initial_stack(pcb_t *pcb, unsigned int stack_top,
                                 unsigned int entry_point, int pid) {
    for (int i = 0; i < 13; i++) pcb->registers[i] = 0;

    pcb->pid   = pid;
    pcb->sp    = stack_top;   // SVC SP for this process
    pcb->pc    = entry_point; // where to resume 
    pcb->lr    = entry_point; // SVC LR 
    pcb->cpsr  = 0x13;        // SVC mode, IRQs enabled
    pcb->state = READY;
}


/* =========================
 * Main / IRQ
 * ========================= */

int main(void) {
    watchdog_disable();
    uart_init();

    os_uart_puts("OS booting...\n");
    os_uart_puts("Platform: ");
    if (current_platform == PLATFORM_BEAGLE) {
        os_uart_puts("BEAGLE\n");
    } else {
        os_uart_puts("QEMU\n");
    }

    os_uart_puts("UART base : ");
    uart_put_hex(hw()->uart_base);
    os_uart_puts("\n");

    os_uart_puts("Timer base: ");
    uart_put_hex(hw()->timer_base);
    os_uart_puts("\n");

    os_uart_puts("INTC base : ");
    uart_put_hex(hw()->intc_base);
    os_uart_puts("\n");

    intc_init();
    timer_init();
    enable_irq();

    os_uart_puts("IRQs enabled\n");

    //  PCB Initialization 
    #define P1_ENTRY      0x82100000u
    #define P2_ENTRY      0x82200000u
    #define P1_STACK_TOP  0x82112000u
    #define P2_STACK_TOP  0x82212000u

    setup_initial_stack(&pcb_array[0], P1_STACK_TOP, P1_ENTRY, 1);
    setup_initial_stack(&pcb_array[1], P2_STACK_TOP, P2_ENTRY, 2);

    current_proc = &pcb_array[0];
    current_proc->state = RUNNING;
    next_proc = current_proc;

    os_uart_puts("Starting first process...\n");

    //  context restore 
    __asm__ volatile (
        "ldr r0, =next_proc      \n"
        "ldr r0, [r0]            \n"

        // Load CPSR into SPSR
        "ldr r1, [r0, #68]       \n" // PCB_CPSR
        "msr spsr_cxsf, r1       \n"

        // Switch to SVC mode to restore SP/LR
        "mrs r2, cpsr            \n"
        "bic r3, r2, #0x1F       \n"
        "orr r3, r3, #0x13       \n"
        "msr cpsr_c, r3          \n"

        "ldr sp, [r0, #4]        \n" // PCB_SP
        "ldr lr, [r0, #12]       \n" // PCB_LR

        // Back to IRQ mode
        "msr cpsr_c, r2          \n"

        // Load PC
        "ldr lr, [r0, #8]        \n" // PCB_PC

        // Jump 
        "movs pc, lr             \n"
    );

    while (1) {
        __asm__("wfi");
    }

    return 0;
}

void timer_irq_handler(void) {
    timer_ack();
    intc_eoi();

    // Pick next process (round-robin)
    next_proc = (current_proc->pid == 1) ? &pcb_array[1] : &pcb_array[0];

    // Update current_proc for next tick
    current_proc = next_proc;
}