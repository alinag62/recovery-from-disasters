/*
###########################################################################
 0)                     Intro
########################################################################### */

* Housekeeping
clear
clear matrix
set more off

local pathbuilt $path2save_shake
local percentage_thresholds $perc_thr
local path2shp $path2shp
local country $country
local country_abbr $country_abbr
local adm_level $adm_level

*************************************************
* Manual check
*************************************************
*cd /Users/alina/Box/recovery-from-disasters/
*local country Indonesia
*local country_abbr IDN
*local pathbuilt "./data/earthquakes/intermediate/`country'_adm2"
*local percentage_thresholds 10 
*local path2shp "./data/firm-data/`country'/Shapefile/`country_abbr'_adm_shp/`country_abbr'_adm2.shp"

*************************************************/
* Combine to 1 dataset
*************************************************

local files : dir "`pathbuilt'/region_dtas_collapsed" files "*.dta" 

foreach file in `files' {
	append using `pathbuilt'/region_dtas_collapsed/`file'
}

cap drop mpga mag_pgv mpgv mag num_qs number_quakes_pgv area urban_level pop
save "`pathbuilt'/region_panel/panel_earthquakes_thresh_`percentage_thresholds'.dta", replace




