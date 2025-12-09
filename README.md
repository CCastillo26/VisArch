# *VisArch*: An Interactive Dashboard for Comparing LiDAR Preprocessing
Methods at Chachapoya Settlements
## Quick Tutorial
*VisArch* is an interactive visualization tool for exploring how different LiDAR preprocessing methods affect archaeological interpretation at the Chachapoya site of Ollape. The main dashboard is implemented as an R Markdown flexdashboard (`week4_dashboard.Rmd`). When you knit this file, RStudio produces an HTML page that you can open in any web browser.

A default set of rasters in the `/Outputs` is loaded automatically.

## 1. *VisArch* Dashboard (`week4_dashboard.Rmd`)
This dashboard is the primary view for comparing preprocessing pipelines and their effects on derived surfaces. 

### What it does
* Loads DSM, DTM, and CHM rasters for:
  *   Raw point cloud
  *   RF-based filter (Abate et al., 2019)
  *   XGBoost classifier, including random and tiled sampling
* Lets you switch between preprocessing methods and layers using the left-hand controls.
* Shows precision, recall, and F1 for each method and class (Vegetation, Other).

### How to use it
* **1. Open the dashboard**
  * In R Studio, run `week2_analysis.R` and `week3_analysis`.
  * Then, open `week4_dashboard.Rmd` and click **Knit**.
  * This will create an HTML file. Open that file in your browser.


