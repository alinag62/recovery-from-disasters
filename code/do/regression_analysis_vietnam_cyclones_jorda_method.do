*#############################################################################
*Program for appending local projections results into one column 
*#############################################################################

capt prog drop appendmodels
*! version 1.0.0  14aug2007  Ben Jann
program appendmodels, eclass
    // using first equation of model
    version 8
    syntax namelist
    tempname b V tmp
    foreach name of local namelist {
        qui est restore `name'
        mat `tmp' = e(b)
        local eq1: coleq `tmp'
        gettoken eq1 : eq1
        mat `tmp' = `tmp'[1,"`eq1':"]
        local cons = colnumb(`tmp',"_cons")
        if `cons'<. & `cons'>1 {
            mat `tmp' = `tmp'[1,1..`cons'-1]
        }
        mat `b' = nullmat(`b') , `tmp'
        mat `tmp' = e(V)
        mat `tmp' = `tmp'["`eq1':","`eq1':"]
        if `cons'<. & `cons'>1 {
            mat `tmp' = `tmp'[1..`cons'-1,1..`cons'-1]
        }
        capt confirm matrix `V'
        if _rc {
            mat `V' = `tmp'
        }
        else {
            mat `V' = ///
            ( `V' , J(rowsof(`V'),colsof(`tmp'),0) ) \ ///
            ( J(rowsof(`tmp'),colsof(`V'),0) , `tmp' )
        }
    }
    local names: colfullnames `b'
    mat coln `V' = `names'
    mat rown `V' = `names'
    eret post `b' `V'
    eret local cmd "whatever"
end

*#############################################################################
cd /Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters
cd /Users/alinagafanova/Library/CloudStorage/Box-Box/recovery-from-disasters
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

rename weighted_pop_v_s maxs_pop_only
rename weighted_pop_storm storm_pop_only

label var maxs_pop_only "Max Speed (m/s)"
label var storm_pop_only "N of Storms"

sort ID_2 year
foreach i of num 1/20 {
	by ID_2: gen maxs_pop_only_lag`i' = maxs_pop_only[_n-`i']
	by ID_2: gen storm_pop_only_lag`i' = storm_pop_only[_n-`i']
	
	label var maxs_pop_only_lag`i' "Lag `i'"
	label var storm_pop_only_lag`i' "Lag `i'"
}

*#############################################################################

