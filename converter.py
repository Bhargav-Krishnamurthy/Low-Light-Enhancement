import cv2

# 1. Load and resize
img = cv2.imread("input.jpg")
img_small = cv2.resize(img, (256, 256))

# 2. Convert to RGB color space
img_rgb = cv2.cvtColor(img_small, cv2.COLOR_BGR2RGB)

# 3. Save as 24-bit hex
with open("image_hex.txt", "w") as f:
    for row in img_rgb:
        for pixel in row:
            r, g, b = pixel
            # Format as a single 6-character hex string (e.g., FF0088)
            f.write(f"{r:02X}{g:02X}{b:02X}\n")

print("Created 256x256 RGB test image: image_hex.txt")