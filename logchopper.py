import math

# 1. Generate Log LUT (Strictly 12-bit = 3 Hex Digits)
with open("log_values.mem", "w") as f:
    for i in range(256):
        val = int(1.5 * math.log2(1 + i) * 256)
        # Clamp to 4095 (0xFFF) to guarantee it never exceeds 12 bits
        val = min(val, 4095)
        f.write(f"{val:03X}\n")

# 2. Generate Reciprocal LUT (Strictly 16-bit = 4 Hex Digits)
with open("reciprocal.mem", "w") as f:
    f.write("0000\n") # 4 zeros for the first line
    for i in range(1, 4096):
        # Clamp to 65535 (0xFFFF) to guarantee it never exceeds 16 bits
        val = min(int((255 * 65536) / i), 65535) 
        f.write(f"{val:04X}\n")