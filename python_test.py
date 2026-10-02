import serial
import time

ser = serial.Serial('/dev/ttyUSB1', 115200, timeout=1.0)
ser.reset_input_buffer()
ser.reset_output_buffer()

test_byte = b'\x41' # ASCII 'A'
ser.write(test_byte)
ser.flush()

response = ser.read(1)
if response:
    print(f"SUCCESS! Sent: {hex(test_byte[0])} | Received: {hex(response[0])}")
else:
    print("TIMEOUT")

ser.close()
