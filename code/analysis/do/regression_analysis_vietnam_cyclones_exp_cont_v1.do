*#############################################################################
* v1 - based on years with exposure in past 5 years
*#############################################################################

cd /Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters

* Housekeeping
clear
clear matrix
set more off

use "./data/tropical-cyclones/intermediate/Vietnam/maxWindsADM2_with_population.dta",clear

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

*create a dummy for repeated exposure (N in 5 last year with storm at at least 1 pixel)
foreach k of num 1/5 {
	gen storm_`k'_year_ago = 0
	replace storm_`k'_year_ago = 1 if storm_pop_only_lag`k' >0
}
egen storms_five_ys = rowtotal(storm_1_year_ago storm_2_year_ago storm_3_year_ago storm_4_year_ago storm_5_year_ago)
label var storms_five_ys "Rep"

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

******************************************************************************************************


/*reghdfe log_L c.storm_pop_only##c.storms_five_ys c.storm_pop_only_lag1##c.storms_five_ys c.storm_pop_only_lag2##c.storms_five_ys c.storm_pop_only_lag3##c.storms_five_ys c.storm_pop_only_lag4##c.storms_five_ys c.storm_pop_only_lag5##c.storms_five_ys, absorb(plant year) vce(cluster plant region#year)


reghdfe log_L c.storm_pop_only##c.storms_five_ys c.storm_pop_only_lag1##c.storms_five_ys, absorb(plant year) vce(cluster plant region#year)
quietly: margins, at(storms_five_ys=(1(1)5) storm_pop_only=(0(1)3))
marginsplot, x(storm_pop_only) recast(line) 

quietly: margins, dydx(storm_pop_only) at(storms_five_ys=(0(1)5))
marginsplot, yline(0)


reghdfe log_L c.storm_pop_only##c.storms_five_ys c.storm_pop_only_lag1##c.storms_five_ys c.storm_pop_only_lag2##c.storms_five_ys c.storm_pop_only_lag3##c.storms_five_ys c.storm_pop_only_lag4##c.storms_five_ys c.storm_pop_only_lag5##c.storms_five_ys, absorb(plant year) vce(cluster plant region#year)

quietly: margins, dydx(storm_pop_only storm_pop_only_lag1 storm_pop_only_lag2 storm_pop_only_lag3 storm_pop_only_lag4 storm_pop_only_lag5) at(storms_five_ys=(0(1)5))
marginsplot, yline(0)

reghdfe log_L c.storm_pop_only##c.storms_five_ys, absorb(plant year) vce(cluster plant region#year)
quietly: margins, at(storms_five_ys=(1(1)5) storm_pop_only=(0(1)3)) saving(predictions, replace)*/


* 2007-2013: find an overlap so that N is the same for all the regressions: storm DUMMY

preserve
sort plant year
eststo clear
keep if log_rS_exists==1&log_rLC_exists==1&log_rK_exists==1&log_rwage_exists==1&log_L_exists==1&log_rtot_wage_exists==1&log_sales2labor_exists==1

foreach var in maxs_pop_only storm_pop_only {
	
	foreach dep in log_rS log_rLC log_rK  log_rwage log_L log_rtot_wage {		
		
		local treat c.`var'##c.storms_five_ys
		foreach i of num 1/5 {
			local treat `treat' c.`var'_lag`i'##c.storms_five_ys
			di("`treat'")
		}
		
		*0-5 lags
		eststo `dep': quietly: reghdfe `dep' `treat', absorb(plant year) vce(cluster plant region#year) noomitted
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace

	}

	*export results 
	esttab log_rS log_L log_rK  log_rLC  log_rwage  using ./output/regressions_tex/Vietnam/table_`var'_dummy_stable_obs_v3_1.tex, se noconstant title("2007-2013 (dropping VA and Materials since they are not reported in 2007-2008)") replace booktabs compress addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level. ") s(N firm year r2_a , labels("N" "Plant FE" "Year FE" "Adjusted R-squared" )) label
		
}

restore 


******************************************************************************************************
* 2009-2013: find an overlap so that N is the same for all the regressions (you can use VA here): storm DUMMY

preserve

sort plant year

keep if log_rS_exists==1&log_rM_exists==1&log_rV_exists==1&log_rLC_exists==1&log_rK_exists==1&log_rwage_exists==1&log_L_exists==1&log_rtot_wage_exists==1&log_LPV_exists==1&log_sales2labor_exists==1
eststo clear
foreach var in maxs_pop_only storm_pop_only {
	
	foreach dep in log_rS log_rLC log_rK  log_rwage log_L log_rtot_wage {		
		
		local treat c.`var'##c.storms_five_ys
		foreach i of num 1/5 {
			local treat `treat' c.`var'_lag`i'##c.storms_five_ys
			di("`treat'")
		}
		
		*0-5 lags
		eststo `dep': quietly: reghdfe `dep' `treat', absorb(plant year) vce(cluster plant region#year) noomitted
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace

	}

	*export results 
	esttab log_rS log_L log_rK  log_rLC  log_rwage  using ./output/regressions_tex/Vietnam/table_`var'_dummy_stable_obs_v3_2.tex, se noconstant title("2009-2013: subsample of firms that have all the characteristics") replace booktabs compress addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level. ") s(N firm year r2_a , labels("N" "Plant FE" "Year FE" "Adjusted R-squared" )) label
		
}


eststo clear

foreach var in maxs_pop_only storm_pop_only {
	
	foreach dep in log_rM log_rV log_LPV {		
		
		local treat c.`var'##c.storms_five_ys
		foreach i of num 1/5 {
			local treat `treat' c.`var'_lag`i'##c.storms_five_ys
			di("`treat'")
		}
		
		*0-5 lags
		eststo `dep': quietly: reghdfe `dep' `treat', absorb(plant year) vce(cluster plant region#year) noomitted
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace

	}

	*export results 
	esttab log_rM log_rV log_LPV   using ./output/regressions_tex/Vietnam/table_`var'_dummy_stable_obs_v3_3.tex, se noconstant title("2009-2013: subsample of firms that have all the characteristics") replace booktabs compress addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level. ") s(N firm year r2_a , labels("N" "Plant FE" "Year FE" "Adjusted R-squared" )) label
		
}


restore






















