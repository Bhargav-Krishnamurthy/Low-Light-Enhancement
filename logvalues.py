import math

with open("log_values.mem", "w") as f:
    for i in range(256):
        value = int(1.5 * math.log2(1 + i) * 256)
        f.write(f"{value}\n")

print("log_values.mem generated successfully.")
