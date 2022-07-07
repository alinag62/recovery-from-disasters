*cd /Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters
cd /Users/alinagafanova/Library/CloudStorage/Box-Box/recovery-from-disasters

* Housekeeping
clear
clear matrix
set more off

/*import delimited "./data/tropical-cyclones/intermediate/India/maxWindsADM2_with_population.csv", encoding(ISO-8859-9) clear 
drop v1
rename id_2 ID_2
save "./data/tropical-cyclones/intermediate/India/maxWindsADM2_with_population.dta", replace */

*#############################################################################*/
*Part 0. Clean survey
*#############################################################################

use "./data/firm-data/India/Final-Dataset/India_survey_readytoregress.dta", clear 

*drop observations without panel ID 
drop if panelID==.

*after 2008 - only 2 regions exist have spatial IDs
keep if year<2008

merge m:1 year using "./data/firm-data/India/Final-Dataset/wpi_india_2010.dta"
keep if _m==3
drop _m

tempfile survey
save "`survey'"  


*#############################################################################*/
*Part I. Adding lags to the storms data
*#############################################################################

use "./data/tropical-cyclones/intermediate/India/maxWindsADM2_with_population.dta",clear

rename weighted_pop_v_s maxs_pop_only
rename weighted_pop_storm storm_pop_only

label var maxs_pop_only "Max Speed (m/s)"
label var storm_pop_only "N of Storms"

sort ID_2 year
foreach i of num 1/10 {
	by ID_2: gen maxs_pop_only_lag`i' = maxs_pop_only[_n-`i']
	by ID_2: gen storm_pop_only_lag`i' = storm_pop_only[_n-`i']
	
	label var maxs_pop_only_lag`i' "Lag `i'"
	label var storm_pop_only_lag`i' "Lag `i'"
}

drop if year<1985
drop if year>2007

*#############################################################################*/
*Part II. Combining shaking and survey
*#############################################################################
rename ID_2 id_used 
merge 1:m id_used year using "`survey'"  
rename id_used region

*PLENTY OF MISSING SPATIAL IDs 
keep if _m==3
drop _m
rename panelID plant

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

preserve
sort plant year
eststo clear

keep if log_routput_exists==1&log_routput_exists==1&log_rsales_exists==1&log_ravg_wage_exists==1&log_rlabcost_exists==1&log_rmaterials_exists==1&log_rcapital_exists==1&log_rfuels_exists==1&log_employees_exists==1&log_rdisttotout_exists==1

foreach var in maxs_pop_only storm_pop_only {
	
	foreach dep in log_routput log_rsales log_employees log_ravg_wage log_rlabcost {		
		
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
	esttab log_routput log_rsales log_employees log_ravg_wage log_rlabcost using ./output/regressions_tex/India/table_`var'_clean_p1.tex, se noconstant title("India, cyclones, 1985-2007") replace booktabs compress keep(`treat') addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level. ") s(N firm year r2_a , labels("N" "Plant FE" "Year FE" "Adjusted R-squared" )) label
		
}

eststo clear

foreach var in maxs_pop_only storm_pop_only {
	
	foreach dep in log_rcapital log_rmaterials log_rfuels log_rdisttotout{		
		
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
	esttab log_rcapital log_rmaterials log_rfuels log_rdisttotout using ./output/regressions_tex/India/table_`var'_clean_p2.tex, se noconstant title("India, cyclones, 1985-2007") replace booktabs compress keep(`treat') addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level. ") s(N firm year r2_a , labels("N" "Plant FE" "Year FE" "Adjusted R-squared" )) label
		
}

restore 












