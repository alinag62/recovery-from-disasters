/***************************************************************
Stata code for regressions with SR disaster exposure dummy
(last 5 years): Indonesia and earthquakes
***************************************************************/

*run merging file
do code/build/do/merge_and_clean_indonesia_shaking.do
sort plant year

*add dummy for SR exposure: past 5 years, [0:5] - number of EQs in past 5 years
preserve

use "./data/earthquakes/intermediate/Indonesia_adm2/region_panel/panel_earthquakes_thresh_10.dta", clear

merge m:1 ID_2 using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2.dta"
drop _m
rename ADM2_id_in ADM2_id_in_shp_88
destring ADM2_id_in_shp_88, replace
merge m:1 ADM2_id_in using "./data/shapefiles/regions_codes/crosswalk_1988_2015_to_shp.dta"
drop _m

rename populatednum_qs_aw pop_num_aw

*create lags
sort i_harmonize_to_1988 year
foreach i of num 1/5 {
	foreach shake in pop_num_aw{
		by i_harmonize_to_1988: gen `shake'_lag`i' = `shake'[_n-`i']
		label var `shake'_lag`i' "Lag `i'"
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

*merge data on repeated exposure with the main dataset
merge m:1 year ID_2 using "`rep_data'"
keep if _m==3
drop _m

*run regression with SR dummy interaction
preserve
eststo clear
keep if log_rout_exists==1&log_rvad_exists==1&log_rwage_exists==1&log_lbr_exists==1&log_rmat_exists==1&log_rlabprod_exists==1

foreach var in pop_mpga_aw pop_num_aw {
	
	foreach dep in log_rout log_rvad log_lbr log_rwage log_rmat log_rlabprod {		
		
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
	esttab log_rout log_rvad log_lbr log_rwage log_rmat log_rlabprod using ./clean_output/tables/sr_dummy_default_regression_indonesia_shaking_`var'.tex, se noconstant title("Effect of Shaking on Firms in Indonesia, 1988-2015. Dummy for SR repeated exposure") replace booktabs compress addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level." "Rep is defined as the number of years with EQs among 5 last years.") s(N firm year r2_a , labels("N" "Plant FE" "Year FE" "Adjusted R-squared" )) label
		
}

restore




 


