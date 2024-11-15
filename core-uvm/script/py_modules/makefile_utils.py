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
    make_args.append('GUI=0')
    make_args.append('ASSERT=' + ("enable" if args.assertions else  "disable"))
    if args.coverage:
        make_args.append('COVERAGE=enable')
        make_args.append('UCDB_PATH='+ output_folder + '/cov.ucdb')
    if output_folder:
        make_args.append('SIM_TRANSCRIPT_FILE=' + output_folder + '/sim_transcript')
        make_args.append('SPIKE_TRANSCRIPT_FILE=' + output_folder + '/spike_transcript')

    return make_args


