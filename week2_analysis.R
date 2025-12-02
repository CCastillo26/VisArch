library(lidR)
library(parallel)
library(tidyverse)
library(xgboost)

# Read and label data
veg_pc <- readLAS("/Users/charlycastillo/Documents/veg_pc.las")

other_pc1 <- readLAS("/Users/charlycastillo/Documents/other_pc1.las")
other_pc2 <- readLAS("/Users/charlycastillo/Downloads/other_pc2.las")

# Select only variables of interest
vars <- c("X", "Y", "Z", "Intensity","ReturnNumber", "NumberOfReturns", "R", 
          "G", "B")

other_pc1@data  <- other_pc1@data[,  ..vars]
other_pc2@data <- other_pc2@data[, ..vars]

other_pc <- rbind(other_pc1, other_pc2)

veg_df <- veg_pc@data
other_df <- other_pc@data

veg_df$label <- 1L # 1 = vegetation
other_df$label <- 0L # 0 = other

df <- bind_rows(veg_df, other_df) %>% 
  as_tibble()

feature_cols <- c("Z", "Intensity", "ReturnNumber", "NumberOfReturns",
  "R", "G", "B")

# Drop rows with NA in any vars column
df <- df %>% drop_na(all_of(feature_cols))

X <- as.matrix(df[, feature_cols])
y <- df$label

# Create XGBoost parameters
params <- list(
  objective = "binary:logistic", 
  eval_metric = "logloss", 
  max_depth = 6,  
  eta = 0.1,   
  subsample = 0.8,     
  colsample_bytree = 0.8       
)

# 5-fold cross validation on subsample
set.seed(123)

max_cv_n <- 100000 # Cap CV sample size
n_full <- length(y)

if (n_full > max_cv_n) {
  cv_idx <- sample(n_full, max_cv_n)
  X_cv   <- X[cv_idx, , drop = FALSE]
  y_cv   <- y[cv_idx]
} else {
  X_cv <- X
  y_cv <- y
}

K <- 5
n_cv <- length(y_cv)

fold_ids <- sample(rep(1:K, length.out = n_cv))

cv_stats <- matrix(NA, nrow = K, ncol = 3,
                   dimnames = list(NULL, c("precision", "recall", "f1")))

for (k in 1:K) {
  train_idx_cv <- which(fold_ids != k)
  test_idx_cv <- which(fold_ids ==  k)
  
  dtrain_cv <- xgb.DMatrix(X_cv[train_idx_cv, ], label = y_cv[train_idx_cv])
  dtest_cv <- xgb.DMatrix(X_cv[test_idx_cv,  ], label = y_cv[test_idx_cv])
  
  bst_cv <- xgb.train(
    params = params,
    data = dtrain_cv,
    nrounds = 100, # Fewer trees for speed in CV
    verbose = 0
  )
  
  p_cv <- predict(bst_cv, dtest_cv)
  y_true_cv <- y_cv[test_idx_cv]
  y_pred_cv <- as.integer(p_cv >= 0.5)
  
  tp <- sum(y_true_cv == 1 & y_pred_cv == 1)
  fp <- sum(y_true_cv == 0 & y_pred_cv == 1)
  fn <- sum(y_true_cv == 1 & y_pred_cv == 0)
  
  precision <- tp / (tp + fp)
  recall <- tp / (tp + fn)
  f1 <- 2 * precision * recall / (precision + recall)
  
  cv_stats[k, ] <- c(precision, recall, f1)
}

colMeans(cv_stats) # Average precision/recall/F1 across folds

# Create 80/20 train-test split
set.seed(123)

n <- nrow(X)

# Cap for main training for speed
max_n <- 1000000

if (n > max_n) {
  keep_idx <- sample(n, max_n)    
  X <- X[keep_idx, , drop = FALSE]
  y <- y[keep_idx]    
  df <- df[keep_idx, ]
  n <- length(y)                
}

idx <- sample(n) 

train_end <- floor(0.8 * n)   # First 80% -> train, last 20% -> test

train_idx <- idx[1:train_end]
test_idx <- idx[(train_end + 1):n]

dtrain <- xgb.DMatrix(X[train_idx, ], label = y[train_idx])
dtest  <- xgb.DMatrix(X[test_idx,  ], label = y[test_idx])

nrounds <- 200

bst <- xgb.train(
  params = params,
  data = dtrain,
  nrounds = nrounds,
  verbose = 1,
  nthread = detectCores() - 1
)

# Evaluate on test set
p_test <- predict(bst, dtest)

y_test_true <- y[test_idx]
y_test_pred <- as.integer(p_test >= 0.5)

# Confusion matrix
table(True = y_test_true, Pred = y_test_pred)

tp <- sum(y_test_true == 1 & y_test_pred == 1)
fp <- sum(y_test_true == 0 & y_test_pred == 1)
fn <- sum(y_test_true == 1 & y_test_pred == 0)

precision <- tp / (tp + fp)          
recall <- tp / (tp + fn)            
f1 <- 2 * precision * recall / (precision + recall)

precision
recall
f1

# Extra evaluation by tiles
tile_size <- 5

df$tile_x <- floor(df$X / tile_size)
df$tile_y <- floor(df$Y / tile_size)
df$tile_id <- interaction(df$tile_x, df$tile_y, drop = TRUE)

tiles <- unique(df$tile_id)

set.seed(123)
test_tiles <- sample(tiles, size = round(0.2 * length(tiles)))

nX <- nrow(X)
valid_idx <- seq_len(nX)

train_idx_sp <- intersect(train_idx_sp, valid_idx)
test_idx_sp <- intersect(test_idx_sp, valid_idx)

dtrain_sp <- xgb.DMatrix(X[train_idx_sp, ], label = y[train_idx_sp])
dtest_sp <- xgb.DMatrix(X[test_idx_sp,  ], label = y[test_idx_sp])

bst_sp <- xgb.train(
  params = params,
  data = dtrain_sp,
  nrounds = 200,
  verbose = 1,
  nthread = detectCores() - 1
)

p_test_sp <- predict(bst_sp, dtest_sp)

y_true_sp <- y[test_idx_sp]
y_pred_sp <- as.integer(p_test_sp >= 0.5)

table(True = y_true_sp, Pred = y_pred_sp)

tp_sp <- sum(y_true_sp == 1 & y_pred_sp == 1)
fp_sp <- sum(y_true_sp == 0 & y_pred_sp == 1)
fn_sp <- sum(y_true_sp == 1 & y_pred_sp == 0)

precision_sp <- tp_sp / (tp_sp + fp_sp)
recall_sp <- tp_sp / (tp_sp + fn_sp)
f1_sp <- 2 * precision_sp * recall_sp / (precision_sp + recall_sp)

precision_sp
recall_sp
f1_sp

saveRDS(bst, "ollape_xgb_model.rds")
