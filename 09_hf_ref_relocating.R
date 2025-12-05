
## HF & Refuges Correction ##
# This script drags HF or Refuges located in invalid pixels in the merged land cover
# (water bodies, barriers and land use with speed = 0) to the closest road pixel.


# Luis de la Rua December 2025

# SETTINGS ----
# Clean workspace
rm(list = ls())
gc()

source("setup.R")

# Additional libraries
library(eeptools) # Check duplicates

# Country using iso3
country <- 'SLV'

# Paths to the directory we store the data
dir <- paste0("C:/GIS/UNFPA GIS/HF/", country,"/")



# Access mode detects the H Facilities that fall into invalid pixels
# 1. Prepare data input
# Import refuges layer
# hf_am <- read.csv(paste0(dir,"layers/input/hf/am5_export_table_hfTable_2024-12-18.csv"))
ref <- vect(paste0(dir,"am_input/refuges_54034.shp"))

# We cannot download the csv table anymore so I am puting here the osmid directly to identify refuges in barrier zones.

isid(as.data.frame(ref),"osm_id") # check fid is unique value

# Ref in barrier
barr_id <- c('3814809441', '4037453053','8038412534', '9976280797','10176132951' )

ref <- ref %>% 
  mutate(in_barrier = ifelse(osm_id %in% barr_id, 'yes', 'no'))

# Import friction raster

# friction <- rast(paste0(dir,"layers/am_output/raster_land_cover_merged_merge_nonav_20241216/raster_land_cover_merged_merge_nonav_20241216.img"))
friction <- rast(paste0(dir,"AM_results/friction_1_2025_12_05@19_44/raster_land_cover_merged_stack1.img"))

# Check crs compatibility
same.crs(friction,ref)

# 2. Start correction process ========

# HF are already identified by error and by luse cat where they fall.
# Identify luse categories where we want to move the selected points.
head(ref)
# We need to correct HF that are either located in barrier or in landuseZero

# Identify hf to be corrected with field tocorr
ref <- ref %>% 
  mutate(tocorr = ifelse(in_barrier=='yes' , 1,0)) 

ref_to_corr <- ref %>% 
  filter(tocorr == 1)

# Find the cell indices where the raster values are greater than 1000 (roads in the friction layer)
cell_indices <- which(values(friction) > 1000)

# Convert these cell indices to spatial coordinates
coords <- xyFromCell(friction, cell_indices)

# Function to find the nearest road point for each point
find_nearest_road_point <- function(point, road_coords) {
  distances <- sqrt((road_coords[,1] - point[1])^2 + (road_coords[,2] - point[2])^2)
  nearest_index <- which.min(distances)
  return(road_coords[nearest_index, ])
}

# Create a matrix of coordinates for the points
point_coords <- crds(ref_to_corr)

# Update the coordinates of each point to the nearest road point
new_coords <- t(apply(point_coords, 1, find_nearest_road_point, coords))

# reconnect attributes
ref_to_corr_df <- as.data.frame(ref_to_corr)

colnames(new_coords) <- c("x", "y")

ref_to_corr_df <- cbind(new_coords, ref_to_corr_df)

ref_corrected <- vect(ref_to_corr_df, geom = c("x", "y"), crs = crs(ref))
nrow(ref_corrected)

# 3. Consolidate and export =====
ref_tocomplete <- ref %>% 
  filter(tocorr == 0)

nrow(ref_tocomplete)

ref_corr <- rbind(ref_tocomplete,ref_corrected)



writeVector(ref_corr,paste0(dir,"am_input/ref_corrected_54034.shp"), overwrite = T)
