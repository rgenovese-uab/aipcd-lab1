#!/usr/bin/env python3
import sys
import os
import tarfile
import logging

SYS_EXIT_FAIL = 1

def create_dir(path):
    """ Helper function to create a directory.

    Args:
        path: Path where the directory should be created
    """
    try:
        os.makedirs(path, exist_ok=True)
    except OSError:
        logging.info("Couldn't create directory {}".format(path))
        sys.exit(SYS_EXIT_FAIL)

def add_file_to_tar(tar, filepath, ignoreError=False):
    """ Adds a file to a tar, if ignoreError is set to True, if the file doesn't exist it
        won't be added and no error will be reported, otherwise a FileNotFoundError exception
        will be raised.

    Args:
        tar: Tar object.
        filepath: Path to the file to add.
        ignoreError: Flag to determine whether errors are ignored or not.
    """

    if os.path.isfile(filepath):
        tar.add(filepath, arcname=os.path.basename(filepath))
    elif not ignoreError:
        raise FileNotFoundError("Couldn't add file " + filepath +  " to tar " + str(tar))
    elif ignoreError:
        logging.debug("Couldn't add file " + filepath + " to tar " + str(tar) + ", error was ignored")

def file_or_fail(file_path):
    """ Function to check if the given path is a file. If not
        it will exit the execution.

    Args:
        file_path: Path to be checked
    """

    if not os.path.isfile(file_path):
        logging.info(f"Couldn't find the file {file_path}")
        sys.exit(SYS_EXIT_FAIL)

    return True


def dir_or_fail(folder_path):
    """ Function to check if the given path is a folder. If not
        it will exit the execution.

    Args:
        folder_path: Path to be checked
    """
    if not os.path.isdir(folder_path):
        logging.info(f"Couldn't find the folder {folder_path}")
        sys.exit(SYS_EXIT_FAIL)

    return True

