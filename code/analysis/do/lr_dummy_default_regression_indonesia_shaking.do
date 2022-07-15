/***************************************************************
Stata code for regressions with LR disaster exposure dummy:
Indonesia and earthquakes
***************************************************************/

*run merging file
do code/build/do/merge_and_clean_indonesia_shaking.do
sort plant year

*add dummy for SR exposure: tercile based on avg mpga among all years
preserve

use "./data/earthquakes/intermediate/Indonesia_adm2/region_panel/panel_earthquakes_thresh_10.dta", clear

merge m:1 ID_2 using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2.dta"
drop _m
rename ADM2_id_in ADM2_id_in_shp_88
destring ADM2_id_in_shp_88, replace
merge m:1 ADM2_id_in using "./data/shapefiles/regions_codes/crosswalk_1988_2015_to_shp.dta"
drop _m

rename populatedmpga_aw pop_mpga_aw

*take mean of mpga among all years
collapse (mean) pop_mpga_aw, by(ID_2)
xtile pga_terc = pop_mpga_aw, nq(3)
drop pop_mpga_aw

label var pga_terc "Rep Tercile"

tempfile rep_data
save "`rep_data'"

restore

*merge data on repeated exposure with the main dataset
merge m:1 ID_2 using "`rep_data'"
keep if _m==3
drop _m

*run regression with LR dummy interaction
preserve
eststo clear
keep if log_rout_exists==1&log_rvad_exists==1&log_rwage_exists==1&log_lbr_exists==1&log_rmat_exists==1&log_rlabprod_exists==1

foreach var in pop_mpga_aw pop_num_aw {
	
	foreach dep in log_rout log_rvad log_lbr log_rwage log_rmat log_rlabprod {		
		
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
	esttab log_rout log_rvad log_lbr log_rwage log_rmat log_rlabprod using ./clean_output/tables/lr_dummy_default_regression_indonesia_shaking_`var'.tex, se noconstant title("Effect of Shaking on Firms in Indonesia, 1988-2015. Dummy for LR repeated exposure") replace booktabs compress addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level." "Repeated exposure terciles are defined based on LR mean MPGA in pop. areas. Non-interacted variables correspond to 1st tercile.") s(N firm year r2_a , labels("N" "Plant FE" "Year FE" "Adjusted R-squared" )) label drop(*.pga_terc 1.pga_terc#* _cons)
		
}

restore





