#!/bin/bash

PATH_KA_CORE=$PWD
TESTS_PATH="${PATH_KA_CORE}/tests/build/generated_tests"
PATH_SUCCESS_TESTS="/eda/verification/ka-uvm-core/random_tests/successful_tests"
PATH_FAILED_TESTS="/eda/verification/ka-uvm-core/random_tests/failed_tests"
if [ ! -d "PATH_SUCCESS_TESTS" ]; then
mkdir -p $PATH_SUCCESS_TESTS/bin
mkdir -p $PATH_SUCCESS_TESTS/ucdbs
fi
if [ ! -d "PATH_FAILED_TESTS" ]; then
mkdir -p $PATH_FAILED_TESTS/bin
mkdir -p $PATH_SUCCESS_TESTS/ucdbs
fi

cd ${PATH_KA_CORE}/regress/results/ka_random_check/
ls -F | grep \/$ > list_tests1.txt
awk '{gsub("/", "");print}' list_tests1.txt > list_tests.txt
rm list_tests1.txt
while read line_tests; do
    TEST_NAME=$line_tests
    if [ -f "${TEST_NAME}/report.yaml" ]; then
       grep "cause: SUCCESS" ${TEST_NAME}/report.yaml >& /dev/null
       if [ $? == 0 ]; then
	  cp  ${TESTS_PATH}/${TEST_NAME} ${PATH_SUCCESS_TESTS}/bin/
         # cp ${TEST_NAME}/${TEST_NAME}.ucdb  ${PATH_SUCCESS_TESTS}/ucdbs/
       else
          cp  ${TESTS_PATH}/${TEST_NAME} ${PATH_FAILED_TESTS}/bin/
         # cp ${TEST_NAME}/${TEST_NAME}.ucdb  ${PATH_FAILED_TESTS}/ucdbs/
       fi
    else
       echo "report.yaml file does'nt exist"
    fi
done < list_tests.txt
