#!/bin/bash

echo "Start compilation"

#set -e
cd coremark

# Compile coremark ------------------------------
# Configuration: 
# DFLOAT -- floating-point support
# Define to 1 if the platform supports floating point.
# DITERATIONS -- Number of iterations.

riscv64-unknown-elf-gcc -mcmodel=medany   \
 -static -std=gnu99 -O2 -ffast-math       \
 -mbranch-cost=6 -faggressive-loop-optimizations -funroll-loops\
 -ffast-math \
 -nostdlib -nostartfiles                  \
 -fno-common -fno-builtin-printf          \
 -fno-tree-loop-distribute-patterns       \
 -fvisibility=hidden                      \
 -march=rv64g -mabi=lp64                  \
 -I./scalar                               \
 -I./common                               \
 -T./common/test.ld                       \
 -D__BENCH=0                              \
 -DFLAGS_STR=0                            \
 -DITERATIONS=10                          \
 -DFLOAT=0                                \
 core_list_join.c core_main.c core_matrix.c core_state.c core_util.c  \
 core_portme.c ./common/pmu.c ./common/syscalls.c ./common/crt.S -o coremark.riscv  
#-------------------------------------------------

cp coremark.riscv ../
rm coremark.riscv 
cd ..
echo " coremark.riscv has been created."

#dump 
riscv64-unknown-elf-objdump \
 --disassemble-all --disassemble-zeroes --section=.text \
 --section=.text.startup --section=.text.init --section=.data \
 coremark.riscv > coremark.riscv.dump 
echo " coremark.riscv.dump has been created."



