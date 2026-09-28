with open("reciprocal.mem", "w") as f:
    for den in range(4096):
        if den == 0:
            val = 0 # Avoid divide by zero
        else:
            # Calculate (255 * 65536) / den to match the >> 16 shift in Verilog
            val = min(int((255 * 65536) / den), 65535)
            
        # Write strictly as a 4-character hex string (16-bit)
        f.write(f"{val:04X}\n")