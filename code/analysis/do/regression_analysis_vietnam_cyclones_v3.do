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

merge m:1 ID_2 using "./data/firm-data/Vietnam/gadm36_VNM_shp/VNM_adm2_areas_gadm36.dta"
drop _m

sort ID_2 year
foreach i of num 1/10 {
	by ID_2: gen maxs_lag`i' = maxs[_n-`i']
	by ID_2: gen maxs_pop_only_lag`i' = maxs_pop_only[_n-`i']
	by ID_2: gen storm_pop_only_lag`i' = storm_pop_only[_n-`i']
}

*create a dummy for repeated exposure (N in 5 last year with storm at at least 1 pixel)
foreach k of num 1/5 {
	gen storm_`k'_year_ago = 0
	replace storm_`k'_year_ago = 1 if storm_pop_only_lag`k' >0
}
egen storms_five_ys = rowtotal(storm_1_year_ago storm_2_year_ago storm_3_year_ago storm_4_year_ago storm_5_year_ago)

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
	label var log_`dep'`"Logged`label_dep' times 100"' 
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
label var log_rS "Logged Sales X 100" 
label var log_rLC "Logged Labor Cost X 100"
label var log_rK "Logged Capital X 100"
label var log_rwage "Logged Average Wage X 100"
label var log_L "Logged Labor X 100"
label var log_rtot_wage "Logged Total Wage X 100"

******************************************************************************************************

* 2007-2013: find an overlap so that N is the same for all the regressions: storm DUMMY

preserve
sort plant year
eststo clear
keep if log_rS_exists==1&log_rLC_exists==1&log_rK_exists==1&log_rwage_exists==1&log_L_exists==1&log_rtot_wage_exists==1

foreach var in maxs_pop_only {
	
	foreach dep in log_rS log_rLC log_rK  log_rwage log_L log_rtot_wage {		
		
		local treat c.`var'#i.storms_five_ys
		foreach i of num 1/5 {
			local treat `treat' c.`var'_lag`i'#i.storms_five_ys
			di("`treat'")
		}
		
		*0-5 lags
		eststo `dep': quietly: reghdfe `dep' `treat', absorb(plant year) vce(cluster plant region#year)
		
		*plot separate plots for dummies and combine
		foreach j of num 0/5 {
		coefplot `dep', keep(`j'.storms_five_ys#*.`var'*) omitted baselevels xline(0)  coeflabel(`j'.storms_five_ys#*.`var'  = "Maximum Wind Speed" `j'.storms_five_ys#*.`var'_lag1  = "Lag 1" `j'.storms_five_ys#*.`var'_lag2  = "Lag 2" `j'.storms_five_ys#*.`var'_lag3  = "Lag 3" `j'.storms_five_ys#*.`var'_lag4 = "Lag 4" `j'.storms_five_ys#*.`var'_lag5  = "Lag 5") nodraw name(lag`j',replace) title(`j' out of 5 last years with storms)
		}
		
		graph combine lag0 lag1 lag2 lag3 lag4 lag5, rows(3) colfirst title("Regression Results for `: variable label `dep''," "interacted with number of storms in previous 5 years")  
		graph export output/Vietnam/figs/regs_by_repeated_exposure/`dep'_`var'.pdf, as(pdf) replace
		
	}
}

foreach var in storm_pop_only {
	
	foreach dep in log_rS log_rLC log_rK  log_rwage log_L log_rtot_wage {		
		
		local treat c.`var'#i.storms_five_ys
		foreach i of num 1/5 {
			local treat `treat' c.`var'_lag`i'#i.storms_five_ys
			di("`treat'")
		}
		
		*0-5 lags
		eststo `dep': quietly: reghdfe `dep' `treat', absorb(plant year) vce(cluster plant region#year)
		
		*plot separate plots for dummies and combine
		foreach j of num 0/5 {
		coefplot `dep', keep(`j'.storms_five_ys#*.`var'*) omitted baselevels xline(0)  coeflabel(`j'.storms_five_ys#*.`var'  = "Number of Storms" `j'.storms_five_ys#*.`var'_lag1  = "Lag 1" `j'.storms_five_ys#*.`var'_lag2  = "Lag 2" `j'.storms_five_ys#*.`var'_lag3  = "Lag 3" `j'.storms_five_ys#*.`var'_lag4 = "Lag 4" `j'.storms_five_ys#*.`var'_lag5  = "Lag 5") nodraw name(lag`j',replace) title(`j' out of 5 last years with storms)
		}
		
		graph combine lag0 lag1 lag2 lag3 lag4 lag5, rows(3) colfirst title("Regression Results for `: variable label `dep''," "interacted with number of storms in previous 5 years")  
		graph export output/Vietnam/figs/regs_by_repeated_exposure/`dep'_`var'.pdf, as(pdf) replace
		
	}
}


restore 








