/***************************************************************
Stata code for merging Indonesia firm data and cyclones
***************************************************************/

cd /Users/alinagafanova/Library/CloudStorage/Box-Box/recovery-from-disasters

* Housekeeping
clear
clear matrix
set more off

*#############################################################################*/
*Part I. Creating lags in cyclones data
*#############################################################################

use "./data/tropical-cyclones/intermediate/Indonesia/maxWindsADM2_with_population.dta",clear

merge m:1 ID_2 using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2.dta"
drop _m
rename ADM2_id_in ADM2_id_in_shp_88
destring ADM2_id_in_shp_88, replace
merge m:1 ADM2_id_in using "./data/shapefiles/regions_codes/crosswalk_1988_2015_to_shp.dta"
drop _m

rename weighted_pop_v_s maxs_pop_only
rename weighted_pop_storm storm_pop_only

label var maxs_pop_only "Max Speed (m/s)"
label var storm_pop_only "N of Storms"

sort i_harmonize_to_1988 year
foreach i of num 1/10 {
	foreach storm in maxs_pop_only storm_pop_only {
		by i_harmonize_to_1988: gen `storm'_lag`i' = `storm'[_n-`i']
		label var `storm'_lag`i' "Lag `i'"
	}
}

*keep year ID_2 i_harmonize_to_1988 maxs_pop_only* storm_pop_only* _ID

*#############################################################################*/
*Part II. Merging shaking data with firm data and cleaning it
*#############################################################################
merge 1:m i_harmonize_to_1988 year using "./data/firm-data/Indonesia/Final-Dataset/maindata_clean_95perc.dta"
keep if _m==3
drop _m
rename i_harmonize_to_1988 region
rename PSID plant

label var ID_2 "unique ADM2 in shapefile"
label var region "unique region in the survey"
label var _ID "shp2dta ID"

* get deflator by sector and create real vars
gen deflator = rvad/vad
gen rnetInv = netInv*deflator
label var rnetInv "Net Investment, deflated by sector"
gen rlabprod = labprod*deflator
label var rlabprod "Labor Productivity (va/lbr), deflated by sector"
gen rinv = inv*deflator
label var rinv "Investment, deflated by sector"

*for capital we use lnrkapFB - previously cleaned variable
rename lnrkapFB log_rkapFB
replace log_rkapFB = log_rkapFB*100

*create logged vars
foreach dep in rout lbr rvad rnetInv rlabprod rwage rmat rinv{
	gen log_`dep' = 100*log(`dep')
	local label_dep: var label `dep'
	label var log_`dep'`"100Log `label_dep'"' 
}

*dummies if variables exist
foreach dep in rout lbr rvad rnetInv rlabprod rwage rmat rinv rkapFB{
	gen log_`dep'_exists = 1 if log_`dep'!=.
	replace log_`dep'_exists = 0 if log_`dep'_exists==.
}

******************************************************************************************************

*change variable labels for better titles
label var log_rout "100Log(Output)" 
label var log_lbr "100Log(L)"
label var log_rvad "100Log(VA)"
label var log_rnetInv "100Log(Net Inv)"
label var log_rlabprod  "100Log(VA/L)"
label var log_rwage "100Log(Avg Wage)"
label var log_rinv "100Log(Inv)"
label var log_rmat "100Log(Mat)"
label var log_rkapFB "100Log(K)"

******************************************************************************************************
