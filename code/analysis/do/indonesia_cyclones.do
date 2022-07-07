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
graph set window fontface "Helvetica Light"

*#############################################################################
*0. Clean
*#############################################################################

merge m:1 i_harmonize_to_1988 using "./data/shapefiles/regions_codes/crosswalk_1988_2015_to_shp.dta"
keep if _m==3
drop _m
rename ADM2_id_in_shp_88 ADM2_id_in
tostring ADM2_id_in, replace

*shp2dta using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2.shp", data("./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2.dta")  coor("./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2_coordinates.dta") replace
merge m:1 ADM2_id_in using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2.dta"
keep if _m==3
drop _m
rename i_harmonize_to_1988 region

rename PSID plant

tempfile survey
save "`survey'"

*#############################################################################
*Part I. Analysing the survey
*#############################################################################


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

*create lags
sort region year
foreach i of num 1/10 {
	by region: gen mpga_aw_lag`i' = mpga_aw[_n-`i']
	by region: gen num_qs_aw_lag`i' = num_qs_aw[_n-`i']
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

*use real values
drop OUTPUT
rename rout OUTPUT
drop kap
rename rkap kap
drop labprod
rename labprodR0 labprod
gen rvad_to_lbr = rvad/lbr
label var rvad_to_lbr `"Real Productivity (VA/Labor)"'

*create difference vars
sort plant year
bys plant: gen lbr_diff = lbr[_n]-lbr[_n-1]
bys plant: gen kap_diff = kap[_n]-kap[_n-1]

*create logged vars
foreach dep in OUTPUT lbr kap labprod out rvad_to_lbr {
	gen log_`dep' = log10(`dep')
	local label_dep: var label `dep'
	label var log_`dep'`"Logged `label_dep'"' 
}

*#############################################################################
*Part III. 1 year before and after major cyclone
*#############################################################################

*Vamei: 2001
gen affected_by_vamei = 0
replace affected_by_vamei = 1 if ID_2==45| ID_2== 137 |ID_2== 154 |ID_2== 46|ID_2== 197 |ID_2== 215

* Real Labor Productivity 

twoway (hist log_rvad_to_lbr if affected_by_vamei==1&year==2002, color(red%30) freq width(0.3) start(3)) (hist log_rvad_to_lbr if affected_by_vamei==1&year==2000, color(blue%30) freq width(0.3) start(3)),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "1 year after earthquake" 2 "1 year before earthquake" ) position(6)) ytitle("Number of Firms") title("Indonesia: distribution of logged labor before and after earthquake impact (1988-2015)")  xline(`mean_lag', lcolor(red%70) noextend)  xline(`mean_lead', lcolor(blue%70) noextend)

twoway (hist log_rvad_to_lbr if year==2002, color(red%30) freq width(0.3) start(0)) (hist log_rvad_to_lbr if year==2000, color(blue%30) freq width(0.3) start(0)),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "1 year after earthquake" 2 "1 year before earthquake" ) position(6)) ytitle("Number of Firms") title("Indonesia: distribution of logged labor before and after earthquake impact (1988-2015)")  xline(`mean_lag', lcolor(red%70) noextend)  xline(`mean_lead', lcolor(blue%70) noextend)




*Gillian: 2014
preserve
gen affected_by_gill = 0
replace affected_by_gill = 1 if ID_2==179| ID_2== 135 |ID_2== 263 |ID_2== 72|ID_2== 67 |ID_2== 105 |ID_2== 170  |ID_2== 199 |ID_2== 220|ID_2== 14|ID_2== 74

bys plant: egen start = min(year)
drop if start==2015
drop if start ==2014

sum log_rvad_to_lbr if affected_by_gill==1&year==2015
local mean_lag = r(mean)
sum log_rvad_to_lbr if affected_by_gill==1&year==2013
local mean_lead = r(mean)

twoway (hist log_rvad_to_lbr if affected_by_gill==1&year==2015, color(red%30) freq width(0.3) start(2)) (hist log_rvad_to_lbr if affected_by_gill==1&year==2013, color(blue%30) freq width(0.3) start(2)),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "1 year after Gillian (2015)" 2 "1 year before Gillian (2013)" ) position(6)) ytitle("Number of Firms") title("Indonesia: distribution of logged labor productivity before and after Gillian cyclone in 2014")  xline(`mean_lag', lcolor(red%70) noextend)  xline(`mean_lead', lcolor(blue%70) noextend)


restore



























