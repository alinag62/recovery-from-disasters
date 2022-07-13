############################################
#MANUAL CHANGES BELOW ######################
############################################

#set project path
cd /Users/alinagafanova/Library/CloudStorage/Box-Box/recovery-from-disasters
export path_from_shell="/Users/alinagafanova/Library/CloudStorage/Box-Box/recovery-from-disasters"

#country name as in folder's name; country_abbr as in shapefile name; level of adm data
export country_from_shell="Colombia"
export country_abbr_from_shell="COL"
export adm_level_from_shell="adm1"

# perc_thr is for step 4 
export perc_thr_from_shell="10"

# ID is unique id in shapefile 
export ID_from_shell="ID_1"

# years for which firm survey exists (plus a few years before for lags)
export year_start_from_shell="1973"
export year_end_from_shell="1991"

#the gridded file used for converting shapefiles to gridded version; name for the raster 
export path_to_grid_from_shell="./data/GPW/gpw-v4-land-water-area-rev11_landareakm_30_sec_tif/gpw_v4_land_water_area_rev11_landareakm_30_sec.tif"
export raster_name_from_shell="COL_adm1_30_sec"

############################################
############################################
############################################

export PATH=$PATH:/Applications/MATLAB_R2022a.app/bin/
export PATH=$PATH:/Applications/Stata/StataSE.app/Contents/MacOS/

Rscript code/build/R/rasterizing_districts/shp2raster_for_shell.R
matlab -nosplash -nodisplay -nodesktop -r  "run ./code/build/matlab/entire_shaking_aggregation_matlab.m; quit"  
StataSE -b do code/build/do/entire_shaking_aggregation_do.do
