# 07_admin_bounds_processing

# This script collects, filters and process Admin boundaries 
# Using Admin boundaries from SLV country office

# Luis de la Rua December 2025

# SETTINGS ----
# Clean workspace
rm(list = ls())
gc()

source("setup.R")

# Country using iso3
country <- 'SLV'

# Paths to the directory we store the data
dir <- paste0("C:/GIS/UNFPA GIS/HF/", country,"/")


# 1. IMPORT AND CLIP WITH sALVADOR EXTENT ======================================
ab <- vect(paste0(dir, "raw_data/unfpa_slv_nooficial.gpkg"), layer = 'distrital')

# Reproject
ab <- project(ab, "ESRI:54034")

# Export
writeVector(ab,paste0(dir,"am_input/distritos_54034.shp"), overwrite = T)



  