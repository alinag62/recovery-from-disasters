/***************************************************************
Stata code for regressions with firm size dummy (labor): 
India and earthquakes (1989 and 1995 reference years)
***************************************************************/

*run merging file
do code/build/do/merge_and_clean_india_shaking.do

*add size dummies based on 1985 and 1995 
foreach y in 1989 1995 {
	preserve
	keep if year == `y'
	xtile size = labor, nq(3)
	label var size "Size Tercile"
	keep plant size
	
	tempfile sizes_in_`y'
	save "`sizes_in_`y''"
	restore
}

*run regression for each subset 
foreach y in 1989 1995 {
	local yplus1=`y'+1
	
	preserve
	merge m:1 plant using "`sizes_in_`y''"
	
	*keep only plants with defined sizes and after the year when it's defined
	keep if _m==3
	drop if year<=`y'
	
	eststo clear
	keep if log_routput_exists==1&log_rsales_exists==1&log_ravg_wage_exists==1&log_rlabcost_exists==1&log_rmaterials_exists==1&log_rcapital_exists==1&log_rfuels_exists==1&log_employees_exists==1&log_rdisttotout_exists==1

	foreach var in pop_mpga_aw pop_num_aw {
		
		foreach dep in log_routput log_rsales log_employees log_ravg_wage log_rcapital log_rmaterials {		
			
			local treat c.`var'##i.size
			foreach i of num 1/5 {
				local treat `treat' c.`var'_lag`i'##i.size
			}
			
			di("`treat'")
			
			*0-5 lags
			eststo `dep': quietly: reghdfe `dep' `treat', absorb(plant year) vce(cluster plant region#year)
			quietly: estadd local firm "Yes" , replace
			quietly: estadd local year "Yes" , replace

		}

		*export results 
		esttab log_routput log_rsales log_employees log_ravg_wage log_rcapital log_rmaterials using ./clean_output/tables/size_dummy_`y'_default_regression_india_shaking_`var'.tex , se noconstant title("Effect of Shaking on Firms in India, `yplus1'-2007") replace booktabs compress addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level." "Sizes are defined in `y' based on labor. Non-interacted variables correspond to 1st tercile.") drop(*.size 1.size#* _cons) s(N firm year r2_a , labels("N" "Plant FE" "Year FE" "Adjusted R-squared" )) label
			
	}
	
	restore 
	
}

