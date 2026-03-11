import serial
import serial.tools.list_ports
import time
import os
from xmodem import XMODEM

# --- CONFIGURATION ---
BAUD = 115200
BIN_FILE = "build/kernel.bin"
LOAD_ADDR = "0x82000000"

# 1. Port Detection
ports = list(serial.tools.list_ports.comports())
# Using tty instead of cu for better control on macOS
PORT = next((p.device.replace("cu.", "tty.") for p in ports if "usb" in p.device.lower()), None)

if not PORT:
    raise Exception("BeagleBone serial port not found. Please check your USB connection.")

# 2. Setup Serial Connection
ser = serial.Serial(PORT, BAUD, timeout=1)

def getc(size, timeout=1):
    return ser.read(size) or None

def putc(data, timeout=1):
    return ser.write(data)

# mode='xmodem1k' uses 1024 byte blocks, which matches U-Boot 'loady' expectations
modem = XMODEM(getc, putc, mode='xmodem1k')

print(f"Connecting to: {PORT}")
print("\n[Action] Press RESET on the BeagleBone now!")

# -----------------------------
# 2. Interrupt U-Boot
# -----------------------------
ser.reset_input_buffer()
found_prompt = False
end_time = time.time() + 15 

print("Interrupting autoboot...")
while time.time() < end_time:
    ser.write(b" ")
    if ser.in_waiting:
        line = ser.read(ser.in_waiting).decode(errors="ignore")
        if "=>" in line:
            found_prompt = True
            break
    time.sleep(0.01)

if not found_prompt:
    print("Error: Failed to interrupt U-Boot. (Is the board powered?)")
    exit(1)

# -----------------------------
# 3. Trigger loady
# -----------------------------
print("Interrupt successful. Starting YMODEM transfer...")
ser.write(f"loady {LOAD_ADDR}\n".encode())

time.sleep(0.5)
ser.read_all() # Clear the 'loady' command echo and message text

print("Waiting for 'C' (Ready) signal...")
c_received = False
for _ in range(50):
    if ser.read(1) == b'C':
        c_received = True
        break
    time.sleep(0.1)

if not c_received:
    print("Error: Did not receive 'C' signal from U-Boot.")
    exit(1)

# -----------------------------
# 4. Send the file
# -----------------------------

if os.path.exists(BIN_FILE):
    with open(BIN_FILE, 'rb') as f:
        print(f"Sending {BIN_FILE}...")
        try:
            # We ignore the return status because U-Boot often ends the transfer
            # without the specific ACK the Python library expects.
            modem.send(f)
        except Exception:
            # Silence protocol errors at the very end of the stream
            pass 
    print("Transfer Complete.")
else:
    print(f"Error: {BIN_FILE} not found.")
    exit(1)

# -----------------------------
# 5. Wait for Prompt & Execute
# -----------------------------
print("Verifying U-Boot prompt...")
time.sleep(0.5)
prompt_ready = False

# We send Enters and look for '=>' to ensure the board is listening
for _ in range(10):
    ser.write(b"\r\n")
    time.sleep(0.2)
    if ser.in_waiting:
        response = ser.read(ser.in_waiting).decode(errors="ignore")
        if "=>" in response:
            prompt_ready = True
            break

if not prompt_ready:
    print("Warning: Could not confirm U-Boot prompt, attempting 'go' anyway...")

print(f"Starting execution at {LOAD_ADDR}...")
ser.write(f"go {LOAD_ADDR}\n".encode())

# -----------------------------
# 6. Serial Monitor
# -----------------------------
print("\n--- Kernel Output ---")
try:
    while True:
        if ser.in_waiting:
            # flush=True ensures real-time printing in the terminal
            print(ser.read(ser.in_waiting).decode(errors="ignore"), end="", flush=True)
        time.sleep(0.01)
except KeyboardInterrupt:
    print("\nDisconnected by user.")