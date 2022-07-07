/*
###########################################################################
                    Intro
########################################################################### */

cd /Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters

* Housekeeping
clear
clear matrix
set more off

local path2save_shake "./data/earthquakes/intermediate/Indonesia_adm2"

use "./data/firm-data/Indonesia_worldbank/maindata_with_spatial_id_part1.dta",clear

*#############################################################################
set scheme plottig 
grstyle init
grstyle set imesh, horizontal minor
grstyle set ci 538, select(13 10) opacity(60)
grstyle set color "35 35 35" "35 35 35"  "62 102 206"  "62 102 206"
graph set window fontface "Helvetica Light"

*#############################################################################
*Part I. Analysing the survey
*#############################################################################
*Drop 2017 since it contains different PSIDs
drop if year==2017 

*Drop East Timor since it's independent now
drop if prov == "54"

* clean
rename prov province_id
rename DKABUP district_id
rename PSID plant
order plant year

tempfile survey
save "`survey'"

*#############################################################################*/
*Part II. Analysing the shaking data
*#############################################################################

use "`path2save_shake'/region_panel/panel_earthquakes_thresh_10.dta", clear
rename region ID_2
merge m:1  ID_2 using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2.dta"
rename ID_2 region 
drop _m

*create lags
sort region year
foreach i of num 1/10 {
	by region: gen mpga_aw_lag`i' = mpga_aw[_n-`i']
	by region: gen num_qs_aw_lag`i' = num_qs_aw[_n-`i']
}

*number of years when shaking occurs
gen shaking_year = 0
replace shaking_year = 1 if num_qs_aw>0
bys region: egen years_shaking = total(shaking_year)
label var years_shaking "Years with shaking (from 43)"

/*a few maps with sum stats
preserve
bys region: drop if _n>1
rename region ID_2
replace years_shaking=. if years_shaking==0
spmap years_shaking using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2_coordinates.dta",   id(_ID) fcolor(Reds) clnumber(7) legend(label(1 "No shaking") label(2 "1 year with earthquakes") label(3 "2 years with earthquakes") label(4 "3 years with earthquakes") label(5 "4 years with earthquakes") label(6 "5-6 years with earthquakes") label(7 "7-20 years with earthquakes")) title("Years with earthquakes from 43 years (1973-2015)", size(*0.7))
graph export "./output/Indonesia_worldbank/eq/Indonesia_num_qs.png", as(png) replace
restore  

preserve
rename region ID_2
merge m:1  ID_2 using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2.dta"
collapse (mean) mpga_aw, by(ID_2 _ID)
replace mpga_aw=. if mpga_aw==0
format (mpga_aw) %12.2f
spmap mpga_aw using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2_coordinates.dta", id(_ID) fcolor(Reds) legend(title("Mean MPGA", size(*0.9)) label(1 "No shaking" ) size(*2.1) ) title("Mean MPGA for 43 years (1973-2015)", size(*1.3)) 
graph export "./output/Indonesia_worldbank/eq/Indonesia_mpga.png", as(png) replace
restore  */


/* maps of exposure by year, animation
preserve
rename region ID_2
replace mpga_aw=. if mpga_aw==0
forval year = 1980/2015 {
	spmap mpga_aw if year==`year' using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2_coordinates.dta", id(_ID) clm(c) clb(0 0.1 0.5 1 2 10 41) fcolor(Reds) legend(label(1 "No shaking")) title(`year', size(*0.8))
	graph export "./output/Indonesia_worldbank/eq/gif_mpga_aw_`year'.png", as(png) width(3000) replace
}
restore

preserve
rename region ID_2
replace num_qs_aw=. if num_qs_aw==0
forval year = 1980/2015 {
	spmap num_qs_aw if year==`year' using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2_coordinates.dta", id(_ID) clm(c) clb(0 0.1 0.2 0.5 0.75 1 2) fcolor(Reds) legend(label(1 "No shaking")) title(`year', size(*0.8))
	graph export "./output/Indonesia_worldbank/eq/gif_num_qs_aw_`year'.png", as(png) width(3000) replace
}
restore */

