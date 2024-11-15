#!/bin/bash -xe

# $1 root_directory
# $2 complete_regression_set_size
# $3 small_regression_set_size

root_directory="/eda/verification/lagarto-ka-dv/random_tests"

if [[ $# -ne 3 ]]; then
    echo "Usage: ./regressions_set_creation <root_directory> <complete_regression_set_size> <small_regression_set_size>"
    exit 1
fi


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

success_dir=$1/successful_tests
success_bin_dir=$1/successful_tests/bin
success_ucdb_dir=$1/successful_tests/ucdbs

compl_regress_size=$2
small_regress_size=$3

regressions_dir=$1/regression
compl_regress_dir=${regressions_dir}/complete
compl_output_dir=${compl_regress_dir}/complete_ranktest
compl_regress_bin_dir=${compl_regress_dir}/bin
compl_regress_ucdb_dir=${compl_regress_dir}/ucdbs
small_regress_dir=${regressions_dir}/small
small_output_dir=${small_regress_dir}/small_ranktest
small_regress_bin_dir=${small_regress_dir}/bin
small_regress_ucdb_dir=${small_regress_dir}/ucdbs

tmp_dir=$TMP_REGR_DIR
#if [ ! -d "${tmp_dir}/bin" ]; then
#            mkdir -p ${tmp_dir}/bin \
#            mkdir -p ${tmp_dir}/ucdbs
#fi
tmp_bin_dir=${tmp_dir}/bin
tmp_ucdb_dir=${tmp_dir}/ucdbs

function check_dirs_exist {
    for dir in \
                $1 $tmp_dir $tmp_bin_dir $tmp_ucdb_dir $compl_regress_dir \
                $compl_regress_bin_dir $compl_regress_ucdb_dir $compl_regress_dir \
                $compl_regress_bin_dir $compl_regress_ucdb_dir $regressions_dir
    do
        if [ ! -d "$dir" ]; then
            echo "Directory $dir does not exist."
            exit 1
        fi

    done
}

function rm_bin_ucdbs {
    echo "Test binaries and UCDBs are going to be removed..."

    rm -f ${compl_output_dir}/bin/*
    rm -f ${compl_output_dir}/ucdbs/*.ucdb

    rm -f ${small_output_dir}/bin/*
    rm -f ${small_output_dir}/ucdbs/*.ucdb

}

ranktest_file="ranktest.fewest"

function rank_tests() {
    ucdbs=$(ls -d ${tmp_ucdb_dir}/*)

    if [ -z "$ucdbs" ]; then
        echo "Directory ${tmp_ucdb_dir} contained no UCDB. Exiting..."
        exit 1
    fi

    vcover ranktest -j 32 -fewest -maxtests ${compl_regress_size} -testassociated ${ucdbs} -logfile ${ranktest_file} -suppress 6820,6821,6854,6814
}

check_dirs_exist
rank_tests
rm_bin_ucdbs

python3 $SCRIPT_DIR/rankfile_parser.py \
    -r ${ranktest_file} \
    -o ${compl_output_dir} \
    -b ${tmp_bin_dir} \
    -u ${tmp_ucdb_dir} \
    -n ${compl_regress_size} \
    --verbosity-level debug

python3 $SCRIPT_DIR/rankfile_parser.py \
    -r ${ranktest_file} \
    -o ${small_output_dir} \
    -b ${tmp_bin_dir} \
    -u ${tmp_ucdb_dir} \
    -n ${small_regress_size} \
    --verbosity-level debug
