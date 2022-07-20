/***************************************************************
Stata code for regressions with LR disaster exposure dummy:
India and earthquakes
***************************************************************/

*run merging file
do code/build/do/merge_and_clean_india_shaking.do

*add dummy for SR exposure: past 5 years, [0:5] - number of EQs in past 5 years
preserve

use "./data/earthquakes/intermediate/India_adm2/region_panel/panel_earthquakes_thresh_10.dta", clear

*after 2008 - only 2 regions exist have spatial IDs
drop if year>=2008

*before 1989 - firms only stay 1-2 years; no firms that start before 1989
*exist in data in or after 1989
drop if year<=1988

rename populatedmpga_aw pop_mpga_aw

*take mean of mpga among all years
collapse (mean) pop_mpga_aw, by(ID_2)
xtile pga_terc = pop_mpga_aw, nq(3)
drop pop_mpga_aw

label var pga_terc "Rep Tercile"

rename ID_2 region

tempfile rep_data
save "`rep_data'"

restore

*merge data on repeated exposure with the main dataset
merge m:1 region using "`rep_data'"
keep if _m==3
drop _m

*run regression with SR dummy interaction

preserve
eststo clear
keep if log_routput_exists==1&log_rsales_exists==1&log_ravg_wage_exists==1&log_rlabcost_exists==1&log_rmaterials_exists==1&log_rcapital_exists==1&log_rfuels_exists==1&log_employees_exists==1&log_rdisttotout_exists==1

foreach var in pop_mpga_aw pop_num_aw {
	
	foreach dep in log_routput log_rsales log_employees log_ravg_wage log_rcapital log_rmaterials {		
		
		local treat c.`var'##i.pga_terc
		foreach i of num 1/5 {
			local treat `treat' c.`var'_lag`i'##i.pga_terc
			*di("`treat'")
		}
		
		*0-5 lags
		eststo `dep': quietly: reghdfe `dep' `treat', absorb(plant year) vce(cluster plant region#year)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace

	}

	*export results 
	esttab log_routput log_rsales log_employees log_ravg_wage log_rcapital log_rmaterials using ./clean_output/tables/lr_dummy_default_regression_india_shaking_`var'.tex, se noconstant title("Effect of Shaking on Firms in India, 1989-2007. Dummy for LR repeated exposure") replace booktabs compress addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level." "Repeated exposure terciles are defined based on LR mean MPGA in pop. areas. Non-interacted variables correspond to 1st tercile.") s(N firm year r2_a , labels("N" "Plant FE" "Year FE" "Adjusted R-squared" )) label drop(*.pga_terc 1.pga_terc#* _cons)
		
}

restore













