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

*add size dummies (year t-1; only firms affected once in the survey)
preserve

sort plant year
bys plant: gen n = _n
bys plant: gen N = _N

gen EQ_lag1 = 0
replace EQ_lag1 = 1 if num_qs_aw_lag1!=0&num_qs_aw_lag1!=.
bys plant: egen EQ_lag1_total = total(EQ_lag1)

gen EQ_lead1 = 0
replace EQ_lead1 = 1 if num_qs_aw_lead1!=0&num_qs_aw_lead1!=.
bys plant: egen EQ_lead1_total = total(EQ_lead1)

drop if EQ_lag1_total>1|EQ_lead1_total!=1
keep if EQ_lead1==1|EQ_lag1==1

gen output_before_shock = OUTPUT if  EQ_lead1==1
xtile size_rout = output_before_shock, nq(4)
label var size_rout "Size Quantile"
sort plant year
bys plant: replace size_rout = size_rout[_n-1] if size_rout==.

gen lbr_before_shock = lbr if  EQ_lead1==1
xtile size_lbr = lbr_before_shock, nq(4)
label var size_lbr "Size Quantile"
sort plant year
bys plant: replace size_lbr = size_lbr[_n-1] if size_lbr==.

keep if EQ_lead1==1
keep plant size_rout size_lbr
tempfile sizes
save "`sizes'"
restore
merge m:1 plant using "`sizes'"
drop _m 

/***********************************
preserve

drop if rlabprod==.

sort plant year
bys plant: gen n = _n
bys plant: gen N = _N

*drop firms with weird gaps
bys plant: egen year_min = min(year)
bys plant: egen year_max = max(year)
gen th = year_max-year_min+1
drop if th!=N

*keep only firms hit by EQ once in the period of existence
gen EQ = 1 if num_qs_aw > 0
bys plant: egen tot_EQ = total(EQ)
keep if tot_EQ==1
drop tot_EQ

*drop firms that experienced EQ 5 years or later before the EQ started (otherwise they are treated twice)
gen double_treated = 1 if (EQ == 1)&(num_qs_aw_lag1!=0|num_qs_aw_lag2!=0|num_qs_aw_lag3!=0|num_qs_aw_lag4!=0|num_qs_aw_lag5!=0)
bys plant: gen double_treated_firm = sum(double_treated )
drop if double_treated_firm!=0

gen EQ_lag1 = 0
replace EQ_lag1 = 1 if num_qs_aw_lag1!=0&num_qs_aw_lag1!=.
bys plant: egen EQ_lag1_total = total(EQ_lag1)

gen EQ_lead1 = 0
replace EQ_lead1 = 1 if num_qs_aw_lead1!=0&num_qs_aw_lead1!=.
bys plant: egen EQ_lead1_total = total(EQ_lead1)

keep if EQ_lag1==1|EQ_lead1==1

sort plant year
*only keep if the pair lead-lag exists (for 1 before and 1 after)
drop if EQ_lag1==1&n<3
drop if EQ_lead1==1&n==N
drop if EQ_lead1==1&n==N-1

bys plant: gen obs = _N
drop if obs==1
bys plant: gen next_year = year[_n+1]
bys plant: gen last_year = year[_n-1]
gen next_year_theory = year + 2 if EQ_lead1 == 1 
gen last_year_theory = year - 2 if EQ_lag1 == 1 
keep if (next_year==next_year_theory&EQ_lead1 == 1)|EQ_lag1==1
keep if (last_year==last_year_theory&EQ_lag1==1)|EQ_lead1 == 1

gen output_before_shock = OUTPUT if  EQ_lead1==1
xtile q_out = output_before_shock, nq(4)
sort plant year
bys plant: replace q_out = q_out[_n-1] if q_out==.
keep if  EQ_lead1==1
keep plant q_out

tempfile sizes
save "`sizes'"
restore
merge m:1 plant using "`sizes'"
drop _m */

***********************************

replace size_rout = 0 if size_rout==.
replace size_lbr = 0 if size_lbr==.

