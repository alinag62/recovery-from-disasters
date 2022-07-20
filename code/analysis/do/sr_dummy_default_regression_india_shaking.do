/***************************************************************
Stata code for regressions with SR disaster exposure dummy
(last 5 years): India and earthquakes
***************************************************************/

*run merging file
do code/build/do/merge_and_clean_india_shaking.do

*add dummy for SR exposure: past 5 years, [0:5] - number of EQs in past 5 years
preserve

use "./data/earthquakes/intermediate/India_adm2/region_panel/panel_earthquakes_thresh_10.dta", clear

*after 2008 - only 2 regions exist have spatial IDs
drop if year>=2008

rename populatednum_qs_aw pop_num_aw

*add lags
sort ID_2 year
foreach i of num 1/5 {
	foreach var in pop_num_aw {
		by ID_2: gen `var'_lag`i' = `var'[_n-`i']
		label var `var'_lag`i' "Lag `i'"
	}
}

*before 1989 - firms only stay 1-2 years; no firms that start before 1989
*exist in data in or after 1989
drop if year<=1988

*create a dummy for repeated exposure (N in 5 last year with storm at at least 1 pixel)
foreach k of num 1/5 {
	gen eq_`k'_year_ago = 0
	replace eq_`k'_year_ago = 1 if pop_num_aw_lag`k' >0
}
egen eqs_five_ys = rowtotal(eq_1_year_ago eq_2_year_ago eq_3_year_ago eq_4_year_ago eq_5_year_ago)
label var eqs_five_ys "Rep"
keep year ID_2 eqs_five_ys
rename ID_2 region

tempfile rep_data
save "`rep_data'"

restore

*merge data on repeated exposure with the main dataset
merge m:1 year region using "`rep_data'"
keep if _m==3
drop _m

*run regression with SR dummy interaction

preserve
eststo clear
keep if log_routput_exists==1&log_rsales_exists==1&log_ravg_wage_exists==1&log_rlabcost_exists==1&log_rmaterials_exists==1&log_rcapital_exists==1&log_rfuels_exists==1&log_employees_exists==1&log_rdisttotout_exists==1

foreach var in pop_mpga_aw pop_num_aw {
	
	foreach dep in log_routput log_rsales log_employees log_ravg_wage log_rcapital log_rmaterials {		
		
		local treat c.`var'##c.eqs_five_ys
		foreach i of num 1/5 {
			local treat `treat' c.`var'_lag`i'##c.eqs_five_ys
			*di("`treat'")
		}
		
		*0-5 lags
		eststo `dep': quietly: reghdfe `dep' `treat', absorb(plant year) vce(cluster plant region#year)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace

	}

	*export results 
	esttab log_routput log_rsales log_employees log_ravg_wage log_rcapital log_rmaterials using ./clean_output/tables/sr_dummy_default_regression_india_shaking_`var'.tex, se noconstant title("Effect of Shaking on Firms in India, 1989-2007. Dummy for SR repeated exposure") replace booktabs compress addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level." "Rep is defined as the number of years with EQs among 5 last years.") s(N firm year r2_a , labels("N" "Plant FE" "Year FE" "Adjusted R-squared" )) label
		
}

restore













