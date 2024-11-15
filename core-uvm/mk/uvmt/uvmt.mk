
# "Constants"
DATE           = $(shell date +%F)
CV_CORE_LC     = $(shell echo $(CV_CORE) | tr A-Z a-z)
CV_CORE_UC     = $(shell echo $(CV_CORE) | tr a-z A-Z)
SIMULATOR_UC   = $(shell echo $(SIMULATOR) | tr a-z A-Z)
export CV_CORE_LC
export CV_CORE_UC

# Useful commands
MKDIR_P = mkdir -p

# Compile compile flags for all simulators (careful!)
WAVES        ?= 0
SV_CMP_FLAGS ?= "+define+$(CV_CORE_UC)_ASSERT_ON"
TIMESCALE    ?= -timescale 1ns/1ps
UVM_PLUSARGS ?=

# User selectable SystemVerilog simulator targets/rules
CV_SIMULATOR ?= vsim
SIMULATOR    ?= $(CV_SIMULATOR)

# Optionally exclude the OVPsim (not recommended)
USE_ISS      ?= YES

# Common configuration variables
CFG             ?= default

###############################################################################
# Seed management for constrained-random sims
SEED    ?= 1
RNDSEED ?=

ifeq ($(SEED),random)
RNDSEED = $(shell date +%N)
else
ifeq ($(SEED),)
# Empty SEED variable selects 1
RNDSEED = 1
else
RNDSEED = $(SEED)
endif
endif


# Include the targets/rules for the selected SystemVerilog simulator
#ifeq ($(SIMULATOR), unsim)
#include unsim.mk
#else
ifeq ($(SIMULATOR), dsim)
include $(VERIF)/mk/uvmt/dsim.mk
else ifeq ($(SIMULATOR), xrun)
include $(VERIF)/mk/uvmt/xrun.mk
else ifeq ($(SIMULATOR), vsim)
include $(VERIF)/mk/uvmt/vsim.mk
else ifeq ($(SIMULATOR), vcs)
include $(VERIF)/mk/uvmt/vcs.mk
else ifeq ($(SIMULATOR), riviera)
include $(VERIF)/mk/uvmt/riviera.mk
else ifeq ($(SIMULATOR), verilator)
include $(VERIF)/mk/uvmt/verilator.mk
else
include $(VERIF)/mk/uvmt/unsim.mk
endif
