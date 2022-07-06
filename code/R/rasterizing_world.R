##---------------------------------------------------
## This is R code for rasterizing world shapefile
## to get land areas                
## Author: Alina Gafanova                 
##---------------------------------------------------

# load packages
library('raster')
library('rgdal')
library('rgeos')
library('sf')
library('fasterize')
library('maptools')

path <- "/Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters"
setwd(path)

# read shape file of the world
world_shp <- st_read("./data/shapefiles/qgis_world_basemap/qgis_basemap.shp")
# path and read file with land areas
path_to_grid <- "./data/GPW/gpw-v4-land-water-area-rev11_landareakm_30_sec_tif/gpw_v4_land_water_area_rev11_landareakm_30_sec.tif"
grid <- raster(path_to_grid)

# save country ids on top of areas
raster_district_id <- fasterize(world_shp, grid, field = "fid", background = -99)
raster_district_id_and_areas <- stack(grid, raster_district_id)

# -99 in district means it is not a part of the world
writeRaster(raster_district_id_and_areas, "./data/shapefiles/qgis_basemap_rasterized/world.tiff", overwrite=TRUE)
writeRaster(grid,"./data/shapefiles/qgis_basemap_rasterized/world_area_only.tiff",  overwrite=TRUE)
writeRaster(raster_district_id, "./data/shapefiles/qgis_basemap_rasterized/world_ids_only.tiff", overwrite=TRUE)




