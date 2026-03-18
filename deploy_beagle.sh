#!/bin/bash
# Deploy kernel to BeagleBone via YMODEM

set -e

# ---- Configuration ----
SERIAL_PORT="${SERIAL_PORT:-/dev/cu.usbserial-AB6ZOWNT}"
BAUD_RATE=115200
LOAD_ADDR=0x82000000
BINARY=build/kernel.bin

# ---- Check binary ----
if [ ! -f "$BINARY" ]; then
    echo "ERROR: $BINARY not found."
    echo "Run: make beagle"
    exit 1
fi

# ---- Check YMODEM tool ----
if command -v lsb &> /dev/null; then
    SB_CMD="lsb"
elif command -v sb &> /dev/null; then
    SB_CMD="sb"
elif command -v sz &> /dev/null; then
    SB_CMD="sz --ymodem"
else
    echo "ERROR: Install lrzsz first:"
    echo "brew install lrzsz"
    exit 1
fi

echo "================================"
echo "Binary:  $BINARY"
echo "Serial:  $SERIAL_PORT"
echo "Address: $LOAD_ADDR"
echo "================================"
echo

# ---- Open serial ----
exec 3<>"$SERIAL_PORT"
stty -f "$SERIAL_PORT" "$BAUD_RATE" cs8 -cstopb -parenb raw -echo

# ---- Interrupt U-Boot ----
(while true; do echo -n " " >&3; sleep 0.1; done) &
SPAM_PID=$!

echo ">>> Press RESET on BeagleBone, then press ENTER <<<"
read -r

echo "Interrupting U-Boot..."
sleep 2

kill $SPAM_PID 2>/dev/null || true
wait $SPAM_PID 2>/dev/null || true
sleep 0.5

# ---- Send loady ----
echo "Sending loady $LOAD_ADDR..."
echo "loady $LOAD_ADDR" >&3
sleep 1

# Drain U-Boot output
cat <&3 > /dev/null &
DRAIN_PID=$!
sleep 4
kill $DRAIN_PID 2>/dev/null || true
wait $DRAIN_PID 2>/dev/null || true

# ---- Send binary ----
echo "Sending $BINARY via YMODEM..."
$SB_CMD "$BINARY" <&3 >&3
sleep 1

# ---- Boot program ----
echo "Sending go $LOAD_ADDR..."
echo "go $LOAD_ADDR" >&3

echo
echo "================================"
echo " Program running. UART output:"  
echo "================================"
echo

cat <&3