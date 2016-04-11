#! /usr/bin/python

import argparse
import os
import sys
import pandas as pd

parser = argparse.ArgumentParser(description='Pull song ID from MXM data file')
parser.add_argument('mxm', help='path to MXM file', type=str, default=None)
parser.add_argument('--out', help='desired output path', default=os.getcwd())
parser.add_argument('--name', help='desired output filename',
	default='extracted_ids.grp')
parser.add_argument('--sep', help='separator in file', default='\t')

args = parser.parse_args(sys.argv[1:])
outpath = args.out

f = open(args.mxm, 'r')
ids = []
for line in f.readlines():
	if line.startswith('#') or line.startswith('%'):
		# comment or word ids, skip
		next
	else:
		parts = line.strip().split(args.sep)
		ids.append(parts[0])
f.close()

f = open(os.path.join(args.out, args.name), 'w')
for x in ids:
	f.write('%s\n' % x)
f.close()