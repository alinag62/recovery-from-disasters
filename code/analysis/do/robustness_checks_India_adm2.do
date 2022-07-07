cd /Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters

* Housekeeping
clear
clear matrix
set more off

local country India
local ID ID_2
local ID_in_survey id_used

local path2save_shake "./data/earthquakes/intermediate/India_adm2"
local firms_folder "./data/firm-data/India"
local path2shp_dta "./data/firm-data/India/Shapefile/IND_adm_shp/IND_adm2.dta"
local r2r_folder "./data/firm-data/clean-with-eq-ready-to-regress/"

*#############################################################################
grstyle init
grstyle set mesh, horizontal compact minor
*#############################################################################

*#############################################################################
*0. Load and clean dataset
*#############################################################################

use "`firms_folder'/Final-Dataset/India_survey_readytoregress.dta", clear
keep if year>=1985&year<=2011
drop if panelID==.
rename id_used region
drop if region == .

tempfile survey
save "`survey'"  

use "`path2save_shake'/region_panel/panel_earthquakes_thresh_10.dta"
keep if year>=1975&year<=2011

rename region ID_2
merge m:1  ID_2 using "./data/firm-data/India/Shapefile/IND_adm_shp/IND_adm2.dta"
drop _m
rename ID_2 region
drop NAME_0 ID_0 ISO ID_1 NAME_1 HASC_2 CCN_2 CCA_2 TYPE_2 ENGTYPE_2 NL_NAME_2 VARNAME_2 _ID

*rename since the names are too long
rename populatedmpga_aw popmpga_aw
rename populatednum_qs_aw popnum_qs_aw
rename populatedmpga_aw10 popmpga_aw10
rename populatednum_qs_aw10 popnum_qs_aw10

*add lags
sort region year
foreach i of num 1/10 {
	foreach var in mpga_aw popmpga_aw urbanmpga_aw ruralmpga_aw num_qs_aw popnum_qs_aw urbannum_qs_aw ruralnum_qs_aw mpga_aw10 urbanmpga_aw10 ruralmpga_aw10 popmpga_aw10 num_qs_aw10 urbannum_qs_aw10 ruralnum_qs_aw10 popnum_qs_aw10 {
		by region: gen `var'_lag`i' = `var'[_n-`i']
		label var `var'_lag`i' "Lag `i'"
	}
}

foreach var in mpga_aw popmpga_aw urbanmpga_aw ruralmpga_aw num_qs_aw popnum_qs_aw urbannum_qs_aw ruralnum_qs_aw mpga_aw10 urbanmpga_aw10 ruralmpga_aw10 popmpga_aw10 num_qs_aw10 urbannum_qs_aw10 ruralnum_qs_aw10 popnum_qs_aw10 {
		label var `var' "`var'"
}

tempfile shaking
save "`shaking'"  


use "`survey'"
bys region year: gen firms_that_year_in_region = _N

merge m:1 region year using "`shaking'"
order panelID year region 
keep if _m==3

****************************************************
****************************************************
* Important notes on Indian data:
* a) 2008-2011 have only 1-3% of obs of other years
* b) there is a dummy called "open"
* c) some firms have reported data for multiple plants 
****************************************************
****************************************************

*keep only open plants
keep if open==1

*rename to not manipulate reg code
rename panelID plant

*new var
gen dom_sales = sales-exports
label var dom_sales "Domestic Sales"

*convert some vars to thousands 
gen wages_th = wages/1000
gen sales_th = sales/1000
gen tot_invent_eoy = stfgclose+ stsfgclose+ stmfsclose
gen tot_invent_eoy_th = tot_invent_eoy/1000
gen capital_th = capital/1000
gen exports_th = exports/1000

label var wages_th "Wages Total, in ths"
label var sales_th "Total Sales, in ths"
label var tot_invent_eoy "Total Inventories (end of the year)"
label var tot_invent_eoy_th "Total Inventories (end of the year), in ths"
label var capital_th "Total Assets Value, in ths"
label var exports_th "Total Exports, in ths"

*create logged vars
foreach dep in wages sales tot_invent_eoy capital exports labor output dom_sales {
	gen log_`dep' = log(`dep')
	local label_dep: var label `dep'
	label var log_`dep'`"Logged `label_dep'"' 
}

*create 1 diff of logs
sort plant year
foreach dep in wages sales tot_invent_eoy capital exports labor output dom_sales {
	bys plant:gen log_`dep'_diff = log_`dep'-log_`dep'[_n-1]
	
	local label_dep: var label `dep'
	label var log_`dep'_diff `"Logged `label_dep' (first difference)"' 
}

*create logged vars with constant if 0
foreach dep in wages sales tot_invent_eoy capital exports labor output dom_sales {
	gen log_`dep'_const = log(`dep'+0.001)
}

