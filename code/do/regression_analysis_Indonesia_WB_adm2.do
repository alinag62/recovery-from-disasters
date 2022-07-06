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
label var num_qs_aw "N of EQs"

rename populatedmpga_aw popmpga_aw
rename populatednum_qs_aw pop_num_qs_aw
rename populatedmag_aw popmag_aw

*create lags
sort region year

foreach i of num 1/10 {
	foreach shake in mpga_aw num_qs_aw popmpga_aw pop_num_qs_aw popmag_aw{
		by region: gen `shake'_lag`i' = `shake'[_n-`i']
		label var `shake'_lag`i' "Lag `i'"
	}
}

*create leads
sort region year
foreach i of num 1/10 {
	by region: gen mpga_aw_lead`i' = mpga_aw[_n+`i']
	by region: gen num_qs_aw_lead`i' = num_qs_aw[_n+`i']
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
	gen log_`dep' = log10(`dep')
	local label_dep: var label `dep'
	label var log_`dep'`"Logged `label_dep'"' 
}

/*create diff of logs
sort plant year
foreach dep in out lbr kap labprod elec est_val book_val depr vad netInv inv{
	bys plant: gen log_`dep'_diff = log_`dep'-log_`dep'[_n-1]
	local label_dep: var label `dep'
	label var log_`dep'_diff `"Logged `label_dep' (first difference)"' 
}*/



*add macro-region FEs
gen macro_region = 1 if provn==11|provn==12|provn==13|provn==14|provn==15|provn==17|provn==16|provn==18
replace macro_region = 2 if provn==31|provn==32|provn==33|provn==34|provn==35
replace macro_region = 3 if provn==51|provn==52|provn==53
replace macro_region = 4 if provn==61|provn==62|provn==63|provn==64
replace macro_region = 5 if provn==71|provn==72|provn==73|provn==74
replace macro_region = 6 if provn==81
replace macro_region = 7 if provn==82

*add size dummies (ONLY firms starting in 1988)
preserve
keep if year==1988
xtile size_tiers = lbr, nq(3)
keep plant size_tiers
drop if size_tiers==.

tempfile sizes
save "`sizes'"
restore
merge m:1 plant using "`sizes'"
drop _m

*add dummy for survival(?)
bys plant: egen max_year = max(year)
gen surv = 0
replace surv = 1 if max_year==2015
drop max_year


*I. Year x region time FE, plant FE, errors clustered at plant-level
		
/*foreach var in mpga_aw num_qs_aw  {
	foreach dep in log_OUTPUT log_lbr log_kap log_labprod {		
		
		**********
		* Year and plant fixed effects; t=0 included
		**********
		
		eststo clear
		local treat `var'
		
		*0 lag
		quietly: areg `dep' `treat'  i.year##i.macro_region, absorb(plant) vce(cluster plant)
		est sto m0
		
		foreach i of num 1/5 {
			local treat `treat' `var'_lag`i'
			di("`treat'")
		}
		
		*0-5 lags
		quietly: areg `dep' `treat'  i.year##i.macro_region, absorb(plant) vce(cluster plant)
		est sto m5
		
		foreach i of num 6/10 {
			local treat `treat' `var'_lag`i'
			di("`treat'")
		}
		
		*0-10 lags
		quietly: areg `dep' `treat'  i.year##i.macro_region, absorb(plant) vce(cluster plant)
		est sto m10

		*export results 
		local results m0 m5 m10
		esttab `results' using ./output/regressions_tex/Indonesia_wb/table_`var'_`dep'.tex, se noconstant nomtitles title("Indonesia ADM2. Dependent variable: `: var label `dep''.") replace booktabs compress keep(`treat') addnotes("Plant and year-macro region fixed effects are included in each" "specification. Errors are clustered on plant-level.") label

	
	}
}

foreach var in mpga_aw num_qs_aw  {
	foreach dep in log_OUTPUT_diff log_lbr_diff log_kap_diff log_labprod_diff {		
		
		**********
		* Year and plant fixed effects; t=0 included
		**********
		
		eststo clear
		local treat `var'
		
		*0 lag
		quietly: areg `dep' `treat'  i.year##i.macro_region, absorb(plant) vce(cluster plant)
		est sto m0
		
		foreach i of num 1/5 {
			local treat `treat' `var'_lag`i'
			di("`treat'")
		}
		
		*0-5 lags
		quietly: areg `dep' `treat'  i.year##i.macro_region, absorb(plant) vce(cluster plant)
		est sto m5
		
		foreach i of num 6/10 {
			local treat `treat' `var'_lag`i'
			di("`treat'")
		}
		
		*0-10 lags
		quietly: areg `dep' `treat'  i.year##i.macro_region, absorb(plant) vce(cluster plant)
		est sto m10

		*export results 
		local results m0 m5 m10
		esttab `results' using ./output/regressions_tex/Indonesia_wb/table_`var'_`dep'_log_diff.tex, se noconstant nomtitles title("Indonesia ADM2. Dependent variable: `: var label `dep''.") replace booktabs compress keep(`treat') addnotes("Plant and year-macro region fixed effects are included in each" "specification. Errors are clustered on plant-level.") label

	
	}
}
*/


*II. Plant and year FE, errors clustered at region-level	
		
/*foreach var in mpga_aw num_qs_aw popmpga_aw pop_num_qs_aw popmag_aw {
	foreach dep in log_OUTPUT log_lbr log_kap log_labprod log_elec log_est_val log_book_val log_depr log_vad{		
		eststo clear
		local treat `var'
		
		*0 lag
		eststo m0: quietly: areg `dep' `treat'  i.year, absorb(plant) vce(cluster region)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace
		quietly: estadd local size "No" , replace
		quietly: estadd local exit "No" , replace
		
		foreach i of num 1/5 {
			local treat `treat' `var'_lag`i'
			di("`treat'")
		}
		
		*0-5 lags
		eststo m5: quietly: areg `dep' `treat'  i.year, absorb(plant) vce(cluster region)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace
		quietly: estadd local size "No" , replace
		quietly: estadd local exit "No" , replace
		
		foreach i of num 6/10 {
			local treat `treat' `var'_lag`i'
			di("`treat'")
		}
		
		*0-10 lags
		eststo m10: quietly: areg `dep' `treat'  i.year, absorb(plant) vce(cluster region)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace
		quietly: estadd local size "No" , replace
		quietly: estadd local exit "No" , replace
		
		*0 lag with size
		local treat `var'
		eststo m0_size: quietly: areg `dep' `treat'  i.year i.size_tier, absorb(plant) vce(cluster region)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace
		quietly: estadd local size "Yes" , replace
		quietly: estadd local exit "No" , replace
		
		foreach i of num 1/5 {
			local treat `treat' `var'_lag`i'
			di("`treat'")
		}
		
		*0-5 lags
		eststo m5_size: quietly: areg `dep' `treat'  i.year i.size_tier, absorb(plant) vce(cluster region)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace
		quietly: estadd local size "Yes" , replace
		quietly: estadd local exit "No" , replace
		
		foreach i of num 6/10 {
			local treat `treat' `var'_lag`i'
			di("`treat'")
		}
		
		*0-10 lags
		eststo m10_size: quietly: areg `dep' `treat'  i.year i.size_tier, absorb(plant) vce(cluster region)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace
		quietly: estadd local size "Yes" , replace
		quietly: estadd local exit "No" , replace
		
		*0 lag, no exit
		local treat `var'
		eststo m0_exit: quietly: areg `dep' `treat'  i.year if surv==1, absorb(plant) vce(cluster region)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace
		quietly: estadd local size "Yes" , replace
		quietly: estadd local exit "Yes" , replace
		
		foreach i of num 1/5 {
			local treat `treat' `var'_lag`i'
			di("`treat'")
		}
		
		*0-5 lags
		eststo m5_exit: quietly: areg `dep' `treat'  i.year if surv==1, absorb(plant) vce(cluster region)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace
		quietly: estadd local size "Yes" , replace
		quietly: estadd local exit "Yes" , replace
		
		foreach i of num 6/10 {
			local treat `treat' `var'_lag`i'
			di("`treat'")
		}
		
		*0-10 lags
		eststo m10_exit: quietly: areg `dep' `treat'  i.year if surv==1, absorb(plant) vce(cluster region)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace
		quietly: estadd local size "Yes" , replace
		quietly: estadd local exit "Yes" , replace
		
		*export results 
		local results m0 m5 m10 m0_size m5_size m10_size m0_exit m5_exit m10_exit
		
		esttab `results' using ./output/regressions_tex/Indonesia_wb/table_`var'_`dep'_v2.tex, se noconstant nomtitles title("Indonesia ADM2. Dependent variable: `: var label `dep''.") replace booktabs compress keep(`treat') addnotes("Plant and year fixed effects are included in each specification." "Errors are clustered on region-level. Size is defined by labor tier in 1988.") s(N firm year size exit r2 , labels("N" "Plant FE" "Year FE" "Size FE" "No exit" "Adjusted R-squared" )) label

	
	}
}


*II. Plant and year FE, errors clustered at plant-level	
		
foreach var in mpga_aw num_qs_aw popmpga_aw pop_num_qs_aw popmag_aw   {
	foreach dep in log_OUTPUT log_lbr log_kap log_labprod log_elec log_est_val log_book_val log_depr log_vad{		
		eststo clear
		local treat `var'
		
		*0 lag
		eststo m0: quietly: areg `dep' `treat'  i.year, absorb(plant) vce(cluster plant)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace
		quietly: estadd local size "No" , replace
		quietly: estadd local exit "No" , replace
		
		foreach i of num 1/5 {
			local treat `treat' `var'_lag`i'
			di("`treat'")
		}
		
		*0-5 lags
		eststo m5: quietly: areg `dep' `treat'  i.year, absorb(plant) vce(cluster plant)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace
		quietly: estadd local size "No" , replace
		quietly: estadd local exit "No" , replace
		
		foreach i of num 6/10 {
			local treat `treat' `var'_lag`i'
			di("`treat'")
		}
		
		*0-10 lags
		eststo m10: quietly: areg `dep' `treat'  i.year, absorb(plant) vce(cluster plant)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace
		quietly: estadd local size "No" , replace
		quietly: estadd local exit "No" , replace
		
		*0 lag with size
		local treat `var'
		eststo m0_size: quietly: areg `dep' `treat'  i.year i.size_tier, absorb(plant) vce(cluster plant)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace
		quietly: estadd local size "Yes" , replace
		quietly: estadd local exit "No" , replace
		
		foreach i of num 1/5 {
			local treat `treat' `var'_lag`i'
			di("`treat'")
		}
		
		*0-5 lags
		eststo m5_size: quietly: areg `dep' `treat'  i.year i.size_tier, absorb(plant) vce(cluster plant)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace
		quietly: estadd local size "Yes" , replace
		quietly: estadd local exit "No" , replace
		
		foreach i of num 6/10 {
			local treat `treat' `var'_lag`i'
			di("`treat'")
		}
		
		*0-10 lags
		eststo m10_size: quietly: areg `dep' `treat'  i.year i.size_tier, absorb(plant) vce(cluster plant)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace
		quietly: estadd local size "Yes" , replace
		quietly: estadd local exit "No" , replace
		
		*0 lag, no exit
		local treat `var'
		eststo m0_exit: quietly: areg `dep' `treat'  i.year if surv==1, absorb(plant) vce(cluster plant)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace
		quietly: estadd local size "Yes" , replace
		quietly: estadd local exit "Yes" , replace
		
		foreach i of num 1/5 {
			local treat `treat' `var'_lag`i'
			di("`treat'")
		}
		
		*0-5 lags
		eststo m5_exit: quietly: areg `dep' `treat'  i.year if surv==1, absorb(plant) vce(cluster plant)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace
		quietly: estadd local size "Yes" , replace
		quietly: estadd local exit "Yes" , replace
		
		foreach i of num 6/10 {
			local treat `treat' `var'_lag`i'
			di("`treat'")
		}
		
		*0-10 lags
		eststo m10_exit: quietly: areg `dep' `treat'  i.year if surv==1, absorb(plant) vce(cluster plant)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace
		quietly: estadd local size "Yes" , replace
		quietly: estadd local exit "Yes" , replace
		
		
		*export results 
		local results m0 m5 m10 m0_size m5_size m10_size m0_exit m5_exit m10_exit
		
		esttab `results' using ./output/regressions_tex/Indonesia_wb/table_`var'_`dep'_v3.tex, se noconstant nomtitles title("Indonesia ADM2. Dependent variable: `: var label `dep''.") replace booktabs compress keep(`treat') addnotes("Plant and year fixed effects are included in each specification." "Errors are clustered on plant-level. Size is defined by labor tier in 1988.") s(N firm year size exit r2 , labels("N" "Plant FE" "Year FE" "Size FE" "No exit" "Adjusted R-squared" )) label

	
	}
}  */


*V4: Plant and year FE, adding 2way clustering 

foreach var in mpga_aw num_qs_aw popmpga_aw {
	foreach dep in log_rout log_lbr log_rvad log_rnetInv log_rlabprod log_rwage log_rmat log_rinv {		
		eststo clear
		local treat `var'
		
		*0 lag
		eststo m0: quietly: reghdfe `dep' `treat', absorb(plant year) vce(cluster plant region#year)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace
		quietly: estadd local exit "No" , replace
		
		foreach i of num 1/5 {
			local treat `treat' `var'_lag`i'
			di("`treat'")
		}
		
		*0-5 lags
		eststo m5: quietly: reghdfe `dep' `treat', absorb(plant year) vce(cluster plant region#year)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace
		quietly: estadd local exit "No" , replace
		
		foreach i of num 6/10 {
			local treat `treat' `var'_lag`i'
			di("`treat'")
		}
		
		*0-10 lags
		eststo m10: quietly: reghdfe `dep' `treat', absorb(plant year) vce(cluster plant region#year)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace
		quietly: estadd local exit "No" , replace

		*0 lag, no exit
		local treat `var'
		eststo m0_exit: quietly: reghdfe `dep' `treat' if surv==1, absorb(plant year) vce(cluster plant region#year)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace
		quietly: estadd local exit "Yes" , replace
		
		foreach i of num 1/5 {
			local treat `treat' `var'_lag`i'
			di("`treat'")
		}
		
		*0-5 lags, no exit
		eststo m5_exit: quietly: reghdfe `dep' `treat' if surv==1, absorb(plant year) vce(cluster plant region#year)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace
		quietly: estadd local exit "Yes" , replace
		
		foreach i of num 6/10 {
			local treat `treat' `var'_lag`i'
			di("`treat'")
		}
		
		*0-10 lags, no exit
		eststo m10_exit: quietly: reghdfe `dep' `treat' if surv==1, absorb(plant year) vce(cluster plant region#year)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace
		quietly: estadd local exit "Yes" , replace

		*export results 
		local results m0 m5 m10 m0_exit m5_exit m10_exit
		
		esttab `results' using ./output/regressions_tex/Indonesia_wb/table_`var'_`dep'_v4.tex, se noconstant nomtitles title("Indonesia ADM2. Dependent variable: `: var label `dep''.") replace booktabs compress keep(`treat') addnotes("Plant and year fixed effects are included in each specification." "Errors are clustered on both plant-level and region-by-year level. ") s(N firm year exit r2 , labels("N" "Plant FE" "Year FE" "No exit" "Adjusted R-squared" )) label
		
	}
}

******************************************************************
******************************************************************
eststo clear

foreach var in mpga_aw num_qs_aw {
	
	foreach dep in log_OUTPUT log_labprod log_vad log_netInv{		
		
		local treat `var'
		foreach i of num 1/5 {
			local treat `treat' `var'_lag`i'
			di("`treat'")
		}
		
		*0-5 lags
		eststo m5_`dep': quietly: reghdfe `dep' `treat', absorb(plant year) vce(cluster plant region#year)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace

	}

	*export results 
	esttab m5_log_OUTPUT m5_log_labprod m5_log_vad m5_log_netInv using ./output/regressions_tex/Indonesia_wb/table_meth_`var'.tex, se noconstant title("?") replace booktabs compress keep(`treat') addnotes("Plant and year fixed effects are included in each specification." "Errors are clustered on both plant-level and region-by-year level. ") s(N firm year r2 , labels("N" "Plant FE" "Year FE" "Adjusted R-squared" )) label
		
}


foreach var in mpga_aw num_qs_aw {
	
	foreach dep in log_out log_labprod log_vad log_netInv{		
		
		local treat `var'
		foreach i of num 1/5 {
			local treat `treat' `var'_lag`i'
			di("`treat'")
		}
		
		*0-5 lags
		eststo m5_`dep': quietly: reghdfe `dep' `treat', absorb(plant year) vce(cluster plant region#year)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace

	}

	*export results 
	esttab m5_log_out m5_log_labprod m5_log_vad m5_log_netInv using ./output/regressions_tex/Indonesia_wb/table_meth_`var'_v2.tex, se noconstant title("?") replace booktabs compress keep(`treat') addnotes("Plant and year fixed effects are included in each specification." "Errors are clustered on both plant-level and region-by-year level. ") s(N firm year r2 , labels("N" "Plant FE" "Year FE" "Adjusted R-squared" )) label
		
}

foreach var in mpga_aw num_qs_aw{
	
	foreach dep in lnrouts lnrvads labprodR0 lnrInv{		
		
		local treat `var'
		foreach i of num 1/5 {
			local treat `treat' `var'_lag`i'
			di("`treat'")
		}
		
		*0-5 lags
		eststo m5_`dep': quietly: reghdfe `dep' `treat', absorb(plant year) vce(cluster plant region#year)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace

	}

	*export results 
	esttab m5_lnrouts m5_lnrvads m5_lnrInv using ./output/regressions_tex/Indonesia_wb/table_meth_`var'_v3.tex, se noconstant title("?") replace booktabs compress keep(`treat') addnotes("Plant and year fixed effects are included in each specification." "Errors are clustered on both plant-level and region-by-year level. ") s(N firm year r2 , labels("N" "Plant FE" "Year FE" "Adjusted R-squared" )) label
		
}

foreach var in mpga_aw num_qs_aw{
	
	foreach dep in log_rout log_rvad log_rnetInv log_rlabprod  log_rmat {		
		
		local treat `var'
		foreach i of num 1/5 {
			local treat `treat' `var'_lag`i'
			di("`treat'")
		}
		
		*0-5 lags
		eststo m5_`dep': quietly: reghdfe `dep' `treat', absorb(plant year) vce(cluster plant region#year)
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace

	}

	*export results 
	esttab m5_log_rout m5_log_rvad m5_log_rnetInv m5_log_rlabprod  m5_log_rmat using ./output/regressions_tex/Indonesia_wb/table_meth_`var'_v4.tex, se noconstant title("?") replace booktabs compress keep(`treat') addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level. ") s(N firm year r2 , labels("N" "Plant FE" "Year FE" "Adjusted R-squared" )) label
		
}



