#!/bin/bash
 
./refactor_bin/DefaultConfig-sim +max-cycles=100000000 \
 +load=vvadd.riscv \
 > /scratch/neiel_leyva/pmu_test/vvadd_mem.log
