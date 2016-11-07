sample_from_col <- function(D, n=500, col="genre") {
	Dsub <- rbindlist(lapply(as.list(unique(D[[col]])), function(x) {
		tmp <- D[ D[[col]] == x ]
		tmp[sample(1:nrow(tmp), n)]
		}))
	return(Dsub)
}

# Nov 1 2016
library(randomForest) # for random forest
library(class) # for knn
library(e1071) # for svm

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
rf_model <- randomForest(x=train3k[, grep("^w_", names(train3k)), with=F], y=as.factor(train3k$genre))

# and testing it
rf_predictions <- as.character(predict(rf_model, newdata=test600[, grep("^w_", names(test600)), with=F]))

# make a table of predicted vs. actual
rf_result <- data.table(track_id=test600$track_id, predicted=rf_predictions, actual=test600$genre)

# save it
write.tbl(rf_result, "random_forest/prediction_table.txt")


# training a KNN model in one shot
knn_predictions <- as.character(
	knn(train=train3k[, grep("^w_", names(train3k)), with=F],
		test=test600[, grep("^w_", names(test600)), with=F],
		cl=train3k$genre, k=30)
	)

# make a table of predicted vs. actual
knn_result <- data.table(track_id=test600$track_id, predicted=knn_predictions, actual=test600$genre)

# save it
write.tbl(knn_result, "knn/prediction_table.txt")


# train the svm
svm_model <- svm(x=train3k[, grep("^w_", names(train3k)), with=F], y=as.factor(train3k$genre))

# and test it
svm_predictions <- as.character(predict(svm_model, newdata=test600[, grep("^w_", names(test600)), with=F]))

# make a table of predicted vs. actual
svm_result <- data.table(track_id=test600$track_id, predicted=svm_predictions, actual=test600$genre)

# save it
write.tbl(svm_result, "svm/prediction_table.txt")



# compile all the results into a single table
rf_result$classifier <- "RF"
knn_result$classifier <- "KNN"
svm_result$classifier <- "SVM"
res <- rbindlist(list(rf_result, knn_result, svm_result), use.names=T)

# generate a frequency table for correct classifications
res_agg <- res[, .(count = .N), .(classifier, actual, predicted)]

# make sure factor levels are set
genres <- sort(unique(res_agg$predicted))
res_agg$predicted <- factor(res_agg$predicted, levels=genres)
res_agg$actual <- factor(res_agg$actual, levels=genres)

# plot confusion matrices
p <- ggplot(res_agg) + theme_bw()
p <- p + geom_tile(aes(x=actual, y=predicted, fill=count))
p <- p + scale_fill_gradient(low="white", high="red")
p <- p + facet_grid(. ~ classifier) 
p <- p + theme(panel.grid=element_blank(),
	axis.text.x=element_text(angle=45, hjust=1, vjust=1),
	panel.margin=grid::unit(2, "lines"))
ggsave("confusion_matrix.png", height=4.25, width=12)

# bar plot of prediction accuracy for each genres
accuracy <- res[, .(accuracy = sum(predicted==actual)/.N), .(classifier, actual)]
p <- ggplot(accuracy) + theme_bw()
p <- p + geom_bar(aes(x=actual, y=accuracy, fill=classifier),
	stat="identity", position="dodge")
p <- p + xlab("") + ylab("Accuracy") + ylim(0, 1) 
p <- p + theme(panel.grid=element_blank(),
	axis.text.x=element_text(angle=45, hjust=1, vjust=1),
	panel.margin=grid::unit(2, "lines"))
# add horiz line at random guess frequency
guess_freq <- 1 / length(unique(accuracy$actual))
p <- p + geom_hline(yintercept=guess_freq, linetype="dashed", size=1.3)
ggsave("accuracy_bar_all_genres.png", height=4.25, width=12)

# bar plot of prediction accuracy for each classifier
avg_accuracy <- accuracy[, .(avg_accuracy = mean(accuracy)), .(classifier)]
p <- ggplot(avg_accuracy) + theme_bw()
p <- p + geom_bar(aes(x=classifier, y=avg_accuracy, fill=classifier),
	stat="identity", position="dodge")
p <- p + xlab("") + ylab("Average Accuracy") + ylim(0, 1) 
p <- p + theme(panel.grid=element_blank(),
	axis.text.x=element_text(angle=45, hjust=1, vjust=1),
	panel.margin=grid::unit(2, "lines"))
# add horiz line at random guess frequency
guess_freq <- 1 / length(unique(accuracy$actual))
p <- p + geom_hline(yintercept=guess_freq, linetype="dashed", size=1.3)
ggsave("accuracy_bar_by_classifier.png", height=4.25, width=7)


# plot frequency of artist / genre relationships
