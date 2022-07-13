/***************************************************************
Stata code for default regressions: Indonesia and earthquakes
***************************************************************/

*run merging file
do code/build/do/merge_and_clean_indonesia_shaking.do

*run and save regression output 
preserve
sort plant year
eststo clear
keep if log_rout_exists==1&log_rvad_exists==1&log_rwage_exists==1&log_lbr_exists==1&log_rmat_exists==1&log_rlabprod_exists==1

foreach var in pop_mpga_aw pop_num_aw {
	
	foreach dep in log_rout log_rvad log_lbr log_rwage log_rmat log_rlabprod {		
		
		local treat `var'
		foreach i of num 1/5 {
			local treat `treat' `var'_lag`i'
			*di("`treat'")
		}
		
		*0-5 lags
		eststo `dep': quietly: reghdfe `dep' `treat', absorb(plant year) vce(cluster plant region#year)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace

	}

	*export results 
	esttab log_rout log_rvad log_lbr log_rwage log_rmat log_rlabprod  using ./clean_output/tables/default_regression_indonesia_shaking_`var'_no_capital.tex, se noconstant title("Effect of Shaking on Firms in Indonesia, 1988-2015") replace booktabs compress keep(`treat') addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level. ") s(N firm year r2_a , labels("N" "Plant FE" "Year FE" "Adjusted R-squared" )) label
		
}
restore 

*run and save regression output: subset with reported capital
preserve
sort plant year
eststo clear
keep if log_rout_exists==1&log_rvad_exists==1&log_rwage_exists==1&log_lbr_exists==1&log_rmat_exists==1&log_rlabprod_exists==1&log_rkapFB_exists==1

foreach var in pop_mpga_aw pop_num_aw {
	
	foreach dep in log_rout log_rvad log_lbr log_rwage log_rmat log_rlabprod log_rkapFB{		
		
		local treat `var'
		foreach i of num 1/5 {
			local treat `treat' `var'_lag`i'
			*di("`treat'")
		}
		
		*0-5 lags
		eststo `dep': quietly: reghdfe `dep' `treat', absorb(plant year) vce(cluster plant region#year)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace

	}

	*export results 
	esttab log_rout log_rvad log_lbr log_rwage log_rmat log_rlabprod log_rkapFB  using ./clean_output/tables/default_regression_indonesia_shaking_`var'_with_capital.tex, se noconstant title("Effect of Shaking on Firms in Indonesia, 1988-2015") replace booktabs compress keep(`treat') addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level.") s(N firm year r2_a , labels("N" "Plant FE" "Year FE" "Adjusted R-squared" )) label
		
}
restore 


