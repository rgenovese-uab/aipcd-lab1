#!/bin/bash


echo "Initial Scripts for build-env_hun_core"
make clone_hun_core
cd rtl/vas_tile_core/
source /home/tools/riscv_vector_toolchain/set_env.sh
source piton/lagarto_setup.sh
source piton/lagarto_build_tools.sh
cd build
rm -rf manycore
sims -sys=manycore -x_tiles=1 -y_tiles=1 -msm_build -lagarto -config_rtl=BSC_RTL_SRAMS -config_rtl=FPU_ZAGREB
cd ../../../
cp vas_tile_core_Makefile rtl/vas_tile_core/piton/design/chip/tile/vas_tile_core/Makefile
make -C rtl/vas_tile_core/piton/design/chip/tile/vas_tile_core/ filelist
cp script/csr_interface.sv rtl/vas_tile_core/piton/design/chip/tile/vas_tile_core/modules/drac-inorder/rtl/datapath/rtl/interface_csr/rtl/csr_interface.sv
