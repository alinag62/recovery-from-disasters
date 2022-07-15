/***************************************************************
Stata code for regressions with firm size dummy (labor): 
Indonesia and earthquakes (1988, 1995, 2006 reference years)
***************************************************************/

*run merging file
do code/build/do/merge_and_clean_indonesia_shaking.do
sort plant year

*add size dummies based on 1988, 1995 and 2006
foreach y in 1988 1995 2006 {
	preserve
	keep if year == `y'
	xtile size = lbr, nq(3)
	label var size "Size Tercile"
	keep plant size
	
	tempfile sizes_in_`y'
	save "`sizes_in_`y''"
	restore
}

foreach y in 1988 1995 2006 {
	local yplus1=`y'+1
	di("`yplus1'")
}

*run regression for each subset 
foreach y in 1988 1995 2006 {
	local yplus1=`y'+1
	
	preserve
	merge m:1 plant using "`sizes_in_`y''"
	
	*keep only plants with defined sizes and after the year when it's defined
	keep if _m==3
	drop if year<=`y'
	
	eststo clear
	keep if log_rout_exists==1&log_rvad_exists==1&log_rwage_exists==1&log_lbr_exists==1&log_rmat_exists==1&log_rlabprod_exists==1

	foreach var in pop_mpga_aw pop_num_aw {
		
		foreach dep in log_rout log_rvad log_lbr log_rwage log_rmat log_rlabprod {		
			
			local treat c.`var'##i.size
			foreach i of num 1/5 {
				local treat `treat' c.`var'_lag`i'##i.size
				*di("`treat'")
			}
			
			*0-5 lags
			eststo `dep': quietly: reghdfe `dep' `treat', absorb(plant year) vce(cluster plant region#year)
			quietly: estadd local firm "Yes" , replace
			quietly: estadd local year "Yes" , replace

		}

		*export results 
		esttab log_rout log_rvad log_lbr log_rwage log_rmat log_rlabprod using ./clean_output/tables/size_dummy_`y'_default_regression_indonesia_shaking_`var'.tex , se noconstant title("Effect of Shaking on Firms in Indonesia, `yplus1'-2015") replace booktabs compress addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level." "Sizes are defined in `y' based on labor. Non-interacted variables correspond to 1st tercile.") drop(*.size 1.size#* _cons) s(N firm year r2_a , labels("N" "Plant FE" "Year FE" "Adjusted R-squared" )) label
			
	}
	
	restore 
	
}



