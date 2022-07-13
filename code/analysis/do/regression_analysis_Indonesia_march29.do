/*
###########################################################################
                    Intro
########################################################################### */

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
*Part II. Analysing the shaking data
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

label var mpga_aw "Max. PGA"
label var num_qs_aw "NE (t=0)"

rename populatedmpga_aw popmpga_aw
rename populatednum_qs_aw pop_num_qs_aw
rename populatedmag_aw popmag_aw

*create dummy for eq exposure
gen eq_exp = 0
replace eq_exp = 1 if num_qs_aw>0

*create lags
sort region year

foreach i of num 1/10 {
	foreach shake in mpga_aw num_qs_aw popmpga_aw pop_num_qs_aw popmag_aw eq_exp{
		by region: gen `shake'_lag`i' = `shake'[_n-`i']
		label var `shake'_lag`i' "Lag `i'"
	}
}

*create leads
sort region year
foreach i of num 1/10 {
	by region: gen mpga_aw_lead`i' = mpga_aw[_n+`i']
	by region: gen num_qs_aw_lead`i' = num_qs_aw[_n+`i']
	by region: gen eq_exp_lead`i' = eq_exp[_n+`i']
}

*#############################################################################
*Part III. Analysing survey+shaking
*#############################################################################

*merge survey and EQs
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
foreach dep in rout lbr rvad rnetInv rlabprod rwage rmat rinv{
	gen log_`dep' = log(`dep')
	local label_dep: var label `dep'
	label var log_`dep'`"Logged `label_dep'"' 
}

*create log diff
sort plant year
foreach dep in rout lbr rvad rnetInv rlabprod rwage rmat rinv{
	bys plant: gen log_diff_`dep' = log_`dep'[_n] - log_`dep'[_n-1]
	local label_dep: var label `dep'
	label var log_diff_`dep'`"Logged Diff `label_dep'"' 
}

*add size dummies based on year-specific quartiles
preserve

rename lbr lbr33
gen lbr66 = lbr33
collapse (p33) lbr33 (p66) lbr66 , by(year)
label var lbr33  "Labor: 33th perc"
label var lbr66  "Labor: 66th perc"
*twoway (line lbr year) (line lbr2 year, color(green)) (line lbr3 year)
*graph export "./output/Indonesia/figs/size_quartiles_by_year.png", as(png) width(3000) replace

tempfile sizes
save "`sizes'"

restore

merge m:1 year using "`sizes'"
drop _m

* Define labor size
gen size_labor = 1 if lbr>0&lbr<= lbr33
replace size_labor=2 if lbr>lbr33&lbr<= lbr66
replace size_labor=3 if lbr>lbr66

*create size lags
sort plant year
foreach i of num 1/6 {
		by plant: gen size_labor_lag`i' = size_labor[_n-`i']
		label var size_labor_lag`i' "Size Lag `i'"
}

/* regressions witgh interactions on sizes
label var log_rout "Log(Output)"
label var log_rvad "Log(VA)"
label var log_lbr "Log(Labor)"

foreach dep in log_rout log_rvad log_lbr {
	quietly: eststo m1: reghdfe `dep' num_qs_aw num_qs_aw_lag1 num_qs_aw_lag2 num_qs_aw_lag3 num_qs_aw_lag4 num_qs_aw_lag5, absorb(plant year) vce(cluster plant region#year)
	quietly: estadd local firm "Yes" , replace
	quietly: estadd local year "Yes" , replace
	quietly: estadd local firmsize "No" , replace
	quietly: estadd local yearsize "No" , replace
	quietly: estadd local subsample "No" , replace
	
	quietly: eststo m2: reghdfe `dep' num_qs_aw num_qs_aw_lag1 num_qs_aw_lag2 num_qs_aw_lag3 num_qs_aw_lag4 num_qs_aw_lag5 if size_labor_lag6!=., absorb(plant year) vce(cluster plant region#year)
	quietly: estadd local firm "Yes" , replace
	quietly: estadd local year "Yes" , replace
	quietly: estadd local firmsize "No" , replace
	quietly: estadd local yearsize "No" , replace
	quietly: estadd local subsample "Yes" , replace
	

	quietly: eststo m3: reghdfe `dep' c.num_qs_aw#i.size_labor_lag1 c.num_qs_aw_lag1#i.size_labor_lag2 c.num_qs_aw_lag2#i.size_labor_lag3 c.num_qs_aw_lag3#i.size_labor_lag4 c.num_qs_aw_lag4#i.size_labor_lag5 c.num_qs_aw_lag5#i.size_labor_lag6, absorb(i.size_labor#i.plant i.size_labor#i.year) vce(cluster plant region#year) 
	quietly: estadd local firm "Yes" , replace
	quietly: estadd local year "Yes" , replace
	quietly: estadd local firmsize "Yes" , replace
	quietly: estadd local yearsize "Yes" , replace
	quietly: estadd local subsample "Yes" , replace
	
	esttab m1 m2 m3 using ./output/regressions_tex/Indonesia_wb/`dep'_time_specific_lbr_size_no_0.tex, se noconstant title("?") replace longtable booktabs compress addnotes("Plant and year fixed effects (size-interacted or not) are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level." "Firms' size are defined in the year before the earthquake.'") s(N firm year firmsize yearsize subsample r2 , labels("N" "Plant FE" "Year FE" "Plant $\times$ Size FE" "Year $\times$ Size FE" "Sizes Defined for All Lags" "Adjusted R-squared" )) label

}


/* size if firm existed n lags ago
foreach i of num 1/6 {
	replace size_labor_lag`i' = 0 if (size_labor_lag`i'==.)&(year-`i'>=estyear)
}

*regressions witgh interactions on sizes => adding firms that existed but were not in survey
foreach dep in log_rout log_rvad log_lbr {
	
	quietly: eststo m1: reghdfe `dep' num_qs_aw num_qs_aw_lag1 num_qs_aw_lag2 num_qs_aw_lag3 num_qs_aw_lag4 num_qs_aw_lag5, absorb(plant year) vce(cluster plant region#year)
	quietly: estadd local firm "Yes" , replace
	quietly: estadd local year "Yes" , replace

	quietly: eststo m2: reghdfe `dep' c.num_qs_aw#i.size_labor_lag1 c.num_qs_aw_lag1#i.size_labor_lag2 c.num_qs_aw_lag2#i.size_labor_lag3 c.num_qs_aw_lag3#i.size_labor_lag4 c.num_qs_aw_lag4#i.size_labor_lag5 c.num_qs_aw_lag5#i.size_labor_lag6, absorb(plant year) vce(cluster plant region#year) 
	quietly: estadd local firm "Yes" , replace
	quietly: estadd local year "Yes" , replace
	
	esttab m1 m2 using ./output/regressions_tex/Indonesia_wb/`dep'_time_specific_lbr_size.tex, se noconstant title("?") replace longtable booktabs compress addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level." "Firms' size are defined in the year before the earthquake.'") s(N firm year r2 , labels("N" "Plant FE" "Year FE" "Adjusted R-squared" )) label

}*/

*AGGREGATED VERSION

preserve
collapse (sum) rout rvad rnetInv rlabprod rmat (first) num_qs_aw num_qs_aw_lag1 num_qs_aw_lag2 num_qs_aw_lag3 num_qs_aw_lag4 num_qs_aw_lag5, by(year region)

foreach dep in rout rvad rnetInv rlabprod rmat{
	gen log_`dep' = log10(`dep')
	local label_dep: var label `dep'
	label var log_`dep'`"Logged `label_dep'"' 
}


foreach var in num_qs_aw{
	
	foreach dep in log_rout log_rvad log_rnetInv log_rlabprod  log_rmat {		
		
		local treat `var'
		foreach i of num 1/5 {
			local treat `treat' `var'_lag`i'
			di("`treat'")
		}
		
		*0-5 lags
		eststo m5_`dep': quietly: reghdfe `dep' `treat', absorb(region year) vce(cluster region year)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace

	}

	*export results 
	esttab m5_log_rout m5_log_rvad m5_log_rnetInv m5_log_rlabprod  m5_log_rmat using ./output/regressions_tex/Indonesia_wb/table_meth_`var'_v4_agg.tex, se noconstant title("?") replace booktabs compress keep(`treat') addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level. ") s(N firm year r2 , labels("N" "Plant FE" "Year FE" "Adjusted R-squared" )) label
		
}


restore




*WEIGHTED REGRESSION

foreach var in num_qs_aw{
	
	foreach dep in log_rout log_rvad log_rnetInv log_rlabprod  log_rmat {		
		
		local treat `var'
		foreach i of num 1/5 {
			local treat `treat' `var'_lag`i'
			di("`treat'")
		}
		
		*0-5 lags
		eststo m5_`dep': quietly: reghdfe `dep' `treat' [aweight=lbr], absorb(plant year) vce(cluster plant region#year) 
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace

	}

	*export results 
	esttab m5_log_rout m5_log_rvad m5_log_rnetInv m5_log_rlabprod  m5_log_rmat using ./output/regressions_tex/Indonesia_wb/table_meth_`var'_v6.tex, se noconstant title("?") replace booktabs compress keep(`treat') addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level." "Regression is weighted by labor-base size.") s(N firm year r2 , labels("N" "Plant FE" "Year FE" "Adjusted R-squared" )) label
		
}












