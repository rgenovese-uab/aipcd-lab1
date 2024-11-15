// Extract RGB values from rs1
uint8_t R = RS1 & 0xFF;               // Bits [7:0]
uint8_t G = (RS1 >> 8) & 0xFF;        // Bits [15:8]
uint8_t B = (RS1 >> 16) & 0xFF;       // Bits [23:16]

// Perform RGB to YUV conversion
uint8_t Y = (uint8_t)(0.299 * R + 0.587 * G + 0.114 * B);
uint8_t U = (uint8_t)(0.492 * (B - Y) + 128); // Add 128 for unsigned range
uint8_t V = (uint8_t)(0.877 * (R - Y) + 128); // Add 128 for unsigned range

// Pack YUV back into a 32-bit word
uint32_t YUV = (Y) | (U << 8) | (V << 16);

// Write result to rd
WRITE_RD(YUV);