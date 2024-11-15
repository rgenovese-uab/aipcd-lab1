import yaml
import pprint
import argparse
import os
import sys
import subprocess
import re
from collections import defaultdict
from datetime import datetime

regress_path = "regress/"
results_path = "regress/results/"
regress_files = list(filter(lambda n : n.endswith(".yaml") , os.listdir(regress_path)))
test_report = "sim/build/report.yaml"

class Build:
    def __init__(self, args, path, result_dir):
        self.args=args
        self.path=path
        self.result_dir=result_dir

def read_yaml(regress_file):
    """ A function to read YAML file"""
    with open(regress_path + regress_file) as f:
        config = yaml.safe_load(f)
    return config

def write_yaml(data):
    """ A function to write YAML file"""
    with open('toyaml.yml', 'a') as f:
        yaml.dump_all(data, f, default_flow_style=False)

def exclude_tests(tests, regress_config, ignore_exclusion=False):
    total_tests = 0
    total_tests_after_exclude = 0
    excluded_tests = regress_config.get('tests', {}).get('exclude', [])
    excluded_tests_regex = [re.compile(pattern.replace('*', '.*')) for pattern in excluded_tests]
    for key in tests:
        # Remove the prefix "tests/build/rvv//" from each test name
        total_tests += len(tests[key])
        # Exclude tests matching the patterns
        filtered_tests = []
        for test in tests[key]:
            exclude_test = False
            for regex in excluded_tests_regex:
                if regex.search(os.path.basename(test)):
                    if not ignore_exclusion:
                        exclude_test = True
                        print("Excluded test: ", test)
                        break
            if not exclude_test:
                filtered_tests.append(test) # restore path
        tests[key] = filtered_tests
        total_tests_after_exclude += len(tests[key])

    print("Total number of tests before exclusion:", total_tests)
    print("Total number of tests after exclusion:", total_tests_after_exclude)

    return tests

