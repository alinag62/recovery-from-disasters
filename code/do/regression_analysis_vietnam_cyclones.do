cd /Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters

* Housekeeping
clear
clear matrix
set more off

/*import delimited "./data/tropical-cyclones/intermediate/Vietnam/maxWindsADM2.csv", encoding(ISO-8859-9) clear 
drop v1
rename id_2 ID_2
rename v_s maxs
label var maxs "Spatial Average of Maximum Annual Wind Speed (m/s)"
save "./data/tropical-cyclones/intermediate/Vietnam/maxWindsADM2.dta", replace*/

use "./data/tropical-cyclones/intermediate/Vietnam/maxWindsADM2.dta",clear
*#############################################################################
set scheme plottig 
grstyle init
grstyle set imesh, horizontal minor
grstyle set ci 538, select(13 10) opacity(60)
grstyle set color "35 35 35" "35 35 35"  "62 102 206"  "62 102 206"
graph set window fontface "Helvetica Light"

*#############################################################################
*Generate lags and leads
merge m:1 ID_2 using "./data/firm-data/Vietnam/gadm36_VNM_shp/VNM_adm2.dta"
drop NL_NAME_1 NAME_2 NL_NAME_2 TYPE_2 ENGTYPE_2 _m GID_1 NAME_1 VARNAME_2
*rename NAME_1 adm1
*rename VARNAME_2 adm2

merge m:1 ID_2 using "./data/firm-data/Vietnam/gadm36_VNM_shp/VNM_adm2_areas_gadm36.dta"
drop _m

sort ID_2 year
foreach i of num 1/10 {
	by ID_2: gen maxs_lag`i' = maxs[_n-`i']
	by ID_2: gen storm_lag`i' = storm[_n-`i']
	by ID_2: gen maxs_lead`i' = maxs[_n+`i']
}

merge 1:m year ID_2 using "./data/firm-data/Vietnam/Vietnam_worldbank_data/firms_VNM_clean.dta"
keep if _m==3
drop _m

*clean firm data
label var rK "Real Capital"
label var LPV "Labor Productivity (Real VA / Labor)"
rename id plant
drop region
rename ID_2 region
gen rtot_wage = rwage*L
label var rtot_wage "Real Total Wage"
gen sales2labor = rS/L
label var sales2labor "Real Sales per Worker"
*****************

*create logged vars
foreach dep in rS rM rV rLC rK LPV rwage L rtot_wage sales2labor{
	gen log_`dep' = log(`dep')
	local label_dep: var label `dep'
	label var log_`dep'`"Logged `label_dep'"' 
}

*dummies if variables exist
foreach dep in rS rM rV rLC rK LPV rwage L rtot_wage sales2labor{
	gen `dep'_exists = 1 if `dep'!=.
	replace `dep'_exists = 0 if `dep'_exists==.
	
	gen log_`dep'_exists = 1 if log_`dep'!=.
	replace log_`dep'_exists = 0 if log_`dep'_exists==.
}

******************************************************************************************************
/*Maximum observations for each dependent variable (different N in each regression)
sort plant year

eststo clear
foreach var in maxs {
	
	foreach dep in log_rS log_rM log_rV log_rLC log_rK {		
		
		local treat `var'
		foreach i of num 1/5 {
			local treat `treat' `var'_lag`i'
			di("`treat'")
		}
		
		*0-5 lags
		eststo `dep': quietly: reghdfe `dep' `treat', absorb(plant year) vce(cluster plant region#year)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace

	}

	*export results 
	esttab log_rS log_rM log_rV log_rLC log_rK  using ./output/regressions_tex/Vietnam/table_`var'_part1.tex, se noconstant title("?") replace booktabs compress keep(`treat') addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level. ") s(N firm year r2_a , labels("N" "Plant FE" "Year FE" "Adjusted R-squared" )) label
		
}

eststo clear
foreach var in maxs {
	
	foreach dep in log_LPV log_rwage log_L log_rtot_wage  {		
		
		local treat `var'
		foreach i of num 1/5 {
			local treat `treat' `var'_lag`i'
			di("`treat'")
		}
		
		*0-5 lags
		eststo `dep': quietly: reghdfe `dep' `treat', absorb(plant year) vce(cluster plant region#year)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace

	}

	*export results 
	esttab log_LPV log_rwage log_L log_rtot_wage  using ./output/regressions_tex/Vietnam/table_`var'_part2.tex, se noconstant title("?") replace booktabs compress keep(`treat') addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level. ") s(N firm year r2_a , labels("N" "Plant FE" "Year FE" "Adjusted R-squared" )) label
		
}*/


