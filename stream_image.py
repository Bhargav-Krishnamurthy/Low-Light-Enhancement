import cv2
import numpy as np
import serial
import time
import os
import glob

BAUD_RATE = 115200
IMAGE_PATH = 'dark_image.jpg'
CHUNK_PIXELS = 256  # Send 1 row (768 bytes) per transfer block to prevent OS overrun

def find_fpga_port():
    # Check by-id path first
    by_id_paths = glob.glob('/dev/serial/by-id/*if01-port0')
    if by_id_paths:
        return by_id_paths[0]
    
    # Fallback to standard ttyUSB ports
    usb_ports = glob.glob('/dev/ttyUSB*')
    if usb_ports:
        return sorted(usb_ports)[-1]
        
    return '/dev/ttyUSB1'

def main():
    if not os.path.exists(IMAGE_PATH):
        print(f"Error: '{IMAGE_PATH}' not found in current directory!")
        return

    # 1. Read & Prepare Image
    img = cv2.imread(IMAGE_PATH)
    img_256 = cv2.resize(img, (256, 256))
    rgb_img = cv2.cvtColor(img_256, cv2.COLOR_BGR2RGB)
    raw_bytes = rgb_img.tobytes()
    total_bytes = len(raw_bytes)

    port_name = find_fpga_port()
    print(f"Target Port: {port_name}")
    print(f"Sending 256x256 image ({total_bytes} bytes) at {BAUD_RATE} baud...")

    # 2. Open Serial Port
    try:
        ser = serial.Serial(port_name, BAUD_RATE, timeout=5)
        time.sleep(1.5)
        ser.reset_input_buffer()
        ser.reset_output_buffer()
    except Exception as e:
        print(f"Failed to open serial port {port_name}: {e}")
        return

    # 3. Stream in Paced Chunks
    received_data = bytearray()
    chunk_bytes_size = CHUNK_PIXELS * 3
    start_time = time.time()

    for offset in range(0, total_bytes, chunk_bytes_size):
        chunk = raw_bytes[offset:offset + chunk_bytes_size]
        ser.write(chunk)
        
        # Read back processed chunk
        response = ser.read(len(chunk))
        received_data.extend(response)
        
        # Print progress bar
        progress = (len(received_data) / total_bytes) * 100
        print(f"\rProgress: [{int(progress):3d}%] {len(received_data)}/{total_bytes} bytes", end="")

    elapsed = time.time() - start_time
    print(f"\nCompleted in {elapsed:.2f} seconds ({total_bytes / elapsed / 1024:.2f} KB/s).")
    ser.close()

    # 4. Handle Partial or Full Frame Output
    if len(received_data) < total_bytes:
        print(f"Warning: Received {len(received_data)} / {total_bytes} bytes. Padding missing bytes with 0.")
        received_data.extend(b'\x00' * (total_bytes - len(received_data)))

    # 5. Reconstruct RGB Matrix and Display
    out_buf = np.frombuffer(received_data[:total_bytes], dtype=np.uint8)
    out_rgb = out_buf.reshape((256, 256, 3))
    out_bgr = cv2.cvtColor(out_rgb, cv2.COLOR_RGB2BGR)

    comparison = np.hstack((img_256, out_bgr))
    cv2.imshow("Left: Low-Light Input | Right: FPGA Enhanced Output", comparison)
    cv2.imwrite("fpga_enhanced_output.jpg", out_bgr)
    print("Output saved as 'fpga_enhanced_output.jpg'. Press any key on image window to exit.")
    cv2.waitKey(0)
    cv2.destroyAllWindows()

if __name__ == '__main__':
    main()
