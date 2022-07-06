*#############################################################################
cd /Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters

* Housekeeping
clear
clear matrix
set more off

local path2save_shake "./data/earthquakes/intermediate/Colombia_adm2"
local firms_folder "./data/firm-data/Colombia"
local r2r_folder "./data/firm-data/clean-with-eq-ready-to-regress/"
local country Colombia
local ID ID_2
local ID_in_survey id_used

*#############################################################################
grstyle init
grstyle set mesh, horizontal compact minor

*#############################################################################
*0. Load and clean dataset
*#############################################################################
use "`path2save_shake'/region_panel/panel_earthquakes_thresh_10.dta", clear

rename region ID_2
merge m:1  ID_2 using "./data/firm-data/Colombia/Shapefile/COL_adm_shp/COL_adm2.dta"
drop _m
rename ID_2 region
drop GID_0 NAME_0 GID_1 NAME_1 NL_NAME_1 GID_2 VARNAME_2 NL_NAME_2 TYPE_2 ENGTYPE_2 CC_2 HASC_2 _ID

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

*only keep obs with adm2
gen region_identified_in_survey = 0
replace region_identified_in_survey = 1 if region==76|region==141|region==169|region==330|region==568|region==847|region==863|region==1043
keep if region_identified_in_survey==1
drop region_identified_in_survey

tempfile shaking
save "`shaking'"

*merge shaking with firm data 
use "`firms_folder'/Final-Dataset/`country'_survey_readytoregress.dta"
rename id_used region
bys region year: gen firms_that_year_in_region = _N
merge m:1 region year using "`shaking'"  
keep if _m==3

rename wage_tot wages
rename tot_emp labor
rename totasst_val capital
rename prod_val output
rename tot_sales sales
rename netinv_val tot_invest

*convert some vars to thousands
gen wages_th = wages/1000
gen sales_th = sales/1000
gen tot_invent_eoy_th = tot_invent_eoy/1000
gen capital_th = capital/1000
gen exports_th = exports/1000
gen bldings_val_th = bldings_val/1000
gen tot_invest_th = tot_invest/1000


label var wages_th "Wages Total, in ths"
label var sales_th "Total Sales, in ths"
label var tot_invent_eoy_th "Total Inventories (end of the year), in ths"
label var capital_th "Total Assets Value, in ths"
label var exports_th "Total Exports, in ths"
label var bldings_val_th "Book Value of Buildings and Structures, in ths"
label var tot_invest_th "Total Net Investment, in ths"

*create logged vars
foreach dep in labor wages tot_invent_eoy capital exports bldings_val tot_invest output dom_sales sales {
	gen log_`dep' = log(`dep')
	local label_dep: var label `dep'
	label var log_`dep'`"Logged `label_dep'"' 
}

*create 1 diff of logs
sort plant year
foreach dep in labor wages tot_invent_eoy capital exports bldings_val tot_invest output dom_sales sales {
	bys plant:gen log_`dep'_diff = log_`dep'-log_`dep'[_n-1]
	local label_dep: var label `dep'
	label var log_`dep'_diff `"Logged `label_dep' (first difference)"' 
}

*create logged vars with constant if 0
foreach dep in labor wages tot_invent_eoy capital exports bldings_val tot_invest output dom_sales sales {
	gen log_`dep'_const = log(`dep'+0.001)
}

*create 1 diff of logs with constant if 0
sort plant year
foreach dep in labor wages tot_invent_eoy capital exports bldings_val tot_invest output dom_sales sales{
	bys plant: gen log_`dep'_diff_const = log_`dep'_const-log_`dep'_const[_n-1]
}

*enumerate all observation years before dropping them
sort plant year
bys plant: gen n = _n
bys plant: gen N = _N

*indicate observations that don't have all 5/10 lags (balanced panel)
gen all_10_lags = 0
replace all_10_lags=1 if  mpga_aw_lag10!=.

gen all_5_lags = 0
replace all_5_lags=1 if  mpga_aw_lag5!=.

*indicate firms with missing obs
foreach dep in labor wages tot_invent_eoy capital exports bldings_val tot_invest output dom_sales sales {
	gen `dep'_non_missing = 1
	replace `dep'_non_missing = 0 if missing(`dep')
	bys plant: egen total_`dep'_non_missing = total(`dep'_non_missing)
	
	gen non_missing_`dep'=1 if N == total_`dep'_non_missing
	
	drop total_`dep'_non_missing `dep'_non_missing
}

*#############################################################################
*1. mpga_aw
*#############################################################################

