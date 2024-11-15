#!/bin/bash

PATH_KA_DV=$PWD
THRESHOLD_VALUE=500
verification_data_path="/eda/verification/lagarto-ka-dv/random_tests"
complete_regr_set_size=200
small_regr_set_size=20
TMP_DIR=`mktemp -d`
TESTS_PATH="/eda/verification/lagarto-ka-dv/random_tests/successful_tests"
TESTS_NUM=`ls ${TESTS_PATH}/bin/ | wc -l`
echo "Number of tests in ${TESTS_PATH}/bin is ${TESTS_NUM}"
if [[ ${TESTS_NUM} -lt ${THRESHOLD_VALUE} ]]; then
   echo "Number of tests in ${TESTS_PATH} is below the threshold" 
   exit 1
else
   echo "Number of tests in ${TESTS_PATH} is above the threshold"
fi

echo "Start execution if no of tests are above threshold" 
#source /eda/mentor/mentor.sh
#source /eda/mentor/lic_mentor_epi.sh
if [[ ${THRESHOLD_VALUE} -le ${TESTS_NUM} ]]; then
	export TMP_REGR_DIR="${TMP_DIR}" 
        TIMESTAMP=$(date +"%Y_%m_%d") 
        REGR_COPY=${verification_data_path}/${TIMESTAMP}_regressions
fi

echo "checking folder structure exists or not"
if [ ! -d ${verification_data_path}/regression ]; then 
        mkdir -p ${verification_data_path}/regression 
        mkdir -p ${verification_data_path}/regression/complete 
        mkdir -p ${verification_data_path}/regression/complete/bin 
        mkdir -p ${verification_data_path}/regression/complete/ucdbs 
        mkdir -p ${verification_data_path}/regression/small 
        mkdir -p ${verification_data_path}/regression/small/bin 
        mkdir -p ${verification_data_path}/regression/small/ucdbs 
else
	echo "regression directory already exists"
fi
			
echo "Now executing copy_regression_sets_creation.sh script"	 
./script/copy_regression_sets_creation.sh ${verification_data_path} ${complete_regr_set_size} ${small_regr_set_size}
if [[ ${THRESHOLD_VALUE} -le ${TESTS_NUM} ]]; then 
                                    export TMP_REGR_DIR="${TMP_DIR}"
                                    ./script/regression_sets_creation.sh ${verification_data_path} ${complete_regr_set_size} ${small_regr_set_size} 
fi
