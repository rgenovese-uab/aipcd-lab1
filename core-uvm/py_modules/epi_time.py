#!/usr/bin/env python3

from datetime import timedelta, datetime
import re

seconds_per_unit = {"s": 1, "m": 60, "h": 3600, "d": 86400, "w": 604800}

def is_formatted(s):
    regex = r'((\d+[s,m,h,d,w])((-\d+[s,m,h,d,w]-)?(-\d+[s,m,h,d,w]))*)'
    match = re.match(regex, s)

    if match is None or match.group() != s:
        return False

    return True

def convert_to_seconds(s):
    try:
        val = seconds_per_unit[s[-1]]
    except:
        raise Exception("Argument -d is not well formatted")

    return int(s[:-1]) * seconds_per_unit[s[-1]]

def str_to_delta(arg):

    if not is_formatted(arg):
        raise Exception("Argument -d is not well formatted")

    parts = arg.split('-')
    units = 0

    delta = timedelta()

    for elem in parts:
        delta = delta + timedelta(seconds=convert_to_seconds(elem))

    return delta

def date_to_str(date, format="%Y_%m_%d_%H_%M_%S"):
    return date.strftime(format)

def get_now():
    return datetime.now()