foreach dep in labor wages tot_invent_eoy capital exports bldings_val tot_invest output dom_sales sales  {
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

	*Log; all 10 lags;
	local treat mpga_aw

	foreach i of num 1/5 {
	local treat `treat' mpga_aw_lag`i'
	di("`treat'")
	}

	quietly: areg log_`dep'_diff `treat'  i.year if all_10_lags==1, absorb(plant) vce(cluster plant)
	est sto m5_growth_all_10_lags

	*Log+const; all 10 lags;

	local treat mpga_aw

	foreach i of num 1/5 {
	local treat `treat' mpga_aw_lag`i'
	di("`treat'")
	}

	quietly: areg log_`dep'_diff_const `treat' i.year if all_10_lags==1, absorb(plant) vce(cluster plant)
	est sto m5_growth_const_all_10_lags

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
	
	*Levels; all 10 lags;
	local treat mpga_aw

	foreach i of num 1/5 {
	local treat `treat' mpga_aw_lag`i'
	di("`treat'")
	}

	quietly: areg `dep' `treat'  i.year if all_10_lags==1, absorb(plant) vce(cluster plant)
	est sto m5_levels_all_10_lags

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

	
	
	coefplot (m5_growth, label("5 Lags")) (m5_growth_all_10_lags, label("5 Lags, only obs with all 10 lags")) (m5_growth_no_missing, label("5 Lags, only obs with all non-NA"))  (m10_growth, label("10 Lags")) (m10_growth_no_missing, label("10 Lags, only obs with all non-NA")), keep(mpga_aw*) yline(0) vertical xsize(10) title("Growth Rates Models") legend(off) name(g1) 
	local graphs "`graphs' g1"
	
	coefplot (m5_levels, label("5 Lags")) (m5_levels_all_10_lags, label("5 Lags, only obs with all 10 lags")) (m5_levels_no_missing, label("5 Lags, only obs with all non-NA")) (m10_levels, label("10 Lags")) (m10_levels_no_missing, label("10 Lags, only obs with all non-NA")), keep(mpga_aw*) yline(0) vertical xsize(10) title("Models in Levels") legend(position(3) cols(1)) name(g2) 
	local graphs "`graphs' g2" 
	
	coefplot (m5_growth_const, label("5 Lags")) (m5_growth_const_all_10_lags, label("5 Lags, only obs with all 10 lags")) (m5_growth_const_no_missing, label("5 Lags, only obs with all non-NA")) (m10_growth_const, label("10 Lags")) (m10_growth_const_no_missing, label("10 Lags, only obs with all non-NA")), keep(mpga_aw*) yline(0) vertical xsize(10) title("Growth Rates Models, log(x+const)")   name(g3)
	local graphs "`graphs' g3" 
	
	grc1leg `graphs',  row(3) legendfrom(g2) pos(3) title("`: var label `dep'': robustness checks")
	graph display, xsize(10) ysize(4)
	
	graph export "./output/Colombia/coefplots/`dep'_coefplot_col.pdf", replace 
	
	*coefplot (m5_growth, label("Growth Rates")) (m5_growth_all_10_lags) (m5_growth_no_missing)  (m10_growth) (m10_growth_no_missing) , subtitle("d") || (m5_levels) (m5_levels_all_10_lags) (m5_levels_no_missing) (m10_levels) (m10_levels_no_missing)  ||(m5_growth_const) (m5_growth_const_all_10_lags) (m5_growth_const_no_missing) (m10_growth_const) (m10_growth_const_no_missing) , keep(mpga_aw*) yline(0) vertical xsize(10) byopts(compact cols(1) yrescale legend(position(3))) norecycle 
	
	*coefplot (m5_growth) (m5_growth_const) (m5_growth_all_10_lags) (m5_growth_const_all_10_lags) (m5_growth_no_missing) (m5_growth_const_no_missing) (m10_growth) (m10_growth_const) (m10_growth_no_missing) (m10_growth_const_no_missing) (m5_levels, axis(2)) (m5_levels_all_10_lags, axis(2)) (m5_levels_no_missing, axis(2)) (m10_levels, axis(2)) (m10_levels_no_missing, axis(2)), keep(mpga_aw*) yline(0) vertical xsize(10) 

	*coefplot (m5_growth, label("Growth Rates")) (m5_growth_all_10_lags) (m5_growth_no_missing)  (m10_growth) (m10_growth_no_missing)  || (m5_levels) (m5_levels_all_10_lags) (m5_levels_no_missing) (m10_levels) (m10_levels_no_missing)  ||(m5_growth_const) (m5_growth_const_all_10_lags) (m5_growth_const_no_missing) (m10_growth_const) (m10_growth_const_no_missing) , keep(mpga_aw*) yline(0) vertical xsize(10) byopts(compact cols(1) yrescale legend(position(3))) norecycle 
	
	*coefplot (m5) (m5_all_10_lags) (m5_no_missing) (m10) (m10_no_missing) (m5_levels, axis(2)), keep(mpga_aw*) yline(0) vertical xsize(10)  ytitle(m5_levels, axis(2))
	
	*coefplot (m5) (m5_const) (m5_all_10_lags) (m5_const_all_10_lags) (m5_no_missing) (m5_const_no_missing) (m10) (m10_const) (m10_no_missing) (m10_const_no_missing) , keep(mpga_aw*) yline(0) vertical xsize(9) 

	*coefplot (m5) (m5_const) (m5_all_5_lags) (m5_const_all_5_lags) (m5_all_10_lags) (m5_const_all_10_lags) (m5_no_missing) (m5_const_no_missing) || (m10) (m10_const) (m10_all_5_lags) (m10_const_all_5_lags) (m10_all_10_lags) (m10_const_all_10_lags) (m10_no_missing) (m10_const_no_missing), keep(mpga_aw*) yline(0) vertical xsize(9) byopts(compact cols(1) legend(position(3))) 
	
	
}



