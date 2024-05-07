#!/usr/bin/python3

#First run module load StdEnv/2020 scipy-stack/2023a

DESCRIPTION = """
Prints the mean and std of the percentage of values in each sample >= the threshold if a threshold is provided
Otherwise prints the mean and std of the mean of each sample
The intermediary values are saved to an optional output file.
"""

DEFAULT_SAMPLE_SIZE       = 1000
DEFAULT_NUMBER_OF_SAMPLES = 1000

import sys, random, argparse
import numpy as np
from numpy import genfromtxt

parser = argparse.ArgumentParser(
    prog="monte_carlo.py",
    description=DESCRIPTION,
    formatter_class=argparse.ArgumentDefaultsHelpFormatter
)

parser.add_argument('input_file')
parser.add_argument('-s', '--sample_size',       type=int, default=DEFAULT_SAMPLE_SIZE,       help='# of lengths in each samples')
parser.add_argument('-n', '--number_of_samples', type=int, default=DEFAULT_NUMBER_OF_SAMPLES, help='# of samples taken')
parser.add_argument('-t', '--threshold',         type=int, help='length threshold')
parser.add_argument('-o', '--output_file')

args = parser.parse_args()

data = list( genfromtxt(args.input_file, delimiter=',') )

observed_lengths = []

for sample_number in range( args.number_of_samples ):   
    sample = random.sample( data, args.sample_size )
    observed_lengths.append(0)
    
    if args.threshold is not None:
        for value in sample:
            observed_lengths[-1] += value >= args.threshold
        observed_lengths[-1] = (observed_lengths[-1]/args.sample_size)*100
    else:
        observed_lengths[-1] = np.mean(sample)

if args.output_file is not None:
    np.savetxt(args.output_file, observed_lengths, delimiter=",", fmt='%.4f')
       
observed_length_mean = np.mean( observed_lengths )
observed_length_std  = np.std(  observed_lengths )


print( f'{observed_length_mean:.4f},{observed_length_std:.4f},{args.sample_size},{args.number_of_samples},{args.threshold}' )
