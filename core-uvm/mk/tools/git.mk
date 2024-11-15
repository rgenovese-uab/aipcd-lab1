CV_KA_TILE_NAME    ?= lagarto_ka-tile
CV_KA_TILE_REPO    ?= git@gitlab-internal.bsc.es:hwdesign/rtl/core-tile/lagarto_ka-tile.git
CV_SARGANTANA_NAME ?= sargantana_core
CV_SARGANTANA_REPO ?= git@gitlab-internal.bsc.es:hwdesign/rtl/core-tile/sargantana_tile.git
CV_KA_TILE_BRANCH  ?= main
CV_SARGANTANA_BRANCH ?= main
CV_KA_TILE_TAG     ?= master
CV_SARGANTANA_TAG  ?= none
CV_KA_TILE_PKG     ?= ${VERIF}/rtl/${CV_KA_TILE_NAME}
CV_SARGANTANA_PKG  ?= ${VERIF}/rtl/${CV_SARGANTANA_NAME}
TESTS_PATH	   ?= ${PROJECT_PATH}/tests
TESTS_PACKAGE_NAME ?= rvv1.0-epacx
TESTS_TAR_NAME ?= rvv1.0-epacx
TESTS_URL ?= https://gitlab.bsc.es/api/v4/projects/2107/packages/generic/${TESTS_PACKAGE_NAME}/0.0.1/${TESTS_TAR_NAME}.tar.gz
SPIKE_PATH_BASE	   ?= $(PROJECT_PATH)/vendor/spike/spike
SPIKE_VERSION      ?= master_bsc
SPIKE_URL_BASE	   ?= https://gitlab.bsc.es/api/v4/projects/1982/packages/generic/$(SPIKE_VERSION)/0.0.1/spike
SPIKE_PATH         ?= $(SPIKE_PATH_BASE).so
SPIKE_PATH_INFO    ?= $(SPIKE_PATH_BASE).info
SPIKE_URL 	       ?= $(SPIKE_URL_BASE).so
SPIKE_URL_INFO     ?= $(SPIKE_URL_BASE).info
SELECTED_TESTS_PATH ?= ${TESTS_PATH}/build/
SELECTED_TESTS_URL ?= https://gitlab.bsc.es/api/v4/projects/2277/packages/generic/random_selection_$(CORE_TYPE)/0.0.1/random_selection_$(CORE_TYPE).tar.gz

ifeq ($(CI)$(SPIKE_TOKEN),) 
ifneq ("$(wildcard $(PROJECT_PATH)/mk/tools/package_download_tokens.mk)","")
include $(PROJECT_PATH)/mk/tools/package_download_tokens.mk
endif
else ifeq ($(CI)$(TESTS_TOKEN),)
ifneq ("$(wildcard $(PROJECT_PATH)/mk/tools/package_download_tokens.mk)","")
include $(PROJECT_PATH)/mk/tools/package_download_tokens.mk
endif
endif

ifdef SPIKE_TOKEN
SPIKE_HEADER = PRIVATE-TOKEN: ${SPIKE_TOKEN}
else ifdef CI_JOB_TOKEN
SPIKE_HEADER = JOB-TOKEN: ${CI_JOB_TOKEN}
endif

ifdef TESTS_TOKEN
TESTS_HEADER  = PRIVATE-TOKEN: ${TESTS_TOKEN}
else ifdef CI_JOB_TOKEN
TESTS_HEADER  = JOB-TOKEN: ${CI_JOB_TOKEN}
endif

ifdef SELECTED_TESTS_TOKEN
SELECTED_TESTS_HEADER  = PRIVATE-TOKEN: ${SELECTED_TESTS_TOKEN}
else ifdef CI_JOB_TOKEN
SELECTED_TESTS_HEADER  = JOB-TOKEN: ${CI_JOB_TOKEN}
endif

