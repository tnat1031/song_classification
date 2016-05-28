# given a directory of split up training matrices,
# read and transpose each, anonymizing the words
# and appending genre and track id tags

library(argparser)
library(data.table)

parser <- arg_parser("process split matrices")
parser <- add_argument(parser, "--dir", help="path to directory containing matrices", default=NA)
parser <- add_argument(parser, "--out", help="desired output directory", default=NA)
parser <- add_argument(parser, "--word_map", help="table of anonymized words", default=NA)
parser <- add_argument(parser, "--genre_map", help="maps track_id to genre", default=NA)


# parse arguments
args <- parse_args(parser, argv=commandArgs(trailingOnly=T))

# function to process one file
process_matrix <- function(d, word_map, genre_map) {
	d <- data.table(d)
	dt <- as.data.table(t(d[, 2:ncol(d), with=F]))
	word_idx <- match(d$word, word_map$original)
	names(dt) <- word_map$new[word_idx]
	dt$track_id <- names(d)[2:ncol(d)]
	# keep only those tracks in genre_map
	dt <- dt[ dt$track_id %in% genre_map$track_id ]
	genre_idx <- match(dt$track_id, genre_map$track_id)
	dt$genre <- genre_map$genre[genre_idx]
	# reorder the columns
	dt <- dt[, c("track_id", "genre", grep("^w_", names(dt), value=T)), with=F]
	return(dt)
}


# main program

# read data
word_map <- fread(args$word_map)
genre_map <- fread(args$genre_map)

outpath <- args$out
if (!file.exists(outpath)) dir.create(outpath)

# get a list of the files
files <- dir(args$dir, pattern="\\.txt", full.names=T)
message(paste("found", length(files), "files"))

for (f in files) {
	fname <- basename(f)
	message("working on ", fname)
	fraw <- fread(f)
	ofile <- paste(outpath, fname, sep="/")
	if (!file.exists(ofile)) {
		fprocessed <- process_matrix(fraw, word_map, genre_map)
		write.table(fprocessed, ofile,
			col.names=T, row.names=F, sep="\t", quote=F)
	} else {
		message(paste(ofile, "exists, skipping"))
	}
}