tempfile shaking
save "`shaking'"  

*#############################################################################
*Part III. Analysing survey+shaking
*#############################################################################

*merge survey and EQs
use "`survey'"
rename id_used region
bys region year: gen firms_that_year_in_region = _N
merge m:1 region year using "`shaking'"
keep if _m==3
order plant year region 

*create logged vars
foreach dep in OUTPUT routR0 lbr kap kapR labprod {
	gen log_`dep' = log(`dep')
	local label_dep: var label `dep'
	label var log_`dep'`"Logged `label_dep'"' 
}


********************************************************************************
/*count firms in each year, annually
preserve
*generic unit
gen i = 1

*count firms
collapse (sum) i, by(region year _ID)

*merge to have all regions, not only with firms
merge m:1  _ID using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2.dta"
keep year i _ID
fillin year _ID
drop if year==.
replace i = 0 if i ==.
drop _f

*create a map for each year
forval year = 1988/2015 {
	
	* CREATE AN ALIGNED FORMAT FOR ALL MAPS!
	spmap i if year==i using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2_coordinates.dta", id(_ID) fcolor(Oranges) 
	
}
restore */
********************************************************************************

********************************************************************************
/*count unique plants' IDs for all the period
preserve

*leave 1 observation per firm
duplicates drop plant, force

*generic unit
gen i = 1

*count firms
collapse (sum) i, by(_ID)

*merge to have all regions, not only with firms
merge m:1  _ID using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2.dta"
keep i _ID
replace i = 0 if i ==.

* CREATE AN ALIGNED FORMAT FOR ALL MAPS!
spmap i using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2_coordinates.dta", id(_ID) fcolor(Oranges) 

restore */

********************************************************************************


********************************************************************************

********************************************************************************



