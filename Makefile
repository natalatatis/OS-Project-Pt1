CC=arm-none-eabi-gcc
LD=arm-none-eabi-ld
OBJCOPY=arm-none-eabi-objcopy

SRC=src
OS=OS
INC=include
BUILD=build

CFLAGS=-ffreestanding -nostdlib -nostartfiles -I$(INC) -g

OBJS=$(BUILD)/start.o $(BUILD)/main.o $(BUILD)/uart.o

.PHONY: qemu beagle flash clean build

# -------------------------
# QEMU
# -------------------------
qemu: clean
	$(MAKE) START="$(OS)/root_qemu.s" LINKER=linker_qemu.ld CPU="-DQEMU -mcpu=arm926ej-s" build_qemu
	qemu-system-arm -M versatilepb -cpu arm926 -nographic -kernel $(BUILD)/kernel.elf

build_qemu: build $(BUILD)/kernel.elf

# -------------------------
# BeagleBone
# -------------------------
beagle: clean
	$(MAKE) START="$(OS)/root_beagle.s" LINKER=linker_beagle.ld CPU="-mcpu=cortex-a8" build_beagle
	$(MAKE) flash

build_beagle: build $(BUILD)/kernel.bin

flash:
	@echo "================================"
	@echo " Deploying to BeagleBone Black"
	@echo "================================"
	./deploy_beagle.sh

# -------------------------
# Build rules
# -------------------------
build:
	mkdir -p $(BUILD)

# Assembly (from OS/)
$(BUILD)/start.o:
	$(CC) -c $(START) $(CFLAGS) $(CPU) -o $@

# C files (from src/)
$(BUILD)/main.o: $(SRC)/main.c
	$(CC) -c $< $(CFLAGS) $(CPU) -o $@

$(BUILD)/uart.o: $(SRC)/uart.c
	$(CC) -c $< $(CFLAGS) $(CPU) -o $@

# Link
$(BUILD)/kernel.elf: $(OBJS)
	$(LD) -T $(LINKER) $^ -o $@

# Binary
$(BUILD)/kernel.bin: $(BUILD)/kernel.elf
	$(OBJCOPY) -O binary $< $@

clean:
	rm -rf $(BUILD)