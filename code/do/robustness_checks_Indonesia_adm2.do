/*
###########################################################################
                    Intro
########################################################################### */
cd /Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters

* Housekeeping
clear
clear matrix
set more off

local path2save_shake "./data/earthquakes/intermediate/Indonesia_adm2"
local firms_folder "./data/firm-data/Indonesia"
local path2shp_dta "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2.dta"
local r2r_folder "./data/firm-data/clean-with-eq-ready-to-regress/"
local country Indonesia
local ID ID_2
local ID_in_survey id_used

*#############################################################################
/*set scheme plottig  
grstyle init
grstyle set imesh, horizontal minor
grstyle set ci 538, select(13 10) opacity(60)
grstyle set color "35 35 35" "35 35 35"  "62 102 206"  "62 102 206" */

grstyle init
grstyle set mesh, horizontal compact minor

*#############################################################################
*0. Cleaning dataset
*#############################################################################

*################
*add labels from a different document
import excel "./data/firm-data/Indonesia/Final-Dataset/VarList-Whole.xls", sheet("Var List (SI Cross)") firstrow  clear
gen clean_var = substr(VAR_NEW, 2, .)
keep clean_var LABEL

tempname fh
local N = c(N)
di(`N')

// create a new do-file
file open `fh' using ./code/do/my_labels_IDN.do , write replace
forvalues i = 1/`N' {
	file write `fh' "cap " 
    file write `fh' "label variable `= clean_var[`i']' "
    file write `fh' `""`= LABEL[`i']'""' _newline
}
file close `fh'
type ./code/do/my_labels_IDN.do

use "`firms_folder'/Final-Dataset/`country'_survey_readytoregress.dta", clear
do ./code/do/my_labels_IDN.do
rm ./code/do/my_labels_IDN.do
*################

rename PSID plant
order plant year

keep plant year province_id district_id province_name district_name id_used country  name_used   LTLNOU FTTLCU STDVCU OUTPUT V1104 V1116 YPRVCU PRPREX ZPDCCU ZPDKCU ZNDCCU ZNDKCU 


tempfile survey
save "`survey'"

use "`path2save_shake'/region_panel/panel_earthquakes_thresh_10.dta", clear

rename region ID_2
merge m:1  ID_2 using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2.dta"
drop _m
rename ID_2 region
drop NAME_0 ID_0 ISO ID_1 NAME_1 HASC_2 CCN_2 CCA_2 TYPE_2 ENGTYPE_2 VARNAME_2 _ID

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
rename id_used region
bys region year: gen firms_that_year_in_region = _N

*get final dataset
merge m:1 region year using "`shaking'"
order plant year region
keep if _m==3

rename LTLNOU labor
rename FTTLCU tot_invest
rename STDVCU tot_invent_eoy
rename OUTPUT tot_output
rename V1104 bldings_val
rename V1116 capital
rename YPRVCU output
gen exports = output*(PRPREX/100) if PRPREX!=.&PRPREX<=100

label var exports "Goods Exported"

*convert some vars to thousands 
gen tot_invest_th = tot_invest/1000
gen tot_invent_eoy_th = tot_invent_eoy/1000
gen wages = (ZPDCCU+ ZPDKCU+ ZNDCCU+ ZNDKCU)
gen wages_th = (ZPDCCU+ ZPDKCU+ ZNDCCU+ ZNDKCU)/1000
gen tot_output_th = tot_output/1000
gen bldings_val_th = bldings_val/1000
gen capital_th = capital/1000
drop Z* PRPREX output

label var tot_invest_th "Total Investment, in ths"
label var tot_invent_eoy_th "Total Inventories (end of the year), in ths"
label var wages_th "Wages Total, in ths"
label var tot_output_th "Total Output, in ths"
label var capital_th "Total Assets Book Value, in ths"
label var bldings_val_th "Book Value of Buildings and Structures, in ths"

*create logged vars
foreach dep in labor tot_invest tot_invent_eoy capital tot_output bldings_val wages exports{
	gen log_`dep' = log(`dep')
	local label_dep: var label `dep'
	label var log_`dep'`"Logged `label_dep'"' 
}