/*Testing for autocorrelation: 10 lags

*number of storms are uncorrelated
*areg storm_pop_only storm_pop_only_lag1, absorb(ID_2) 

*wind speed is positively correlated with t-1 lagm (but not t-2. and only if the error is not robust, iid)
*areg maxs_pop_only maxs_pop_only_lag1, absorb(ID_2)

* Full dataset (1997-2013)
preserve
eststo clear
local out 
foreach i of num 1/10 {
	quietly: eststo d`i': areg storm_pop_only storm_pop_only_lag`i', absorb(ID_2) vce(robust)
	local out `out' d`i'
}
esttab `out' using ./output/regressions_tex/Vietnam/autocorr_1997_2013.tex, se label s(N, labels("N") fmt(%9.0f)) replace nocon b(3) mtitles("N of Storms" "N" "N" "N" "N" "N" "N" "N" "N" "N")
restore

preserve
eststo clear
local treat
local out 
foreach i of num 1/10 {
	local treat `treat' storm_pop_only_lag`i'
	quietly: eststo d`i': areg storm_pop_only `treat', absorb(ID_2) vce(robust)
	local out `out' d`i'
	
}

esttab `out' using ./output/regressions_tex/Vietnam/autocorr_1997_2013_simult.tex, se label s(N, labels("N") fmt(%9.0f)) replace nocon b(3) mtitles("N of Storms" "N" "N" "N" "N" "N" "N" "N" "N" "N")
restore

* Partial dataset (2007-2013)
preserve
eststo clear
local out 
keep if year>=2007
foreach i of num 1/10 {
	quietly: eststo d`i': areg storm_pop_only storm_pop_only_lag`i', absorb(ID_2) vce(robust)
	local out `out' d`i'
}
esttab `out' using ./output/regressions_tex/Vietnam/autocorr_2007_2013.tex, se label s(N, labels("N") fmt(%9.0f)) replace nocon b(3) mtitles("N of Storms" "N" "N" "N" "N" "N" "N" "N" "N" "N")
restore


preserve
eststo clear
local treat
local out 
keep if year>=2007
foreach i of num 1/10 {
	local treat `treat' storm_pop_only_lag`i'
	quietly: eststo d`i': areg storm_pop_only `treat', absorb(ID_2) vce(robust)
	local out `out' d`i'
	
}
esttab `out' using ./output/regressions_tex/Vietnam/autocorr_2007_2013_simult.tex, se label s(N, labels("N") fmt(%9.0f)) replace nocon b(3) mtitles("N of Storms" "N" "N" "N" "N" "N" "N" "N" "N" "N")
restore

* Full dataset (1997-2013)
preserve
eststo clear
local out 
foreach i of num 1/10 {
	quietly: eststo d`i': areg maxs_pop_only maxs_pop_only_lag`i', absorb(ID_2) vce(robust)
	local out `out' d`i'
}
esttab `out' using ./output/regressions_tex/Vietnam/autocorr_1997_2013_maxs.tex, se label s(N, labels("N") fmt(%9.0f)) replace nocon b(3) mtitles("Max Speed" "" "" "" "" "" "" "" "" "")
restore

preserve
eststo clear
local treat
local out 
foreach i of num 1/10 {
	local treat `treat' maxs_pop_only_lag`i'
	quietly: eststo d`i': areg maxs_pop_only `treat', absorb(ID_2) vce(robust)
	local out `out' d`i'
	
}
esttab `out' using ./output/regressions_tex/Vietnam/autocorr_1997_2013_simult_maxs.tex, se label s(N, labels("N") fmt(%9.0f)) replace nocon b(3) mtitles("Max Speed" "" "" "" "" "" "" "" "" "")
restore

* Partial dataset (2007-2013)
preserve
eststo clear
local out 
keep if year>=2007
foreach i of num 1/10 {
	quietly: eststo d`i': areg maxs_pop_only maxs_pop_only_lag`i', absorb(ID_2) vce(robust)
	local out `out' d`i'
}
esttab `out' using ./output/regressions_tex/Vietnam/autocorr_2007_2013_maxs.tex, se label s(N, labels("N") fmt(%9.0f)) replace nocon b(3) mtitles("Max Speed" "" "" "" "" "" "" "" "" "")
restore


preserve
eststo clear
local treat
local out 
keep if year>=2007
foreach i of num 1/10 {
	local treat `treat' maxs_pop_only_lag`i'
	quietly: eststo d`i': areg maxs_pop_only `treat', absorb(ID_2) vce(robust)
	local out `out' d`i'
	
}
esttab `out' using ./output/regressions_tex/Vietnam/autocorr_2007_2013_simult_maxs.tex, se label s(N, labels("N") fmt(%9.0f)) replace nocon b(3) mtitles("Max Speed" "" "" "" "" "" "" "" "" "")
restore

*############################################################################# */

/*#############################################################################

*Testing for autocorrelation: 10 to 20 lag


* Partial dataset (2007-2013)

preserve
eststo clear
local treat
local kept
local out 
keep if year>=2007

foreach i of num 1/10 {
	local treat `treat' storm_pop_only_lag`i'
}

foreach i of num 11/20 {
	local kept `kept' storm_pop_only_lag`i'
}

foreach i of num 11/20 {
	local treat `treat' storm_pop_only_lag`i'
	quietly: eststo d`i': areg storm_pop_only `treat', absorb(ID_2) vce(robust)
	local out `out' d`i'
}

esttab `out' using ./output/regressions_tex/Vietnam/autocorr_2007_2013_simult_10_20_lags.tex, se label s(N, labels("N") fmt(%9.0f)) replace nocon b(3) mtitles("N of Storms" "N" "N" "N" "N" "N" "N" "N" "N" "N") keep(`kept')
restore


* Partial dataset (2007-2013)

preserve
eststo clear
local treat
local out 
local kept
keep if year>=2007

foreach i of num 1/10 {
	local treat `treat' maxs_pop_only_lag`i'
}

foreach i of num 11/20 {
	local kept `kept' maxs_pop_only_lag`i'
}


foreach i of num 11/20 {
	local treat `treat' maxs_pop_only_lag`i'
	quietly: eststo d`i': areg maxs_pop_only `treat', absorb(ID_2) vce(robust)
	local out `out' d`i'
	
}
esttab `out' using ./output/regressions_tex/Vietnam/autocorr_2007_2013_simult_maxs_10_20_lags.tex, se label s(N, labels("N") fmt(%9.0f)) replace nocon b(3) mtitles("Max Speed" "" "" "" "" "" "" "" "" "") keep(`kept')
restore

*############################################################################# */

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

