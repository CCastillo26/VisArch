library(lidR)
library(terra)
library(xgboost)
library(data.table)

raw_path <-"/Users/charlycastillo/Downloads/ollape_nomanual.las"
rf_path <- "/Users/charlycastillo/Downloads/ollape_3DMASC.las"
xgb_model <- "ollape_xgb_model.rds"
xgb_out_las <- "ollape_xgb_classified.las"

bst <- readRDS("ollape_xgb_model.rds")
raw_pc <- readLAS("/Users/charlycastillo/Downloads/ollape_nomanual.las")

df_raw <- as.data.frame(raw_pc@data)
feature_use <- intersect(feature_cols, names(df_raw))
X_full <- as.matrix(df_raw[, feature_use])

d_full <- xgb.DMatrix(X_full)
p_full <- predict(bst, d_full)
pred_all <- as.integer(p_full >= 0.5) # 1 = veg, 0 = other

raw_pc@data$pred_xgb <- pred_all
raw_pc@data$prob_xgb <- p_full

writeLAS(raw_pc, xgb_out_las)

pc_xgb_clean <- filter_poi(raw_pc, pred_xgb == 0) # Cleaned, only non-veg

rf_pc <- readLAS(rf_path)

# DTMs (0.5 m)
dtm_raw <- rasterize_terrain(raw_pc, res = 0.5, algorithm = knnidw())
dtm_rf  <- rasterize_terrain(rf_pc, res = 0.5, algorithm = knnidw())
dtm_xgb <- rasterize_terrain(pc_xgb_clean, res = 0.5, algorithm = knnidw())

writeRaster(dtm_raw, "dtm_raw_0p5m.tif", overwrite = TRUE)
writeRaster(dtm_rf, "dtm_rf_0p5m.tif", overwrite = TRUE)
writeRaster(dtm_xgb, "dtm_xgb_0p5m.tif", overwrite = TRUE)

# DSMs (0.5 m)
dsm_raw <- rasterize_canopy(raw_pc, res = 0.5, algorithm = p2r())
dsm_rf <- rasterize_canopy(rf_pc, res = 0.5, algorithm = p2r())
dsm_xgb <- rasterize_canopy(pc_xgb_clean, res = 0.5, algorithm = p2r())

writeRaster(dsm_raw, "dsm_raw_0p5m.tif", overwrite = TRUE)
writeRaster(dsm_rf,  "dsm_rf_0p5m.tif",  overwrite = TRUE)
writeRaster(dsm_xgb, "dsm_xgb_0p5m.tif", overwrite = TRUE)

# CHMs (DSM - DTM)
chm_raw <- dsm_raw - dtm_raw
chm_rf <- dsm_rf - dtm_rf
chm_xgb <- dsm_xgb - dtm_xgb

writeRaster(chm_raw, "chm_raw_0p5m.tif", overwrite = TRUE)
writeRaster(chm_rf,  "chm_rf_0p5m.tif",  overwrite = TRUE)
writeRaster(chm_xgb, "chm_xgb_0p5m.tif", overwrite = TRUE)



# XGBoost-cleaned DTM
pc_clean <- filter_poi(raw_pc, pred_xgb == 0)

dtm_xgb <- rasterize_terrain(pc_clean, res = 0.5, algorithm = knnidw())

writeRaster(dtm_xgb, "dtm_xgb_0p5m.tif", overwrite = TRUE)

# DSM (raw)
dsm_raw <- rasterize_canopy(raw_pc, res = 0.5, algorithm = p2r())
writeRaster(dsm_raw, "dsm_raw_0p5m.tif", overwrite = TRUE)

# DSM (XGBoost-cleaned)
dsm_xgb <- rasterize_canopy(pc_clean, res = 0.5, algorithm = p2r())
writeRaster(dsm_xgb, "dsm_xgb_0p5m.tif", overwrite = TRUE)

# CHM = DSM - DTM
chm_raw <- dsm_raw - dtm_raw
writeRaster(chm_raw, "chm_raw_0p5m.tif", overwrite = TRUE)

chm_xgb <- dsm_xgb - dtm_xgb
writeRaster(chm_xgb, "chm_xgb_0p5m.tif", overwrite = TRUE)

# Choose a viewpoint — you will eventually get coordinates from Parker
# vp <- vect(data.frame(x = 187600, y = 9282300), crs = crs(dtm_raw))

# Raw visibility
# vis_raw <- viewshed(dtm_raw, vp)
# writeRaster(vis_raw, "vis_raw.tif", overwrite = TRUE)

# XGB visibility
# vis_xgb <- viewshed(dtm_xgb, vp)
# writeRaster(vis_xgb, "vis_xgb.tif", overwrite = TRUE)





# Structure-to-structure visibility
# structs <- read.csv("ollape_structures.csv")
# vp <- vect(structs, geom = c("x", "y"), crs = crs(dtm_xgb))
# ids <- structs$id

# build_visibility_network <- function(dtm, vp, ids, observer_height = 1.5) {
  # n <- nrow(vp)
  # vis_mat <- matrix(0, n, n, dimnames = list(ids, ids))
  
  # for (i in seq_len(n)) {
    # vs <- viewshed(dtm, vp[i, ], h = observer_height)
    # vals <- extract(vs, vp)[, 2] # Raster value at each structure
    # vis_mat[i, ] <- as.integer(!is.na(vals) & vals > 0)
  # }
  
  # vis_mat
# }

# Visibility networks for Raw and XGBoost surfaces
# vis_raw <- build_visibility_network(dtm_raw, vp, ids)
# vis_xgb <- build_visibility_network(dtm_xgb, vp, ids)

# saveRDS(vis_raw, "vis_network_raw.rds")
# saveRDS(vis_xgb, "vis_network_xgb.rds")


