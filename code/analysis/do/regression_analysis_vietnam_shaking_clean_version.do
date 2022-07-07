cd /Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters
cd /Users/alinagafanova/Library/CloudStorage/Box-Box/recovery-from-disasters

* Housekeeping
clear
clear matrix
set more off

use "data/earthquakes/intermediate/Vietnam_adm2/region_panel/panel_earthquakes_thresh_10.dta",clear
rename region ID_2 

*#############################################################################
*Generate lags and leads

*merge with a map
merge m:1 ID_2 using "./data/firm-data/Vietnam/gadm36_VNM_shp/VNM_adm2.dta"
drop _m

keep year ID_2 populatedmpga_aw populatednum_qs_aw _ID

rename populatedmpga_aw pop_mpga_aw
rename populatednum_qs_aw pop_num_aw
label var pop_mpga_aw "Max PGA"
label var pop_num_aw "N of EQs"


sort ID_2 year
foreach i of num 1/10 {
	by ID_2: gen pop_mpga_aw_lag`i' = pop_mpga_aw[_n-`i']
	by ID_2: gen pop_num_aw_lag`i' = pop_num_aw[_n-`i']
	
	label var pop_mpga_aw_lag`i' "Lag `i'"
	label var pop_num_aw_lag`i' "Lag `i'"
}

*#############################################################################

*Testing for autocorrelation

preserve
eststo clear
local treat
local out 
keep if year>=2007
foreach i of num 1/10 {
	local treat `treat' pop_mpga_aw_lag`i'
	quietly: eststo d`i': areg pop_mpga_aw `treat', absorb(ID_2) 
	local out `out' d`i'
	
}
esttab `out' using ./output/regressions_tex/Vietnam/autocorr_2007_2013_simult_shaking.tex, se label s(N, labels("N") fmt(%9.0f)) replace nocon b(3) mtitles("MPGA" "" "" "" "" "" "" "" "" "")
restore

*############################################################################# *

merge 1:m year ID_2 using "./data/firm-data/Vietnam/Vietnam_worldbank_data/firms_VNM_clean.dta"
keep if _m==3
drop _m

*clean firm data
label var rK "Real Capital"
label var LPV "Labor Productivity (Real VA / Labor)"
rename id plant
drop region
rename ID_2 region
gen rtot_wage = rwage*L
label var rtot_wage "Real Total Wage"
gen sales2labor = rS/L
label var sales2labor "Real Sales per Worker"
*****************

*create logged vars
foreach dep in rS rM rV rLC rK LPV rwage L rtot_wage sales2labor{
	gen log_`dep' = log10(`dep')*100
	local label_dep: var label `dep'
	label var log_`dep'`"Logged `label_dep' times 100"' 
}

*dummies if variables exist
foreach dep in rS rM rV rLC rK LPV rwage L rtot_wage sales2labor{
	gen `dep'_exists = 1 if `dep'!=.
	replace `dep'_exists = 0 if `dep'_exists==.
	
	gen log_`dep'_exists = 1 if log_`dep'!=.
	replace log_`dep'_exists = 0 if log_`dep'_exists==.
}

******************************************************************************************************

*change variable labels for better titles
label var log_rS "100Log(Sales)" 
label var log_rLC "100Log(L Cost)"
label var log_rK "100Log(K)"
label var log_rwage "100Log(Avg Wage)"
label var log_L "100Log(L)"
label var log_rtot_wage "100Log(Tot Wage)"
label var log_LPV  "100Log(VA/L)"
label var log_rV "100Log(VA)"
label var log_rM "100Log(Mat)"

******************************************************************************************************

