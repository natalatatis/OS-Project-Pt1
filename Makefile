CC      = arm-none-eabi-gcc
LD      = arm-none-eabi-ld
OBJCOPY = arm-none-eabi-objcopy

OS    = OS
LIB   = Library
INC   = include
P1    = P1
P2    = P2
BUILD = build

CFLAGS = -ffreestanding -nostdlib -nostartfiles -g -I$(INC) -I$(LIB) -I$(OS)

.PHONY: qemu beagle flash clean run_qemu \
        _build_os _build_p1 _build_p2

qemu: clean
	$(MAKE) BUILD_START="$(OS)/root_qemu.s" \
	        LINKER="$(OS)/linker_qemu.ld" \
	        CPU="-DTARGET_QEMU -mcpu=arm926ej-s -marm" \
	        P1_LINKER="$(P1)/p1.ld" \
	        P2_LINKER="$(P2)/p2.ld" \
	        _build_os _build_p1 _build_p2

beagle: clean
	@echo "================================"
	@echo " Building for BeagleBone Black"
	@echo "================================"
	$(MAKE) BUILD_START="$(OS)/root_beagle.s" \
	        LINKER="$(OS)/linker_beagle.ld" \
	        CPU="-DTARGET_BEAGLE -mcpu=cortex-a8 -marm" \
	        P1_LINKER="$(P1)/p1.ld" \
	        P2_LINKER="$(P2)/p2.ld" \
	        _build_os _build_p1 _build_p2
	@echo "================================"
	@echo " Deploying to BeagleBone Black"
	@echo "================================"
	./deploy_beagle.sh

run_qemu: qemu
	qemu-system-arm -M versatilepb -cpu arm926 -nographic -kernel $(BUILD)/kernel.elf

$(BUILD):
	mkdir -p $(BUILD)

# -----------------------------
# OS
# -----------------------------
_build_os: $(BUILD) $(BUILD)/kernel.bin

$(BUILD)/start.o: $(BUILD_START)
	$(CC) -c $< $(CFLAGS) $(CPU) -o $@

$(BUILD)/os.o: $(OS)/os.c
	$(CC) -c $< $(CFLAGS) $(CPU) -o $@

$(BUILD)/kernel.elf: $(BUILD)/start.o $(BUILD)/os.o
	$(LD) -T $(LINKER) $^ -o $@

$(BUILD)/kernel.bin: $(BUILD)/kernel.elf
	$(OBJCOPY) -O binary $< $@

# -----------------------------
# P1
# -----------------------------
_build_p1: $(BUILD) $(BUILD)/p1.bin

$(BUILD)/p1.o: $(P1)/main.c
	$(CC) -c $< $(CFLAGS) $(CPU) -o $@

$(BUILD)/p1_stdio.o: $(LIB)/stdio.c
	$(CC) -c $< $(CFLAGS) $(CPU) -o $@

$(BUILD)/p1_string.o: $(LIB)/string.c
	$(CC) -c $< $(CFLAGS) $(CPU) -o $@

$(BUILD)/p1_io.o: $(LIB)/io.c
	$(CC) -c $< $(CFLAGS) $(CPU) -o $@

$(BUILD)/p1.elf: $(BUILD)/p1.o $(BUILD)/p1_stdio.o $(BUILD)/p1_string.o $(BUILD)/p1_io.o
	$(LD) -T $(P1_LINKER) $^ -o $@

$(BUILD)/p1.bin: $(BUILD)/p1.elf
	$(OBJCOPY) -O binary $< $@

# -----------------------------
# P2
# -----------------------------
_build_p2: $(BUILD) $(BUILD)/p2.bin

$(BUILD)/p2.o: $(P2)/main.c
	$(CC) -c $< $(CFLAGS) $(CPU) -o $@

$(BUILD)/p2_stdio.o: $(LIB)/stdio.c
	$(CC) -c $< $(CFLAGS) $(CPU) -o $@

$(BUILD)/p2_string.o: $(LIB)/string.c
	$(CC) -c $< $(CFLAGS) $(CPU) -o $@

$(BUILD)/p2_io.o: $(LIB)/io.c
	$(CC) -c $< $(CFLAGS) $(CPU) -o $@

$(BUILD)/p2.elf: $(BUILD)/p2.o $(BUILD)/p2_stdio.o $(BUILD)/p2_string.o $(BUILD)/p2_io.o
	$(LD) -T $(P2_LINKER) $^ -o $@

$(BUILD)/p2.bin: $(BUILD)/p2.elf
	$(OBJCOPY) -O binary $< $@

clean:
	rm -rf $(BUILD)