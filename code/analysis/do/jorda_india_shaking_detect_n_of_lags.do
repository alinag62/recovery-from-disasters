/***************************************************************
Stata code to detect N of lags to use in jorda regression
for shaking in India
***************************************************************/

cd /Users/alinagafanova/Library/CloudStorage/Box-Box/recovery-from-disasters

* Housekeeping
clear
clear matrix
set more off

*#############################################################################*/
*Part I. Creating lags in shaking data
*#############################################################################
use "./data/earthquakes/intermediate/India_adm2/region_panel/panel_earthquakes_thresh_10.dta"

*after 2008 - only 2 regions exist have spatial IDs
drop if year>=2008

*rename since the names are too long
rename populatedmpga_aw pop_mpga_aw
rename populatednum_qs_aw pop_num_aw
label var pop_mpga_aw "Max PGA"
label var pop_num_aw "N of EQs"

*add lags
sort ID_2 year
foreach i of num 1/10 {
	foreach var in pop_mpga_aw  pop_num_aw {
		by ID_2: gen `var'_lag`i' = `var'[_n-`i']
		label var `var'_lag`i' "Lag `i'"
	}
}

*before 1989 - firms only stay 1-2 years; no firms that start before 1989
*exist in data in or after 1989
drop if year<=1988

keep year ID_2 pop_mpga_aw* pop_num_aw* 
rename ID_2 region

*#############################################################################*/
*Part II. Testing for autocorrelation: 10 lags
*#############################################################################

preserve
eststo clear
local treat
local out 
foreach i of num 1/10 {
	local treat `treat' pop_mpga_aw_lag`i'
	quietly: eststo d`i': areg pop_mpga_aw `treat', absorb(region) vce(robust)
	local out `out' d`i'
	
}
esttab `out', se label s(N, labels("N") fmt(%9.0f)) replace nocon b(3) mtitles("MPGA" "" "" "" "" "" "" "" "" "")
*esttab `out' using ./output/regressions_tex/India/autocorr_shaking_1989_2007_mpga.tex, se label s(N, labels("N") fmt(%9.0f)) replace nocon b(3) mtitles("MPGA" "" "" "" "" "" "" "" "" "")

restore


preserve
eststo clear
local treat
local out 
foreach i of num 1/10 {
	local treat `treat' pop_num_aw_lag`i'
	quietly: eststo d`i': areg pop_num_aw `treat', absorb(region) vce(robust)
	local out `out' d`i'
	
}
esttab `out', se label s(N, labels("N") fmt(%9.0f)) replace nocon b(3) mtitles("N of EQs" "" "" "" "" "" "" "" "" "")
*esttab `out' using ./output/regressions_tex/India/autocorr_shaking_1989_2007_num.tex, se label s(N, labels("N") fmt(%9.0f)) replace nocon b(3) mtitles("N of EQs" "" "" "" "" "" "" "" "" "")
restore

*############################################################################# */








