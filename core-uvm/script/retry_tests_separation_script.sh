#!/bin/bash

PATH_KA_DV=$PWD
TESTS_PATH="${PATH_KA_DV}/tests/build/generated_tests"
PATH_SUCCESS_TESTS="${TESTS_PATH}/successful_tests"
PATH_FAILED_TESTS="${TESTS_PATH}/failed_tests"
mkdir -p $PATH_SUCCESS_TESTS
mkdir -p $PATH_FAILED_TESTS
cd ${PATH_KA_DV}/regress/results/ka_random_check/
ls -F | grep \/$ > list_tests1.txt
awk '{gsub("/", "");print}' list_tests1.txt > list_tests.txt
rm list_tests1.txt
while read line_tests; do
    TEST_NAME=$line_tests
    if [ -f "${TEST_NAME}/report.yaml" ]; then
       grep "cause: SUCCESS" ${TEST_NAME}/report.yaml >& /dev/null
       if [ $? == 1 ]; then
          cp  ${TESTS_PATH}/${TEST_NAME} ${PATH_FAILED_TESTS}/
       else
	  cp  ${TESTS_PATH}/${TEST_NAME} ${PATH_SUCCESS_TESTS}/
       fi
    else
       echo "file does'nt exit"
    fi
done < list_tests.txt

