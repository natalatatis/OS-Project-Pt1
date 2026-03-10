CC=arm-none-eabi-gcc
AS=arm-none-eabi-as
LD=arm-none-eabi-ld
OBJCOPY=arm-none-eabi-objcopy

SRC=src
INC=include
BUILD=build

CFLAGS=-ffreestanding -nostdlib -nostartfiles -I$(INC) -g

OBJS=$(BUILD)/start.o $(BUILD)/main.o $(BUILD)/uart.o

# QEMU build
qemu: CFLAGS+=-DQEMU -mcpu=arm926ej-s
qemu: LINKER=linker_qemu.ld
qemu: clean build $(BUILD)/kernel.elf
	qemu-system-arm -M versatilepb -cpu arm926 -nographic -kernel $(BUILD)/kernel.elf

# Beagle build
beagle: CFLAGS+=-mcpu=cortex-a8
beagle: LINKER=linker_beagle.ld
beagle: clean build $(BUILD)/kernel.bin
	@echo "Load build/kernel.bin at 0x402F0400"

build:
	mkdir -p $(BUILD)

$(BUILD)/start.o:
	$(AS) $(SRC)/start.s -o $(BUILD)/start.o

$(BUILD)/main.o:
	$(CC) -c $(SRC)/main.c $(CFLAGS) -o $(BUILD)/main.o

$(BUILD)/uart.o:
	$(CC) -c $(SRC)/uart.c $(CFLAGS) -o $(BUILD)/uart.o

$(BUILD)/kernel.elf: $(BUILD)/start.o $(BUILD)/main.o $(BUILD)/uart.o
	$(LD) -T $(LINKER) $^ -o $@

$(BUILD)/kernel.bin: $(BUILD)/kernel.elf
	$(OBJCOPY) -O binary $< $@

clean:
	rm -rf $(BUILD)