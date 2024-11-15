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

present=$(date +"%Y%m%d")

success_dir=$1/successful_tests
success_bin_dir=$1/successful_tests/bin
success_ucdb_dir=$1/successful_tests/ucdbs

prev_failing_dir=$1/previously_failed_tests
prev_failing_bin_dir=$1/previously_failed_tests/bin
prev_failing_ucdb_dir=$1/previously_failed_tests/ucdbs

compl_regress_size=$2
small_regress_size=$3

regressions_dir=$1/regression
compl_regress_dir=${regressions_dir}/complete
compl_regress_bin_dir=${compl_regress_dir}/bin
compl_regress_ucdb_dir=${compl_regress_dir}/ucdbs
small_regress_dir=${regressions_dir}/small
small_regress_bin_dir=${small_regress_dir}/bin
small_regress_ucdb_dir=${small_regress_dir}/ucdbs
compl_output_dir=${compl_regress_dir}/complete_ranktest
small_output_dir=${small_regress_dir}/small_ranktest

function check_dirs_exist {

    for dir in \
                $1 $success_dir $success_bin_dir $success_ucdb_dir $regressions_dir \
                $compl_regress_dir $compl_regress_bin_dir $compl_regress_ucdb_dir   \
                $small_regress_dir $small_regress_bin_dir $small_regress_ucdb_dir   \
                $prev_failing_dir $prev_failing_bin_dir $prev_failing_ucdb_dir $TMP_REGR_DIR
    do
        if [ ! -d "$dir" ]; then
            echo "Directory $dir does not exist."
            exit 1
        fi

    done
}

tmp_dir=${TMP_REGR_DIR}
if [ ! -d "${tmp_dir}/bin" ]; then
            mkdir -p ${tmp_dir}/bin \
            mkdir -p ${tmp_dir}/ucdbs
fi
tmp_bin_dir=${tmp_dir}/bin
tmp_ucdb_dir=${tmp_dir}/ucdbs

ranktest_file="ranktest.fewest"

function blend_bin_ucdbs {
    echo "Test binaries and UCDBs are going to be moved to ${tmp_dir}"

    cp -rp ${regressions_dir} ${root_directory}/archive/regression_${present}

    cp -rp ${success_dir} ${root_directory}/archive/success_dir_${present}

    mv ${success_bin_dir}/* ${tmp_bin_dir}/ || true
    mv ${success_ucdb_dir}/* ${tmp_ucdb_dir}/ || true

    cp ${compl_output_dir}/bin/* ${tmp_bin_dir}/ || true
    cp ${compl_output_dir}/ucdbs/*.ucdb ${tmp_ucdb_dir}/ || true

    cp ${small_output_dir}/bin/* ${tmp_bin_dir}/ || true
    cp ${small_output_dir}/ucdbs/*.ucdb ${tmp_ucdb_dir}/ || true

    cp ${prev_failing_bin_dir}/* ${tmp_bin_dir}/ || true
    cp ${prev_failing_ucdb_dir}/*.ucdb ${tmp_ucdb_dir}/ || true
}

check_dirs_exist
blend_bin_ucdbs
