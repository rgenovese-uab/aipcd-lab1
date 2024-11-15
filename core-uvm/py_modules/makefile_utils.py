import os
import json
import datetime
import argparse
import shutil
import urllib.request
import urllib.error
import tempfile
import logging
import subprocess

def make_args(args, target = "", output_folder = ""):
    make_args = target
    make_args.append('TEST=' + args.test)
    make_args.append('TESTNAME='+os.path.basename(args.test))
    make_args.append('GUI=0')
    make_args.append('ASSERT=' + ("enable" if args.assertions else  "disable"))
    make_args.append('SEED=' + args.seed )
    make_args.append('UVM_VERBOSITY=' + args.uvm_verbosity)
    if args.coverage:
        make_args.append('COVERAGE=enable')
        make_args.append('UCDB_PATH='+ output_folder + '/cov.ucdb')
    if output_folder:
        make_args.append('SIM_TRANSCRIPT_FILE=' + output_folder + '/sim_transcript')
    return make_args

def make_args_test(args, test, output_folder = ""):
    make_args = test.args
    make_args.append('TEST=' + args.test)
    make_args.append('TESTNAME='+os.path.basename(args.test))
    make_args.append('GUI='+ ("1" if args.gui else  "0"))
    make_args.append('ASSERT=' + ("enable" if args.assertions else  "disable"))
    make_args.append('SEED=' + args.seed )
    make_args.append('UVM_VERBOSITY=' + args.uvm_verbosity)
    if args.coverage:
        make_args.append('COVERAGE=enable')
        make_args.append('UCDB_PATH='+ output_folder + '/' + os.path.basename(args.test) + '.ucdb')
    if args.wave:
        make_args.append('WAVES=enable')
        make_args.append('WLF_PATH='+ output_folder + '/' + os.path.basename(args.test) + '.wlf')    
    if args.interrupts:
        make_args.append('INTERRUPTS=enable')
    if args.hit_miss_rand:
        make_args.append('HIT_MISS_RAND=enable')
    if args.riscv_tests:
        make_args.append('RISCV_TESTS=enable')
    if args.piton_lagarto:
        make_args.append('PITON_LAGARTO=enable')
    if args.boot_rom:
        make_args.append('BOOT_ROM=enable')
    if output_folder:
        make_args.append('SIM_TRANSCRIPT_FILE=' + output_folder + '/sim_transcript')
    if (args.spike_commitlog and output_folder):
        make_args.append('SPIKE_TRANSCRIPT_FILE=' + output_folder + '/spike_transcript')

    print(make_args)
    return make_args

