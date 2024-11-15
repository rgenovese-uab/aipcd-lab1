#!/usr/bin/env python3
import os
import json
import datetime
import argparse
import shutil
import urllib.request
import urllib.error
import tempfile
import logging
import epi_subprocess
import xml.etree.ElementTree as ET
import sys
import re

def merge_ucdbs(in_list, out_path):
    """ Merges a list of UCDBs and leave the tool result
        in the given path.

        Returns the exit code of the executed command

    Args:
        in_list: List of paths to UCDBs
        out_path: Path where the merged UCDB is output
    """

    cmd = " ".join(['vcover', 'merge', '-testassociated', out_path] + in_list)
    cmd_res = epi_subprocess.run_cmd(cmd)
    ecode = cmd_res.exit_code

    if ecode != 0:
        logging.error("Command " + cmd + " finished with exit code " + str(ecode))
        sys.exit(ecode)

    return ecode

def generate_report(in_ucdb, out_path):
    print(in_ucdb)
    print(out_path)
    cmd = " ".join(['vcover', 'report', ' -file', out_path] + in_ucdb)
    cmd_res = epi_subprocess.run_cmd(cmd)

    ecode = cmd_res.exit_code

    if ecode != 0:
        logging.error("Command " + cmd + " finished with exit code " + str(ecode))
        sys.exit(ecode)

    return ecode

def generate_html_report(in_ucdb, out_path):
    print(in_ucdb)
    print(out_path)
    cmd = " ".join([ "vcover", "report", "-html", "-annotate", "-codeAll", "-cvg", "-details", "-binrhs", in_ucdb, "-output" , out_path])
    cmd_res = epi_subprocess.run_cmd(cmd)

    ecode = cmd_res.exit_code

    if ecode != 0:
        logging.error("Command " + cmd + " finished with exit code " + str(ecode))
        sys.exit(ecode)

    return ecode


def analyze_report_xml(in_path):
    if (not os.path.isfile(in_path)):
        return -1

    root = ET.parse(in_path).getroot()

    ### TODO Parsing Code

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

    return ret
