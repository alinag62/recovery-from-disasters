/*
###########################################################################
                    Intro
########################################################################### */

cd /Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters

* Housekeeping
clear
clear matrix
set more off

use "./data/tropical-cyclones/intermediate/Indonesia/maxWindsADM2.dta",clear
label var maxs "Spatial Average of Maximum Annual Wind Speed (m/s)"
*#############################################################################
set scheme plottig 
grstyle init
grstyle set imesh, horizontal minor
grstyle set ci 538, select(13 10) opacity(60)
grstyle set color "35 35 35" "35 35 35"  "62 102 206"  "62 102 206"
graph set window fontface "Helvetica Light"

*#############################################################################
*1. merge with a map
rename id_2 ID_2
merge m:1 ID_2 using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2.dta"

*#############################################################################

*Generate lags and leads
keep if _m==3
drop _m

rename ADM2_id_in ADM2_id_in_shp_88
destring ADM2_id_in_shp_88, replace
merge m:1 ADM2_id_in_shp_88 using "./data/shapefiles/regions_codes/crosswalk_1988_2015_to_shp.dta"
keep if _m==3
drop _m

*create lags
sort ID_2 year
foreach i of num 1/10 {
	by ID_2: gen maxs_lag`i' = maxs[_n-`i']
	by ID_2: gen maxs_lead`i' = maxs[_n+`i']
}

merge 1:m i_harmonize_to_1988 year using "./data/firm-data/Indonesia/Final-Dataset/maindata_clean_95perc.dta"
keep if _m==3
drop _m
rename PSID plant
rename i_harmonize_to_1988 region

*use real values
gen rvad_to_lbr = rvad/lbr
label var rvad_to_lbr `"Real Productivity (VA/Labor)"'

* get deflator by sector and deflated vars
gen deflator = rvad/vad
gen rnetInv = netInv*deflator
label var rnetInv "Net Investment, deflated by sector"
gen rinv = inv*deflator
label var rinv "Investment, deflated by sector"

*create logged vars
foreach dep in rout lbr rkap rvad_to_lbr rvad rinv rnetInv rmat{
	gen log_`dep' = log10(`dep')
	local label_dep: var label `dep'
	label var log_`dep'`"Logged `label_dep'"' 
}

*#############################################################################

foreach var in maxs {
	
	foreach dep in log_rout log_rvad rinv log_rnetInv log_rvad_to_lbr log_lbr log_rmat {		
		
		local treat `var'
		foreach i of num 1/5 {
			local treat `treat' `var'_lag`i'
			di("`treat'")
		}
		
		*0-5 lags
		eststo m5_`dep': quietly: reghdfe `dep' `treat', absorb(plant year) vce(cluster plant region#year)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace

	}

	*export results 
	esttab m5_log_rout m5_log_rvad m5_rinv m5_log_rnetInv m5_log_rvad_to_lbr m5_log_lbr m5_log_rmat  using ./output/regressions_tex/Indonesia_wb/table_meth_`var'_cyclones.tex, se noconstant title("?") replace booktabs compress keep(`treat') addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level. ") s(N firm year r2 , labels("N" "Plant FE" "Year FE" "Adjusted R-squared" )) label
		
}



