RISCV_PREFIX ?= riscv64-unknown-elf-
RISCV_GCC ?= $(RISCV_PREFIX)gcc

DHRY-LFLAGS =

DHRY-CFLAGS := -O3 -save-temps -I../common -ffast-math -fno-tree-loop-distribute-patterns
DHRY-CFLAGS += -fno-builtin-printf -fno-common -falign-functions=4
DHRY-CFLAGS += -mbranch-cost=6 -faggressive-loop-optimizations -funroll-loops
DHRY-CFLAGS += -fsplit-loops -fprefetch-loop-arrays -ftree-loop-if-convert 

DHRY-CFLAGS += -DPREALLOCATE=1 -DHOST_DEBUG=0 -mcmodel=medany -static
DHRY-CFLAGS += -std=gnu99 -march=rv64ima -mabi=lp64 ../common/pmu.c ../common/syscalls.c ../common/crt.S -static -nostartfiles -lc -lgcc

#Uncomment below for FPGA run, default DHRY_ITERS is 2000 for RTL
DHRY-CFLAGS += -DDHRY_ITERS=2000

SRC = dhry_1.c dhry_2.c strcmp.S
HDR = dhry.h

override CFLAGS += $(DHRY-CFLAGS) $(XCFLAGS) -T ../common/test.ld
dhrystone: $(SRC) $(HDR)
	$(RISCV_GCC) $(CFLAGS) $(SRC) $(LDFLAGS) $(LOADLIBES) $(LDLIBS) -o $@

clean:
	rm -f *.i *.s *.o dhrystone dhrystone.hex

