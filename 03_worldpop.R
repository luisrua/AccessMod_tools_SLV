# 03_worldpop
# This script collects, filters and process WorldPop population grids available
# at Worldpop repository

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

# 1. DOWNLOAD POP RASTER DIRECTLY FROM WorldPop Site ----
# Save path
save_path <- paste0(dir,"raw_data/wpop_2025.tif")

# Dataset URL
wpop2025_url <- "https://data.worldpop.org/GIS/Population/Global_2015_2030/R2025A/2025/SLV/v1/100m/constrained/slv_pop_2025_CN_100m_R2025A_v1.tif"


if(!file.exists(save_path)) {

  download.file(wpop2025_url, destfile = save_path, mode = "wb")
}

wpop <- rast(save_path)

# Calculate total population
wpop_tpop <- global(wpop, fun = "sum", na.rm=T)
wpop_tpop


# 2. RASTERS PROCESSING.=======================================================

## 2.1 Reproject to Equal Area crs using Mass preserving =====

target_crs <- "ESRI:54034"

# I am reprojecting wpop in one go jut the get extension for the new raster

target_template <- rast(extent = project(ext(wpop), from = crs(wpop), to = target_crs),
                        crs = target_crs, 
                        resolution = 100)

# --- THE CORRECT "MASS PRESERVING" WORKFLOW ---

# A. Calculate the area of each pixel in the ORIGINAL raster (in square meters)
#    (WGS84 pixels get smaller as you go north, so this is crucial)
area_source <- cellSize(wpop, unit = "m")

# B. Convert "People" to "People per Square Meter" (Density)
pop_density <- wpop / area_source

# C. Reproject the DENSITY using Bilinear
#    (Density is a continuous field, so Bilinear is valid here!)
pop_density_proj <- project(pop_density, target_template, method = "bilinear")

# D. Calculate the area of pixels in the NEW raster
#    (In Equal Area projection, this should be constant ~10,000 m2, but let's calculate to be exact)
area_target <- cellSize(pop_density_proj, unit = "m")

# E. Convert back to "People" (Density * Area)
pop_final <- pop_density_proj * area_target


# Verify the Totals (The "Mass" Check)
# The sums should be very close (within <1% difference due to edge effects)
sum_orig <- global(wpop, "sum", na.rm=TRUE)[1,1]
sum_new  <- global(pop_final, "sum", na.rm=TRUE)[1,1]

message("Original Pop: ", round(sum_orig))
message("New Pop:      ", round(sum_new))
message("Difference:   ", round(sum_new - sum_orig))

## 2.2 Last adjustment ----

pop_ratio <- sum_orig/sum_new
wpop_rep <- pop_final * pop_ratio

sum_rep <- global(wpop_rep, "sum", na.rm=TRUE)[1,1]

message("Difference: ", sum_rep - sum_orig)

# Plot
plot(wpop_rep, main = "Reprojected Population (Mass Preserved)")

## 2.3 Export
writeRaster(wpop_rep,datatype = "INT4S", paste0(dir,"am_input/wpop25_54034.tif"), overwrite = T)




