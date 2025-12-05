# 08_climate_refuges_locations_processing

# This script collects, filters and process potential climate refuges from HDX
# use PAHO dataset
# Luis de la Rua December 2025

# SETTINGS ----
# Clean workspace
rm(list = ls())
gc()

source("setup.R")

# Additional libraries
library(rhdx)
library(readr)

# Country using iso3
country <- 'SLV'

# Paths to the directory we store the data
dir <- paste0("C:/GIS/UNFPA GIS/HF/", country,"/")


# 1. IMPORT AND CLIP WITH sALVADOR EXTENT ======================================
# 1. DOWNLOAD DATASET FROM HDX -------------------------------------------------
## 1.1 Connect to HDX

set_rhdx_config(hdx_site = "prod")

## 1.2 Search and Fetch the Dataset

# We search for the specific ID: 'hotosm_slv_waterways'
# This dataset is managed by the Humanitarian OpenStreetMap Team (HOT)
dataset <- search_datasets("hotosm_slv_points_of_interest", rows = 1) %>% 
  .[[1]]

resource_list <- get_resources(dataset)

resource <- dataset %>% 
  get_resource(3)

## 1.3 Save in raw data folder and select the right item within the gpkg
zip_path <- resource %>% 
  download_resource(path = tempdir(), force = TRUE)
unzip(zip_path, exdir = paste0(dir,"raw_data"))

# Load the thing as a collection 
pois <- svc(paste0(dir,"raw_data/hotosm_slv_points_of_interest.gpkg"))
pois <- pois[[2]] # Adjust number if needed this case is the second item

plot(pois, col="red")

# 2. HARMONISE, CLEAN AND CONVERT TO SPATIAL ===================================
names(pois)
pois

# summary the categories to ask about refuge cat selection
sum_table <- pois %>% 
  group_by(amenity) %>% 
  summarize(count = n())

## 2.1 First classification ----

refuge_high <- c("school", "college", "university", "kindergarten", 
                 "place_of_worship", "townhall", "alcaldia", 
                 "community_centre", "social_centre", "shelter", 
                 "hospital", "clinic", "courthouse", "music_school")

refuge_potential <- c("cinema", "theatre", "arts_centre", "events_venue",
                      "bus_station", "ferry_terminal", "police", 
                      "fire_station", "hotel")

# Apply the classification to your dataframe
# Replace 'poi_points' with your actual dataframe name
poi_classified <- pois %>%
  mutate(
    refuge_status = case_when(
      amenity %in% refuge_high ~ "Yes",
      amenity %in% refuge_potential ~ "Potential",
      TRUE ~ "No" # Everything else
    )
  )  %>%
  select(c(osm_id,refuge_status, amenity)) %>% 
  filter(refuge_status == 'Yes')


## 2.2 View the result for the "Yes" categories ----
refuge_summary <- poi %>%
  filter(refuge_status == "Yes") %>%
  group_by(amenity) %>%
  count() %>%
  arrange(desc(n)) %>% 
  as_tibble()

print(refuge_summary)


# Export as csv
write.csv(poi_classified, paste0("C:/GIS/UNFPA GIS/Spatial Analysis Regional/Disaster_popestimates/SLV/tables/cat_refugios.csv"))


## 2.3 Reproject layer to Equal Area Projection -----
model_crs <- "ESRI:54034"

poi_classified <- project(poi_classified, model_crs)

plot(poi_classified)




# for the moment we keep all fields in case they can be useful
# Export to GPKG in layers folder

writeVector(poi_classified,paste0(dir,"am_input/refuges_54034.shp"), overwrite = T)


