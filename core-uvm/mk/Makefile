SHELL = /bin/bash
WAVE_FILE = wave_test_test.do

PREFIX = questa 2019.10
SIMDIR = $(VERIF)/sim

ifeq ($(SARGANTANA), enable)
CORE_TYPE = sargantana
$(info Note that core type used in now indicated with CORE_TYPE={sargantana|lagarto_ka})
endif

# Default core_type: change to ox later
CORE_TYPE ?= lagarto_ka
ifeq ($(CORE_TYPE),sargantana)
RTLDIR ?= $(VERIF)/rtl/sargantana_core
export HPDCACHE_DIR=${RTLDIR}/rtl/dcache
else ifeq ($(CORE_TYPE), lagarto_ka)
RTLDIR ?= $(VERIF)/rtl/lagarto_ka-tile
else ifeq ($(CORE_TYPE), lagarto_ox)
$(error Lagarto_ox still unsupported)
else
$(error Unknown core type $(CORE_TYPE) or CORE_TYPE not set)
endif
$(info Compiling core-uvm for type $(CORE_TYPE))

UVMTDIR = $(VERIF)/tb/uvmt
DUTDIR = $(VERIF)/tb/dut
ENVDIR = $(VERIF)/env/
WORKDIR = $(SIMDIR)/build/work
COVE_DIR = $(SIMDIR)/build/covhtmlreport/
COMP_TRANSCRIPT_FILE ?= $(SIMDIR)/build/comp_transcript
SIM_TRANSCRIPT_FILE ?= $(SIMDIR)/build/sim_transcript
SPIKE_TRANSCRIPT_FILE ?= $(SIMDIR)/build/spike_transcript
UCDB_FILE ?= $(SIMDIR)/build/*.ucdb
WLF_FILE ?= $(SIMDIR)/build/*.wlf
DBG_FILE ?= $(SIMDIR)/build/*.dbg
YML_FILE ?= $(SIMDIR)/build/report.yaml
TRANS_FILE ?= $(SIMDIR)/build/transcript
VENDIR = $(VERIF)/vendor/
OUTPUT_DIR ?= $(SIMDIR)/build/
BOOTROM_BIN ?= $(VERIF)/bootrom/build/bootrom.bin
RESET_VECTOR ?= 0x1000
export DTB_PATH = $(VERIF)/vendor/spike/lib/dtb.dat

ASSERT ?=disable
COVERAGE ?=disable
INTERRUPTS ?=disable
HIT_MISS_RAND ?=enable
ADDR_SPACE ?=0x40000000:0x3FC0000000,0x100:0xff00
SPIKE_COMMITLOG ?= disable
SIM ?= questasim
UVM_VERBOSITY ?= UVM_LOW

## Filelists
ifeq ($(CORE_TYPE), sargantana)
export rtlfilelist = $(RTLDIR)/dc_filelist.f
export incdirfilelist = $(VERIF)/tb/dut/incdir-sargantana.flist
export tbfilelist = $(VERIF)/tb/dut/dut-sargantana.flist
export targetuvmfilelist = $(VERIF)/tb/uvmt/uvmt-sargantana.flist
export targetenvfilelist = $(VERIF)/env/uvme-sargantana.flist
else ifeq ($(CORE_TYPE), lagarto_ka)
export rtlfilelist = $(DUTDIR)/rtl-ka.flist
export incdirfilelist = $(VERIF)/tb/dut/incdir-ka.flist
export tbfilelist = $(VERIF)/tb/dut/dut-ka.flist
export targetuvmfilelist = $(VERIF)/tb/uvmt/uvmt-ka.flist
export targetenvfilelist = $(VERIF)/env/uvme-ka.flist
export BSC_IP = $(KA_TILE_RTL_DIR)/vpu/
endif
export coreuvmfilelist = $(VERIF)/tb/uvmt/uvmt-core.flist
export coreenvfilelist = $(VERIF)/env/uvme-core.flist

ifeq ($(ASSERT),enable)
	VLOG_FLAGS := $(VLOG_FLAGS) -define "ASSERT"
	VSIM_FLAGS := $(VSIM_FLAGS) -assertcounts -assertdebug
endif

ifeq ($(COVERAGE),enable)
	VLOG_FLAGS := $(VLOG_FLAGS) -define "COVERAGE"
endif

ifeq ($(INTERRUPTS),enable)
	VLOG_FLAGS := $(VLOG_FLAGS) -define "INTERRUPTS"
endif

ifeq ($(HIT_MISS_RAND),enable)
	VLOG_FLAGS := $(VLOG_FLAGS) -define "HIT_MISS_RAND"
endif

ifeq ($(RISCV_TESTS),enable)
	VLOG_FLAGS := $(VLOG_FLAGS) -define "RISCV_TESTS"
endif

ifeq ($(BOOT_ROM),enable)
	VLOG_FLAGS := $(VLOG_FLAGS) -define "BOOT_ROM"
endif

ifeq ($(WAVES),enable)
	VLOG_FLAGS := $(VLOG_FLAGS) -define "WAVES"
endif

# Target specific flags, variables and commands
ifeq ($(CORE_TYPE), sargantana)
	VLOG_FLAGS := $(VLOG_FLAGS) -define "SARGANTANA" -define "SIM_COMMIT_LOG" -define "HPDC"
	## Enforce vregfile initialization to 0
	VSIM_FLAGS += -voptargs="+initmem=rb+0+vregfile/registers"
	UVM_TESTNAME = sargantana_bin_test
	FILELIST_FIX = echo "No Filelist Fix needed for Sargantana"
	SPIKE_VERSION = master_bsc
else ifeq ($(CORE_TYPE), lagarto_ka)
	VLOG_FLAGS := $(VLOG_FLAGS) -define "LAGARTO_KA"
	VLOG_FLAGS := $(VLOG_FLAGS) -define "PERTE_PROJECT" -define "CONF_SARGANTANA_ENABLE_PCR"
	UVM_TESTNAME = ka_bin_test
	FILELIST_FIX = @echo $(addprefix $(RTLDIR)/, $(shell sed '' $(RTLDIR)/filelist.f)) > $(DUTDIR)/rtl.flist
	SPIKE_VERSION = master_bsc_cincoranch
endif

ifeq ($(OPENPITON_UVM),enable)
	VLOG_FLAGS := $(VLOG_FLAGS) -define "OPENPITON_UVM"
endif

all: compile_all run

include $(VERIF)/mk/tools/git.mk
include $(VERIF)/mk/tools/custom.mk
include $(VERIF)/mk/tools/utils.mk
include $(VERIF)/mk/tools/disasm.mk
include $(VERIF)/mk/uvmt/uvmt.mk

filelist:
	$(FILELIST_FIX)

.PHONY: all run

compile_all: filelist
	@mkdir -p $(VERIF)/sim/build
	make bootrom.bin
	@${VLOG} ${VLOG_FLAGS} -f $(VERIF)/mk/targets/comp_all.flist &> ${COMP_TRANSCRIPT_FILE}

run:
	@${VSIM} ${VSIM_FLAGS} +UVM_TESTNAME=${UVM_TESTNAME} top_tb > ${SIM_TRANSCRIPT_FILE} 2> ${SPIKE_TRANSCRIPT_FILE}

clean:
	rm -rf $(VWORK) ${COVE_DIR}
	rm -rf vsim.wlf certe_dump.xml stdout.txt tr_db.log vsim.dbg
	rm -f $(TRANSCRIPT_FILE) $(SIM_TRANSCRIPT_FILE) $(UCDB_FILE) $(WLF_FILE) $(DBG_FILE) $(COMP_TRANSCRIPT_FILE) $(YML_FILE) $(TRANS_FILE) $(SPIKE_TRANSCRIPT_FILE)
