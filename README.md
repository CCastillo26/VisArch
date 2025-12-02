Final project for CSCI 2370: Interdisciplinary Scientific Visualization
Vegetation Classification & Terrain Modeling Using LiDAR + XGBoost

This repository contains a full LIDAR processing pipeline for vegetation classification, DTM/DSM/CHM construction, and visibility analysis using lidR, xgboost, terra, and a Shiny dashboard for visualization.

Workflow:
Read & clean LiDAR point clouds
Build a labeled training set (vegetation and non vegetation)
Train an XGBoost classifier
Classify a new LiDAR dataset
Generater terrain models (DTM, DSM, CHM)
Computer visibility maps
Explore outputs in an interactive dashboard

Dependencies (R packages): 
library(lidR)
library(tidyverse)
library(parallel)
library(xgboost)
library(terra)
library(data.table)
library(flexdashboard)
library(shiny)
library(DT)

Classification Pipeline:

The script prepares the labeled data by reading vegetation and non-vegetation LAS files, selecting key features
(Z, Intensity, returns, and RGB), merging them, and removing rows with missing values. A feature matrix (X) and a label vectory (y) are created for model training.

The pipeline performs cross validation on a capped subsample to quickly estimate precision recall and F1. The dataset is then split 80/20 into training and testing sets.

An XGBoost classifier is trained using paramters for binary classification. The model is then evaluated on the 20% test set, and precision, recall, and F1 scores are computed. The final trained model is saved as ollape_xgb_model.rds.

Classifying a New Point Cloud:

The saved XGBoost model is loaded and applied to a new .las file. Each point has:
pred_xgb (vegetation 1 or non-vegetation 0)
prob_xgb (predicted probability of vegetation)

A new classified .las file (ollape_xgb_classified.las) is written. A cleaned version of the cloud with only non-vegetation points is also generated for terrain modeling.

Terrain Modeling:
DTM DSM, and CHM rasters (0.5m resolution) are generated for the:
raw point could
3DMASC-processed cloud
XGBoost-cleaned cloud

Each set will include raster, dtm_*.tif, dsm_*.tif, chm_*.tif.

Visibility Analysis:
Three viewpoints are defined manually and visibility maps are computed for the:
raw terrain
3DMASC terrain
XGBoost terrain

Each view is saved as a raster (vis_*.tif) showing visible and non-visible areas from that location.

Dashboard:
A Shiny app allows the interactive exploration of results. The user can switch between preprocessing methods,
Raw 3DMASC, XGBoost and layers DTM, CHM, or visibility. The dashboard also displays precision, recall, and F1 metrics for each method. All images in the dashboard are stored in the Outputs/ folder.

Output Summary:
Trained model: ollape_xgb_model.rds
Classified point cloud: ollape_xgb_classified.las
Terrain rasters
Visibility rasters
Dashboard images and R Markdownfile

Reproducing Workflow
Update .las file paths
Run the training/classification script
Run the new cloud classification script
Generate rasters and visibility maps
Open the dashboard to explore results
