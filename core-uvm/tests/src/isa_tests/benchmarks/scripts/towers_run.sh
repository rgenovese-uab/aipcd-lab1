#!/bin/bash
 
./refactor_bin/DefaultConfig-sim +max-cycles=100000000 \
 +load=towers.riscv \
 > /scratch/neiel_leyva/pmu_test/towers_mem.log
