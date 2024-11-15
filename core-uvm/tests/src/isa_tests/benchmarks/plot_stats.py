#!/usr/bin/env python3

import sys
import os
import matplotlib.pyplot as plt
import pandas as pd
from math import nan

metrics = ['IPC'] # metrics to be calculated from raw counters
plot_metrics = ['INSTRUCTION-COUNTER', 'IPC'] # including raw counters and calculated metrics

def main(argv):
    args = parse_args(argv)
    benchmarks = parse_benchmark_list(args['bench_list_file'])
    print(benchmarks)

    stats = []
    for bench in benchmarks:
        bench_stats = parse_benchmark_stats(os.path.join(args['artifacts_dir'], bench + '.core.log'))
        bench_stats['benchmark'] = bench
        stats.append(bench_stats)

    df = pd.DataFrame(stats)
    calculate_metrics(df)
    df.to_csv(os.path.join(args['artifacts_dir'], 'stats.csv'))
    plot(df, args['artifacts_dir'])
    print(df)


def calculate_metrics(df):
    for metric in metrics:
        metric_function = globals().get('calculate_metric_' + metric)
        if metric_function:
            df[metric] = metric_function(df)
        else:
            print('Function {} not implemented'.format('calculate_metric_' + metric))
            df[metric] = nan


def calculate_metric_IPC(df):
    return 1.0 * df['INSTRUCTION-COUNTER'] / df['NUMBER-OF-EXEC-CYCLES']


def parse_benchmark_list(bench_file):
    with open(bench_file, 'r') as f:
        lines = f.readlines()
    return [b.strip() for b in lines]


def plot(df, out_dir):
    for plot_metric in plot_metrics:
        df.plot.bar(x='benchmark', y=plot_metric)
        plt.savefig(os.path.join(out_dir, plot_metric + '.pdf'), pad_inches=0, bbox_inches='tight')


def parse_benchmark_stats(log_file):
    try:
        with open(log_file, 'r') as f:
            lines = f.readlines()
    except:
        print('Error reading file ' + log_file)
        return {}
    stats = {}
    for line in lines:
        if '-PMU' in line:
            tokens = line.split(':')
            stat = tokens[0].lstrip('-PMU').strip().replace(' ', '-')
            val = int(tokens[1])
            stats[stat] = val
    return stats


def parse_args(argv):
    if len(argv) != 3:
        print('Usage: {} <artifacts_dir> <benchmarks_list_file>'.format(argv[0]))
        exit()
    args = {}
    args['artifacts_dir'] = argv[1]
    args['bench_list_file'] = argv[2]
    return args


if __name__ == '__main__':
    main(sys.argv)
