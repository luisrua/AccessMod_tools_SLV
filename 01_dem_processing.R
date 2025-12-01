#01_dem_processing
# This script collects, filters and process Digital Elevation Model for AccessMod (AM)

# Luis de la Rua Dec 2025

# DEM processing is the first step to start a new project in AM environment

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

# 1. IMPORT DEM DATASET FROM GEE (let's try) ====================

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

## 1.4 GET NASADEM DATA ----

# Asset ID: NASA/NASADEM_HGT/001
# We select 'elevation' (height in meters). Other bands like 'slope' exist too.
nasadem <- ee$Image("NASA/NASADEM_HGT/001")
dem_slv <- nasadem$select("elevation")$clip(region_geometry)

# GEE cannot "download" massive rasters directly to R's memory instantly.
# It must export to Drive first.
task_desc <- "nasadem_el_salvador_raw"

task <- ee_image_to_drive(
  image = dem_slv,
  description = task_desc,
  folder = "RGEE_EXPORTS",   # A folder it will create in your Drive
  region = region_geometry,
  scale = 100,                # NASADEM resolution is 30 meters
  maxPixels = 1e9,           # Allow large file export
  fileFormat = "GeoTIFF"
)

# Start the task on Google's servers
task$start()
message("Export task started on GEE servers...")

## 1.5 MONITOR & DOWNLOAD (The "R in the Middle" automation) ----

# This loop checks the status every 10 seconds until finished.
message("Waiting for GEE to finish processing (this clips and saves to Drive)...")
ee_monitoring(task) 

# Once 'ee_monitoring' finishes, it means the file is in your Google Drive.
# Now we use R to pull it from Drive to your local computer.

message("Downloading from Google Drive to local computer...")
output_filename <- "El_Salvador_NASADEM.tif"

## 1.6  Save in local ----
# Look for the downloaded raster
folder_contents <- drive_ls(path = "RGEE_EXPORTS")

print(folder_contents)

# We take the first file in the list (folder_contents[1, ])
# This avoids typos with the exact filename
if (nrow(folder_contents) > 0) {
  
  target_file <-"El_Salvador_NASADEM.tif" # Grabs the first file in the folder
  message("Downloading: ", target_file$name)
  
  drive_download(
    file = target_file, 
    path = paste0(dir,'raw_data/SLV_NASADEM.tif'), 
    overwrite = TRUE
  )
} else {
  warning("The folder 'RGEE_EXPORTS' appears empty to R. Check if the GEE task is 100% finished.")
}

# And read raw DEM
dem <- rast(paste0(dir,'raw_data/SLV_NASADEM.tif'))
plot(dem)
dem


# 2 Reproject to Equal Area crs ================================================

dem_rep <- project(dem,"ESRI:54034",
                 method = 'near',
                 res = 100)

# AccessMod seems to not like float and covert all values into barriers...
terra::datatype(dem_rep)

# 3. Export to input folder ready to be imported in Access Mod ================
writeRaster(dem_rep, datatype = "INT4S", paste0(dir,"am_input/dem_54034.tif"), overwrite = T)
