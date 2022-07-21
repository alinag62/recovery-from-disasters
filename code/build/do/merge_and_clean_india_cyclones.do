/***************************************************************
Stata code for merging India firm data and cyclones
***************************************************************/

cd /Users/alinagafanova/Library/CloudStorage/Box-Box/recovery-from-disasters

* Housekeeping
clear
clear matrix
set more off

*#############################################################################*/
*Part I. Creating lags in cyclones data
*#############################################################################
*the output of cyclone algorithm is saved as .csv
*make sure you have the latest version
import delimited "./data/tropical-cyclones/intermediate/India/maxWindsADM2_with_population.csv", encoding(ISO-8859-9) clear 
drop v1
rename id_2 ID_2
save "./data/tropical-cyclones/intermediate/India/maxWindsADM2_with_population.dta", replace 

use "./data/tropical-cyclones/intermediate/India/maxWindsADM2_with_population.dta",clear

*after 2008 - only 2 regions exist have spatial IDs
drop if year>2007

*rename since the names are too long
rename weighted_pop_v_s maxs_pop_only
rename weighted_pop_storm storm_pop_only
label var maxs_pop_only "Max Speed (m/s)"
label var storm_pop_only "N of Storms"

*add lags
sort ID_2 year
foreach i of num 1/10 {
	foreach var in maxs_pop_only  storm_pop_only {
		by ID_2: gen `var'_lag`i' = `var'[_n-`i']
		label var `var'_lag`i' "Lag `i'"
	}
}

keep year ID_2 maxs_pop_only* storm_pop_only* 

*#############################################################################*/
*Part II. Merging cyclones data with firm data and cleaning it
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



































