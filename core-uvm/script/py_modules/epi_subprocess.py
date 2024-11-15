#!/usr/bin/env python3
import gitlab
import sys
import os
import json
import datetime
import argparse
import tarfile
import time
from pathlib import Path
import shutil
import urllib.request, urllib.error
import tempfile
import logging
from collections import namedtuple
import subprocess
from threading import Timer

SYS_EXIT_SUCC = 0
SYS_EXIT_FAIL = 1

CmdResult = namedtuple('CmdResult', 'cmd exit_code errfile outfile output exec_time')

def run_cmd(cmd, timeout_s=999999, e_msg="", return_exit_code=False, outfiles=None):
    """ Executes the command passed as argument

    Args:
        cmd     : String with the command to execute
        e_msg   : Error message to display
        timeout : Timeout to recieve the cmd output
        outfiles: Path to a file, this file is divided into .out and .err
    """

    errfile = None
    outfile = None

    exec_time = 0.0
    ret = 0
    ps = None
    output = None

    if outfiles:
        fd_out = open("{}.out".format(outfiles),"w+")
        fd_err = open("{}.err".format(outfiles),"w+")
        outfile = fd_out
        errfile = fd_err
    else:
        fd_out = subprocess.PIPE
        fd_err = subprocess.STDOUT

    logging.debug("    - " + cmd)
    ps = subprocess.Popen("exec " + cmd,
                            shell=True,
                            executable='/bin/bash',
                            universal_newlines=True,
                            stdout=fd_out,
                            stderr=fd_err,
                            bufsize=-1)
    timer = Timer(timeout_s, ps.kill)

    try:
        timer.start()
        if not outfiles:
            with ps.stdout:
                output = ps.stdout.read()

        pid, ret, ru = os.wait4(ps.pid, 0)
        ret = ret >> 8
        exec_time = ru.ru_utime + ru.ru_stime
    except subprocess.CalledProcessError:
        logging.info(ps.communicate()[0])
        sys.exit(SYS_EXIT_FAIL)

    except KeyboardInterrupt:
        logging.info("\nExited Ctrl-C from user request")
        ps.kill()
        sys.exit(SYS_EXIT_SUCC)
    finally:
        timer.cancel()

    if return_exit_code and ret != 0:
        logging.error("\tCommand " + cmd + "\nreturned exit code: " + str(ret))
        sys.exit(SYS_EXIT_FAIL)


    return CmdResult(cmd=cmd, exit_code=ret, errfile=errfile, outfile=outfile, output=output, exec_time=exec_time)

