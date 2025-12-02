
# 04_waterways_processing

# This script collects, filters and process Waterways input datasets 
# from HDX as input to carry out Health Facilities accessibility assessment

# Luis de la Rua December 2025

# SETTINGS ----
# Clean environment
gc()
rm(list = ls())
source("setup.R")

# Country using iso3
country <- 'SLV'

# Paths to the directory we store the data
dir <- paste0("C:/GIS/UNFPA GIS/HF/", country,"/")


# Additional libraries
# Use rdhx library to explore and download data info in "https://dickoa.gitlab.io/rhdx/"
# remotes::install_github("dickoa/rhdx")

library(rhdx)
library(readr)

# 1. DOWNLOAD DATASET FROM HDX -------------------------------------------------
## 1.1 Connect to HDX

set_rhdx_config(hdx_site = "prod")

## 1.2 Search and Fetch the Dataset

# We search for the specific ID: 'hotosm_slv_waterways'
# This dataset is managed by the Humanitarian OpenStreetMap Team (HOT)
dataset <- search_datasets("hotosm_slv_waterways", rows = 1) %>% 
  .[[1]]

resource_list <- get_resources(dataset)

resource <- dataset %>% 
  get_resource(3)

## 1.3 Save in raw data folder and select the right item within the gpkg
zip_path <- resource %>% 
  download_resource(path = tempdir(), force = TRUE)
unzip(zip_path, exdir = paste0(dir,"raw_data"))

# Load the thing as a collection 
waterways <- svc(paste0(dir,"raw_data/hotosm_slv_waterways.gpkg"))
waterways <- waterways[[2]] # Adjust number if needed this case is the second item

plot(waterways, col="blue", main="Extracted Lines")

# 2. HARMONISE AND CLEAN DATA. ================================================
wways_proc <- waterways %>% 
  select(c(waterway)) %>% 
  aggregate(by = "waterway", FUN = union) # Disolve to make it easier to handle
 
# keep those categories that can be real barriers 
entries_in <- c("canal",	"river",	"stream")

# keep those categories that can be real barriers
wways_proc <- wways_proc %>% 
  filter(waterway %in% entries_in)

# Project into equal area projection
wways_rep <- wways_proc %>% 
  project(., "ESRI:54034")

# Export to the input folder
writeVector(wways_rep,paste0(dir,"am_input/wways_54034.shp"), overwrite = T)