********************************************************************************
/*histograms: 1 year before vs 1 year after 

*subset plants ever affected by EQs in panel
gen EQ_lag1 = 0
replace EQ_lag1 = 1 if num_qs_aw_lag1!=0&num_qs_aw_lag1!=.
bys plant: egen EQ_lag1_total = total(EQ_lag1)

preserve
drop if  EQ_lag1_total==0

* LABOR: LOGGED
label var log_lbr `"Logged Total Number of Workers"' 

sum log_lbr if EQ_lag1 == 0
local mean_no_EQ = r(mean)
sum log_lbr if EQ_lag1 == 1
local mean_after_EQ = r(mean)

twoway (hist log_lbr  if num_qs_aw_lag1>0, color(red%30) width(0.18) ) (hist log_lbr if num_qs_aw_lag1==0, color(blue%30) width(0.18)  ) ,  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "Firms in districts affected by EQ in year t-1" 2 "Firms not affected by EQ in year t-1" ) position(6)) title("Indonesia: distribution of logged labor by earthquake (EQ) impact (1988-2015)") xline(`mean_after_EQ', lcolor(red%70) noextend)  xline(`mean_no_EQ', lcolor(blue%70) noextend) 
graph export "./output/Indonesia_worldbank/plots/fig_IDN_labor_distr.png", as(png) replace

* OUTPUT: LOGGED
sum log_OUTPUT if EQ_lag1 == 0
local mean_no_EQ = r(mean)
sum log_OUTPUT if EQ_lag1 == 1
local mean_after_EQ = r(mean)

twoway (hist log_OUTPUT  if num_qs_aw_lag1>0, color(red%30) width(0.18) ) (hist log_OUTPUT if num_qs_aw_lag1==0, color(blue%30) width(0.18)  ) ,  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "Firms in districts affected by EQ in year t-1" 2 "Firms not affected by EQ in year t-1" ) position(6)) title("Indonesia: distribution of logged output by earthquake (EQ) impact (1988-2015)") xline(`mean_after_EQ', lcolor(red%70) noextend)  xline(`mean_no_EQ', lcolor(blue%70) noextend) 
graph export "./output/Indonesia_worldbank/plots/fig_IDN_output_distr.png", as(png) replace

* REAL OUTPUT: LOGGED
sum log_routR0 if EQ_lag1 == 0
local mean_no_EQ = r(mean)
sum log_routR0 if EQ_lag1 == 1
local mean_after_EQ = r(mean)

twoway (hist log_routR0  if num_qs_aw_lag1>0, color(red%30) width(0.18) ) (hist log_routR0 if num_qs_aw_lag1==0, color(blue%30) width(0.18)  ) ,  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "Firms in districts affected by EQ in year t-1" 2 "Firms not affected by EQ in year t-1" ) position(6)) title("Indonesia: distribution of logged real output by earthquake (EQ) impact (1988-2015)") xline(`mean_after_EQ', lcolor(red%70) noextend)  xline(`mean_no_EQ', lcolor(blue%70) noextend) 
graph export "./output/Indonesia_worldbank/plots/fig_IDN_output_distr_real.png", as(png) replace

* CAPITAL: LOGGED
sum log_kap if EQ_lag1 == 0
local mean_no_EQ = r(mean)
sum log_kap if EQ_lag1 == 1
local mean_after_EQ = r(mean)

twoway (hist log_kap  if num_qs_aw_lag1>0, color(red%30) width(0.18) ) (hist log_kap if num_qs_aw_lag1==0, color(blue%30) width(0.18)  ) ,  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "Firms in districts affected by EQ in year t-1" 2 "Firms not affected by EQ in year t-1" ) position(6)) title("Indonesia: distribution of logged capital by earthquake (EQ) impact (1988-2015)") xline(`mean_after_EQ', lcolor(red%70) noextend)  xline(`mean_no_EQ', lcolor(blue%70) noextend) 
graph export "./output/Indonesia_worldbank/plots/fig_IDN_capital_distr.png", as(png) replace

* REAL CAPITAL: LOGGED
sum log_kapR if EQ_lag1 == 0
local mean_no_EQ = r(mean)
sum log_kapR if EQ_lag1 == 1
local mean_after_EQ = r(mean)

twoway (hist log_kapR  if num_qs_aw_lag1>0, color(red%30) width(0.18) ) (hist log_kapR if num_qs_aw_lag1==0, color(blue%30) width(0.18)  ) ,  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "Firms in districts affected by EQ in year t-1" 2 "Firms not affected by EQ in year t-1" ) position(6)) title("Indonesia: distribution of logged real capital by earthquake (EQ) impact (1988-2015)") xline(`mean_after_EQ', lcolor(red%70) noextend)  xline(`mean_no_EQ', lcolor(blue%70) noextend) 
graph export "./output/Indonesia_worldbank/plots/fig_IDN_capital_distr_real.png", as(png) replace


* PRODUCTIVITY: LOGGED
sum log_labprod if EQ_lag1 == 0
local mean_no_EQ = r(mean)
sum log_labprod if EQ_lag1 == 1
local mean_after_EQ = r(mean)

twoway (hist log_labprod  if num_qs_aw_lag1>0, color(red%30) width(0.18) ) (hist log_labprod if num_qs_aw_lag1==0, color(blue%30) width(0.18)  ) ,  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "Firms in districts affected by EQ in year t-1" 2 "Firms not affected by EQ in year t-1" ) position(6)) title("Indonesia: distribution of logged labor productivity by earthquake (EQ) impact (1988-2015)") xline(`mean_after_EQ', lcolor(red%70) noextend)  xline(`mean_no_EQ', lcolor(blue%70) noextend) 
graph export "./output/Indonesia_worldbank/plots/fig_IDN_prod_distr.png", as(png) replace


restore*/


********************************************************************************



























