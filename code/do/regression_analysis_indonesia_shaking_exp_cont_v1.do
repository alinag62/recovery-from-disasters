*#############################################################################
* v1 - based on years with exposure in past 5 years
*#############################################################################

cd /Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters

* Housekeeping
clear
clear matrix
set more off

use "./data/firm-data/Indonesia/Final-Dataset/maindata_clean_95perc.dta",clear

*#############################################################################
set scheme plottig 
grstyle init
grstyle set imesh, horizontal minor
grstyle set ci 538, select(13 10) opacity(60)
grstyle set color "35 35 35" "35 35 35"  "62 102 206"  "62 102 206"

*#############################################################################
*0. Clean
*#############################################################################
rename i_harmonize_to_1988 region

rename PSID plant

tempfile survey
save "`survey'"

*#############################################################################*/
*Part II. Adding lags to the shaking data
*#############################################################################

use "./data/earthquakes/intermediate/Indonesia_adm2/region_panel/panel_earthquakes_thresh_10.dta", clear

rename region ID_2
merge m:1 ID_2 using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2.dta"
drop _m
rename ADM2_id_in ADM2_id_in_shp_88
destring ADM2_id_in_shp_88, replace
merge m:1 ADM2_id_in using "./data/shapefiles/regions_codes/crosswalk_1988_2015_to_shp.dta"
drop _m
rename i_harmonize_to_1988 region

rename populatedmpga_aw pop_mpga_aw
rename populatednum_qs_aw pop_num_aw
label var pop_mpga_aw "Max PGA"
label var pop_num_aw "N of EQs"

sort region year
foreach i of num 1/10 {
	by region: gen pop_mpga_aw_lag`i' = pop_mpga_aw[_n-`i']
	by region: gen pop_num_aw_lag`i' = pop_num_aw[_n-`i']
	by region: gen num_qs_aw_lag`i' = num_qs_aw[_n-`i']
	
	label var pop_mpga_aw_lag`i' "Lag `i'"
	label var pop_num_aw_lag`i' "Lag `i'"
}

*create a dummy for repeated exposure (N in 5 last year with storm at at least 1 pixel)
foreach k of num 1/5 {
	gen eq_`k'_year_ago = 0
	replace eq_`k'_year_ago = 1 if pop_num_aw_lag`k' >0
}
egen eqs_five_ys = rowtotal(eq_1_year_ago eq_2_year_ago eq_3_year_ago eq_4_year_ago eq_5_year_ago)
label var eqs_five_ys "Rep"

*#############################################################################*/
*Part III. Combining shaking and survey
*#############################################################################
merge 1:m region year using "`survey'"
keep if _m==3
drop _m

rename EELVCU elec
rename V1115 est_val
rename V1116 book_val
rename V1117 depr

* get deflator by sector and deflated vars
gen deflator = rvad/vad
gen rnetInv = netInv*deflator
label var rnetInv "Net Investment, deflated by sector"
gen rlabprod = labprod*deflator
label var rlabprod "Labor Productivity (va/lbr), deflated by sector"
gen rinv = inv*deflator
label var rinv "Investment, deflated by sector"

*create logged vars
foreach dep in rout lbr rvad rnetInv rlabprod rwage rmat rinv rkap{
	gen log_`dep' = 100*log(`dep')
	local label_dep: var label `dep'
	label var log_`dep'`"100Log `label_dep'"' 
}

*dummies if variables exist
foreach dep in rout lbr rvad rnetInv rlabprod rwage rmat rinv rkap{
	gen `dep'_exists = 1 if `dep'!=.
	replace `dep'_exists = 0 if `dep'_exists==.
	
	gen log_`dep'_exists = 1 if log_`dep'!=.
	replace log_`dep'_exists = 0 if log_`dep'_exists==.
}


******************************************************************************************************

*change variable labels for better titles
label var log_rout "100Log(Output)" 
label var log_lbr "100Log(L)"
label var log_rvad "100Log(VA)"
label var log_rnetInv "100Log(Net Inv)"
label var log_rlabprod  "100Log(VA/L)"
label var log_rwage "100Log(Avg Wage)"
label var log_rinv "100Log(Inv)"
label var log_rmat "100Log(Mat)"
label var log_rkap "100Log(K)"

******************************************************************************************************

* 1988-2015: find an overlap so that N is the same for all the regressions

preserve
sort plant year
eststo clear
keep if log_rout_exists==1&log_rvad_exists==1&log_rwage_exists==1&log_lbr_exists==1&log_rmat_exists==1&log_rlabprod_exists==1

foreach var in pop_mpga_aw pop_num_aw {
	
	foreach dep in log_rout log_rvad log_lbr log_rwage log_rmat {		
		
		local treat c.`var'##c.eqs_five_ys
		foreach i of num 1/5 {
			local treat `treat' c.`var'_lag`i'##c.eqs_five_ys
			di("`treat'")
		}
		
		*0-5 lags
		eststo `dep': quietly: reghdfe `dep' `treat', absorb(plant year) vce(cluster plant region#year)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace

	}

	*export results 
	esttab log_rout log_rvad log_lbr log_rwage log_rmat  using ./output/regressions_tex/Indonesia/table_`var'_interact_1.tex, se noconstant title("Indonesia, 1988-2015") replace booktabs compress  addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level. ") s(N firm year r2_a , labels("N" "Plant FE" "Year FE" "Adjusted R-squared" )) label
		
}

restore 





