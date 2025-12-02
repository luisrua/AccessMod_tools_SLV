#05_roads_processing
# This script collects, filters and process Roads and Waterways input datasets 
# from HDX as input to carry out Health Facilities accessibility assessment

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
dataset <- search_datasets("hotosm_slv_roads", rows = 1) %>% 
  .[[1]]

resource_list <- get_resources(dataset)

resource <- dataset %>% 
  get_resource(3)

## 1.3 Save in raw data folder and select the right item within the gpkg
zip_path <- resource %>% 
  download_resource(path = tempdir(), force = TRUE)
unzip(zip_path, exdir = paste0(dir,"raw_data"))

# Load the thing as a collection 
roads <- svc(paste0(dir,"raw_data/hotosm_slv_roads.gpkg"))
roads <- roads[[2]] # Adjust number if needed this case is the second item

plot(roads, col="black", main="Extracted Lines")


# 2. HARMONISE AND CLEAN DATA. ================================================

## 2.1 Disolve and remove categories are not useful 
roads_proc <- roads %>% 
  select(c(highway)) %>% 
  aggregate(by = "highway", FUN = union) %>% # Disolve to make it easier to handle
  select(-agg_n)


entries_out <- c("MT-338", "abandoned", "bridleway", "bus_guideway", "bus_stop", 
                 "closed", "construction", "corridor", "crossing", "cycleway", 
                 "disused", "dummy", "elevator", "emergency_access_point", 
                 "emergency_bay", "escape", "footway", "no", "passing_place",
                 "pedestrian", "planned", "proposed", "raceway", "razed", "steps", 
                 "traffic_signals", "via_ferrata", "yes", "path","rest_area",
                 "platform", "path")

roads_proc <- roads_proc %>% 
  filter(!highway %in% entries_out)

# Merge residential categories
unique(roads_proc$highway)

table(roads_proc$highway)

## 2.2 Reproject layer to Equal Area Projection -----
model_crs <- "ESRI:54034"

roads_proc_rep <- project(roads_proc, model_crs)

# 3.4 Include Average Speed for each category.

# Get all categories and export table to set average speeds
road_cat <- roads_proc_rep %>%
  as.data.frame() %>%
  select(highway)

road_cat

# Define speed limits for each category
entry1 <- c("busway", 40)
entry2 <- c("living_street", 40)
entry3 <- c("motorway", 90)
entry4 <- c("motorway_link", 90)
entry5 <- c("primary", 80)
entry6 <- c("primary_link", 80)
entry7 <- c("residential", 40)
entry8 <- c("road", 80)
entry9 <- c("secondary", 80)
entry10 <- c("secondary_link", 80)
entry11 <- c("service", 40)
entry12 <- c("services", 40)
entry13 <- c("tertiary", 70)
entry14 <- c("tertiary_link", 70)
entry15 <- c("track", 40)
entry16 <- c("trunk", 40)
entry17 <- c("trunk_link", 40)
entry18 <- c("unclassified", 40)

# Combine all entries into a list and then create a data frame
road_cat_speed <- as.data.frame(do.call(rbind, list(
  entry1, entry2, entry3, entry4, entry5, entry6, entry7, entry8, entry9,
  entry10, entry11, entry12, entry13, entry14, entry15, entry16, entry17, 
  entry18
)))

# Rename columns
colnames(road_cat_speed) <- c("highway", "avsp_kmh")

# Convert avsp_kmh to numeric
road_cat_speed$avsp_kmh <- as.numeric(road_cat_speed$avsp_kmh)

# Create integer unique id for each category 
road_cat_speed<- road_cat_speed %>% 
  mutate(rid = row_number())

# Display the data frame
print(road_cat_speed)

# Export into csv to be imported on AccessMod later on
write_csv(road_cat_speed, paste0(dir,"am_input/road_cat_speed_kmh.csv"))

# Merge speed table with road layer
road_input <- merge(roads_proc_rep, road_cat_speed, by = "highway")
View(as.data.frame(road_input))

  
# Export into layer format to be accessed by qGIS (gpkg has better handling) and by AccessMod (only reads shp)
writeVector(road_input, paste0(dir,"am_input/lroads_speed_54034.shp"), overwrite=T)
