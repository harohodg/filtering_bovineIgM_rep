#!/usr/bin/python3
#First run module load scipy-stack/2023a
#Then run python3 monte_carlo.py <input_file> <sample_size> <number_of_samples> [<threshold>]
#Returns mean and std of the percentage of values in each sample >= the threshold if a threshold is provided
#Otherwise returns the mean and std of the mean of each sample

import sys, random
import numpy as np

inputFile   = sys.argv[1]
sample_size = int(sys.argv[2])
num_samples = int(sys.argv[3])

threshold   = int(sys.argv[4]) if len(sys.argv) == 5 else None

with open( inputFile, 'r') as f:
    first_line = f.readline()
    data = [ float(line) for line in f ]

observed_length = []

for sample_number in range( num_samples ):   
    sample      = random.sample( data, sample_size )
    observed_length.append(0)
    
    if threshold is not None:
        for value in sample:
            observed_length[-1] += value >= threshold
        observed_length[-1] = (observed_length[-1]/sample_size)*100
    else:
        observed_length[-1] = np.mean(sample)
       
observed_length_mean = np.mean( observed_length )
observed_length_std  = np.std( observed_length )

print( f'{observed_length_mean:.4f},{observed_length_std:.4f},{sample_size},{num_samples},{threshold}' )