******************************************************************************************************
* 2007-2013: find an overlap so that N is the same for all the regressions

preserve
sort plant year
eststo clear
keep if log_rS_exists==1&log_rLC_exists==1&log_rK_exists==1&log_rwage_exists==1&log_L_exists==1&log_rtot_wage_exists==1&log_sales2labor_exists==1

foreach var in maxs {
	
	foreach dep in log_rS log_rLC log_rK  log_rwage log_L log_rtot_wage log_sales2labor {		
		
		local treat `var'
		foreach i of num 1/5 {
			local treat `treat' `var'_lag`i'
			di("`treat'")
		}
		
		*0-5 lags
		eststo `dep': quietly: reghdfe `dep' `treat', absorb(plant year) vce(cluster plant region#year)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace

	}

	*export results 
	esttab log_rS log_rLC log_rK  log_rwage log_L log_rtot_wage log_sales2labor  using ./output/regressions_tex/Vietnam/table_maxs_stable_obs_v1.tex, se noconstant title("?") replace booktabs compress keep(`treat') addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level. ") s(N firm year r2_a , labels("N" "Plant FE" "Year FE" "Adjusted R-squared" )) label
		
}

restore 

******************************************************************************************************
* 2009-2013: find an overlap so that N is the same for all the regressions (you can use VA here)

preserve

sort plant year

keep if log_rS_exists==1&log_rM_exists==1&log_rV_exists==1&log_rLC_exists==1&log_rK_exists==1&log_rwage_exists==1&log_L_exists==1&log_rtot_wage_exists==1&log_LPV_exists==1&log_sales2labor_exists==1
eststo clear
foreach var in maxs {
	
	foreach dep in log_rS log_rLC log_rK  log_rwage log_L log_rtot_wage log_sales2labor {		
		
		local treat `var'
		foreach i of num 1/5 {
			local treat `treat' `var'_lag`i'
			di("`treat'")
		}
		
		*0-5 lags
		eststo `dep': quietly: reghdfe `dep' `treat', absorb(plant year) vce(cluster plant region#year)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace

	}

	*export results 
	esttab log_rS log_rLC log_rK  log_rwage log_L log_rtot_wage log_sales2labor  using ./output/regressions_tex/Vietnam/table_maxs_stable_obs_v2_1.tex, se noconstant title("?") replace booktabs compress keep(`treat') addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level. ") s(N firm year r2_a , labels("N" "Plant FE" "Year FE" "Adjusted R-squared" )) label
		
}

eststo clear
foreach var in maxs {
	
	foreach dep in log_rM log_rV log_LPV  {		
		
		local treat `var'
		foreach i of num 1/5 {
			local treat `treat' `var'_lag`i'
			di("`treat'")
		}
		
		*0-5 lags
		eststo `dep': quietly: reghdfe `dep' `treat', absorb(plant year) vce(cluster plant region#year)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace

	}

	*export results 
	esttab log_rM log_rV log_LPV  using ./output/regressions_tex/Vietnam/table_maxs_stable_obs_v2_2.tex, se noconstant title("?") replace booktabs compress keep(`treat') addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level. ") s(N firm year r2_a , labels("N" "Plant FE" "Year FE" "Adjusted R-squared" )) label
		
}

restore

/*preserve
keep if log_rS_exists==1&log_rV_exists==1&log_rLC_exists==1&log_rwage_exists==1&log_L_exists==1&log_LPV_exists==1

eststo clear
foreach var in maxs {
	
	foreach dep in log_rS log_rV log_rLC  log_rwage log_L  log_LPV  {		
		
		local treat `var'
		foreach i of num 1/5 {
			local treat `treat' `var'_lag`i'
			di("`treat'")
		}
		
		*0-5 lags
		eststo `dep': quietly: reghdfe `dep' `treat', absorb(plant year) vce(cluster plant region#year)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace

	}

	*export results 
	esttab log_rS log_rV log_rLC  log_rwage log_L  log_LPV  using ./output/regressions_tex/Vietnam/table_maxs_stable_obs_v2_3.tex, se noconstant title("?") replace booktabs compress keep(`treat') addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level. ") s(N firm year r2_a , labels("N" "Plant FE" "Year FE" "Adjusted R-squared" )) label
		
}




restore*/



******************************************************************************************************
/* 2007-2013: find an overlap so that N is the same for all the regressions; size weights

preserve
sort plant year
eststo clear
keep if log_rS_exists==1&log_rLC_exists==1&log_rK_exists==1&log_rwage_exists==1&log_L_exists==1&log_rtot_wage_exists==1&log_sales2labor_exists==1

foreach var in maxs {
	
	foreach dep in log_rS log_rLC log_rK  log_rwage log_L log_rtot_wage log_sales2labor {		
		
		local treat `var'
		foreach i of num 1/5 {
			local treat `treat' `var'_lag`i'
			di("`treat'")
		}
		
		*0-5 lags
		eststo `dep': quietly: reghdfe `dep' `treat', absorb(plant year) vce(cluster plant region#year) [aw=L]
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace

	}

	*export results 
	esttab log_rS log_rLC log_rK  log_rwage log_L log_rtot_wage log_sales2labor  using ./output/regressions_tex/Vietnam/table_maxs_stable_obs_v1.tex, se noconstant title("?") replace booktabs compress keep(`treat') addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level. ") s(N firm year r2_a , labels("N" "Plant FE" "Year FE" "Adjusted R-squared" )) label
		
}

restore 
*/


******************************************************************************************************
/* 2009-2013: find an overlap so that N is the same for all the regressions; Size of ADM2 dummy

preserve
sort plant year
eststo clear
keep if log_rS_exists==1&log_rM_exists==1&log_rV_exists==1&log_rLC_exists==1&log_rK_exists==1&log_rwage_exists==1&log_L_exists==1&log_rtot_wage_exists==1&log_LPV_exists==1&log_sales2labor_exists==1


gen small_area100 = 0
replace small_area100 = 1 if area_sqkm<=100

gen small_area200 = 0
replace small_area200 = 1 if area_sqkm<=200

gen small_area500 = 0
replace small_area500 = 1 if area_sqkm<=500

eststo clear
foreach var in maxs {
	
	foreach dep in log_L log_rV  {		
		
		local treat `var'
		foreach i of num 1/5 {
			local treat `treat' `var'_lag`i'
			di("`treat'")
		}
		
		*0-5 lags
		eststo `dep'_all: quietly: reghdfe `dep' `treat', absorb(plant year) vce(cluster plant region#year)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace
		quietly: estadd local all "Yes" , replace
		quietly: estadd local small "No" , replace
		quietly: estadd local notsmall "No" , replace
		
		eststo `dep'_small: quietly: reghdfe `dep' `treat' if small_area100==1, absorb(plant year) vce(cluster plant region#year)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace
		quietly: estadd local all "No" , replace
		quietly: estadd local small "Yes" , replace
		quietly: estadd local notsmall "No" , replace
		
		eststo `dep'_notsmall: quietly: reghdfe `dep' `treat' if small_area100==0, absorb(plant year) vce(cluster plant region#year)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace
		quietly: estadd local all "No" , replace
		quietly: estadd local small "No" , replace
		quietly: estadd local notsmall "Yes" , replace
		
	}

	*export results 
	esttab log_L_all log_L_small log_L_notsmall log_rV_all log_rV_small log_rV_notsmall using ./output/regressions_tex/Vietnam/table_maxs_stable_obs_small_adm2_areas.tex, se noconstant title("?") replace booktabs compress keep(`treat') addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level. ") s(N firm year all small notsmall r2_a , labels("N" "Plant FE" "Year FE" "All ADM2" "Small ADM2 ($\leq100km^2$)" "Not Small ADM2" "Adjusted R-squared" )) label
		
}


restore*/


******************************************************************************************************
* 2007-2013: find an overlap so that N is the same for all the regressions: storm DUMMY

preserve
sort plant year
eststo clear
keep if log_rS_exists==1&log_rLC_exists==1&log_rK_exists==1&log_rwage_exists==1&log_L_exists==1&log_rtot_wage_exists==1&log_sales2labor_exists==1

foreach var in storm {
	
	foreach dep in log_rS log_rLC log_rK  log_rwage log_L log_rtot_wage log_sales2labor {		
		
		local treat `var'
		foreach i of num 1/5 {
			local treat `treat' `var'_lag`i'
			di("`treat'")
		}
		
		*0-5 lags
		eststo `dep': quietly: reghdfe `dep' `treat', absorb(plant year) vce(cluster plant region#year)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace

	}

	*export results 
	esttab log_rS log_rLC log_rK  log_rwage log_L log_rtot_wage log_sales2labor  using ./output/regressions_tex/Vietnam/table_storm_dummy_stable_obs_v1.tex, se noconstant title("?") replace booktabs compress keep(`treat') addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level. ") s(N firm year r2_a , labels("N" "Plant FE" "Year FE" "Adjusted R-squared" )) label
		
}

restore 

******************************************************************************************************
* 2009-2013: find an overlap so that N is the same for all the regressions (you can use VA here): storm DUMMY

preserve

sort plant year

keep if log_rS_exists==1&log_rM_exists==1&log_rV_exists==1&log_rLC_exists==1&log_rK_exists==1&log_rwage_exists==1&log_L_exists==1&log_rtot_wage_exists==1&log_LPV_exists==1&log_sales2labor_exists==1
eststo clear
foreach var in storm {
	
	foreach dep in log_rS log_rLC log_rK  log_rwage log_L log_rtot_wage log_sales2labor {		
		
		local treat `var'
		foreach i of num 1/5 {
			local treat `treat' `var'_lag`i'
			di("`treat'")
		}
		
		*0-5 lags
		eststo `dep': quietly: reghdfe `dep' `treat', absorb(plant year) vce(cluster plant region#year)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace

	}

	*export results 
	esttab log_rS log_rLC log_rK  log_rwage log_L log_rtot_wage log_sales2labor  using ./output/regressions_tex/Vietnam/table_storm_dummy_stable_obs_v2_1.tex, se noconstant title("?") replace booktabs compress keep(`treat') addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level. ") s(N firm year r2_a , labels("N" "Plant FE" "Year FE" "Adjusted R-squared" )) label
		
}

eststo clear
foreach var in storm {
	
	foreach dep in log_rM log_rV log_LPV  {		
		
		local treat `var'
		foreach i of num 1/5 {
			local treat `treat' `var'_lag`i'
			di("`treat'")
		}
		
		*0-5 lags
		eststo `dep': quietly: reghdfe `dep' `treat', absorb(plant year) vce(cluster plant region#year)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace

	}

	*export results 
	esttab log_rM log_rV log_LPV  using ./output/regressions_tex/Vietnam/table_storm_dummy_stable_obs_v2_2.tex, se noconstant title("?") replace booktabs compress keep(`treat') addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level. ") s(N firm year r2_a , labels("N" "Plant FE" "Year FE" "Adjusted R-squared" )) label
		
}

restore