def run_regression(rname, regress_config, ignore_exclusion=False):
    print('Running ' + regress_config['name'])
    print(regress_config['description'])
    rname_results_path = os.path.abspath(results_path) + "/" + regress_config["name"] + "/"
    print('You can find the regression results in the ' + rname_results_path + ' folder')

    if not os.path.exists(results_path):
        os.system('mkdir ' + results_path)

    if not os.path.exists(rname_results_path):
        os.system('mkdir ' + rname_results_path)

    if regress_config["type"] == "build":
        # Compile design
        make_args = [regress_config['builds']['compile-env']['cmd']]
        make_args.extend(regress_config['builds']['compile-env']['args'])
        if args.assertions:
            make_args.append('ASSERT=enable')
        if args.coverage:
            make_args.append('COVERAGE=enable')
        if args.interrupts:
            make_args.append('INTERRUPTS=enable')
        if args.disable_miss:
            make_args.append('HIT_MISS_RAND=disable')
        if args.hit_miss_rand:
            make_args.append('HIT_MISS_RAND=enable')
        if args.piton_lagarto:
            make_args.append('PITON_LAGARTO=enable')
        if args.sargantana:
            make_args.append('CORE_TYPE=sargantana')
        if args.sv39:
            make_args.append('SV39=enable')
        if args.riscv_tests:
            make_args.append('RISCV_TESTS=enable')
        if args.boot_rom:
            make_args.append('BOOT_ROM=enable')
        make_args.append('COMP_TRANSCRIPT_FILE=' + rname_results_path + 'comp_transcript')
        #print( make_args)
        error = subprocess.call(make_args)
        if error != 0: sys.exit("Compilation failed, check compilation results in the " + rname_results_path + "comp_transcript file!")
        else: print("Compilation OK")
    elif regress_config["type"] == "test":

        # Create map
        tests = defaultdict(list)
        if (regress_config['tests']['rtype'] == 'set'):
            for test in sorted(os.listdir(regress_config['tests']['test'])):
                tests[regress_config['tests']['test']].append(regress_config['tests']['test'] + "/" + test)

        elif (regress_config['tests']['rtype'] == 'list'):
            for test in regress_config['tests']['test']:
                tests["user_list"].append(test)

        elif (regress_config['tests']['rtype'] == 'single'):
            tests["user_single"].append(regress_config['tests']['test'])

        else:
            print("\nError: rtype " + regress_config['tests']['rtype'] + " is not supported.")
            sys.exit(1)

        exclude_tests(tests, regress_config, ignore_exclusion)

        # Execute tests
        for key in tests:
            set_path = rname_results_path + os.path.basename(key) + "/"
            regress_results = []
            tableRows = []
            failed_tests = 0
            total_tests = 0
            if not os.path.exists(set_path):
                os.mkdir(set_path)
            for test in tests[key]:
                total_tests += 1
                test_result_path = set_path + os.path.basename(test)
                if not os.path.exists(test_result_path):
                    os.mkdir(test_result_path)

                # Execute test
                start = datetime.now()
                current_time = start.strftime("%H:%M:%S")
                testrun_str = current_time + ' :: Running test ' + os.path.basename(test)
                test_width = 40
                test_width -= len(testrun_str)
                spaces = ''
                for i in range(test_width): spaces = spaces + ' '
                cmd = regress_config['tests']['cmd'].split(' ')
                args.test = test
                make_args = makefile_utils.make_args(args, cmd, test_result_path)
                if 'args' in regress_config['tests']:
                    make_args = make_args + regress_config['tests']['args']
                try:
                    subprocess.run(make_args, timeout=int(args.timeout), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                except subprocess.TimeoutExpired:
                    print(f"The test timeout has expired")

                # Gather, print and save results
                cause = 'REPORT MISSING'
                seed = 0
                pc = ''
                ins = ''
                mnemo = ''
                executed_ins = 0
                executed_interrupts = 0
                finish = datetime.now()
                delay = finish - start
                try:
                    with open(test_report) as f:
                        test_results = yaml.safe_load(f)
                        if test_results and ("cause" in test_results):
                            cause = test_results["cause"]
                            seed = test_results["seed"]
                            ins = hex(test_results['instr']['ins'])
                            pc = hex(test_results['instr']['pc'])
                            mnemo = test_results['instr']['disasm']
                            executed_ins = test_results['instr']['executed_ins']
                            executed_interrupts = test_results['instr']['executed_interrupts']
                            test_results['instr']['ins'] = ins
                            test_results['instr']['pc'] = pc
                            if test_results["cause"] != "SUCCESS":
                                failed_tests += 1
                        else:
                            failed_tests += 1
                            test_results = {}
                            test_results["cause"] = cause
                    os.rename(test_report, test_result_path + '/report.yaml')
                except:
                    failed_tests += 1
                    test_results = {}
                    test_results["cause"] = cause
                try:
                    from termcolor import colored
                except:
                    def colored(pass_msg, color):
                        return pass_msg;
                if cause == 'SUCCESS': passfail = colored('Pass', 'green')
                else: passfail = colored('Fail', 'red')
                delay_msg = " (" + str(round(delay.total_seconds(),2)) + "s)"
                print(testrun_str + spaces + passfail + delay_msg)
                tableRows.append([os.path.basename(test), passfail, cause, pc, mnemo, executed_ins, seed, executed_interrupts])
                test_results = {os.path.basename(test):test_results}
                regress_results.append(test_results)

            # Regression reporting
            set_report = set_path + "report.yaml"
            set_report_file = open(set_report, 'w')
            for report in regress_results:
                yaml.dump(report, set_report_file, default_flow_style=False)

            try:
                from prettytable import PrettyTable
                PTable = PrettyTable();
                PTable.field_names = ["Test", "Status", "Cause", "PC", "Instruction", "Executed instructions", "Seed", "Executed interrupts"]
                PTable.align["Test"] = "l"
                PTable.align["Status"] = "l"
                PTable.align["Cause"] = "l"
                PTable.align["PC"] = "l"
                PTable.align["Instruction"] = "l"
                PTable.align["Executed instructions"] = "l"
                PTable.align["Seed"] = "l"
                PTable.align["Executed interrupts"] = "l"
                for row in tableRows: PTable.add_row(row)
                print(PTable)
            except:
                print("Failed to import prettytable. If you are seeing this message you should install pretty table in python, use:\npip3 install prettytable")
            pass_rate = ((total_tests-failed_tests)/total_tests)*100
            results_msg = str(total_tests-failed_tests) + '/' + str(total_tests) + ' (' + str(round(pass_rate, 2)) + '%)'
            results_msg = results_msg + ' of tests passed.'
            print(results_msg)

        if (args.coverage):
            merged_ucdb = set_path + "merged.ucdb"
            html_dir = set_path + "html_report"
            ucdbs = []
            for root, dirs, files in os.walk(set_path):
                for file in files:
                    if file.endswith(".ucdb"):
                         ucdbs.append(os.path.join(root, file))

            coverage_utils.merge_ucdbs(ucdbs, merged_ucdb)
            if (args.coverage_report_html):
                coverage_utils.generate_html_report(merged_ucdb, html_dir)

        if failed_tests:
            sys.exit('Regression failed, ' + str(failed_tests) + ' tests failed!')
        else:
            print('Regression complete, none of the tests failed!')

if __name__ == "__main__":

    parser = argparse.ArgumentParser(description='Run tests.')
    parser.add_argument('-r', '--regress', dest='regress_yaml', choices=regress_files,
                        help='Type of regressions to be run.')
    parser.add_argument('-t', '--test', dest='test',
                        help='Path of the test to be run')
    parser.add_argument('--gui', action='store_true',
                    help='If specified, the test will be run in graphical mode.')
    parser.add_argument("--assertions", action='store_true',
                        help="Enable assertions")
    parser.add_argument("--coverage", action="store_true",
                        help="Enable coverage collection")
    parser.add_argument("--coverage-report-html", action="store_true",
                        help="Enable coverage report")
    parser.add_argument("--interrupts", action="store_true",
                        help="Enable interrupts")
    parser.add_argument("--disable_miss", action="store_true",
                        help="Disable miss randomization in icache")
    parser.add_argument("--hit_miss_rand", action="store_true",
                        help="Enable hit_miss_rand")
    parser.add_argument("--piton_lagarto", action="store_true",
                        help="compitable with lagarto_hun")
    parser.add_argument("--sargantana", action="store_true",
                        help="compitable with sargantana")
    parser.add_argument("--sv39", action="store_true",
                        help="compitable with sv39")
    parser.add_argument("--riscv_tests", action="store_true",
                        help="related with datapath.sv rtl only for lagarto_hun")
    parser.add_argument("--boot_rom", action="store_true",
                        help="Enable boot rom")
    parser.add_argument('--wave',action="store_true",
                        help='Save waveforms for future reference.')
    parser.add_argument('--seed', default='1',
                        help='For different seed selection. For a random seed, specify "random"')
    parser.add_argument('--timeout', default='1200',
                        help='Timeout for the test in seconds (default: 1200)')
    parser.add_argument("-v", "--uvm-verbosity", type=str, default="UVM_LOW",
                        choices=["UVM_NONE", "UVM_LOW", "UVM_MEDIUM", "UVM_HIGH", "UVM_FULL", "UVM_DEBUG"],
                        help="Indicates the level of verbosity of UVM, default set by this script is UVM_LOW"
                       )
    parser.add_argument("--ignore-exclusion", action="store_true", 
                        help="Ignore exclusion rules")


    args = parser.parse_args();

    sys.path.append("./py_modules/")
    from py_modules import epi_subprocess
    from py_modules import makefile_utils
    from py_modules import coverage_utils

    if args.test:
        print("Running test " + args.test)
        result_dir='sim/build/'
        transcript_args = ['make'] + ['COMP_TRANSCRIPT_FILE=' + result_dir + '/' + 'comp_transcript']
        transcript_args = transcript_args + ['SIM_TRANSCRIPT_FILE=' + result_dir + '/' + 'sim_transcript']
        transcript_args = transcript_args + ['SPIKE_TRANSCRIPT_FILE=' + result_dir + '/' + 'spike_transcript']
        test = Build(transcript_args, args.test, result_dir + '/')
        make_args = makefile_utils.make_args_test(args, test, test.result_dir)
        error = subprocess.call(make_args)
        if error != 0: sys.exit("Compilation failed!")
        else: print("Test finished, check results in sim/build/sim_transcript file.")    

    if args.regress_yaml:
        if args.regress_yaml == 'all':
            for rtype in regress_files:
                regress_config = read_yaml(rtype)
                run_regression(rtype, regress_config, args.ignore_exclusion)
        else:
            regress_config = read_yaml(args.regress_yaml)
            run_regression(args.regress_yaml, regress_config, args.ignore_exclusion)

    if (not args.test and not args.regress_yaml):
        print("You did not specify any test or regression set to run!")
