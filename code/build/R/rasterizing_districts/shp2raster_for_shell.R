#---------------------------------------------------#
# This is R code for rasterizing shapefile with     
# administrative data to specific resolution                     
# Author: Alina Gafanova                 
#---------------------------------------------------#

# load packages
library('raster')
library('rgdal')
library('rgeos')
library('sf')
library('fasterize')
library('maptools')

#--------------------------------#
# 0. Get env vars from shell ----
#--------------------------------#
path = Sys.getenv("path_from_shell")
country_name = Sys.getenv("country_from_shell")
country_abbr = Sys.getenv("country_abbr_from_shell")
id = Sys.getenv("ID_from_shell")
path_to_grid = Sys.getenv("path_to_grid_from_shell")
adm_level = Sys.getenv("adm_level_from_shell")
raster_name = Sys.getenv("raster_name_from_shell")

country_shp_path = paste("./data/firm-data/",country_name,"/Shapefile/",country_abbr, "_adm_shp/",country_abbr,"_",adm_level,".shp", sep="")
# #--------------------------------#
# # 1. Load and clean data -----
# #--------------------------------#

setwd(path)
# read shape file of polygons
country_shp <- st_read(country_shp_path)
# read raster grid with 30'' resolution
grid <- raster(path_to_grid)
# crop grid to bbox of the country
box <- crop(grid, country_shp, snap = 'out')
country_grid <- mask(box, country_shp)

#------------------------------------------------------------#
# 2. Rasterize; if several districts cover the cell,  -----
# choose district that overlaps cell's center 
#------------------------------------------------------------#
raster_district_id <- fasterize(country_shp, country_grid, field = id, background = -99)
raster_district_id_and_areas <- stack(country_grid, raster_district_id)

#create directory if it doesn't exist
if(!dir.exists(paste("./data/firm-data/",country_name,"/Shapefile/rasterized_districts/", sep=""))) {
  dir.create(paste("./data/firm-data/",country_name,"/Shapefile/rasterized_districts/", sep=""))
}

# -99 in district means it is not a part of the country
writeRaster(raster_district_id_and_areas, paste("./data/firm-data/",country_name,"/Shapefile/rasterized_districts/",raster_name,".tif", sep=""), overwrite=TRUE)
writeRaster(country_grid, paste("./data/firm-data/",country_name,"/Shapefile/rasterized_districts/",raster_name,"_area_only.tif", sep=""), overwrite=TRUE)
writeRaster(raster_district_id, paste("./data/firm-data/",country_name, "/Shapefile/rasterized_districts/",raster_name,"_dist_id_only.tif", sep=""), overwrite=TRUE)

