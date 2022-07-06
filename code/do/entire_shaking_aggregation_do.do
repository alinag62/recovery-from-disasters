*******************************************************
***MANUAL CHOICE, DONE IN SHELL************************
*******************************************************

*country name as in folder's name; country_abbr as in shapefile name
*level of adm data
*perc_thr is for step 4
global country: env country_from_shell
global country_abbr: env country_abbr_from_shell
global adm_level: env adm_level_from_shell
global perc_thr: env perc_thr_from_shell

* ID is unique id in shapefile 
* ID_in_survey is unique id in firm data
* ID and ID_in_survey correspond to the same regions
global ID: env ID_from_shell
global ID_in_survey: env ID_in_survey_from_shell

*******************************************************
*******************************************************
*******************************************************
*for manual check:
*cd /Users/alina/Box/recovery-from-disasters/
*global country Colombia
*global country_abbr COL
*global perc_thr 10
*global ID ID_2
*global ID_in_survey id_used
********************************************************

local country $country
local country_abbr $country_abbr
local adm_level $adm_level

global path2save_shake "./data/earthquakes/intermediate/`country'_`adm_level'"
global firms_folder "./data/firm-data/`country'"
global path2shp "./data/firm-data/`country'/Shapefile/`country_abbr'_adm_shp/`country_abbr'_`adm_level'.shp"

* create folders if they don't exist
capture confirm file $path2save_shake/region_dtas
if _rc mkdir $path2save_shake/region_dtas

capture confirm file $path2save_shake/region_dtas_collapsed
if _rc mkdir $path2save_shake/region_dtas_collapsed

capture confirm file $path2save_shake/region_panel
if _rc mkdir $path2save_shake/region_panel


* Step 3
do code/do/ShakingAggregation3_CSVtoStata.do
di("Done with CSVtoStata!")

*Step 4
do code/do/ShakingAggregation4_SpatialAggregation.do
di("Done with SpatialAggregation!")

*Step 5
do code/do/ShakingAggregation5_CombiningDatasets.do
di("Done with CombiningDatasets!")


