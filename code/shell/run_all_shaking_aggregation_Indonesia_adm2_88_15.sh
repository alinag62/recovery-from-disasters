############################################
#MANUAL CHANGES BELOW ######################
############################################

#set project path
cd /Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters
export path_from_shell="/Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters"

#country name as in folder's name; country_abbr as in shapefile name
export country_from_shell="Indonesia"
export country_abbr_from_shell="IDN"
export adm_level_from_shell="adm2"

# perc_thr is for step 4 
export perc_thr_from_shell="10"

# ID is unique id in shapefile 
# ID_in_survey is unique id in firm data
# ID and ID_in_survey correspond to the same regions
export ID_from_shell="ID_2"
export ID_in_survey_from_shell="ADM2_id_in"

# years for which firm survey exists (plus a few years before for lags)
export year_start_from_shell="1973"
export year_end_from_shell="2015"

#the gridded file used for converting shapefiles to gridded version; name for the raster 
export path_to_grid_from_shell="./data/GPW/gpw-v4-land-water-area-rev11_landareakm_30_sec_tif/gpw_v4_land_water_area_rev11_landareakm_30_sec.tif"
export raster_name_from_shell="IDN_adm2_30_sec"

############################################
############################################
############################################

export PATH=$PATH:/Applications/MATLAB_R2021a.app/bin/
export PATH=$PATH:/Applications/Stata/StataMP.app/Contents/MacOS/

#Rscript code/R/rasterizing_districts/shp2raster_for_shell.R
matlab -nosplash -nodisplay -nodesktop -r  "run ./code/matlab/entire_shaking_aggregation_matlab.m; quit" 
StataMP -b do code/do/entire_shaking_aggregation_do.do
