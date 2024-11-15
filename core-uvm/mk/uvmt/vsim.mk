PREFIX = questa 2022.4

SIM = questasim

UCDB_PATH ?= ${WORKDIR}/../${TESTNAME}.ucdb
WLF_PATH ?= ${WORKDIR}/../${TESTNAME}.wlf

# Executables
VLIB                    = vlib
VMAP                    = vmap
VLOG                    = $(CV_SIM_PREFIX) vlog
VOPT                    = $(CV_SIM_PREFIX) vopt
VSIM                    = $(CV_SIM_PREFIX) vsim
VISUALIZER              = $(CV_TOOL_PREFIX) visualizer
VCOVER                  = vcover

# Paths
VWORK                   = $(WORKDIR)
VSIM_RESULTS           ?= $(if $(CV_RESULTS),$(CV_RESULTS)/vsim_results,$(MAKE_PATH)/vsim_results)
VSIM_COV_MERGE_DIR     ?= $(VSIM_RESULTS)/$(CFG)/merged
UVM_HOME               ?= $(abspath $(shell which $(VLIB))/../../verilog_src/uvm-1.2/src)
DPI_INCLUDE            ?= $(abspath $(shell which $(VLIB))/../../include)
USES_DPI = 1

#
# # Default flags
VSIM_USER_FLAGS         ?=
VOPT_COV                ?= +cover=bcestf
VOPT_WAVES_ADV_DEBUG    ?= -designfile design.bin
VSIM_WAVES_ADV_DEBUG    ?= -qwavedb=+signal+assertion+ignoretxntime+msgmode=both
VSIM_WAVES_DO           ?= $(VSIM_SCRIPT_DIR)/waves.tcl
VSIM_COV                ?= -coverage +cover=bcestf -toggleportsonly




# VLOG (compile)
SRAM_DEFINE = BSC_SRAM_RTL #should be adapted for GLS and different technologies.
export VLOG_FLAGS+=+define+${SRAM_DEFINE}
VLOG_FLAGS        += +define+STANDALONE
VLOG_FLAGS        += -modelsimini $(VERIF)/mk/uvmt/vsim/modelsim.ini
VLOG_FLAGS        += +acc=rn
VLOG_FLAGS        += -vopt
VLOG_FLAGS        += -svinputport=compat
VLOG_FLAGS        += -work $(VWORK)
VLOG_FLAGS        += -timescale "1ns/1ps"
VLOG_FLAGS        += $(QUIET)
VLOG_FLAGS        += +cover=bcestf

# VSIM (simulation)
VSIM_FLAGS        += -modelsimini $(VERIF)/mk/uvmt/vsim/modelsim.ini
VSIM_FLAGS        += -work $(VWORK)
VSIM_FLAGS        += $(VSIM_USER_FLAGS)
VSIM_FLAGS        += $(USER_RUN_FLAGS)
VSIM_FLAGS        += -sv_seed $(RNDSEED)
VSIM_FLAGS        += -l $(SIM_TRANSCRIPT_FILE) -dpicpppath /usr/bin/gcc
VSIM_FLAGS        += -syncio
VSIM_FLAGS        += -nostdout
VSIM_FLAGS        += +UVM_VERBOSITY=${UVM_VERBOSITY}
VSIM_FLAGS	  += -optionset UVMDEBUG

#PK_BIN            :=$(VENDIR)spike/lib/pk
VSIM_FLAGS        += +PK_BIN=$(PK_BIN)
VSIM_FLAGS        += +OUTPUT_DIR=${OUTPUT_DIR}

ifdef TEST
VSIM_FLAGS        += +TEST_BIN=$(TEST)
TESTNAME	  ?= $(shell basename $(TEST))
endif

ifdef BOOTROM_BIN
VSIM_FLAGS        += +BOOTROM_BIN=$(BOOTROM_BIN)
endif

ifdef RESET_VECTOR 
VSIM_FLAGS        += +RESET_VECTOR=$(RESET_VECTOR)
endif

ifdef ADDR_SPACE
VSIM_FLAGS        += +ADDR_SPACE=$(ADDR_SPACE)
endif

ifdef MBOOT_MAIN_ID
VSIM_FLAGS        += +MBOOT_MAIN_ID=$(MBOOT_MAIN_ID)
VSIM_FLAGS        += +BOOT_MAIN_ID=$(MBOOT_MAIN_ID)
endif
#############

ifeq ($(SPIKE_COMMITLOG),enable)
VSIM_FLAGS 		  += +SPIKE_COMMITLOG
endif


################################################################################
# Coverage database generation
ifeq ($(call IS_YES,$(COVERAGE)),YES)
VOPT_FLAGS  += $(VOPT_COV)
VSIM_FLAGS  += $(VSIM_COV)
endif

################################################################################
# Waveform generation
ifeq ($(call IS_YES,$(WAVES)),YES)
ifeq ($(call IS_YES,$(ADV_DEBUG)),YES)
VSIM_FLAGS += $(VSIM_WAVES_ADV_DEBUG)
else
VSIM_FLAGS += -wlfcompress -wlf ${WLF_PATH}
VSIM_FLAGS += -do $(VSIM_WAVES_DO)
endif
endif

ifeq ($(call IS_YES,$(ADV_DEBUG)),YES)
VOPT_FLAGS += $(VOPT_WAVES_ADV_DEBUG)
endif

VSIM_DEBUG_FLAGS  ?= -debugdb
VSIM_GUI_FLAGS    ?= -gui -debugdb
VSIM_SCRIPT_DIR	   = $(abspath $(VERIF)/mk/)

VSIM_UVM_ARGS      = +incdir+$(UVM_HOME)/src $(UVM_HOME)/src/uvm_pkg.sv

ifeq ($(call IS_YES,$(USE_ISS)),YES)
VSIM_FLAGS += +USE_ISS
endif

#VSIM_FLAGS += -sv_lib $(basename $(DPI_DASM_LIB))
VSIM_FLAGS += -sv_lib $(VENDIR)/elfloader/elfloader -sv_lib $(VENDIR)/spike/spike

# Skip compile if requested (COMP=NO)
ifneq ($(call IS_NO,$(COMP)),NO)
VSIM_SIM_PREREQ = comp
endif

VSIM_FLAGS += -do "set NoQuitOnFinish 1"
# Interactive simulation
ifeq ($(call IS_YES,$(GUI)),YES)
ifeq ($(call IS_YES,$(ADV_DEBUG)),YES)
VSIM_FLAGS += -visualizer=+designfile=../design.bin
else
VSIM_FLAGS += -gui -debugdb
endif
else
VSIM_FLAGS += -batch
VSIM_FLAGS += -do "run -all;"
ifeq ($(call IS_YES,$(COVERAGE)),YES)
VSIM_FLAGS += -do "coverage save -assert -testname ${TESTNAME} -directive -cvg -codeAll ${UCDB_PATH};"
endif
VSIM_FLAGS += -do "exit;"
endif

