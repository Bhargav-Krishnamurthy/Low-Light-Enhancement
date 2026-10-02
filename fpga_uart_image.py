import serial
import cv2
import numpy as np
import time
import sys

# --- CONFIGURATION ---
# Change this to match your FPGA's port. 
# Windows: 'COM3', 'COM4', etc. (Check Device Manager)
# Mac/Linux: '/dev/ttyUSB0' or '/dev/cu.usbserial-...'
PORT = '/dev/ttyS7' 
BAUD_RATE = 115200
WIDTH = 256
HEIGHT = 256
# ---------------------

print("1. Loading Image...")
img = cv2.imread("dark_image.jpg")
if img is None:
    sys.exit("Error: Could not find input.jpg")
    
img_small = cv2.resize(img, (WIDTH, HEIGHT))
img_rgb = cv2.cvtColor(img_small, cv2.COLOR_BGR2RGB)

# Flatten the 3D image array into a 1D array of bytes
img_bytes = img_rgb.tobytes()
total_bytes = len(img_bytes)

print(f"2. Opening Serial Port {PORT}...")
try:
    ser = serial.Serial(PORT, BAUD_RATE, timeout=5)
except Exception as e:
    sys.exit(f"Failed to open port: {e}")

print(f"3. Sending {total_bytes} bytes to FPGA...")
start_time = time.time()

# Send the image data to the FPGA
ser.write(img_bytes)

# Read the processed data coming back from the FPGA
print("4. Waiting for FPGA to process and return data...")
received_bytes = ser.read(total_bytes)

end_time = time.time()
print(f"5. Transfer complete in {end_time - start_time:.2f} seconds.")

ser.close()

if len(received_bytes) != total_bytes:
    print(f"Warning: Expected {total_bytes} bytes, got {len(received_bytes)}")

# Reconstruct and save the image
out_array = np.frombuffer(received_bytes, dtype=np.uint8)
# Pad array if some bytes were lost in transit
if len(out_array) < total_bytes:
    out_array = np.pad(out_array, (0, total_bytes - len(out_array)))
elif len(out_array) > total_bytes:
    out_array = out_array[:total_bytes]

out_img_rgb = out_array.reshape((HEIGHT, WIDTH, 3))
out_img_bgr = cv2.cvtColor(out_img_rgb, cv2.COLOR_RGB2BGR)

cv2.imwrite("fpga_output.jpg", out_img_bgr)
print("6. Saved output as fpga_output.jpg")
