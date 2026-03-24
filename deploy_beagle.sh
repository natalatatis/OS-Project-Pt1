#!/bin/bash
# Deploy OS + P1 + P2 to BeagleBone via YMODEM

set -e

# ---- Configuration ----
SERIAL_PORT="${SERIAL_PORT:-/dev/cu.usbserial-AB6ZOWNT}"
BAUD_RATE=115200

OS_ADDR=0x82000000
P1_ADDR=0x82100000
P2_ADDR=0x82200000

OS_BIN=build/kernel.bin
P1_BIN=build/p1.bin
P2_BIN=build/p2.bin

# ---- Check binaries ----
for f in "$OS_BIN" "$P1_BIN" "$P2_BIN"; do
    if [ ! -f "$f" ]; then
        echo "ERROR: $f not found."
        echo "Run: make beagle"
        exit 1
    fi
done

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
echo "OS:  $OS_BIN  -> $OS_ADDR"
echo "P1:  $P1_BIN  -> $P1_ADDR"
echo "P2:  $P2_BIN  -> $P2_ADDR"
echo "Serial: $SERIAL_PORT"
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

# ---- Helper function to send a binary ----
send_image () {
    local FILE=$1
    local ADDR=$2

    echo
    echo ">>> Loading $FILE to $ADDR"
    echo "loady $ADDR" >&3
    sleep 1

    # Drain output
    cat <&3 > /dev/null &
    DRAIN_PID=$!
    sleep 3
    kill $DRAIN_PID 2>/dev/null || true
    wait $DRAIN_PID 2>/dev/null || true

    echo "Sending $FILE via YMODEM..."
    $SB_CMD "$FILE" <&3 >&3
    sleep 1
}

# ---- Send all images ----
send_image "$OS_BIN" "$OS_ADDR"
send_image "$P1_BIN" "$P1_ADDR"
send_image "$P2_BIN" "$P2_ADDR"

# ---- Boot OS ----
echo
echo ">>> Starting OS at $OS_ADDR"
echo "go $OS_ADDR" >&3

echo
echo "================================"
echo " System running. UART output:"
echo "================================"
echo

cat <&3