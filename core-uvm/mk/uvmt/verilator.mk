# Verilator binary
VERILATOR := verilator
ifdef VERILATOR_ROOT
VERILATOR := $(VERILATOR_ROOT)/bin/verilator
endif

# Compilation options
SIM_NAME ?= core-uvm
SIM_DIR := $(VERIF)/sim/build/$(SIM_NAME)-sim
COMPILE_ARGS += --cc --exe --main --timing -Mdir $(SIM_DIR)
COMPILE_ARGS += -fno-gate
COMPILE_ARGS += --prefix $(SIM_NAME) -o $(SIM_NAME)
COMPILE_ARGS += -f $(VERIF)/mk/targets/comp_all.flist
EXTRA_ARGS += --timescale 1ns/1ps
WARNING_ARGS += -Wno-lint \
	-Wno-style \
	-Wno-SYMRSVDWORD \
	-Wno-IGNOREDRETURN \
	-Wno-CONSTRAINTIGN \
	-Wno-ZERODLY
