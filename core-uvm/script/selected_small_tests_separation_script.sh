#!/bin/bash

PATH_KA_DV=$PWD
TESTS_DIR="/eda/verification/lagarto-ka-dv/random_tests/regression/small/small_ranktest/bin"
TESTS_PATH="/eda/verification/lagarto-ka-dv/random_tests/regression/small"
PATH_SUCCESS_TESTS="${TESTS_PATH}/successful_tests"
PATH_FAILED_TESTS="${TESTS_PATH}/failed_tests"
if [ ! -d "PATH_SUCCESS_TESTS" ]; then mkdir -p $PATH_SUCCESS_TESTS
fi
if [ ! -d "PATH_FAILED_TESTS" ]; then mkdir -p $PATH_FAILED_TESTS
fi
cd ${PATH_KA_DV}/regress/results/ka_selected_small_tests/
ls -F | grep \/$ > list_tests1.txt
awk '{gsub("/", "");print}' list_tests1.txt > list_tests.txt
rm list_tests1.txt
while read line_tests; do
    TEST_NAME=$line_tests
    if [ -f "${TEST_NAME}/report.yaml" ]; then
       grep "cause: SUCCESS" ${TEST_NAME}/report.yaml >& /dev/null
       if [ $? == 1 ]; then
          cp  ${TESTS_DIR}/${TEST_NAME} ${PATH_FAILED_TESTS}/
       else
          cp  ${TESTS_DIR}/${TEST_NAME} ${PATH_SUCCESS_TESTS}/
       fi
    else
       echo "file does'nt exit"
    fi
done < list_tests.txt
while read line_tests; do
    TEST_NAME=$line_tests
    if [ -f "${TEST_NAME}/cov.ucdb" ]; then
       mv ${TEST_NAME}/cov.ucdb ${TEST_NAME}/${TEST_NAME}.ucdb
    else
       echo "UCDB file doesn't exists"
    fi
    if [ -f "${TEST_NAME}/${TEST_NAME}.ucdb" ]; then
       cp ${TEST_NAME}/${TEST_NAME}.ucdb  ${TESTS_PATH}/ucdbs/
    else
       echo "UCDB file doesn't exists"
    fi
done < list_tests.txt
