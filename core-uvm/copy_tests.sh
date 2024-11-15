ka_core_uvm_main=$PWD
mkdir tests/src/generated_tests
cp generated_tests/asm_tests/*.S tests/src/generated_tests
now=$(date +"%Y%m%d")
cd tests/src/generated_tests
ls *.S -v | cat -n | while read n f; do mv -n "$f" $(printf "${now}_%04d.S" ${n}); done
cd $ka_core_uvm_main
