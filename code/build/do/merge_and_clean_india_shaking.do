/***************************************************************
Stata code for merging India firm data and earthquakes
***************************************************************/

cd /Users/alinagafanova/Library/CloudStorage/Box-Box/recovery-from-disasters

* Housekeeping
clear
clear matrix
set more off

*#############################################################################*/
*Part I. Creating lags in shaking data
*#############################################################################
use "./data/earthquakes/intermediate/India_adm2/region_panel/panel_earthquakes_thresh_10.dta"

*after 2008 - only 2 regions exist have spatial IDs
drop if year>=2008

*rename since the names are too long
rename populatedmpga_aw pop_mpga_aw
rename populatednum_qs_aw pop_num_aw
label var pop_mpga_aw "Max PGA"
label var pop_num_aw "N of EQs"

*add lags
sort ID_2 year
foreach i of num 1/10 {
	foreach var in pop_mpga_aw  pop_num_aw {
		by ID_2: gen `var'_lag`i' = `var'[_n-`i']
		label var `var'_lag`i' "Lag `i'"
	}
}

*before 1989 - firms only stay 1-2 years; no firms that start before 1989
*exist in data in or after 1989
drop if year<=1988

keep year ID_2 pop_mpga_aw* pop_num_aw* 

*#############################################################################*/
*Part II. Merging shaking data with firm data and cleaning it
*#############################################################################
rename ID_2 id_used
merge 1:m id_used year using "./data/firm-data/India/Final-Dataset/India_survey_readytoregress.dta"
keep if _m==3
drop _m

*drop observations without panel ID 
drop if panelID==.
rename panelID plant

*rename region variable
rename id_used region
label var region "unique region in the survey + same in shapefile"

*add wpi for creating real values
merge m:1 year using "./data/firm-data/India/Final-Dataset/wpi_india_2010.dta"
keep if _m==3
drop _m

*generate new vars
gen avg_wage = wages/employees
rename imports importmaterials

*domesticmaterials importmaterials exports

*create real values for a subset of variables
foreach dep in output sales avg_wage labcost materials capital fuels disttotout {
	gen r`dep' = `dep'/wpi2010
}

*create logged vars
foreach dep in routput rsales ravg_wage rlabcost rmaterials rcapital rfuels employees rdisttotout{
	gen log_`dep' = 100*log(`dep')
}

*dummies if variables exist
foreach dep in routput rsales ravg_wage rlabcost rmaterials rcapital rfuels employees rdisttotout{
	gen log_`dep'_exists = 1 if log_`dep'!=.
	replace log_`dep'_exists = 0 if log_`dep'_exists==.
}

order plant year region
sort plant year region

******************************************************************************************************
*change variable labels for better titles
label var log_routput "100Log(Output)" 
label var log_rsales "100Log(Sales)" 
label var log_employees "100Log(L)"
label var log_ravg_wage "100Log(Avg Wage)"
label var log_rcapital "100Log(K)"
label var log_rmaterials "100Log(Mat)"
label var log_rlabcost "100Log(L Cost)"
label var log_rfuels "100Log(Fuels)"
label var log_rdisttotout "100Log(Distr Cost)"
******************************************************************************************************





