#!/bin/bash
 
./refactor_bin/DefaultConfig-sim +max-cycles=100000000 \
 +load=spmv.riscv \
 > /scratch/neiel_leyva/pmu_test/spmv_mem.log
