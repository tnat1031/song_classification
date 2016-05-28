sample_from_col <- function(D, n=500, col="genre") {
	Dsub <- rbindlist(lapply(as.list(unique(D[[col]])), function(x) {
		tmp <- D[ D[[col]] == x ]
		tmp[sample(1:nrow(tmp), n)]
		}))
	return(Dsub)
}