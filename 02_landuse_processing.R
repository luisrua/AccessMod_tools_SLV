# 02_landuse_processing

# This script collects, filters and process Land Use datasets from Copernicus

# Luis de la Rua December 2025

# SETTINGS ----
source("setup.R")
# Additional libraries

# install.packages("rgee")
# install.packages("googledrive")
library(rgee)
library(googledrive)


# Country using iso3
country <- 'SLV'

# Paths to the directory we store the data
dir <- paste0("C:/GIS/UNFPA GIS/HF/", country,"/")

# 1. IMPORT LAND USE DATASET FROM GEE ====================

## 1.2 Initialize Google Earth Engine ----
# If this is your first time, you might need to run: ee_install()
# This sets up the Python environment for you.
# ee_install()

# Authenticate and initialize
ee_Initialize(user = 'luisruarodriguez@gmail.com',drive = TRUE)
#ee_clean_user_credentials()

## 1.3 Define the Region ----
# We use the FAO GAUL dataset (available inside GEE) to get the country border
# Country definitions: El Salvador is roughly feature index or name filter
ee_Initialize()
countries <- ee$FeatureCollection("FAO/GAUL/2015/level0")
el_salvador_ee <- countries$filter(ee$Filter$eq("ADM0_NAME", "El Salvador"))

# Extract geometry for clipping later
region_geometry <- el_salvador_ee$geometry()

## 1.4 Get Land Cover Data ----
# Latest data ESA_WorldVover_2021
# The band is named "Map"
wc_collection <- ee$ImageCollection("ESA/WorldCover/v200")
# Filter and clip

lc_slv <- wc_collection$first()$clip(region_geometry)

task_desc <- "ESA_WorldCover_2021_SLV"

task <- ee_image_to_drive(
  image = lc_slv,
  description = task_desc,
  folder = "RGEE_EXPORTS",
  region = region_geometry,
  scale = 100,             
  maxPixels = 1e9,
  fileFormat = "GeoTIFF"
)

# Start the task
task$start()
message("Export task started for ESA WorldCover 2021...")


## 1.5 Monitor & Download (The "R in the Middle" automation) ----

# This loop checks the status every 10 seconds until finished.
message("Waiting for GEE to finish processing (this clips and saves to Drive)...")
ee_monitoring(task) 

# Once 'ee_monitoring' finishes, it means the file is in your Google Drive.
# Now we use R to pull it from Drive to your local computer.

message("Downloading from Google Drive to local computer...")
output_filename <- "slv_esa_lcover.tif"

## 1.6  Save in local ----
# Look for the downloaded raster
folder_contents <- drive_ls(path = "RGEE_EXPORTS")

print(folder_contents)

# We take the first file in the list (folder_contents[1, ])
# This avoids typos with the exact filename
if (nrow(folder_contents) > 0) {
  
  target_file <- folder_contents[1, ]
  message("Downloading: ", target_file$name)
  
  drive_download(
    file = target_file, 
    path = paste0(dir,'raw_data/SLV_ESA_LCOVER.tif'), 
    overwrite = TRUE
  )
} else {
  warning("The folder 'RGEE_EXPORTS' appears empty to R. Check if the GEE task is 100% finished.")
}

# And read raw DEM
lcover <- rast(paste0(dir,'raw_data/SLV_ESA_LCOVER.tif'))
plot(lcover, main = "Land Cover (El Salvador)", type = "classes")
lcover

col_tab <- data.frame(
  value = c(0,10, 20, 30, 40, 50, 60, 70, 80, 90, 95, 100),
  color = c("#666666", "#006400", "#ffbb22", "#ffff4c", "#f096ff", "#fa0000", 
            "#b4b4b4", "#f0f0f0", "#0064c8", "#0096a0", "#00cf75", "#fae6a0")
)

plot(lcover, 
     type = "classes", 
     levels = col_tab$value, 
     col = col_tab$color,
     main = "ESA WorldCover 2021 - El Salvador")


# 2. PROCESS LAND USE DATASET =================================================

# 2.1 Reclass categories to simplified classification -------------------------

# Define the reclassification rules
reclass_table <- matrix(c(
  0, 0, 0,
  10, 10, 1,
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


luse_rec <- classify(lcover, reclass_table,
                     right = NA)

# Export to check if reclassification worked ok
# writeRaster(luse_rec, paste0(dir,"layers/raw/landuse/luse_rec.tif"), overwrite = T)

# 2.2 Reproject to Equal Area crs ----------------------------------------------

luse_rep <- project(luse_rec,"ESRI:54034",
                 method = 'near',
                 res = 100)

# AccessMod seems to not like float and covert all values into barriers...
terra::datatype(luse_rep)

# 2.3 Export to input folder ready to be imported in Access Mod

writeRaster(luse_rep, datatype = "INT4S", paste0(dir,"am_input/luse_54034.tif"), overwrite = T)
