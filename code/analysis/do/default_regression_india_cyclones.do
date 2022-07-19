/***************************************************************
Stata code for default regressions: India and cyclones
***************************************************************/

*run merging file
do code/build/do/merge_and_clean_india_cyclones.do

*run and save regression output 
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
	esttab log_routput log_rsales log_employees log_ravg_wage log_rlabcost using ./clean_output/tables/default_regression_india_cyclones_`var'_p1.tex, se noconstant title("Effect of Cyclones on Firms in India, 1985-2007, p.1") replace booktabs compress keep(`treat') addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level. ") s(N firm year r2_a , labels("N" "Plant FE" "Year FE" "Adjusted R-squared" )) label
	
	
		
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
	esttab log_rcapital log_rmaterials log_rfuels log_rdisttotout using ./clean_output/tables/default_regression_india_cyclones_`var'_p2.tex, se noconstant title("Effect of Cyclones on Firms in India, 1985-2007, p.2") replace booktabs compress keep(`treat') addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level. ") s(N firm year r2_a , labels("N" "Plant FE" "Year FE" "Adjusted R-squared" )) label
		
}

restore 


