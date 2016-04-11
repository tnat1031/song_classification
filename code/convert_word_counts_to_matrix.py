#! /usr/bin/python

import argparse
import os
import sys
import codecs
import pandas as pd

parser = argparse.ArgumentParser(description='Convert MSD file to matrix')
parser.add_argument('msd', help='path to MSD file', type=str, default=None)
parser.add_argument('--out', help='desired output path', default=os.getcwd())
parser.add_argument('--words', help='grp of all possible words', default=None)


def process_line(line, all_words, delim=','):
    '''
    given a line of text, convert to a 1-column
    pandas DataFrame
    '''
    split_line = line.strip().split(delim)
    msd_id = split_line[0]
    mxm_id = split_line[1]
    words = []
    counts = []
    for word in split_line[2:]:
        parts = word.split(':')
        word_index = int(parts[0])
        word_count = int(parts[1])
        # need the -1 b/c the MSD indexing is 1-based (not 0 like python)
        words.append(all_words[word_index - 1])
        counts.append(word_count)
    # account for any words in all_words that were
    # not in line
    missed_words = list(set(all_words) - set(words))
    words = words + missed_words
    counts = counts + [0] * len(missed_words)
    df = pd.DataFrame({'word': words, msd_id: counts})
    return df


if __name__ == '__main__':
    args = parser.parse_args(sys.argv[1:])
    outpath = args.out

    print 'working on ' + args.msd

    # read the words grp if given
    if args.words:
        all_words = []
        f = codecs.open(args.words, 'rb', 'utf-8')
        for x in f.readlines():
            all_words.append(x.strip())
        f.close()
    # process the input file line by line
    f = codecs.open(args.msd, 'rb', 'utf-8')
    lines = f.readlines()
    f.close()
    lodfs = []
    for line in lines:
        if line.startswith('#'):
            # comment, skip
            next
        elif line.startswith('%'):
            # indicates the start of the word list
            if not args.words:
                # weren't given a list of words, pull from file
                all_words = line.strip().split(',')
            else:
                next
        else:
            lodfs.append(process_line(line, all_words))
    
    # merge all the processed lines together into a single
    # df, making sure to join on the same word
    DF = lodfs[0]
    for df in lodfs[1:]:
        DF = pd.merge(DF, df, on='word', how='outer')

    # replace NaN's with 0
    DF = DF.fillna(value=0)

    # rearrange the column headers
    cols = ['word'] + list(set(DF.columns) - set(['word']))
    DF = DF[cols]

    # and write to output
    fname = os.path.splitext(os.path.basename(args.msd))[0] + '_matrix.txt'
    DF.to_csv(os.path.join(outpath, fname), sep='\t', index=False, encoding='utf-8')