*create 1 diff of logs
sort plant year
foreach dep in labor tot_invest tot_invent_eoy capital tot_output bldings_val wages exports{
	bys plant: gen log_`dep'_diff = log_`dep'-log_`dep'[_n-1]
	
	local label_dep: var label `dep'
	label var log_`dep'_diff `"Logged `label_dep' (first difference)"' 
}

*create logged vars with constant if 0
foreach dep in labor tot_invest tot_invent_eoy capital tot_output bldings_val wages exports{
	gen log_`dep'_const = log(`dep'+0.001)
}

*create 1 diff of logs with constant if 0
sort plant year
foreach dep in labor tot_invest tot_invent_eoy capital tot_output bldings_val wages exports{
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
foreach dep in labor tot_invest tot_invent_eoy capital tot_output bldings_val wages exports {
	gen `dep'_non_missing = 1
	replace `dep'_non_missing = 0 if missing(`dep')
	bys plant: egen total_`dep'_non_missing = total(`dep'_non_missing)
	
	gen non_missing_`dep'=1 if N == total_`dep'_non_missing
	
	drop total_`dep'_non_missing `dep'_non_missing
}

*#############################################################################
*1. mpga_aw
*#############################################################################
foreach dep in labor tot_invest tot_invent_eoy capital tot_output bldings_val wages exports  {
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
	
	graph export "./output/Indonesia/coefplots/`dep'_coefplot_idn.pdf", replace 
	
	*coefplot (m5_growth, label("Growth Rates")) (m5_growth_all_10_lags) (m5_growth_no_missing)  (m10_growth) (m10_growth_no_missing) , subtitle("d") || (m5_levels) (m5_levels_all_10_lags) (m5_levels_no_missing) (m10_levels) (m10_levels_no_missing)  ||(m5_growth_const) (m5_growth_const_all_10_lags) (m5_growth_const_no_missing) (m10_growth_const) (m10_growth_const_no_missing) , keep(mpga_aw*) yline(0) vertical xsize(10) byopts(compact cols(1) yrescale legend(position(3))) norecycle 
	
	*coefplot (m5_growth) (m5_growth_const) (m5_growth_all_10_lags) (m5_growth_const_all_10_lags) (m5_growth_no_missing) (m5_growth_const_no_missing) (m10_growth) (m10_growth_const) (m10_growth_no_missing) (m10_growth_const_no_missing) (m5_levels, axis(2)) (m5_levels_all_10_lags, axis(2)) (m5_levels_no_missing, axis(2)) (m10_levels, axis(2)) (m10_levels_no_missing, axis(2)), keep(mpga_aw*) yline(0) vertical xsize(10) 

	*coefplot (m5_growth, label("Growth Rates")) (m5_growth_all_10_lags) (m5_growth_no_missing)  (m10_growth) (m10_growth_no_missing)  || (m5_levels) (m5_levels_all_10_lags) (m5_levels_no_missing) (m10_levels) (m10_levels_no_missing)  ||(m5_growth_const) (m5_growth_const_all_10_lags) (m5_growth_const_no_missing) (m10_growth_const) (m10_growth_const_no_missing) , keep(mpga_aw*) yline(0) vertical xsize(10) byopts(compact cols(1) yrescale legend(position(3))) norecycle 
	
	*coefplot (m5) (m5_all_10_lags) (m5_no_missing) (m10) (m10_no_missing) (m5_levels, axis(2)), keep(mpga_aw*) yline(0) vertical xsize(10)  ytitle(m5_levels, axis(2))
	
	*coefplot (m5) (m5_const) (m5_all_10_lags) (m5_const_all_10_lags) (m5_no_missing) (m5_const_no_missing) (m10) (m10_const) (m10_no_missing) (m10_const_no_missing) , keep(mpga_aw*) yline(0) vertical xsize(9) 

	*coefplot (m5) (m5_const) (m5_all_5_lags) (m5_const_all_5_lags) (m5_all_10_lags) (m5_const_all_10_lags) (m5_no_missing) (m5_const_no_missing) || (m10) (m10_const) (m10_all_5_lags) (m10_const_all_5_lags) (m10_all_10_lags) (m10_const_all_10_lags) (m10_no_missing) (m10_const_no_missing), keep(mpga_aw*) yline(0) vertical xsize(9) byopts(compact cols(1) legend(position(3))) 
	
	
}








