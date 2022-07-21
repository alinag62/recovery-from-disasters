/***************************************************************
Stata code for jorda regressions: India and earthquakes
***************************************************************/

*run a program for combining jorda results
do code/analysis/do/appendmodels.do

*run merging file
do code/build/do/merge_and_clean_india_shaking.do

gen pop_mpga_aw_lag0 = pop_mpga_aw
label var pop_mpga_aw_lag0 "Max PGA"

gen pop_num_aw_lag0 = pop_num_aw
label var pop_num_aw_lag0 "N of EQs"

*run and save regression output 
preserve
sort plant year
eststo clear
keep if log_routput_exists==1&log_routput_exists==1&log_rsales_exists==1&log_ravg_wage_exists==1&log_rlabcost_exists==1&log_rmaterials_exists==1&log_rcapital_exists==1&log_rfuels_exists==1&log_employees_exists==1&log_rdisttotout_exists==1

foreach var in pop_mpga_aw pop_num_aw {
	
	foreach dep in log_routput log_rsales log_employees log_ravg_wage log_rcapital log_rmaterials {		
		foreach val of numlist 0/5 {
			eststo est`val': quietly: reghdfe `dep' `var'_lag`val', absorb(plant year) vce(cluster plant region#year) 
		}
		
		eststo combined_`dep': appendmodels est0 est1 est2 est3 est4 est5
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace
		quietly: estadd local N "401258" , replace
	
	}

	*export results 

	esttab combined_log_routput combined_log_rsales combined_log_employees combined_log_ravg_wage combined_log_rcapital combined_log_rmaterials using ./clean_output/tables/jorda_regression_india_shaking_`var'.tex, se noconstant title("Effect of Shaking on Firms in India, 1989-2007. Jorda method") replace booktabs compress addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level." "All the results are from local projections, following Jorda (2005).") s(N firm year , labels("N" "Plant FE" "Year FE" )) label mtitles("100Log(Output)" "100Log(Sales)" "100Log(L)" "100Log(Avg Wage)" "100Log(K)" "100Log(Mat)")
		
		
}
restore 






