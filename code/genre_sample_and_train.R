sample_from_col <- function(D, n=500, col="genre") {
	Dsub <- rbindlist(lapply(as.list(unique(D[[col]])), function(x) {
		tmp <- D[ D[[col]] == x ]
		tmp[sample(1:nrow(tmp), n)]
		}))
	return(Dsub)
}

# Nov 1 2016

# bar plot of genere counts
png("genre_counts_bar.png", height=640, width=768, units="px")
par(cex=1.5)
barplot(sort(table(genre_map$genre)), las=3, ylab="# of songs", main="Genre Breakdown\n~100k Labeled Songs")
dev.off()

# sample 200 songs per genre for training and 
# 40 each for testing
song_bins <- list()
for (g in unique(genre_map$genre)) {
	train <- sample(genre_map[genre==g]$track_id, 200)
	test <- setdiff(genre_map[genre==g]$track_id, train)
	if (length(test) > 40) {
		test <- sample(test, 40)
	}
	song_bins[[g]] <- list(train= train, test= test)
}

train_ids <- unlist(lapply(song_bins, function(x) x$train))
test_ids <- unlist(lapply(song_bins, function(x) x$test))

train3k <- D[track_id %in% train_ids]
test600 <- D[track_id %in% test_ids]


# try training random forest
rf <- randomForest(x=train3k[, grep("^w_", names(train3k)), with=F], y=as.factor(train3k$genre))

# and testing it
rf_predictions <- as.character(predict(rf, newdata=test600[, grep("^w_", names(test600)), with=F]))

# make a table of predicted vs. actual
rf_result <- data.table(track_id=test600$track_id, predicted=rf_predictions, actual=test600$genre)

# save it
write.tbl(rf_result, "random_forest/prediction_table.txt")