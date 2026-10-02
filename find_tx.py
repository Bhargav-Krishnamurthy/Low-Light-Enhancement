import serial
import time

ports = ['/dev/ttyUSB0', '/dev/ttyUSB1']
connections = {}

# Open all detected FTDI USB serial ports
for p in ports:
    try:
        s = serial.Serial(p, 115200, timeout=0.5)
        s.reset_input_buffer()
        connections[p] = s
        print(f"Listening on {p}...")
    except Exception as e:
        print(f"Could not open {p}: {e}")

if not connections:
    print("Error: No active USB serial ports found.")
    exit(1)

print("\n--- Scanning for FPGA continuous TX data (5 seconds)... ---")
start = time.time()
found = False

while time.time() - start < 5.0:
    for port_name, ser in connections.items():
        if ser.in_waiting > 0:
            data = ser.read(ser.in_waiting)
            print(f" SUCCESS! Data received on {port_name}: {data}")
            found = True

    time.sleep(0.1)

for ser in connections.values():
    ser.close()

if not found:
    print("\n FAIL: No data received on any port. Re-check physical pin mapping.")
