#!/bin/bash


RISCV_VEC_TOOL_VER=rvv-0.7.1
#RISCV_VEC_TOOL=/opt/riscv-vector-toolchain/$RISCV_VEC_TOOL_VER
#RISCV_VEC_TOOL=/opt/riscv-vector-toolchain/
#RISCV_VEC_TOOL=/users/pahuja/Desktop/$RISCV_VEC_TOOL_VER
RISCV_VEC_TOOL=/opt/riscv-gnu-toolchain/$RISCV_VEC_TOOL_VER

export RISCV=$RISCV_VEC_TOOL

export PATH=$RISCV/bin:$PATH
