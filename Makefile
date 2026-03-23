CC=arm-none-eabi-gcc
LD=arm-none-eabi-ld
OBJCOPY=arm-none-eabi-objcopy

SRC=src
OS=OS
LIB=Library
INC=include
BUILD=build

CFLAGS=-ffreestanding -nostdlib -nostartfiles -I$(INC) -I$(LIB) -g

OBJS=$(BUILD)/start.o \
     $(BUILD)/os.o \
     $(BUILD)/uart_low.o \
     $(BUILD)/stdio.o \
     $(BUILD)/io.o \
     $(BUILD)/string.o

.PHONY: qemu beagle flash clean build

# -------------------------
# QEMU
# -------------------------
qemu: clean
	$(MAKE) START="$(OS)/root_qemu.s" LINKER=$(OS)/linker_qemu.ld CPU="-DTARGET_QEMU -mcpu=arm926ej-s" build_qemu
	qemu-system-arm -M versatilepb -cpu arm926 -nographic -kernel $(BUILD)/kernel.bin

build_qemu: build $(BUILD)/kernel.bin

# -------------------------
# BeagleBone
# -------------------------
beagle: clean
	$(MAKE) START="$(OS)/root_beagle.s" LINKER=$(OS)/linker_beagle.ld CPU="-DTARGET_BEAGLE -mcpu=cortex-a8" build_beagle
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

# Assembly
$(BUILD)/start.o:
	$(CC) -c $(START) $(CFLAGS) $(CPU) -o $@

# OS
$(BUILD)/os.o: $(OS)/os.c
	$(CC) -c $< $(CFLAGS) $(CPU) -o $@

# UART low-level 
$(BUILD)/uart_low.o: $(OS)/uart_low.c
	$(CC) -c $< $(CFLAGS) $(CPU) -o $@

# Library
$(BUILD)/stdio.o: $(LIB)/stdio.c
	$(CC) -c $< $(CFLAGS) $(CPU) -o $@

$(BUILD)/io.o: $(LIB)/io.c
	$(CC) -c $< $(CFLAGS) $(CPU) -o $@

$(BUILD)/string.o: $(LIB)/string.c
	$(CC) -c $< $(CFLAGS) $(CPU) -o $@

# Link
$(BUILD)/kernel.elf: $(OBJS)
	$(LD) -T $(LINKER) $^ -o $@

# Binary
$(BUILD)/kernel.bin: $(BUILD)/kernel.elf
	$(OBJCOPY) -O binary $< $@

clean:
	rm -rf $(BUILD)