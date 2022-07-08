##---------------------------------------------------
## This is R code for rasterizing shapefile of       
## Indian administrative data to 30'' resolution                     
## Author: Alina Gafanova                 
##---------------------------------------------------

##---------------------------------------------------
## MANUAL CHANGES -----------------------------------
##---------------------------------------------------

# Country Name as in firm-data folder
country_name = "India"

# path to shape file of Colombia ADM2 polygons 
country_shp_path = "../../../data/firm-data/India/Shapefile/IND_adm_shp/IND_adm2_unique_id.shp"
#field in shapefile with unique district identifier
id = "unique_id"

# path to raster with specific resolution and areas as values
grid_path = "../../../data/GPW/gpw-v4-land-water-area-rev11_landareakm_30_sec_tif/gpw_v4_land_water_area_rev11_landareakm_30_sec.tif"

# name of new raster file
new_name = "IND_adm2_30_sec"

##---------------------------------------------------
## DON'T CHANGE -------------------------------------
##---------------------------------------------------

source("shp2raster.R")