gen maxs_pop_only_lag0 = maxs_pop_only
label var maxs_pop_only_lag0 "Max Speed (m/s)"
******************************************************************************************************

* 2007-2013: find an overlap so that N is the same for all the regressions: storm DUMMY

preserve
sort plant year
eststo clear
keep if log_rS_exists==1&log_rLC_exists==1&log_rK_exists==1&log_rwage_exists==1&log_L_exists==1&log_rtot_wage_exists==1&log_sales2labor_exists==1

foreach var in storm_pop_only {
	
	foreach dep in log_rS log_rLC log_rK  log_rwage log_L log_rtot_wage {		
	*foreach dep in log_L log_rLC{
		foreach val of numlist 0/5 {
			eststo est`val': quietly: reghdfe `dep' `var'_lag`val', absorb(plant year) vce(cluster plant region#year) 
		}
		eststo combined_`dep': appendmodels est0 est1 est2 est3 est4 est5
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace
		quietly: estadd local N "1363767" , replace
	}
}

esttab combined_log_rS combined_log_L combined_log_rK  combined_log_rLC  combined_log_rwage using ./output/regressions_tex/Vietnam/table_storm_pop_only_jorda_v1_1.tex, se noconstant title("?") replace booktabs compress addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level." "All the results are from local projections, following Jorda (2005).") s(N firm year , labels("N" "Plant FE" "Year FE" )) label mtitles("100Log(Sales)" "100Log(L)" "100Log(K)" "100Log(L Cost)" "100Log(Avg Wage)")

restore



* 2009-2013: find an overlap so that N is the same for all the regressions: storm DUMMY

preserve
sort plant year
eststo clear
keep if log_rS_exists==1&log_rLC_exists==1&log_rK_exists==1&log_rwage_exists==1&log_L_exists==1&log_rtot_wage_exists==1&log_sales2labor_exists==1&log_rM_exists==1&log_rV_exists==1&log_LPV_exists

foreach var in storm_pop_only {
	
	foreach dep in log_rS log_rLC log_rK  log_rwage log_L log_rtot_wage {		
		foreach val of numlist 0/5 {
			eststo est`val': quietly: reghdfe `dep' `var'_lag`val', absorb(plant year) vce(cluster plant region#year) 
		}
		eststo combined_`dep': appendmodels est0 est1 est2 est3 est4 est5
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace
		quietly: estadd local N "864287" , replace
	}
}

esttab combined_log_rS combined_log_L combined_log_rK  combined_log_rLC  combined_log_rwage using ./output/regressions_tex/Vietnam/table_storm_pop_only_jorda_v1_2.tex, se noconstant title("?") replace booktabs compress addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level." "All the results are from local projections, following Jorda (2005).") s(N firm year , labels("N" "Plant FE" "Year FE" )) label mtitles("100Log(Sales)" "100Log(L)" "100Log(K)" "100Log(L Cost)" "100Log(Avg Wage)")



foreach var in storm_pop_only {
	
	foreach dep in log_rM log_rV log_LPV {		
		foreach val of numlist 0/5 {
			eststo est`val': quietly: reghdfe `dep' `var'_lag`val', absorb(plant year) vce(cluster plant region#year) 
		}
		eststo combined_`dep': appendmodels est0 est1 est2 est3 est4 est5
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace
		quietly: estadd local N "864287" , replace
	}
}

esttab combined_log_rM combined_log_rV combined_log_LPV using ./output/regressions_tex/Vietnam/table_storm_pop_only_jorda_v1_3.tex, se noconstant title("?") replace booktabs compress addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level." "All the results are from local projections, following Jorda (2005).") s(N firm year , labels("N" "Plant FE" "Year FE" )) label mtitles("100Log(Mat)" "100Log(VA)" "100Log(VA/L)")


restore

******************************************************************************************************

* 2007-2013: find an overlap so that N is the same for all the regressions: wind speed

preserve
sort plant year
eststo clear
keep if log_rS_exists==1&log_rLC_exists==1&log_rK_exists==1&log_rwage_exists==1&log_L_exists==1&log_rtot_wage_exists==1&log_sales2labor_exists==1

foreach var in maxs_pop_only {
	
	foreach dep in log_rS log_rLC log_rK  log_rwage log_L log_rtot_wage {		
		foreach val of numlist 0/5 {
			eststo est`val': quietly: reghdfe `dep' `var'_lag`val', absorb(plant year) vce(cluster plant region#year) 
		}
		eststo combined_`dep': appendmodels est0 est1 est2 est3 est4 est5
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace
		quietly: estadd local N "1363767" , replace
	}
}

esttab combined_log_rS combined_log_L combined_log_rK  combined_log_rLC  combined_log_rwage using ./output/regressions_tex/Vietnam/table_maxs_pop_only_jorda_v1_1.tex, se noconstant title("?") replace booktabs compress addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level." "All the results are from local projections, following Jorda (2005).") s(N firm year , labels("N" "Plant FE" "Year FE" )) label mtitles("100Log(Sales)" "100Log(L)" "100Log(K)" "100Log(L Cost)" "100Log(Avg Wage)")

restore



* 2009-2013: find an overlap so that N is the same for all the regressions: wind speed

preserve
sort plant year
eststo clear
keep if log_rS_exists==1&log_rLC_exists==1&log_rK_exists==1&log_rwage_exists==1&log_L_exists==1&log_rtot_wage_exists==1&log_sales2labor_exists==1&log_rM_exists==1&log_rV_exists==1&log_LPV_exists

foreach var in maxs_pop_only {
	
	foreach dep in log_rS log_rLC log_rK  log_rwage log_L log_rtot_wage {		
		foreach val of numlist 0/5 {
			eststo est`val': quietly: reghdfe `dep' `var'_lag`val', absorb(plant year) vce(cluster plant region#year) 
		}
		eststo combined_`dep': appendmodels est0 est1 est2 est3 est4 est5
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace
		quietly: estadd local N "864287" , replace
	}
}

esttab combined_log_rS combined_log_L combined_log_rK  combined_log_rLC  combined_log_rwage using ./output/regressions_tex/Vietnam/table_maxs_pop_only_jorda_v1_2.tex, se noconstant title("?") replace booktabs compress addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level." "All the results are from local projections, following Jorda (2005).") s(N firm year , labels("N" "Plant FE" "Year FE" )) label mtitles("100Log(Sales)" "100Log(L)" "100Log(K)" "100Log(L Cost)" "100Log(Avg Wage)")



foreach var in maxs_pop_only {
	
	foreach dep in log_rM log_rV log_LPV {		
		foreach val of numlist 0/5 {
			eststo est`val': quietly: reghdfe `dep' `var'_lag`val', absorb(plant year) vce(cluster plant region#year) 
		}
		eststo combined_`dep': appendmodels est0 est1 est2 est3 est4 est5
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace
		quietly: estadd local N "864287" , replace
	}
}

esttab combined_log_rM combined_log_rV combined_log_LPV using ./output/regressions_tex/Vietnam/table_maxs_pop_only_jorda_v1_3.tex, se noconstant title("?") replace booktabs compress addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level." "All the results are from local projections, following Jorda (2005).") s(N firm year , labels("N" "Plant FE" "Year FE" )) label mtitles("100Log(Mat)" "100Log(VA)" "100Log(VA/L)")


restore







