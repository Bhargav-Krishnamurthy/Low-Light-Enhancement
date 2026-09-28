import numpy as np
import cv2

WIDTH = 256
HEIGHT = 256

with open("output_hex.txt", "r") as f:
    hex_lines = f.readlines()

pixels = []
for line in hex_lines:
    if line.strip():
        # Parse the 24-bit hex value
        val = int(line.strip(), 16)
        
        # Bitwise shift to extract R, G, and B
        r = (val >> 16) & 0xFF
        g = (val >> 8) & 0xFF
        b = val & 0xFF
        pixels.append([r, g, b])

# Reshape into a 3D array (HEIGHT, WIDTH, 3 channels)
expected_pixels = WIDTH * HEIGHT
if len(pixels) == expected_pixels:
    img_array = np.array(pixels, dtype=np.uint8).reshape((HEIGHT, WIDTH, 3))
    
    # OpenCV requires BGR color order for saving and displaying
    img_bgr = cv2.cvtColor(img_array, cv2.COLOR_RGB2BGR)
    
    cv2.imwrite("hardware_simulated_rgb.jpg", img_bgr)
    print("Saved hardware_simulated_rgb.jpg")
else:
    print(f"Error: Expected {expected_pixels} pixels, got {len(pixels)}")