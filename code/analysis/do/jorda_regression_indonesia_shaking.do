/***************************************************************
Stata code for jorda regressions: Indonesia and earthquakes
***************************************************************/

*run a program for combining jorda results
do code/analysis/do/appendmodels.do

*run merging file
do code/build/do/merge_and_clean_indonesia_shaking.do

gen pop_mpga_aw_lag0 = pop_mpga_aw
label var pop_mpga_aw_lag0 "Max PGA"

gen pop_num_aw_lag0 = pop_num_aw
label var pop_num_aw_lag0 "N of EQs"

*run and save regression output 
preserve
sort plant year
eststo clear
keep if log_rout_exists==1&log_rvad_exists==1&log_rwage_exists==1&log_lbr_exists==1&log_rmat_exists==1&log_rlabprod_exists==1

foreach var in pop_mpga_aw pop_num_aw {
	
	foreach dep in log_rout log_rvad log_lbr log_rwage log_rmat log_rlabprod {		
		foreach val of numlist 0/5 {
			eststo est`val': quietly: reghdfe `dep' `var'_lag`val', absorb(plant year) vce(cluster plant region#year) 
		}
		
		eststo combined_`dep': appendmodels est0 est1 est2 est3 est4 est5
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace
		quietly: estadd local N "446641" , replace
	
	}

	*export results 

	esttab combined_log_rout combined_log_rvad combined_log_lbr combined_log_rwage combined_log_rmat combined_log_rlabprod using ./clean_output/tables/jorda_regression_indonesia_shaking_`var'.tex, se noconstant title("Effect of Shaking on Firms in Indonesia, 1988-2015. Jorda method") replace booktabs compress addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level." "All the results are from local projections, following Jorda (2005).") s(N firm year , labels("N" "Plant FE" "Year FE" )) label mtitles("100Log(Output)" "100Log(VA)" "100Log(L)"  "100Log(Avg Wage)" "100Log(Mat)" "100Log(VA/L)")
		
		
}
restore 

