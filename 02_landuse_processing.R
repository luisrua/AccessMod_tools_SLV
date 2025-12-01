# 02_landuse_processing

# This script collects, filters and process Land Use datasets from Copernicus

# Luis de la Rua December 2025

# SETTINGS ----
source("setup.R")

# SETTINGS ----
source("setup.R")
# Additional libraries

install.packages("rgee")
install.packages("googledrive")
library(rgee)
library(googledrive)


# Country using iso3
country <- 'SLV'

# Paths to the directory we store the data
dir <- paste0("C:/GIS/UNFPA GIS/HF/", country,"/")

# 1. IMPORT LAND USE DATASET FROM GEE ====================

# Set this up later if I have time with authenticating and all the stuff

# ee_Initialize()
# reticulate::use_python()
# # rgee run this piece of code to download the land use raster from GEE
# // Define the region of interest (LACRO region)
# var lacroRegion = ee.Geometry.Rectangle([-118.0, -56.0, -34.0, 32.0]);
# 
# // Load the Copernicus Global Land Cover Layers dataset
# var landCover = ee.ImageCollection('COPERNICUS/Landcover/100m/Proba-V-C3/Global')
# .filterBounds(lacroRegion)
# .select('discrete_classification');
# 
# // Check the number of images in the collection
# print('Number of images:', landCover.size());
# 
# // Filter to get the most recent image
# var mostRecentImage = ee.Image(landCover.sort('system:time_start', false).first());
# 
# // Display the most recent image
# Map.addLayer(mostRecentImage, {}, 'Most Recent Land Cover');
# 
# // Export the most recent image
# Export.image.toDrive({
#   image: mostRecentImage,
#   description: 'land_cover_lacro',
#   region: lacroRegion,
#   scale: 100,
#   maxPixels: 1e13
# });
# ee_install()


# Importing data from local file
luse <- rast(paste0(dir,"layers/raw/landuse/land_cover_lacro.tif"))

# 2. PROCESS LAND USE DATASET =================================================

# 2.1 Reclass categories to simplified classification -------------------------

# Define the reclassification rules
reclass_table <- matrix(c(
  0, 0, 0,
  110, 126, 1,
  20, 20, 2,
  30, 30, 3,
  90, 90, 3,
  40, 40, 4,
  50, 50, 5,
  60, 60, 6,
  70, 70, 7,
  80, 80, 8,
  100, 100, 10
), ncol = 3, byrow = TRUE)


luse_rec <- classify(luse, reclass_table,
                     right = NA)

# Export to check if reclassification worked ok
# writeRaster(luse_rec, paste0(dir,"layers/raw/landuse/luse_rec.tif"), overwrite = T)

# 2.2 Reproject to Equal Area crs ----------------------------------------------

luse_rep <- project(luse_rec,"ESRI:54034",
                 method = 'near',
                 res = 1000)

# AccessMod seems to not like float and covert all values into barriers...
terra::datatype(luse_rep)

# 2.3 Export to input folder ready to be imported in Access Mod

writeRaster(luse_rep, datatype = "INT4S", paste0(dir,"layers/input/luse/lacro_luse_54034.tif"), overwrite = T)
