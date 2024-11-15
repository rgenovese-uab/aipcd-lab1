#!/bin/bash
 
./refactor_bin/DefaultConfig-sim +max-cycles=100000000 \
 +load=qsort.riscv \
 > /scratch/neiel_leyva/pmu_test/qsort_mem.log
