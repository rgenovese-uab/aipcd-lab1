#!/bin/bash
 
./refactor_bin/DefaultConfig-sim +max-cycles=100000000 \
 +load=median.riscv \
 > /scratch/neiel_leyva/pmu_test/median_mem.log
