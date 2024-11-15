#!/usr/bin/env python3

"""
Title: rankfile_parser

Project: EPI Vector Lane

Language: Python

Description: TODO
"""

import os
import sys
import shutil
import logging
import argparse
import re
#from py_modules import epi_gitlab
#from py_modules import epi_subprocess
from py_modules import os_utils
from py_modules import coverage

levels = {
    'critical': logging.CRITICAL,
    'error': logging.ERROR,
    'warning': logging.WARNING,
    'info': logging.INFO,
    'debug': logging.DEBUG
}

def process_arguments():

    parser = argparse.ArgumentParser(description="Options to rankfile_parser")

    parser.add_argument("-r", "--rankfile", type=str, required=True,
                        help="Path to the rankfile to be parsed."
                        )
    parser.add_argument("-b", "--binaries", type=str, required=True,
                        help="Path to the directory where binaries are."
                        )
    parser.add_argument("-u", "--ucdbs", type=str, required=True,
                        help="Path to the directory where ucdbs are."
                        )
    parser.add_argument("-o", "--output", type=str, required=True,
                        help="Path to the directory where subset is created."
                        )
    parser.add_argument("-n", "--n-tests", type=int,
                        help="Path to the directory where subset is created."
                        )
    parser.add_argument("--verbosity-level", type=str, default="info", choices=levels.keys(),
                        help="Debug mode"
                        )

    args = parser.parse_args()

    return args

def deserialize_rankfile(path):
    """
        Given the path to a rankfile, returns the list of ranked tests in the given order.

        Args:
            - path : Path to the rankfile.
    """

    """
        Please, note that the following code will only work for the versions of
        vcover that have the style:

        Rank   TotalCov  Testname
        -----  --------  ----------------------------------------------------------------------------------------------------
            1     45.45  A
            2     47.83  B

        Ending with something different than a number (indicating that the Rank rows have finished)
    """

    if not os.path.isfile(path):
        logging.error("Provided path doesn't lead to a file")
        sys.exit(1)

    start_regex = re.compile('[\-]+[ ]+[\-]+[ ]+[\-]+')
    end_regex = re.compile('^((?![0-9]+)).*')

    insideTests = False
    rankedTests = []
    coverageTests = []
    iterator = 0

    fd = open(path, "r")
    contents = fd.read()

    for line in contents.splitlines():

        if insideTests:

            rankedline = ' '.join(line.split()).split(' ')

            line_wout_spaces = ' '.join(rankedline)

            if end_regex.match(line_wout_spaces):
                insideTests = False
                break

            try:
                logging.debug(rankedline)
                if len(rankedline) == 3:
                    # Case where a test is ranked
                    int(rankedline[0])
                    rankedTests.append(rankedline[2])
                    coverageTests.append(float(rankedline[1]))
                    iterator = iterator + 1
                elif len(rankedline) == 1:
                    # Case where the actual line belongs to the test above
                    rankedTests[iterator-1] = rankedTests[iterator-1] + rankedline[0]
                elif len(rankedline) > 3:
                    insideTests = False
                    break
                else:
                    logging.error("Something went wrong while parsing vcover output")
                    sys.exit(1)

            except ValueError:
                logging.error("Something went wrong while parsing vcover output")
                sys.exit(1)

        if start_regex.match(line):
            insideTests = True

    fd.close()

    ret = [x for _,x in sorted(zip(coverageTests, rankedTests), reverse=False)]

    logging.debug("Ranked tests are: " + str(rankedTests))

    print (rankedTests, coverageTests)

    return ret


def main(args):

    # Extract ranked tests


    ranked_tests = []
    if os.path.isfile(args.rankfile):
        ranked_tests = deserialize_rankfile(args.rankfile)

    if len(ranked_tests) <= 0:
        logging.error("No test could be extracted from " + args.rankfile + " exiting.")
        sys.exit(1)

    logging.debug("Ranked tests: " + str(ranked_tests))

    max_tests = sys.maxsize
    if args.n_tests:
        max_tests = args.n_tests

    dst_ucdb_dir = os.path.join(args.output, "ucdbs")
    dst_bin_dir = os.path.join(args.output, "bin")

    os_utils.create_dir(args.output)
    os_utils.create_dir(dst_ucdb_dir)
    os_utils.create_dir(dst_bin_dir)
    os_utils.dir_or_fail(args.binaries)
    os_utils.dir_or_fail(args.ucdbs)

    cpd_tests = 0

    logging.debug("Copying binaries into " + args.output + "/bin")

    logging.debug("ARGS.BINARIES IS "+args.binaries)

    for file_ in ranked_tests:
        file_path = os.path.join(args.binaries, file_ )
        if os_utils.file_or_fail(file_path):
            shutil.copy(file_path, os.path.join(dst_bin_dir, file_ ))
        cpd_tests += 1
        if cpd_tests >= max_tests: break

    logging.debug("Copying ucdbs into " + args.output + "/ucdbs")
    logging.debug("ARGS.OUTPUT IS "+args.output)

    cpd_tests = 0

    for file_ in ranked_tests:
        file_path = os.path.join(args.ucdbs, file_ + ".ucdb")
        if os_utils.file_or_fail(file_path):
            shutil.copy(file_path, os.path.join(dst_ucdb_dir, file_ + ".ucdb"))
        cpd_tests += 1
        if cpd_tests >= max_tests: break

if __name__ == "__main__":

    args = process_arguments()

    verbosity_level = levels[args.verbosity_level]

    FORMAT = '%(asctime)s :: %(levelname)-8s :: %(message)s'
    logging.basicConfig(format=FORMAT, level=verbosity_level)

    main(args)

    sys.exit(0)

