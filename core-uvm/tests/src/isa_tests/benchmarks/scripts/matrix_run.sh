#!/bin/bash
 
./refactor_bin/DefaultConfig-sim +max-cycles=100000000 \
 +load=matrix_mult.riscv \
 > /scratch/neiel_leyva/pmu_test/matrix_mem.log
