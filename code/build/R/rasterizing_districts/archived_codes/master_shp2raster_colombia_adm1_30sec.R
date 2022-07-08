##---------------------------------------------------
## This is R code for rasterizing shapefile of       
## Colombian administrative data to 30'' resolution                     
## Author: Alina Gafanova                 
##---------------------------------------------------
library('raster')

# Country Name as in firm-data folder
country_name = Sys.getenv("country_from_shell")
print(country_name)
# # path to shape file of Colombia ADM2 polygons
# country_shp_path = "../../../data/firm-data/Colombia/Shapefile/COL_adm_shp/COL_adm1.shp"
# #field in shapefile with unique district identifier
# id = "ID_2"
# 
# # path to raster with specific resolution and areas as values
# grid_path = "../../../data/GPW/gpw-v4-land-water-area-rev11_landareakm_30_sec_tif/gpw_v4_land_water_area_rev11_landareakm_30_sec.tif"
# 
# # name of new raster file
# new_name = "COL_adm1_30_sec"
# 
# ##---------------------------------------------------
# ## DON'T CHANGE -------------------------------------
# ##---------------------------------------------------
# 
# source("shp2raster.R")
# 
