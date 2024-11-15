#!/bin/bash
 
./refactor_bin/DefaultConfig-sim +max-cycles=100000000 \
 +load=bubblesort.riscv \
 > /scratch/neiel_leyva/pmu_test/bsort_mem.log
 

