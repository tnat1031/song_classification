#! /usr/bin/python

import argparse
import os
import sys
import pandas as pd

parser = argparse.ArgumentParser(description='Pull song ID, genre from MSD file')
parser.add_argument('msd', help='path to MSD file', type=str, default=None)
parser.add_argument('--out', help='desired output path', default=os.getcwd())
parser.add_argument('--name', help='desired output filename',
	default='genre_map.txt')
parser.add_argument('--sep', help='separator in file', default='\t')

args = parser.parse_args(sys.argv[1:])
outpath = args.out

f = open(args.msd, 'r')
keeplines = ['track_id\tgenre']
for line in f.readlines():
	if line.startswith('#'):
		next
	else:
		parts = line.strip().split('\t')[:2] # keep the highest weighted genre
		keeplines.append('\t'.join(parts))
f.close()

f = open(os.path.join(args.out, args.name), 'w')
for x in keeplines:
	f.write(x + '\n')
f.close()
