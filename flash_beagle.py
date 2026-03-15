import sys
import time
import serial
from ymodem.Socket import ModemSocket


def wait_for_ymodem(ser):
    print("Waiting for YMODEM handshake...")

    start = time.time()

    while time.time() - start < 10:

        if ser.in_waiting:
            data = ser.read(ser.in_waiting)

            if b"C" in data:
                print("YMODEM handshake detected")
                return

    print("WARNING: handshake not detected")


def deploy(port, baud, filepath, addr):

    print(f"Connecting to {port} ({baud})")

    ser = serial.Serial(port, baud, timeout=1)

    time.sleep(0.5)

    ser.reset_input_buffer()

    print(f"Sending loady {addr}")
    ser.write(f"loady {addr}\r\n".encode())

    time.sleep(1)

    ser.read(ser.in_waiting or 1024)

    wait_for_ymodem(ser)

    print(f"Sending {filepath} via YMODEM")

    modem = ModemSocket(
        lambda size, timeout=None: ser.read(size),
        lambda data, timeout=None: ser.write(data)
    )

    modem.send([filepath])

    time.sleep(1)

    print(f"Sending go {addr}")
    ser.write(f"go {addr}\r\n".encode())

    print()
    print("================================")
    print(" Program running. UART output:")
    print("================================")
    print()

    ser.timeout = 0.05

    try:
        while True:

            data = ser.read(ser.in_waiting or 1)

            if data:
                sys.stdout.buffer.write(data)
                sys.stdout.flush()

    except KeyboardInterrupt:
        pass

    finally:
        ser.close()


if __name__ == "__main__":
    deploy(sys.argv[1], int(sys.argv[2]), sys.argv[3], sys.argv[4])