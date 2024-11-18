#include <stdint.h>
extern volatile uint32_t tohost;
// Function prototype for the custom instruction
static inline uint32_t rgb2yub(uint32_t rgb) {
    uint32_t yub;
    // Use inline assembly to perform the custom instruction
    //asm volatile("rgb2yub %0, %1, t0\n":"=r"(yub):"r"(rgb):);
	//https://sourceware.org/binutils/docs/as/RISC_002dV_002dFormats.html
	//R type: 	  .insn r opcode7, 	func3, 	func7, 	rd,	rs1,	rs2
    asm volatile(".insn r 0x0B, 0, 0, %0, %1, x0" : "=r"(yub) : "r"(rgb));
    return yub;
}

int main() {
    uint8_t red = 0xFF;   // Example red component
    uint8_t green = 0x80; // Example green component
    uint8_t blue = 0x40;  // Example blue component

    // Pack the RGB components into a single 32-bit variable
    uint32_t rgb = (red & 0xFF) << 16 | (green & 0xFF) << 8 | (blue & 0xFF);

    // Call the custom instruction with the packed RGB value
    uint32_t yub = rgb2yub(rgb); //result should be 0x4CC07B

    // Finish test by writing YUB value to tohost
    tohost = yub; // Example output mechanism for debugging

    return 0;
}

//In order to compile this test and run in Spike:
// in the tests folder, a simple `make` should do.
// in the Spike folder:
// ./compile.sh -b debug
// ./build/spike -d ../tests/test.exe 
// or:
// ./build/spike --isa=RV64IMAFD -m0x40000000:0x3FC0000000,0x100:0xff00 --reset-vector=0x1FFFF80000 --mboot-main-id-val=1 --bootrom-file=../core-uvm/bootrom/build/bootrom.bin -d ../tests/test.exe 
