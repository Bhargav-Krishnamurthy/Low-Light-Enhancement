import serial

port = '/dev/ttyUSB1'
print(f"Connecting to {port}...")

try:
    ser = serial.Serial(port, 115200, timeout=1.0)
    ser.reset_input_buffer()
    ser.reset_output_buffer()

    test_byte = b'\x55' # Send binary pattern 01010101
    print(f"Sent: {hex(test_byte[0])}")
    ser.write(test_byte)
    ser.flush()

    response = ser.read(1)
    if response:
        print(f"SUCCESS! Received back: {hex(response[0])}")
    else:
        print("TIMEOUT: No data received.")

    ser.close()
except Exception as e:
    print(f"Error: {e}")