*create 1 diff of logs with constant if 0
sort plant year
foreach dep in wages sales tot_invent_eoy capital exports labor output dom_sales{
	bys plant: gen log_`dep'_diff_const = log_`dep'_const-log_`dep'_const[_n-1]
}

*enumerate all observation years before dropping them
sort plant year
bys plant: gen n = _n
bys plant: gen N = _N

*indicate firms with missing obs
foreach dep in wages sales tot_invent_eoy capital exports labor output dom_sales {
	gen `dep'_non_missing = 1
	replace `dep'_non_missing = 0 if missing(`dep')
	bys plant: egen total_`dep'_non_missing = total(`dep'_non_missing)
	
	gen non_missing_`dep'=1 if N == total_`dep'_non_missing
	
	drop total_`dep'_non_missing `dep'_non_missing
}

*#############################################################################
*1. mpga_aw
*#############################################################################

foreach dep in wages sales tot_invent_eoy capital exports labor output dom_sales  {
	eststo clear
	graph drop _all
	local graphs ""

	*Log; all obs; no 0s
	local treat mpga_aw

	foreach i of num 1/5 {
	local treat `treat' mpga_aw_lag`i'
	di("`treat'")
	}

	quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
	est sto m5_growth

	*Log+const; all obs
	local treat mpga_aw

	foreach i of num 1/5 {
	local treat `treat' mpga_aw_lag`i'
	di("`treat'")
	}

	quietly: areg log_`dep'_diff_const `treat'  i.year, absorb(plant) vce(cluster plant)
	est sto m5_growth_const

	*Log; firms with no missing dep obs in all years

	local treat mpga_aw

	foreach i of num 1/5 {
	local treat `treat' mpga_aw_lag`i'
	di("`treat'")
	}

	quietly: areg log_`dep'_diff `treat'  i.year if non_missing_`dep'==1, absorb(plant) vce(cluster plant)
	est sto m5_growth_no_missing

	*Log+const; firms with no missing dep obs in all years

	local treat mpga_aw

	foreach i of num 1/5 {
	local treat `treat' mpga_aw_lag`i'
	di("`treat'")
	}

	quietly: areg log_`dep'_diff_const `treat'  i.year if non_missing_`dep'==1, absorb(plant) vce(cluster plant)
	est sto m5_growth_const_no_missing

	*Log; all obs; no 0s; 10 lags
	local treat mpga_aw

	foreach i of num 1/10 {
	local treat `treat' mpga_aw_lag`i'
	di("`treat'")
	}

	quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
	est sto m10_growth
	
	*Log+const; all obs
	local treat mpga_aw

	foreach i of num 1/10 {
	local treat `treat' mpga_aw_lag`i'
	di("`treat'")
	}

	quietly: areg log_`dep'_diff_const `treat'  i.year, absorb(plant) vce(cluster plant)
	est sto m10_growth_const

	*Log; firms with no missing dep obs in all years

	local treat mpga_aw

	foreach i of num 1/10 {
	local treat `treat' mpga_aw_lag`i'
	di("`treat'")
	}

	quietly: areg log_`dep'_diff `treat'  i.year if non_missing_`dep'==1, absorb(plant) vce(cluster plant)
	est sto m10_growth_no_missing

	*Log+const; firms with no missing dep obs in all years

	local treat mpga_aw

	foreach i of num 1/10 {
	local treat `treat' mpga_aw_lag`i'
	di("`treat'")
	}

	quietly: areg log_`dep'_diff_const `treat'  i.year if non_missing_`dep'==1, absorb(plant) vce(cluster plant)
	est sto m10_growth_const_no_missing

	*Levels
	
	local treat mpga_aw

	foreach i of num 1/5 {
	local treat `treat' mpga_aw_lag`i'
	di("`treat'")
	}

	quietly: areg `dep' `treat'  i.year, absorb(plant) vce(cluster plant)
	est sto m5_levels

	*Levels; firms with no missing dep obs in all years

	local treat mpga_aw

	foreach i of num 1/5 {
	local treat `treat' mpga_aw_lag`i'
	di("`treat'")
	}

	quietly: areg `dep' `treat'  i.year if non_missing_`dep'==1, absorb(plant) vce(cluster plant)
	est sto m5_levels_no_missing


	*Levels; all obs; no 0s; 10 lags
	local treat mpga_aw

	foreach i of num 1/10 {
	local treat `treat' mpga_aw_lag`i'
	di("`treat'")
	}

	quietly: areg `dep' `treat'  i.year, absorb(plant) vce(cluster plant)
	est sto m10_levels

	*Levels; firms with no missing dep obs in all years

	local treat mpga_aw

	foreach i of num 1/10 {
	local treat `treat' mpga_aw_lag`i'
	di("`treat'")
	}

	quietly: areg `dep' `treat'  i.year if non_missing_`dep'==1, absorb(plant) vce(cluster plant)
	est sto m10_levels_no_missing

	
	
	coefplot (m5_growth, label("5 Lags"))  (m5_growth_no_missing, label("5 Lags, only obs with all non-NA"))  (m10_growth, label("10 Lags")) (m10_growth_no_missing, label("10 Lags, only obs with all non-NA")), keep(mpga_aw*) yline(0) vertical xsize(10) title("Growth Rates Models") legend(off) name(g1) 
	local graphs "`graphs' g1"
	
	coefplot (m5_levels, label("5 Lags")) (m5_levels_no_missing, label("5 Lags, only obs with all non-NA")) (m10_levels, label("10 Lags")) (m10_levels_no_missing, label("10 Lags, only obs with all non-NA")), keep(mpga_aw*) yline(0) vertical xsize(10) title("Models in Levels") legend(position(3) cols(1)) name(g2) 
	local graphs "`graphs' g2" 
	
	coefplot (m5_growth_const, label("5 Lags")) (m5_growth_const_no_missing, label("5 Lags, only obs with all non-NA")) (m10_growth_const, label("10 Lags")) (m10_growth_const_no_missing, label("10 Lags, only obs with all non-NA")), keep(mpga_aw*) yline(0) vertical xsize(10) title("Growth Rates Models, log(x+const)")   name(g3)
	local graphs "`graphs' g3" 
	
	grc1leg `graphs',  row(3) legendfrom(g2) pos(3) title("`: var label `dep'': robustness checks")
	graph display, xsize(10) ysize(4)
	
	graph export "./output/India/coefplots/`dep'_coefplot_ind.pdf", replace 
	
	*coefplot (m5_growth, label("Growth Rates")) (m5_growth_all_10_lags) (m5_growth_no_missing)  (m10_growth) (m10_growth_no_missing) , subtitle("d") || (m5_levels) (m5_levels_all_10_lags) (m5_levels_no_missing) (m10_levels) (m10_levels_no_missing)  ||(m5_growth_const) (m5_growth_const_all_10_lags) (m5_growth_const_no_missing) (m10_growth_const) (m10_growth_const_no_missing) , keep(mpga_aw*) yline(0) vertical xsize(10) byopts(compact cols(1) yrescale legend(position(3))) norecycle 
	
	*coefplot (m5_growth) (m5_growth_const) (m5_growth_all_10_lags) (m5_growth_const_all_10_lags) (m5_growth_no_missing) (m5_growth_const_no_missing) (m10_growth) (m10_growth_const) (m10_growth_no_missing) (m10_growth_const_no_missing) (m5_levels, axis(2)) (m5_levels_all_10_lags, axis(2)) (m5_levels_no_missing, axis(2)) (m10_levels, axis(2)) (m10_levels_no_missing, axis(2)), keep(mpga_aw*) yline(0) vertical xsize(10) 

	*coefplot (m5_growth, label("Growth Rates")) (m5_growth_all_10_lags) (m5_growth_no_missing)  (m10_growth) (m10_growth_no_missing)  || (m5_levels) (m5_levels_all_10_lags) (m5_levels_no_missing) (m10_levels) (m10_levels_no_missing)  ||(m5_growth_const) (m5_growth_const_all_10_lags) (m5_growth_const_no_missing) (m10_growth_const) (m10_growth_const_no_missing) , keep(mpga_aw*) yline(0) vertical xsize(10) byopts(compact cols(1) yrescale legend(position(3))) norecycle 
	
	*coefplot (m5) (m5_all_10_lags) (m5_no_missing) (m10) (m10_no_missing) (m5_levels, axis(2)), keep(mpga_aw*) yline(0) vertical xsize(10)  ytitle(m5_levels, axis(2))
	
	*coefplot (m5) (m5_const) (m5_all_10_lags) (m5_const_all_10_lags) (m5_no_missing) (m5_const_no_missing) (m10) (m10_const) (m10_no_missing) (m10_const_no_missing) , keep(mpga_aw*) yline(0) vertical xsize(9) 

	*coefplot (m5) (m5_const) (m5_all_5_lags) (m5_const_all_5_lags) (m5_all_10_lags) (m5_const_all_10_lags) (m5_no_missing) (m5_const_no_missing) || (m10) (m10_const) (m10_all_5_lags) (m10_const_all_5_lags) (m10_all_10_lags) (m10_const_all_10_lags) (m10_no_missing) (m10_const_no_missing), keep(mpga_aw*) yline(0) vertical xsize(9) byopts(compact cols(1) legend(position(3))) 
	
	
}














