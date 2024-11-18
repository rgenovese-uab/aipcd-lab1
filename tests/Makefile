RISCV_GCC ?= riscv64-unknown-elf-gcc
RISCV_OBJDUMP ?= riscv64-unknown-elf-objdump
RISCV_OBJCOPY ?= riscv64-unknown-elf-objcopy
PYTHON ?= python3

FLAGS = -I include/ -Wall -march=rv64imafd -mabi=lp64d -static -mcmodel=medany -nostdlib -nostartfiles
#FLAGS = -I include/ -Wall -march=rv64gcv -mabi=lp64d -static -mcmodel=medany -ffunction-sections -fdata-sections -fvisibility=hidden -nostdlib -nostartfiles -Wl,--gc-sections -g
OBJ_FLAGS = -D
#OBJ_FLAGS = -S #--disassemble-all --disassemble-zeroes

RISCV_LINK_OPTS ?= -static -nostdlib -nostartfiles -lc -lgcc -T link.ld

# ADD TEST NAMES HERE
bmarks = \
	test \

all: $(bmarks)
	:

%: 
	echo $@
	$(RISCV_GCC) $(FLAGS) startup.S $(wildcard include/*.c) $(wildcard include/*.S) $(wildcard ./$@.S) $(wildcard ./$@.c) -o $@.exe $(RISCV_LINK_OPTS)
	$(RISCV_OBJDUMP) $(OBJ_FLAGS) $@.exe > $@.dump

clean:
	rm -rf *.exe *.bin *.dump
