#!/bin/bash
ka_core_uvm_main=$PWD
now=$(date +"%Y%m%d")
mkdir -p tests/build/generated_tests
cp generated_tests/asm_tests/*.o tests/build/generated_tests/
cd tests/build/generated_tests
ls *.o -v | cat -n | while read n f; do
    new_name="$(printf "${now}_%04d" $n)"
    mv -n "$f" "$new_name"
    echo "Renamed $f to $new_name"
done
cd $ka_core_uvm_main