*dummy for exited firms(
bys plant: egen max_year = max(year)

reghdfe log_rout c.num_qs_aw##i.size_rout c.num_qs_aw_lag1##i.size_rout c.num_qs_aw_lag2##i.size_rout c.num_qs_aw_lag3##i.size_rout c.num_qs_aw_lag4##i.size_rout c.num_qs_aw_lag5##i.size_rout, absorb(plant year) vce(cluster plant region#year)
reghdfe log_diff_rout c.num_qs_aw##i.size_rout c.num_qs_aw_lag1##i.size_rout c.num_qs_aw_lag2##i.size_rout c.num_qs_aw_lag3##i.size_rout c.num_qs_aw_lag4##i.size_rout c.num_qs_aw_lag5##i.size_rout, absorb(plant year) vce(cluster plant region#year)


/* export 1
quietly: eststo log_rout: reghdfe log_rout c.num_qs_aw#i.size_lbr c.num_qs_aw_lag1#i.size_lbr c.num_qs_aw_lag2#i.size_lbr c.num_qs_aw_lag3#i.size_lbr c.num_qs_aw_lag4#i.size_lbr c.num_qs_aw_lag5#i.size_lbr, absorb(plant year) vce(cluster plant region#year)
quietly: estadd local firm "Yes" , replace
quietly: estadd local year "Yes" , replace
quietly: eststo log_diff_rout: reghdfe log_diff_rout c.num_qs_aw#i.size_lbr c.num_qs_aw_lag1#i.size_lbr c.num_qs_aw_lag2#i.size_lbr c.num_qs_aw_lag3#i.size_lbr c.num_qs_aw_lag4#i.size_lbr c.num_qs_aw_lag5#i.size_lbr, absorb(plant year) vce(cluster plant region#year)
quietly: estadd local firm "Yes" , replace
quietly: estadd local year "Yes" , replace

esttab log_rout log_diff_rout using ./output/regressions_tex/Indonesia_wb/table_lbr_size_inter.tex, se noconstant title("?") replace longtable booktabs compress addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level." "Firms' size are defined by labor quartile before EQ, 0 means there was no or more than 1 EQ.'") s(N firm year r2 , labels("N" "Plant FE" "Year FE" "Adjusted R-squared" )) label */
	


* export 1
quietly: eststo log_rout: reghdfe log_rout c.num_qs_aw#i.size_lbr c.num_qs_aw_lag1#i.size_lbr c.num_qs_aw_lag2#i.size_lbr, absorb(plant year) vce(cluster plant region#year)
quietly: estadd local firm "Yes" , replace
quietly: estadd local year "Yes" , replace
quietly: eststo log_diff_rout: reghdfe log_diff_rout c.num_qs_aw#i.size_lbr c.num_qs_aw_lag1#i.size_lbr c.num_qs_aw_lag2#i.size_lbr, absorb(plant year) vce(cluster plant region#year)
quietly: estadd local firm "Yes" , replace
quietly: estadd local year "Yes" , replace

esttab log_rout log_diff_rout using ./output/regressions_tex/Indonesia_wb/table_lbr_size_inter.tex, se noconstant title("?") replace longtable booktabs compress addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level." "Firms' size are defined by labor quartile before EQ, 0 means there was no or more than 1 EQ.'") s(N firm year r2 , labels("N" "Plant FE" "Year FE" "Adjusted R-squared" )) label
	



* export 2
quietly: eststo log_rvad: reghdfe log_rvad c.num_qs_aw#i.size_rout c.num_qs_aw_lag1#i.size_rout c.num_qs_aw_lag2#i.size_rout, absorb(plant year) vce(cluster plant region#year)
quietly: estadd local firm "Yes" , replace
quietly: estadd local year "Yes" , replace
quietly: eststo log_diff_rvad: reghdfe log_diff_rvad c.num_qs_aw#i.size_rout c.num_qs_aw_lag1#i.size_rout c.num_qs_aw_lag2#i.size_rout, absorb(plant year) vce(cluster plant region#year)
quietly: estadd local firm "Yes" , replace
quietly: estadd local year "Yes" , replace

esttab log_rvad log_diff_rvad using ./output/regressions_tex/Indonesia_wb/table_out_size_inter.tex, se noconstant title("?") replace longtable booktabs compress addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level." "Firms' size are defined by output quartile before EQ, 0 means there was no or more than 1 EQ.'") s(N firm year r2 , labels("N" "Plant FE" "Year FE" "Adjusted R-squared" )) label
	






