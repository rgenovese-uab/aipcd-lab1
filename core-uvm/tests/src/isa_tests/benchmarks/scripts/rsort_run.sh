#!/bin/bash
 
./refactor_bin/DefaultConfig-sim +max-cycles=100000000 \
 +load=rsort.riscv \
 > /scratch/neiel_leyva/pmu_test/rsort_mem.log
