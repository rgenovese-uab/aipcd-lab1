#!/bin/bash
 
./refactor_bin/DefaultConfig-sim +max-cycles=100000000 \
 +load=multiply.riscv \
 > /scratch/neiel_leyva/pmu_test/multiply_mem.log
