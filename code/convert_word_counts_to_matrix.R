#! /usr/bin/env Rscript

library(argparser)

parser <- arg_parser("Given an MSD word count file,
	convert to a matrix")
parser <- add_argument(parser, "msd", help="path to MSD file", default=NA)
parser <- add_argument(parser, "--skip", help="number of lines to skip", default=18)
parser <- add_argument(parser, "--out", help="output path", default=getwd())

args <- parse_args(parser, commandArgs(trailingOnly=T))

# load other libraries
# library(data.table)

# get args
outpath <- args$out
if (!file.exists(outpath)) dir.create(outpath)

# read in the data
# msd <- fread(args$msd)