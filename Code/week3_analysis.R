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

# Viewpoint visibility
# x1 - central cluster, x2 - southern house/road, x3 - central outskirts
vp_df <- data.frame(
  id = c("central_cluster", "south_house", "east_outskirts"),
  x = c(-69.5182, -21.9884, -7.55639), # Enter coordinates manually
  y = c(285.713, 25.018, 306.499)
)

observer_height <- 1.5  # Meters above ground

for (i in seq_len(nrow(vp_df))) {
  this_id <- vp_df$id[i]
  this_xy <- c(vp_df$x[i], vp_df$y[i]) # Numeric (x, y)
  
  # Raw
  vs_raw <- terra::viewshed(dtm_raw, this_xy, observer = observer_height)
  writeRaster(
    vs_raw,
    paste0("vis_raw_", this_id, "_0p5m.tif"),
    overwrite = TRUE
  )
  
  # RF
  vs_rf <- terra::viewshed(dtm_rf, this_xy, observer = observer_height)
  writeRaster(
    vs_rf,
    paste0("vis_rf_", this_id, "_0p5m.tif"),
    overwrite = TRUE
  )
  
  # XGB
  vs_xgb <- terra::viewshed(dtm_xgb, this_xy, observer = observer_height)
  writeRaster()
    vs_xgb,
    paste0("vis_xgb_", this_id, "_0p5m.tif"),
    overwrite = TRUE
  )
}

# Do confidence levels (red, yellow, green on map overlaid)
