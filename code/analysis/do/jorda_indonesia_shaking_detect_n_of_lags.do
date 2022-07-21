/***************************************************************
Stata code to detect N of lags to use in jorda regression
for shaking in Indonesia
***************************************************************/

cd /Users/alinagafanova/Library/CloudStorage/Box-Box/recovery-from-disasters

* Housekeeping
clear
clear matrix
set more off

*#############################################################################*/
*Part I. Creating lags in shaking data
*#############################################################################

use "./data/earthquakes/intermediate/Indonesia_adm2/region_panel/panel_earthquakes_thresh_10.dta", clear

merge m:1 ID_2 using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2.dta"
drop _m
rename ADM2_id_in ADM2_id_in_shp_88
destring ADM2_id_in_shp_88, replace
merge m:1 ADM2_id_in using "./data/shapefiles/regions_codes/crosswalk_1988_2015_to_shp.dta"
drop _m

rename populatedmpga_aw pop_mpga_aw
rename populatednum_qs_aw pop_num_aw
label var pop_mpga_aw "Max PGA"
label var pop_num_aw "N of EQs"

*create lags
sort i_harmonize_to_1988 year
foreach i of num 1/10 {
	foreach shake in pop_mpga_aw pop_num_aw{
		by i_harmonize_to_1988: gen `shake'_lag`i' = `shake'[_n-`i']
		label var `shake'_lag`i' "Lag `i'"
	}
}

keep year i_harmonize_to_1988 pop_mpga_aw* pop_num_aw*
rename i_harmonize_to_1988 region

*only years of the survey 
keep if year>=1988&year<=2015


*#############################################################################*/
*Part II. Testing for autocorrelation: 10 lags
*#############################################################################

preserve
eststo clear
local treat
local out 
foreach i of num 1/10 {
	local treat `treat' pop_mpga_aw_lag`i'
	quietly: eststo d`i': areg pop_mpga_aw `treat', absorb(region) vce(robust)
	local out `out' d`i'
	
}
esttab `out', se label s(N, labels("N") fmt(%9.0f)) replace nocon b(3) mtitles("MPGA" "" "" "" "" "" "" "" "" "")
*esttab `out' using ./output/regressions_tex/Indonesia/autocorr_shaking_1988_2015_mpga.tex, se label s(N, labels("N") fmt(%9.0f)) replace nocon b(3) mtitles("MPGA" "" "" "" "" "" "" "" "" "")

restore


preserve
eststo clear
local treat
local out 
foreach i of num 1/10 {
	local treat `treat' pop_num_aw_lag`i'
	quietly: eststo d`i': areg pop_num_aw `treat', absorb(region) vce(robust)
	local out `out' d`i'
	
}
esttab `out', se label s(N, labels("N") fmt(%9.0f)) replace nocon b(3) mtitles("N of EQs" "" "" "" "" "" "" "" "" "")
*esttab `out' using ./output/regressions_tex/Indonesia/autocorr_shaking_1988_2015_num.tex, se label s(N, labels("N") fmt(%9.0f)) replace nocon b(3) mtitles("N of EQs" "" "" "" "" "" "" "" "" "")
restore

*############################################################################# */




