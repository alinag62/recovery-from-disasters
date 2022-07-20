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

*before 1989 - firms only stay 1-2 years; no firms that start before 1989
*exist in data in or after 1989
drop if year<=1988

rename populatednum_qs_aw pop_num_aw

*add lags
sort ID_2 year
foreach i of num 1/5 {
	foreach var in pop_mpga_aw  pop_num_aw {
		by ID_2: gen `var'_lag`i' = `var'[_n-`i']
		label var `var'_lag`i' "Lag `i'"
	}
}


*create a dummy for repeated exposure (N in 5 last year with storm at at least 1 pixel)
foreach k of num 1/5 {
	gen eq_`k'_year_ago = 0
	replace eq_`k'_year_ago = 1 if pop_num_aw_lag`k' >0
}
egen eqs_five_ys = rowtotal(eq_1_year_ago eq_2_year_ago eq_3_year_ago eq_4_year_ago eq_5_year_ago)
label var eqs_five_ys "Rep"
keep year ID_2 eqs_five_ys

tempfile rep_data
save "`rep_data'"

restore
