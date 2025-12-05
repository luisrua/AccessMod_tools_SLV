# 06_hf_locations_processing

# This script collects, filters and process Health Facilities input. This time we
# use PAHO dataset
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
hf <- vect(paste0(dir, "raw_data/lac_hf_paho_54034.gpkg"))
ab <- vect(paste0(dir, "raw_data/unfpa_slv_nooficial.gpkg"), layer = 'distrital')

crs(ab)
crs(hf)

# hf is already 54034 so we project ab to align
ab <- project(ab, crs(hf))

# Clip hf locations only within El Salvador PAHO is emergency hospitals focused.
hf <- mask(hf,ab)



# 2. HARMONISE, CLEAN AND CONVERT TO SPATIAL ===================================
names(hf)
hf
# for the moment we keep all fields in case they can be useful
# Export to GPKG in layers folder

writeVector(hf,paste0(dir,"am_input/hf_paho_54034.shp"), overwrite = T)


