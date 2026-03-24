CC      = arm-none-eabi-gcc
LD      = arm-none-eabi-ld
OBJCOPY = arm-none-eabi-objcopy

OS    = OS
LIB   = Library
INC   = include
P1    = P1
P2    = P2
BUILD = build

CFLAGS = -ffreestanding -nostdlib -nostartfiles -I$(INC) -I$(LIB) -g

# OS object files
OS_OBJS = $(BUILD)/start.o \
          $(BUILD)/os.o \
          $(BUILD)/stdio.o \
          $(BUILD)/string.o \
          $(BUILD)/io.o   # real UART

.PHONY: qemu beagle flash clean

# -----------------------------
# QEMU
# -----------------------------
qemu: clean
	$(MAKE) BUILD_START="$(OS)/root_qemu.s" \
	        LINKER=$(OS)/linker_qemu.ld \
	        CPU="-DTARGET_QEMU -mcpu=arm926ej-s" \
	        _build_os _build_p1_qemu _build_p2_qemu
	qemu-system-arm -M versatilepb -cpu arm926 -nographic -kernel $(BUILD)/kernel.bin

# -----------------------------
# BeagleBone
# -----------------------------
beagle: clean
	$(MAKE) BUILD_START="$(OS)/root_beagle.s" \
	        LINKER=$(OS)/linker_beagle.ld \
	        CPU="-DTARGET_BEAGLE -mcpu=cortex-a8" \
	        _build_os _build_p1_beagle _build_p2_beagle
	$(MAKE) flash

flash:
	@echo "================================"
	@echo " Deploying to BeagleBone Black"
	@echo "================================"
	./deploy_beagle.sh

$(BUILD):
	mkdir -p $(BUILD)

# -----------------------------
# OS build
# -----------------------------
_build_os: $(BUILD) $(BUILD)/kernel.bin

$(BUILD)/start.o: $(BUILD_START)
	$(CC) -c $< $(CFLAGS) $(CPU) -o $@

$(BUILD)/os.o: $(OS)/os.c
	$(CC) -c $< $(CFLAGS) $(CPU) -o $@

$(BUILD)/stdio.o: $(LIB)/stdio.c
	$(CC) -c $< $(CFLAGS) $(CPU) -o $@

$(BUILD)/string.o: $(LIB)/string.c
	$(CC) -c $< $(CFLAGS) $(CPU) -o $@

$(BUILD)/io.o: $(LIB)/io.c
	$(CC) -c $< $(CFLAGS) $(CPU) -o $@

$(BUILD)/kernel.elf: $(OS_OBJS)
	$(LD) -T $(LINKER) $^ -o $@

$(BUILD)/kernel.bin: $(BUILD)/kernel.elf
	$(OBJCOPY) -O binary $< $@

# -----------------------------
# P1 build
# -----------------------------
_build_p1_beagle: $(BUILD)
	$(MAKE) BUILD_CPU="-DTARGET_BEAGLE -mcpu=cortex-a8" _build_p1_generic

_build_p1_qemu: $(BUILD)
	$(MAKE) BUILD_CPU="-DTARGET_QEMU -mcpu=arm926ej-s" _build_p1_generic

_build_p1_generic:
	$(CC) -c $(P1)/main.c $(CFLAGS) $(BUILD_CPU) -o $(BUILD)/p1.o
	$(CC) -c $(LIB)/stdio.c $(CFLAGS) $(BUILD_CPU) -o $(BUILD)/p1_stdio.o
	$(CC) -c $(LIB)/string.c $(CFLAGS) $(BUILD_CPU) -o $(BUILD)/p1_string.o
	$(CC) -c $(LIB)/io_stub.c $(CFLAGS) $(BUILD_CPU) -o $(BUILD)/p1_io.o

	$(LD) -T $(P1)/p1.ld \
	      $(BUILD)/p1.o \
	      $(BUILD)/p1_stdio.o \
	      $(BUILD)/p1_string.o \
	      $(BUILD)/p1_io.o \
	      -o $(BUILD)/p1.elf

	$(OBJCOPY) -O binary $(BUILD)/p1.elf $(BUILD)/p1.bin

# -----------------------------
# P2 build
# -----------------------------
_build_p2_beagle: $(BUILD)
	$(MAKE) BUILD_CPU="-DTARGET_BEAGLE -mcpu=cortex-a8" _build_p2_generic

_build_p2_qemu: $(BUILD)
	$(MAKE) BUILD_CPU="-DTARGET_QEMU -mcpu=arm926ej-s" _build_p2_generic

_build_p2_generic:
	$(CC) -c $(P2)/main.c $(CFLAGS) $(BUILD_CPU) -o $(BUILD)/p2.o
	$(CC) -c $(LIB)/stdio.c $(CFLAGS) $(BUILD_CPU) -o $(BUILD)/p2_stdio.o
	$(CC) -c $(LIB)/string.c $(CFLAGS) $(BUILD_CPU) -o $(BUILD)/p2_string.o
	$(CC) -c $(LIB)/io_stub.c $(CFLAGS) $(BUILD_CPU) -o $(BUILD)/p2_io.o

	$(LD) -T $(P2)/p2.ld \
	      $(BUILD)/p2.o \
	      $(BUILD)/p2_stdio.o \
	      $(BUILD)/p2_string.o \
	      $(BUILD)/p2_io.o \
	      -o $(BUILD)/p2.elf

	$(OBJCOPY) -O binary $(BUILD)/p2.elf $(BUILD)/p2.bin

# -----------------------------
# Clean
# -----------------------------
clean:
	rm -rf $(BUILD)