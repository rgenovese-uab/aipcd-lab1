#!/bin/bash

PATH_KA_DV=$PWD
RETRY_TESTS_PATH="/eda/verification/lagarto-ka-dv/random_tests/failed_tests/"
RETRY_SUCCESS_TESTS="/eda/verification/lagarto-ka-dv/random_tests/successful_tests"
PREV_FAILED_TESTS="/eda/verification/lagarto-ka-dv/random_tests/previously_failed_tests"
if [ ! -d "RETRY_SUCCESS_TESTS" ]; then
mkdir -p $RETRY_SUCCESS_TESTS/bin
mkdir -p $RETRY_SUCCESS_TESTS/ucdbs
fi
if [ ! -d "PREV_FAILED_TESTS" ]; then
mkdir -p $PREV_FAILED_TESTS/bin
mkdir -p $PREV_FAILED_TESTS/ucdbs
fi
cd ${PATH_KA_DV}/regress/results/ka_random_failed_tests/
ls -F | grep \/$ > list_tests1.txt
awk '{gsub("/", "");print}' list_tests1.txt > list_tests.txt
rm list_tests1.txt
while read line_tests; do
    TEST_NAME=$line_tests
    if [ -f "${TEST_NAME}/cov.ucdb" ]; then
       mv ${TEST_NAME}/cov.ucdb ${TEST_NAME}/${TEST_NAME}.ucdb
    else
       echo "UCDB file doesn't exists"
    fi
done < list_tests.txt
while read line_tests; do
    TEST_NAME=$line_tests
    if [ -f "${TEST_NAME}/report.yaml" ]; then
       grep "cause: SUCCESS" ${TEST_NAME}/report.yaml >& /dev/null
       if [ $? == 0 ]; then
          cp ${RETRY_TESTS_PATH}/bin/${TEST_NAME} ${PREV_FAILED_TESTS}/bin/
          cp ${TEST_NAME}/${TEST_NAME}.ucdb  ${PREV_FAILED_TESTS}/ucdbs/
          mv  ${RETRY_TESTS_PATH}/bin/${TEST_NAME} ${RETRY_SUCCESS_TESTS}/bin/
          mv ${TEST_NAME}/${TEST_NAME}.ucdb  ${RETRY_SUCCESS_TESTS}/ucdbs/
        else
          echo "Test:${TEST_NAME} failed"
       fi
    else
       echo "report.yaml file does'nt exist"
    fi
done < list_tests.txt
