#! /usr/bin/python

import argparse
import os
import sys
import pandas as pd

parser = argparse.ArgumentParser(description='Pull song ID, title, genre from MXM Genre file')
parser.add_argument('msd', help='path to MXM file', type=str, default=None)
parser.add_argument('--out', help='desired output path', default=os.getcwd())

args = parser.parse_args(sys.argv[1:])
outpath = args.out

df = pd.read_csv(args.msd, encoding='utf-8', skiprows=9)

# remove the '%' from the column headers
cols = [x.replace('%', '') for x in df.columns.tolist()]
df.columns = cols

# write out only the first 4 columns
df.ix[:, 0:4].to_csv(os.path.join(outpath, 'mxm_genre_map.txt'), sep='\t',
	index=False, encoding='utf-8')