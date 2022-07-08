##---------------------------------------------------
## This is R code for rasterizing shapefile with     
## administrative data to specific resolution                     
## Author: Alina Gafanova                 
##---------------------------------------------------

# load packages
library('raster')
library('rgdal')
library('rgeos')
library('sf')
library('fasterize')
library('maptools')

#--------------------------------#
# 1. Load and clean data
#--------------------------------#

# read shape file of polygons 
country_shp <- st_read(country_shp_path)
# read raster grid with 30'' resolution 
grid <- raster(grid_path)
# crop grid to bbox of the country
country_grid <- mask(crop(grid, country_shp, snap = 'out'), country_shp)

#------------------------------------------------------------#
# 2. Rasterize; if several districts cover the cell,
# choose district that overlaps cell's center
#------------------------------------------------------------#
raster_district_id <- fasterize(country_shp, country_grid, field = id, background = -99)
raster_district_id_and_areas <- stack(country_grid, raster_district_id)

#create directory if it doesn't exist
if(!dir.exists(paste("../../../data/firm-data/",country_name,"/Shapefile/rasterized_districts/", sep=""))) {
  dir.create(paste("../../../data/firm-data/",country_name,"/Shapefile/rasterized_districts/", sep=""))
}

# -99 in district means it is not a part of the country
writeRaster(raster_district_id_and_areas, paste("../../../data/firm-data/",country_name,"/Shapefile/rasterized_districts/",new_name,".tiff", sep=""))
writeRaster(country_grid, paste("../../../data/firm-data/",country_name,"/Shapefile/rasterized_districts/",new_name,"_area_only.tiff", sep=""))
writeRaster(raster_district_id, paste("../../../data/firm-data/",country_name, "/Shapefile/rasterized_districts/",new_name,"_dist_id_only.tiff", sep=""))
