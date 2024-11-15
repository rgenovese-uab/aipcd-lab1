
###############################################################################
# Build disassembler
#
DPI_DASM_PKG=$(VERIF)/lib/dpi_dasm/
DPI_DASM_SPIKE_PKG=${DPI_DASM_PKG}/riscv-isa-sim/

DPI_DASM_SRC    = $(DPI_DASM_PKG)/dpi_dasm.cxx  $(DPI_DASM_SPIKE_PKG)/disasm/regnames.cc ${DPI_DASM_SPIKE_PKG}/disasm/disasm.cc
DPI_DASM_ARCH   = $(shell uname)$(shell getconf LONG_BIT)
DPI_DASM_LIB_PKG= $(DPI_DASM_PKG)/lib/$(DPI_DASM_ARCH)/
DPI_DASM_LIB    = $(DPI_DASM_PKG)/lib/$(DPI_DASM_ARCH)/libdpi_dasm.so
DPI_DASM_CFLAGS = -shared -fPIC -std=c++11
DPI_DASM_INC    = -I$(DPI_DASM_PKG) -I$(DPI_INCLUDE) -I$(DPI_DASM_SPIKE_PKG)/riscv -I$(DPI_DASM_SPIKE_PKG)/softfloat
DPI_DASM_CXX    = g++

dpi_dasm: $(DPI_DASM_SPIKE_PKG)
	@mkdir -p ${DPI_DASM_LIB_PKG}
	$(DPI_DASM_CXX) $(DPI_DASM_CFLAGS) $(DPI_DASM_INC) $(DPI_DASM_SRC) -o $(DPI_DASM_LIB)

###############################################################################