ifeq ($(SARGANTANA),enable)
export DESIGN_RTL_DIR ?= ${CV_SARGANTANA_PKG}
else
export KA_TILE_DIR ?= ${CV_KA_TILE_PKG}
export KA_TILE_RTL_DIR ?= ${CV_KA_TILE_PKG}/rtl
export DESIGN_RTL_DIR ?= ${KA_TILE_RTL_DIR}/lagarto_ka
endif

clone_ka_tile:
	git clone ${CV_KA_TILE_REPO} ${CV_KA_TILE_PKG} -b ${CV_KA_TILE_TAG} --recurse-submodules -j 4

update_ka_tile:
	git --git-dir ${CV_KA_TILE_PKG}/.git pull --recurse-submodules -j 4

clone_sargantana_core:
	git clone ${CV_SARGANTANA_REPO} ${CV_SARGANTANA_PKG} -b ${CV_SARGANTANA_BRANCH} --recurse-submodules

update_sargantana_core:
	git --git-dir ${CV_SARGANTANA_PKG}/.git pull --recurse-submodules -j 4
clone_tests:
ifdef TESTS_HEADER
	echo $(TESTS_PATH)
	echo $(PROJECT_PATH)
	mkdir -p $(TESTS_PATH)/build
	wget -nv -O $(TESTS_PATH)/build/${TESTS_TAR_NAME}.tar.gz --header="${TESTS_HEADER}" $(TESTS_URL)
	tar -xvf $(TESTS_PATH)/build/${TESTS_TAR_NAME}.tar.gz -C $(TESTS_PATH)/build/
	rm $(TESTS_PATH)/build/${TESTS_TAR_NAME}.tar.gz
else ifeq ("$(wildcard $(TESTS_PATH)/build)","") # If folder doesn't exist
	$(info Set variable TESTS_TOKEN or download from $(TESTS_URL) and uncompress it in $(TESTS_PATH)/build pah)
	exit -1
else
	$(info TESTS_TOKEN not set, but $(TESTS_PATH)/build/ already exists. Not downloading)
endif

clone_selected_tests:
ifdef SELECTED_TESTS_HEADER
ifneq ("$(wildcard $(SELECTED_TESTS_PATH))","")
	true
endif
	mkdir -p $(SELECTED_TESTS_PATH)
	wget -nv -O $(SELECTED_TESTS_PATH)/random_selection_$(CORE_TYPE).tar.gz --header="${SELECTED_TESTS_HEADER}" $(SELECTED_TESTS_URL)
	cd $(SELECTED_TESTS_PATH); tar -xvf ./random_selection_$(CORE_TYPE).tar.gz; mv -f *.info ../; rm ./random_selection_$(CORE_TYPE).tar.gz
	cd ${PROJECT_PATH}
else ifeq ("$(wildcard $(SELECTED_TESTS_PATH))","") # If folder doesn't exist
	$(info Set variable SELECTED_TESTS_TOKEN or download from $(SELECTED_TESTS_URL) and uncompress it in $(SELECTED_TESTS_PATH))
	exit -1
else
	$(info SELECTED_TESTS_TOKEN not set, but $(SELECTED_TESTS_PATH) already exists. Not downloading)
endif

clone_spike:
ifdef SPIKE_HEADER
	mkdir -p $(dir $(SPIKE_PATH))
	wget -nv -O $(SPIKE_PATH) --header="${SPIKE_HEADER}" $(SPIKE_URL)
	wget -nv -O $(SPIKE_PATH_INFO) --header="${SPIKE_HEADER}" $(SPIKE_URL_INFO)
else ifeq ("$(wildcard $(SPIKE_PATH))","") # If folder doesn't exist
	$(info Set variable SPIKE_TOKEN or download from $(SPIKE_URL))
	exit -1
else
	$(info SPIKE_TOKEN not set, but spike.so already in $(SPIKE_PATH) Not downloading)
endif

clean_rtl:
	rm -rf rtl/*
