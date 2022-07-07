*#############################################################################

* Housekeeping
clear
clear matrix
set more off

use "./data/tropical-cyclones/intermediate/Vietnam/maxWindsADM2_with_population.dta",clear
*#############################################################################

*Generate lags and leads
merge m:1 ID_2 using "./data/firm-data/Vietnam/gadm36_VNM_shp/VNM_adm2.dta"
drop NL_NAME_1 NAME_2 NL_NAME_2 TYPE_2 ENGTYPE_2 _m GID_1 NAME_1 VARNAME_2

label var maxs_pop_only "Max Speed (m/s)"
label var storm_pop_only "N of Storms"

sort ID_2 year
foreach i of num 1/10 {
	by ID_2: gen maxs_lag`i' = maxs[_n-`i']
	by ID_2: gen maxs_pop_only_lag`i' = maxs_pop_only[_n-`i']
	by ID_2: gen storm_pop_only_lag`i' = storm_pop_only[_n-`i']
	
	label var maxs_pop_only_lag`i' "Lag `i'"
	label var storm_pop_only_lag`i' "Lag `i'"
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
	gen log_`dep' = log(`dep')*100
	local label_dep: var label `dep'
	label var log_`dep'`"Logged `label_dep' times 100"' 
}

*dummies if variables exist
foreach dep in rS rM rV rLC rK LPV rwage L rtot_wage sales2labor{
	gen `dep'_exists = 1 if `dep'!=.
	replace `dep'_exists = 0 if `dep'_exists==.
	
	gen log_`dep'_exists = 1 if log_`dep'!=.
	replace log_`dep'_exists = 0 if log_`dep'_exists==.
}

******************************************************************************************************
*change variable labels for better titles
label var log_rS "100Log(Sales)" 
label var log_rLC "100Log(L Cost)"
label var log_rK "100Log(K)"
label var log_rwage "100Log(Avg Wage)"
label var log_L "100Log(L)"
label var log_rtot_wage "100Log(Tot Wage)"
label var log_LPV  "100Log(VA/L)"
label var log_rV "100Log(VA)"
label var log_rM "100Log(Mat)"

gen storm_pop_only_lag0 = storm_pop_only
label var storm_pop_only_lag0 "N of Storms"

******************************************************************************************************
* 2007-2013: find an overlap so that N is the same for all the regressions: storm DUMMY

preserve
sort plant year
eststo clear
keep if log_rS_exists==1&log_rLC_exists==1&log_rK_exists==1&log_rwage_exists==1&log_L_exists==1&log_rtot_wage_exists==1&log_sales2labor_exists==1

foreach var in storm_pop_only maxs_pop_only {
	
	foreach dep in log_rS log_rLC log_rK  log_rwage log_L log_rtot_wage {		
		
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
	esttab log_rS log_L log_rK  log_rLC  log_rwage  using ./output/regressions_tex/Vietnam/table_`var'_clean_1.tex, se noconstant title("2007-2013 (dropping VA and Materials since they are not reported in 2007-2009)") replace booktabs compress keep(`treat') addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level. ") s(N firm year r2_a , labels("N" "Plant FE" "Year FE" "Adjusted R-squared" )) label
		
}

restore 

******************************************************************************************************
* 2009-2013: find an overlap so that N is the same for all the regressions (you can use VA here): storm DUMMY

preserve

sort plant year

keep if log_rS_exists==1&log_rLC_exists==1&log_rK_exists==1&log_rwage_exists==1&log_L_exists==1&log_rtot_wage_exists==1&log_sales2labor_exists==1&log_rM_exists==1&log_rV_exists==1&log_LPV_exists
eststo clear
foreach var in storm_pop_only maxs_pop_only {
	
	foreach dep in log_rS log_rLC log_rK  log_rwage log_L log_rtot_wage {		
		
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
	esttab log_rS log_L log_rK  log_rLC  log_rwage using ./output/regressions_tex/Vietnam/table_`var'_clean_2_1.tex, se noconstant title("2009-2013: subsample of firms that have all the characteristics") replace booktabs compress keep(`treat') addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level. ") s(N firm year r2_a , labels("N" "Plant FE" "Year FE" "Adjusted R-squared" )) label
		
}

eststo clear
foreach var in storm_pop_only maxs_pop_only {
	
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
	esttab log_rM log_rV log_LPV  using ./output/regressions_tex/Vietnam/table_`var'_clean_2_2.tex, se noconstant title("2009-2013: subsample of firms that have all the characteristics") replace booktabs compress keep(`treat') addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level. ") s(N firm year r2_a , labels("N" "Plant FE" "Year FE" "Adjusted R-squared" )) label
		
}

restore

