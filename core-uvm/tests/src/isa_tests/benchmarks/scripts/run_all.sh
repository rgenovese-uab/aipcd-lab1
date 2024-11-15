#!/bin/bash

echo "*** Run Benchmarks ***"
echo "------------------------"
echo "    "

./bsort_run.sh    >  /scratch/neiel_leyva/pmu_test/bsort.log    &
./fibo_run.sh     >  /scratch/neiel_leyva/pmu_test/fibo.log     &
./matrix_run.sh   >  /scratch/neiel_leyva/pmu_test/matrix.log   &
./median_run.sh   >  /scratch/neiel_leyva/pmu_test/median.log   &
./multiply_run.sh >  /scratch/neiel_leyva/pmu_test/multiply.log &      
./qsort_run.sh    >  /scratch/neiel_leyva/pmu_test/qsort.log    &
./rsort_run.sh    >  /scratch/neiel_leyva/pmu_test/rsort.log    &
./spmv_run.sh     >  /scratch/neiel_leyva/pmu_test/spmv.log     &
./towers_run.sh   >  /scratch/neiel_leyva/pmu_test/towers.log   &
./vvadd_run.sh    >  /scratch/neiel_leyva/pmu_test/vvadd.log    &
wait


echo "    "
echo "---- end --- "
