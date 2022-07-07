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
	gen log_`dep' = log10(`dep')
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

*add size dummies based on 1996 (labor OR output)
preserve
keep if year == 1996
xtile size_output = rout, nq(4)
label var size_output "Size Quantile"
xtile size_labor = lbr, nq(4)
label var size_labor "Size Quantile"

keep plant size_labor  size_output

tempfile sizes
save "`sizes'"

restore

merge m:1 plant using "`sizes'"

*keep only plants with defined sizes and only after 1995
keep if _m==3
drop if year<1996


* regressions witgh interactions on sizes: mpga and real output
quietly: eststo mpga_rout1: reghdfe log_rout mpga_aw mpga_aw_lag1 mpga_aw_lag2 mpga_aw_lag3 mpga_aw_lag4 mpga_aw_lag5, absorb(plant year) vce(cluster plant region#year)
quietly: estadd local firm "Yes" , replace
quietly: estadd local year "Yes" , replace
quietly: estadd local after98 "No" , replace

quietly: eststo mpga_rout2: reghdfe log_rout c.mpga_aw#i.size_labor c.mpga_aw_lag1#i.size_labor c.mpga_aw_lag2#i.size_labor c.mpga_aw_lag3#i.size_labor c.mpga_aw_lag4#i.size_labor c.mpga_aw_lag5#i.size_labor, absorb(i.plant#i.size_labor i.year#i.size_labor) vce(cluster plant region#year)
quietly: estadd local firm "Yes" , replace
quietly: estadd local year "Yes" , replace
quietly: estadd local after98 "No" , replace

quietly: eststo mpga_rout3: reghdfe log_rout mpga_aw mpga_aw_lag1 mpga_aw_lag2 mpga_aw_lag3 mpga_aw_lag4 mpga_aw_lag5 if year>1997, absorb(plant year) vce(cluster plant region#year)
quietly: estadd local firm "Yes" , replace
quietly: estadd local year "Yes" , replace
quietly: estadd local after98 "Yes" , replace

quietly: eststo mpga_rout4: reghdfe log_rout c.mpga_aw#i.size_labor c.mpga_aw_lag1#i.size_labor c.mpga_aw_lag2#i.size_labor c.mpga_aw_lag3#i.size_labor c.mpga_aw_lag4#i.size_labor c.mpga_aw_lag5#i.size_labor if year>1997, absorb(i.plant#i.size_labor i.year#i.size_labor) vce(cluster plant region#year)
quietly: estadd local firm "Yes" , replace
quietly: estadd local year "Yes" , replace
quietly: estadd local after98 "Yes" , replace


esttab mpga_rout1 mpga_rout2 mpga_rout3 mpga_rout4 using ./output/regressions_tex/Indonesia_wb/mpga_rout_table.tex, se noconstant title("?") replace longtable booktabs compress addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level." "Firms' sizes are defined by labor quartile in 1996. All observations before 1996 are dropped.'") s(N firm year after98 r2 , labels("N" "Plant FE" "Year FE" "\geq 1998" "Adjusted R-squared" )) label


* regressions witgh interactions on sizes: num of EQs and real output
eststo clear

quietly: eststo num_rout1: reghdfe log_rout num_qs_aw num_qs_aw_lag1 num_qs_aw_lag2 num_qs_aw_lag3 num_qs_aw_lag4 num_qs_aw_lag5, absorb(plant year) vce(cluster plant region#year)

quietly: estadd local firm "Yes" , replace
quietly: estadd local year "Yes" , replace
quietly: estadd local after98 "No" , replace

quietly: eststo num_rout2: reghdfe log_rout c.num_qs_aw#i.size_labor c.num_qs_aw_lag1#i.size_labor c.num_qs_aw_lag2#i.size_labor c.num_qs_aw_lag3#i.size_labor c.num_qs_aw_lag4#i.size_labor c.num_qs_aw_lag5#i.size_labor, absorb(i.plant#i.size_labor i.year#i.size_labor) vce(cluster plant region#year)
quietly: estadd local firm "Yes" , replace
quietly: estadd local year "Yes" , replace
quietly: estadd local after98 "No" , replace

quietly: eststo num_rout3: reghdfe log_rout num_qs_aw num_qs_aw_lag1 num_qs_aw_lag2 num_qs_aw_lag3 num_qs_aw_lag4 num_qs_aw_lag5 if year>1997, absorb(plant year) vce(cluster plant region#year)
quietly: estadd local firm "Yes" , replace
quietly: estadd local year "Yes" , replace
quietly: estadd local after98 "Yes" , replace

quietly: eststo num_rout4: reghdfe log_rout c.num_qs_aw#i.size_labor c.num_qs_aw_lag1#i.size_labor c.num_qs_aw_lag2#i.size_labor c.num_qs_aw_lag3#i.size_labor c.num_qs_aw_lag4#i.size_labor c.num_qs_aw_lag5#i.size_labor if year>1997, absorb(i.plant#i.size_labor i.year#i.size_labor) vce(cluster plant region#year)
quietly: estadd local firm "Yes" , replace
quietly: estadd local year "Yes" , replace
quietly: estadd local after98 "Yes" , replace


esttab num_rout1 num_rout2 num_rout3 num_rout4 using ./output/regressions_tex/Indonesia_wb/num_qs_rout_table.tex, se noconstant title("?") replace longtable booktabs compress addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level." "Firms' sizes are defined by labor quartile in 1996. All observations before 1996 are dropped.'") s(N firm year after98 r2 , labels("N" "Plant FE" "Year FE" "\geq 1998" "Adjusted R-squared" )) label



eststo clear
* regressions witgh interactions on sizes: mpga and real VA
quietly: eststo mpga_rvad1: reghdfe log_rvad mpga_aw mpga_aw_lag1 mpga_aw_lag2 mpga_aw_lag3 mpga_aw_lag4 mpga_aw_lag5, absorb(plant year) vce(cluster plant region#year)

quietly: estadd local firm "Yes" , replace
quietly: estadd local year "Yes" , replace
quietly: estadd local after98 "No" , replace

quietly: eststo mpga_rvad2: reghdfe log_rvad c.mpga_aw#i.size_labor c.mpga_aw_lag1#i.size_labor c.mpga_aw_lag2#i.size_labor c.mpga_aw_lag3#i.size_labor c.mpga_aw_lag4#i.size_labor c.mpga_aw_lag5#i.size_labor, absorb(i.plant#i.size_labor i.year#i.size_labor) vce(cluster plant region#year)
quietly: estadd local firm "Yes" , replace
quietly: estadd local year "Yes" , replace
quietly: estadd local after98 "No" , replace

quietly: eststo mpga_rvad3: reghdfe log_rvad mpga_aw mpga_aw_lag1 mpga_aw_lag2 mpga_aw_lag3 mpga_aw_lag4 mpga_aw_lag5 if year>1997, absorb(plant year) vce(cluster plant region#year)
quietly: estadd local firm "Yes" , replace
quietly: estadd local year "Yes" , replace
quietly: estadd local after98 "Yes" , replace

quietly: eststo mpga_rvad4: reghdfe log_rvad c.mpga_aw#i.size_labor c.mpga_aw_lag1#i.size_labor c.mpga_aw_lag2#i.size_labor c.mpga_aw_lag3#i.size_labor c.mpga_aw_lag4#i.size_labor c.mpga_aw_lag5#i.size_labor if year>1997, absorb(i.plant#i.size_labor i.year#i.size_labor) vce(cluster plant region#year)
quietly: estadd local firm "Yes" , replace
quietly: estadd local year "Yes" , replace
quietly: estadd local after98 "Yes" , replace


esttab mpga_rvad1 mpga_rvad2 mpga_rvad3 mpga_rvad4 using ./output/regressions_tex/Indonesia_wb/mpga_rvad_table.tex, se noconstant title("?") replace longtable booktabs compress addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level." "Firms' sizes are defined by labor quartile in 1996. All observations before 1996 are dropped.'") s(N firm year after98 r2 , labels("N" "Plant FE" "Year FE" "\geq 1998" "Adjusted R-squared" )) label


* regressions witgh interactions on sizes: num of EQs and real VA
eststo clear

quietly: eststo num_rvad1: reghdfe log_rvad num_qs_aw num_qs_aw_lag1 num_qs_aw_lag2 num_qs_aw_lag3 num_qs_aw_lag4 num_qs_aw_lag5, absorb(plant year) vce(cluster plant region#year)

quietly: estadd local firm "Yes" , replace
quietly: estadd local year "Yes" , replace
quietly: estadd local after98 "No" , replace

quietly: eststo num_rvad2: reghdfe log_rvad c.num_qs_aw#i.size_labor c.num_qs_aw_lag1#i.size_labor c.num_qs_aw_lag2#i.size_labor c.num_qs_aw_lag3#i.size_labor c.num_qs_aw_lag4#i.size_labor c.num_qs_aw_lag5#i.size_labor, absorb(i.plant#i.size_labor i.year#i.size_labor) vce(cluster plant region#year)
quietly: estadd local firm "Yes" , replace
quietly: estadd local year "Yes" , replace
quietly: estadd local after98 "No" , replace

quietly: eststo num_rvad3: reghdfe log_rvad num_qs_aw num_qs_aw_lag1 num_qs_aw_lag2 num_qs_aw_lag3 num_qs_aw_lag4 num_qs_aw_lag5 if year>1997, absorb(plant year) vce(cluster plant region#year)
quietly: estadd local firm "Yes" , replace
quietly: estadd local year "Yes" , replace
quietly: estadd local after98 "Yes" , replace

quietly: eststo num_rvad4: reghdfe log_rvad c.num_qs_aw#i.size_labor c.num_qs_aw_lag1#i.size_labor c.num_qs_aw_lag2#i.size_labor c.num_qs_aw_lag3#i.size_labor c.num_qs_aw_lag4#i.size_labor c.num_qs_aw_lag5#i.size_labor if year>1997, absorb(i.plant#i.size_labor i.year#i.size_labor) vce(cluster plant region#year)
quietly: estadd local firm "Yes" , replace
quietly: estadd local year "Yes" , replace
quietly: estadd local after98 "Yes" , replace

esttab num_rvad1 num_rvad2 num_rvad3 num_rvad4 using ./output/regressions_tex/Indonesia_wb/num_qs_rvad_table.tex, se noconstant title("?") replace longtable booktabs compress addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level." "Firms' sizes are defined by labor quartile in 1996. All observations before 1996 are dropped.'") s(N firm year after98 r2 , labels("N" "Plant FE" "Year FE" "\geq 1998" "Adjusted R-squared" )) label













