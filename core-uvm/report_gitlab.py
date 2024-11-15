#!/usr/bin/env python3
import gitlab
import sys
import os
import json
import datetime
import argparse
import tarfile
from pathlib import Path
import shutil
import urllib.request, urllib.error
import tempfile
import logging
import yaml
import pytablewriter

"""
Usage report_gitlab.py <folder_with_reports>
"""

PROJECT_NUM = 2277 # KA-UVM-CORE
#PROJECT_NUM = 1290 # RTL
RANDOM_ISSUE_NUM = 23

MINIMUM_INSTR=1000

# {{{ Day Class
class Day:
    def __init__(self):
        self.instructions = 0
        self.full_date = ""
        self.successful_runs = 0
        self.failed_runs = 0
        self.num_run = 0

    @classmethod
    def from_json(cls, json):
        obj = cls()
        obj.instructions= json['instructions']
        obj.full_date=json['full_date']
        obj.successful_runs= json['successful_runs']
        obj.failed_runs=json['failed_runs']
        return obj

# }}}

def read_yaml(report_file):
    """ A function to read YAML file"""
    with open(report_file) as f:
        config = yaml.safe_load(f)
    return config

def get_night_runs(regression):
#    if (regression == "isa"): reports = read_yaml("regress/results/ka_isa_check/report.yaml")
    if (regression == "random"): reports = read_yaml("regress/results/ka_random_check/report.yaml")
    return reports

def make_table(reports, verbosity, regression):

    d = datetime.date.today()

    count=0
    cause=0
    endl="\n\n"
    issue_comment = f"Report day: `{d.day}-{d.month}-{d.year}`\n\n"
    job_id = os.environ["CI_JOB_ID"]
    issue_comment += "Find results and artifacts in: https://gitlab.bsc.es/lagarto/lagarto_ka/verification/ka-uvm-core-main/-/jobs/" + job_id + "\n\n"
    writer = pytablewriter.MarkdownTableWriter()
    writer.header_list = ["Test", "Status", "Cause", "PC", "Instruction", "Executed  instructions"]
    writer.value_matrix = []

    for test in reports:
        test_name = test.replace("_", "\_")
        status = "Pass"
        cause = reports[test]["cause"]
        if cause != "SUCCESS": status = "Fail"
        pc = reports[test]["instr"]["pc"]
        ins = reports[test]["instr"]["disasm"]
        executed_ins = reports[test]["instr"]["executed_ins"]
        if (regression == "random"):
            binary_link = "https://gitlab.bsc.es/lagarto/lagarto_ka/verification/ka-uvm-core-main/-/jobs/" + job_id + "/artifacts/file/tests/build/generated_tests/" + test
            test_name = "[" + test_name + "](" + binary_link + ")"
        if (verbosity == "all"):
            writer.value_matrix.append([test_name, status, cause, pc, ins, executed_ins])
        elif (verbosity == "failing"):
            if (status == "Fail" or (regression == "random" and executed_ins < MINIMUM_INSTR)):
                writer.value_matrix.append([test_name, status, cause, pc, ins, executed_ins])

    issue_comment += writer.dumps()
    return issue_comment

def connect(project_num):
    api_token = os.environ["UVM_CORE_GITLAB_API_TOKEN"]
    gl = gitlab.Gitlab('https://gitlab.bsc.es/', private_token=api_token)
    gl.auth()
    project = gl.projects.get(project_num, lazy=True)
    return project

def publish_table_on_issue(project_num, regression, issue_comment):
    repo = connect(project_num)
 #   if (regression == "isa"): issue_num = ISA_ISSUE_NUM
    if (regression == "random"): issue_num = RANDOM_ISSUE_NUM 
    issue = repo.issues.get(issue_num)
    issue.notes.create({"body": issue_comment})

def merge_ucdbs():
    sys.path.append("./py_modules/")
    from py_modules import epi_subprocess
    from py_modules import coverage_utils
    ucdbs = []
#    ucdbs.append("regress/results/ka_isa_check/merged.ucdb")
    ucdbs.append("regress/results/ka_random_check/merged.ucdb")
    coverage_utils.merge_ucdbs(ucdbs, "regress/results/merged.ucdb")
    coverage_utils.generate_html_report("regress/results/merged.ucdb", "regress/results/html_report")

def main():
    parser = argparse.ArgumentParser(description="Utility to report night results to gitlab")

    parser.add_argument("-t", "--type", type=str, default="decoy",
                        help="Set decoy mode for the script. ")
    parser.add_argument("-v", "--verbosity", type=str, default="all",
                        help="Set verbosity or reporting, display all tests or just failing ones.")
    parser.add_argument("-r", "--regression", type=str, default="random",
                        help="Set type of tests to report, isa, random, complete or small.")
    parser.add_argument("--coverage-report-html", action="store_true",
                        help="Enable merged coverage report")

    args = parser.parse_args()
    reports = get_night_runs(args.regression)
    table = make_table(reports, args.verbosity, args.regression)
    if (args.type == "publish"):
        publish_table_on_issue(PROJECT_NUM, args.regression, table)
    if (len(reports) == 0):
        print("[DEBUG] Something happend really wrong")
    if (args.coverage_report_html):
        merge_ucdbs()
if __name__ == "__main__":
    main()

