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

********************************************************************************
/* Some maps 

*count firms in each year, annually
preserve
*generic unit
gen i = 1 if plant!=.
replace i = 0 if i==.

*count firms
collapse (sum) i, by(year _ID)

*add ADM2 with no firms
merge m:1 _ID using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2.dta"
drop _m
fillin year _ID
drop if year==.
replace i = 0 if i ==.
drop _f 
replace i=. if i == 0

*create a map for each year
forval year = 1988/2015 {
	spmap i if year==`year' using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2_coordinates.dta", id(_ID) fcolor(Reds) clm(c) clb(1 5 20 60 300 1350)  title("Number of Firms in Indonesia by ADM2, `year'", size(*0.8)) legend(label(1 "No firms") title("Number of Firms",  size(*0.6)) size(*1.3) ) 
	graph export "./output/Indonesia/maps/number_firms_adm2_`year'.png", as(png) width(3000) replace
}

restore  */

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

*add ADM2 with no firms
merge m:1 _ID using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2.dta"
drop _m

*create a map
spmap i using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2_coordinates.dta", id(_ID) clm(c) clb(1 3 15 50 150 400 2300) fcolor(Reds)  title("Number of Unique Firms in Indonesia by ADM2, 1988-2015", size(*0.8)) legend(label(1 "No firms") title("Number of Firms",  size(*0.6)) size(*1.3) )
graph export "./output/Indonesia/maps/number_unique_firms_adm2.png", as(png) width(3000) replace

restore  */

********************************************************************************


********************************************************************************
/*Averages across districts
preserve

gen i = 1

*replace units to mln (rupiah)
gen output_mln = OUTPUT/1000000
gen kap_mln = kap/1000000

*count non-missing values (assume it doesn't mean non-zero')
foreach var in output_mln lbr kap_mln labprod {
	*only use non-negative variables
	replace `var' = . if `var'<0
	gen `var'_count = 1 if `var'!=.
}

*sum over regions
collapse (sum) output_mln lbr kap_mln labprod i (count) output_mln_count lbr_count kap_mln_count labprod_count, by(year _ID)

*find averages
foreach var in output_mln lbr kap_mln labprod {
	gen `var'_avg = `var'/`var'_count
}
drop labprod kap_mln_count labprod_count output_mln_count lbr_count i

*change format for neat legends
format (lbr_avg lbr labprod_avg kap_mln_avg kap_mln output_mln_avg output_mln) %9.0f

*add ADM2 with no firms
merge m:1 _ID using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2.dta"
drop _m
fillin year _ID
drop if year==.

*Plot averages



foreach year in 1988 2000 2015 {
	*total output
	spmap output_mln if year==`year' using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2_coordinates.dta", id(_ID) clnumber(5) fcolor(Oranges) title("Total Output (mln Rp) by ADM2, `year'", size(*1.3)) legend(title("Total Output (mln Rp)",  size(*0.9)) size(*2.1) )  
	graph export "./output/Indonesia/maps/output_totals_`year'.png", as(png) width(3000) replace
	
	*average output 
	spmap output_mln_avg if year==`year' using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2_coordinates.dta", id(_ID) clnumber(5) fcolor(Oranges) title("Average Firm Output (mln Rp) by ADM2, `year'", size(*0.8)) legend(title("Average Firm Output (mln Rp)",  size(*0.6)) size(*1.3) ) 
	graph export "./output/Indonesia/maps/output_avg_`year'.png", as(png) width(3000) replace
	
	*total labor
	spmap lbr if year==`year' using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2_coordinates.dta", id(_ID) clnumber(5) fcolor(Oranges) title("Total Labor by ADM2, `year'", size(*1.3)) legend(title("Total Labor",  size(*0.9)) size(*2.1) )  
	graph export "./output/Indonesia/maps/labor_totals_`year'.png", as(png) width(3000) replace
	
	*average labor
	spmap lbr_avg if year==`year' using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2_coordinates.dta", id(_ID) clnumber(5) fcolor(Oranges) title("Average Labor by ADM2, `year'", size(*0.8)) legend(title("Average Labor",  size(*0.6)) size(*1.3) ) 
	graph export "./output/Indonesia/maps/labor_avg_`year'.png", as(png) width(3000) replace
	
	*total capital
	spmap kap_mln if year==`year' using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2_coordinates.dta", id(_ID) clnumber(5) fcolor(Oranges) title("Total Capital (mln Rp) by ADM2, `year'", size(*0.8)) legend(title("Total Capital (mln Rp)",  size(*0.6)) size(*1.3) )  
	graph export "./output/Indonesia/maps/capital_totals_`year'.png", as(png) width(3000) replace
	
	*average capital 
	spmap output_mln_avg if year==`year' using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2_coordinates.dta", id(_ID) clnumber(5) fcolor(Oranges) title("Average Firm Capital (mln Rp) by ADM2, `year'", size(*0.8)) legend(title("Average Firm Capital (mln Rp)",  size(*0.6)) size(*1.3) ) 
	graph export "./output/Indonesia/maps/capital_avg_`year'.png", as(png) width(3000) replace 
	
	*average productivity
	spmap labprod_avg if year==`year' using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2_coordinates.dta", id(_ID) clnumber(5) fcolor(Oranges) title("Average Labor Productivity by ADM2, `year'", size(*0.8)) legend(title("Average Labor Productivity",  size(*0.6)) size(*1.3) ) 
	graph export "./output/Indonesia/maps/labprod_avg_`year'.png", as(png) width(3000) replace
	
}

restore 
********************************************************************************/



/********************************************************************************
*Plot number of plants by inclusion to dataset

preserve
keep plant year
bys plant: egen inclusion_year = min(year)
gen i = 1

gen incl_years = 1 if (inclusion_year>=1988)&(inclusion_year<=1990)
replace incl_years = 2 if (inclusion_year>=1991)&(inclusion_year<=1995)
replace incl_years = 3 if (inclusion_year>=1996)&(inclusion_year<=2000)
replace incl_years = 4 if (inclusion_year>=2001)&(inclusion_year<=2005)
replace incl_years = 5 if (inclusion_year>=2005)&(inclusion_year<=2010)
replace incl_years = 6 if (inclusion_year>=2011)&(inclusion_year<=2015)

collapse (count) i, by(incl_years year)

sort year incl_years
bys year: gen cum_num = i if _n==1
bys year: replace cum_num = cum_num[_n-1] + i if cum_num==.
bys year: gen low_bound_area_graph = 0 if _n==1
bys year: replace low_bound_area_graph = cum_num[_n-1] if low_bound_area_graph==.


grstyle set color economist
twoway (rarea cum_num low_bound_area_graph year  if incl_years==6) (rarea cum_num low_bound_area_graph year  if incl_years==5) (rarea cum_num low_bound_area_graph year  if incl_years==4) (rarea cum_num low_bound_area_graph year  if incl_years==3) (rarea cum_num low_bound_area_graph year  if incl_years==2) (rarea cum_num low_bound_area_graph year  if incl_years==1), legend(label(6 "1988-90") label(5 "1991-95") label(4 "1996-2000") label(3 "2001-2005") label(2 "2006-2010") label(1 "2011-2015") title(Firms by Year of Inclusion in Survey, size(*0.6))) ytitle("Number of Firms by Year of Inclusion in Survey")
graph export "./output/Indonesia/figs/firms_by_year_of_inclusion.png", as(png) width(3000) replace
grstyle set color "35 35 35" "35 35 35"  "62 102 206"  "62 102 206"

restore


********************************************************************************/



********************************************************************************
/*Plot number of plants by birth

preserve
keep plant year estyear
gen i = 1
drop if estyear==.

gen est_years = 1 if (estyear>=1904)&(estyear<=1987)
replace est_years = 2 if (estyear>=1988)&(estyear<=1990)
replace est_years = 3 if (estyear>=1991)&(estyear<=1995)
replace est_years = 4 if (estyear>=1996)&(estyear<=2000)
replace est_years = 5 if (estyear>=2001)&(estyear<=2005)
replace est_years = 6 if (estyear>=2005)&(estyear<=2010)
replace est_years = 7 if (estyear>=2011)&(estyear<=2015)

collapse (count) i, by(est_years year)

sort year est_years
bys year: gen cum_num = i if _n==1
bys year: replace cum_num = cum_num[_n-1] + i if cum_num==.
bys year: gen low_bound_area_graph = 0 if _n==1
bys year: replace low_bound_area_graph = cum_num[_n-1] if low_bound_area_graph==.


grstyle set color economist
twoway (rarea cum_num low_bound_area_graph year  if est_years==7) (rarea cum_num low_bound_area_graph year  if est_years==6)  (rarea cum_num low_bound_area_graph year  if est_years==5)  (rarea cum_num low_bound_area_graph year  if est_years==4)  (rarea cum_num low_bound_area_graph year  if est_years==3)  (rarea cum_num low_bound_area_graph year  if est_years==2) (rarea cum_num low_bound_area_graph year  if est_years==1), legend(label(7 "1904-87") label(6 "1988-90") label(5 "1991-95") label(4 "1996-2000") label(3 "2001-2005") label(2 "2006-2010") label(1 "2011-2014") title(Firms by Year of Establishment, size(*0.6))) ytitle("Number of Firms by Year of Establishment")
graph export "./output/Indonesia/figs/firms_by_year_of_establishment.png", as(png) width(3000) replace
grstyle set color "35 35 35" "35 35 35"  "62 102 206"  "62 102 206"

restore


********************************************************************************/



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

rename populatednum_qs_aw popnum_qs_aw

*create lags
sort region year
foreach i of num 1/10 {
	by region: gen mpga_aw_lag`i' = mpga_aw[_n-`i']
	by region: gen num_qs_aw_lag`i' = num_qs_aw[_n-`i']
	by region: gen popnum_qs_aw_lag`i' = popnum_qs_aw[_n-`i']
}

*create leads
sort region year
foreach i of num 1/10 {
	by region: gen mpga_aw_lead`i' = mpga_aw[_n+`i']
	by region: gen num_qs_aw_lead`i' = num_qs_aw[_n+`i']
	by region: gen popnum_qs_aw_lead`i' = popnum_qs_aw[_n+`i']
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
gen avg_wage = rwage/lbr
label var avg_wage `"Real Average Wage"'

*create difference vars
sort plant year
bys plant: gen lbr_diff = lbr[_n]-lbr[_n-1]
bys plant: gen kap_diff = kap[_n]-kap[_n-1]

*create logged vars
foreach dep in OUTPUT lbr kap labprod out rvad_to_lbr rvad {
	gen log_`dep' = log10(`dep')
	local label_dep: var label `dep'
	label var log_`dep'`"Logged `label_dep'"' 
}

*create th vars
foreach dep in OUTPUT rvad rmat kap rwage avg_wage{
	gen `dep'_th = `dep'/1000
	local label_dep: var label `dep'
	label var `dep'_th `"`label_dep' (th)"' 
}



********************************************************************************
/*histograms: 1 year before vs 1 year after 

*subset plants ever affected by EQs in panel
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

*drop if EQ_lag1_total==0|EQ_lead1_total==0
drop if EQ_lag1_total!=1|EQ_lead1_total!=1
keep if EQ_lag1==1|EQ_lead1==1

sort plant year
*only keep if the pair lead-lag exists
drop if EQ_lag1==1&n<3
drop if EQ_lead1==1&n==N
drop if EQ_lead1==1&n==N-1

*LABOR: LOGGED

*label var log_lbr `"Logged Total Number of Workers"' 

sum log_lbr if EQ_lag1 == 1
local mean_lag = r(mean)
sum log_lbr if EQ_lead1 == 1
local mean_lead = r(mean)

twoway (hist log_lbr  if EQ_lag1==1, color(red%30) freq start(1.2)) (hist log_lbr if EQ_lead1 == 1, color(blue%30) freq start(1.2)),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "1 year after earthquake" 2 "1 year before earthquake" ) position(6)) ytitle("Number of Firms") title("Indonesia: distribution of logged labor before and after earthquake impact (1988-2015)")  xline(`mean_lag', lcolor(red%70) noextend)  xline(`mean_lead', lcolor(blue%70) noextend)
graph export "./output/Indonesia/figs/labor_distr_before_after.png", as(png) replace

twoway (hist log_lbr  if EQ_lag1==1, color(red%30) freq bin(5)) (hist log_lbr if EQ_lead1 == 1, color(blue%30) freq bin(5)),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "1 year after earthquake" 2 "1 year before earthquake" ) position(6)) ytitle("Number of Firms") title("Indonesia: distribution of logged labor before and after earthquake impact (1988-2015)")  xline(`mean_lag', lcolor(red%70) noextend)  xline(`mean_lead', lcolor(blue%70) noextend)
graph export "./output/Indonesia/figs/labor_distr_quant_before_after.png", as(png) replace

* OUTPUT: LOGGED

sum log_OUTPUT if EQ_lag1 == 1
local mean_lag = r(mean)
sum log_OUTPUT if EQ_lead1 == 1
local mean_lead = r(mean)

twoway (hist log_OUTPUT  if EQ_lag1==1, color(red%30) freq start(3) width(0.2)) (hist log_OUTPUT if EQ_lead1 == 1, color(blue%30) freq start(3) width(0.2)),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "1 year after earthquake" 2 "1 year before earthquake" ) position(6)) ytitle("Number of Firms") title("Indonesia: distribution of logged output before and after earthquake impact (1988-2015)")  xline(`mean_lag', lcolor(red%70) noextend)  xline(`mean_lead', lcolor(blue%70) noextend)
graph export "./output/Indonesia/figs/output_distr_before_after.png", as(png) replace

twoway (hist log_OUTPUT  if EQ_lag1==1, color(red%30) freq start(3) width(1.6)) (hist log_OUTPUT if EQ_lead1 == 1, color(blue%30) freq start(3) width(1.6)),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "1 year after earthquake" 2 "1 year before earthquake" ) position(6)) ytitle("Number of Firms") title("Indonesia: distribution of logged output before and after earthquake impact (1988-2015)")  xline(`mean_lag', lcolor(red%70) noextend)  xline(`mean_lead', lcolor(blue%70) noextend)
graph export "./output/Indonesia/figs/output_distr_quant_before_after.png", as(png) replace

* CAPITAL: LOGGED
sum log_kap if EQ_lag1 == 1
local mean_lag = r(mean)
sum log_kap if EQ_lead1 == 1
local mean_lead = r(mean)

twoway (hist log_kap  if EQ_lag1==1, color(red%30) freq start(0) width(0.2)) (hist log_kap if EQ_lead1 == 1, color(blue%30) freq start(0) width(0.2)),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "1 year after earthquake" 2 "1 year before earthquake" ) position(6)) ytitle("Number of Firms") title("Indonesia: distribution of logged capital before and after earthquake impact (1988-2015)")  xline(`mean_lag', lcolor(red%70) noextend)  xline(`mean_lead', lcolor(blue%70) noextend)
graph export "./output/Indonesia/figs/capital_distr_before_after.png", as(png) replace

twoway (hist log_kap  if EQ_lag1==1, color(red%30) freq start(0) width(3)) (hist log_kap if EQ_lead1 == 1, color(blue%30) freq start(0) width(3)),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "1 year after earthquake" 2 "1 year before earthquake" ) position(6)) ytitle("Number of Firms") title("Indonesia: distribution of logged capital before and after earthquake impact (1988-2015)")  xline(`mean_lag', lcolor(red%70) noextend)  xline(`mean_lead', lcolor(blue%70) noextend)
graph export "./output/Indonesia/figs/capital_distr_quant_before_after.png", as(png) replace
*

* PRODUCTIVITY: LOGGED (VA/wage)
sum log_labprod if EQ_lag1 == 1
local mean_lag = r(mean)
sum log_labprod if EQ_lead1 == 1
local mean_lead = r(mean)

twoway (hist log_labprod  if EQ_lag1==1, color(red%30) freq start(-3) width(0.15)) (hist log_labprod if EQ_lead1 == 1, color(blue%30) freq start(-3) width(0.15)),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "1 year after earthquake" 2 "1 year before earthquake" ) position(6)) ytitle("Number of Firms") title("Indonesia: distribution of logged productivity before and after earthquake impact (1988-2015)")  xline(`mean_lag', lcolor(red%70) noextend)  xline(`mean_lead', lcolor(blue%70) noextend)
graph export "./output/Indonesia/figs/prod_distr_before_after.png", as(png) replace

twoway (hist log_labprod  if EQ_lag1==1, color(red%30) freq start(-3) width(2)) (hist log_labprod if EQ_lead1 == 1, color(blue%30) freq start(-3) width(2)),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "1 year after earthquake" 2 "1 year before earthquake" ) position(6)) ytitle("Number of Firms") title("Indonesia: distribution of logged productivity before and after earthquake impact (1988-2015)")  xline(`mean_lag', lcolor(red%70) noextend)  xline(`mean_lead', lcolor(blue%70) noextend)
graph export "./output/Indonesia/figs/prod_distr_quant_before_after.png", as(png) replace

* PRODUCTIVITY: LOGGED (real VA/lbr)
sum log_rvad_to_lbr if EQ_lag1 == 1
local mean_lag = r(mean)
sum log_rvad_to_lbr if EQ_lead1 == 1
local mean_lead = r(mean)

twoway (hist log_rvad_to_lbr  if EQ_lag1==1, color(red%30) freq start(-3) width(0.2)) (hist log_rvad_to_lbr if EQ_lead1 == 1, color(blue%30) freq start(-3) width(0.2)),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "1 year after earthquake" 2 "1 year before earthquake" ) position(6)) ytitle("Number of Firms") title("Indonesia: distribution of logged productivity before and after earthquake impact (1988-2015)")  xline(`mean_lag', lcolor(red%70) noextend)  xline(`mean_lead', lcolor(blue%70) noextend)


restore  */

********************************************************************************

********************************************************************************
*histograms: compare firms ever hit by EQ and never hit by it
/*preserve

gen hit = 0
replace hit = 1 if num_qs_aw!=0&num_qs_aw!=.
bys region: egen ever_hit = total(hit)
replace ever_hit = 0 if ever_hit==.
replace ever_hit = 1 if ever_hit>0

bys plant: egen firm_ever_hit = total(hit)
replace firm_ever_hit = 0 if firm_ever_hit==.
replace firm_ever_hit = 1 if firm_ever_hit>0

sort plant year
bys plant: gen N = _N
bys plant: gen n = _n

twoway (hist n if ever_hit==1&n==N, color(red%30) freq discrete) (hist n if ever_hit == 0&n==N, color(blue%30) freq discrete ),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) ytitle("Number of Firms") title("Indonesia: distribution of years in survey by earthquake impact (1988-2015)", size(*0.8))  legend(order(1 "Firm Hit by EQ while in 1988-2015" 2 "Firm not Hit by EQ in 1988-2015" ) position(6))
graph export "./output/Indonesia/figs/firms_by_year_and_eq_impact.png", as(png) replace

twoway (hist n if ever_hit==1&n==N, color(red%30) discrete) (hist n if ever_hit == 0&n==N, color(blue%30) discrete ),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) title("Indonesia: distribution of years in survey by earthquake impact (1988-2015)", size(*0.8))  legend(order(1 "Firm Hit by EQ while in 1988-2015" 2 "Firm not Hit by EQ in 1988-2015" ) position(6))
graph export "./output/Indonesia/figs/firms_by_year_and_eq_impact_density.png", as(png) replace

twoway (hist age if ever_hit==1&n==N, color(red%30) discrete freq) (hist age if ever_hit == 0&n==N, color(blue%30) discrete freq),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) title("Indonesia: distribution of age by earthquake impact (1988-2015)", size(*0.8))  legend(order(1 "Area Hit by EQ while in 1988-2015" 2 "Area not Hit by EQ in 1988-2015" ) position(6))
graph export "./output/Indonesia/figs/firms_by_age_and_eq_impact.png", as(png) replace


twoway (hist age if ever_hit==1&n==N, color(red%30) discrete) (hist age if ever_hit == 0&n==N, color(blue%30) discrete ),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) title("Indonesia: distribution of age by earthquake impact (1988-2015)", size(*0.8))  legend(order(1 "Area Hit by EQ while in 1988-2015" 2 "Area not Hit by EQ in 1988-2015" ) position(6))
graph export "./output/Indonesia/figs/firms_by_age_and_eq_impact_density.png", as(png) replace

twoway (hist n if firm_ever_hit==1&n==N, color(red%30) discrete) (hist n if firm_ever_hit == 0&n==N, color(blue%30) discrete),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) title("Indonesia: distribution of years in survey by earthquake impact (1988-2015)", size(*0.8))  legend(order(1 "Firm Hit by EQ while in 1988-2015" 2 "Firm not Hit by EQ in 1988-2015" ) position(6))
graph export "./output/Indonesia/figs/firms_by_age_and_eq_impact_density_firm_level.png", as(png) replace


restore */

********************************************************************************

/*preserve 

*new type of histograms
* drop if no productivity in dataset 
drop if log_rvad_to_lbr==.

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

sum log_rvad_to_lbr if EQ_lag1 == 1
local mean_lag = r(mean)
sum log_rvad_to_lbr if EQ_lead1 == 1
local mean_lead = r(mean)

twoway (hist log_rvad_to_lbr  if EQ_lag1==1, color(red%30) freq start(-3) width(0.2)) (hist log_rvad_to_lbr if EQ_lead1 == 1, color(blue%30) freq start(-3) width(0.2)),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "1 year after earthquake" 2 "1 year before earthquake" ) position(6)) ytitle("Number of Firms") title("Indonesia: distribution of logged productivity before and after earthquake impact (1988-2015)")  xline(`mean_lag', lcolor(red%70) noextend)  xline(`mean_lead', lcolor(blue%70) noextend)


restore
********************************************************************************/

/*averages for 5 years before and after EQ

drop if log_rvad_to_lbr==.&log_lbr==.&log_OUTPUT==.&log_rvad==.

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

*5 years before EQ
gen year_of_EQ = year if EQ ==1
sort plant year_of_EQ
bys plant: replace year_of_EQ = year_of_EQ[_n-1] if year_of_EQ==.
drop if year_of_EQ==.

sort plant year
gen num_of_leads = year_of_EQ-year_min
gen num_of_lags = year_max-year_of_EQ
keep if num_of_lags>=5&num_of_leads>=5
gen five_leads_ago = year_of_EQ-5
drop if year < five_leads_ago
gen five_next_lags = year_of_EQ+5
drop if year > five_next_lags

gen leads = 1 if year< year_of_EQ
gen lags = 1 if year>year_of_EQ


collapse (mean) log_rvad_to_lbr log_OUTPUT log_lbr log_rvad, by(plant leads lags EQ)


sum log_rvad_to_lbr if lags == 1
local mean_lag = r(mean)
sum log_rvad_to_lbr if leads == 1
local mean_lead = r(mean)
sum log_rvad_to_lbr if EQ == 1
local mean_eq = r(mean)

twoway (hist log_rvad_to_lbr  if lags==1, color(red%30) freq start(2) width(0.2)) (hist log_rvad_to_lbr if leads == 1, color(blue%30) freq start(2) width(0.2))       ,  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "5 years after earthquake" 2 "5 years before earthquake") position(6)) ytitle("Number of Firms") title("Indonesia: distribution of logged productivity before and after earthquake (1988-2015)")  xline(`mean_lag', lcolor(red%70) noextend)  xline(`mean_lead', lcolor(blue%70) noextend) 


 
sum log_OUTPUT if lags == 1
local mean_lag = r(mean)
sum log_OUTPUT if leads == 1
local mean_lead = r(mean)

twoway (hist log_OUTPUT  if lags==1, color(red%30) freq start(2) width(0.2)) (hist log_OUTPUT if leads == 1, color(blue%30) freq start(2) width(0.2))       ,  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "5 years after earthquake" 2 "5 years before earthquake") position(6)) ytitle("Number of Firms") title("Indonesia: distribution of logged output before and after earthquake (1988-2015)")  xline(`mean_lag', lcolor(red%70) noextend)  xline(`mean_lead', lcolor(blue%70) noextend) 



 
sum log_lbr if lags == 1
local mean_lag = r(mean)
sum log_lbr if leads == 1
local mean_lead = r(mean)

twoway (hist log_lbr  if lags==1, color(red%30) freq start(0) width(0.2)) (hist log_lbr if leads == 1, color(blue%30) freq start(0) width(0.2))       ,  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "5 years after earthquake" 2 "5 years before earthquake") position(6)) ytitle("Number of Firms") title("Indonesia: distribution of logged labor before and after earthquake (1988-2015)")  xline(`mean_lag', lcolor(red%70) noextend)  xline(`mean_lead', lcolor(blue%70) noextend) 




sum log_rvad if lags == 1
local mean_lag = r(mean)
sum log_rvad if leads == 1
local mean_lead = r(mean)

twoway (hist log_rvad  if lags==1, color(red%30) freq start(0) width(0.2)) (hist log_rvad if leads == 1, color(blue%30) freq start(0) width(0.2))       ,  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "5 years after earthquake" 2 "5 years before earthquake") position(6)) ytitle("Number of Firms") title("Indonesia: distribution of logged VA before and after earthquake (1988-2015)")  xline(`mean_lag', lcolor(red%70) noextend)  xline(`mean_lead', lcolor(blue%70) noextend) 

********************************************************************************
*use pop num instead
drop if log_rvad_to_lbr==.&log_lbr==.&log_OUTPUT==.&log_rvad==.

sort plant year
bys plant: gen n = _n
bys plant: gen N = _N

*drop firms with weird gaps
bys plant: egen year_min = min(year)
bys plant: egen year_max = max(year)
gen th = year_max-year_min+1
drop if th!=N

*keep only firms hit by EQ once in the period of existence
gen EQ = 1 if popnum_qs_aw > 0
bys plant: egen tot_EQ = total(EQ)
keep if tot_EQ==1
drop tot_EQ


*drop firms that experienced EQ 5 years or later before the EQ started (otherwise they are treated twice)
gen double_treated = 1 if (EQ == 1)&(popnum_qs_aw_lag1!=0|popnum_qs_aw_lag2!=0|popnum_qs_aw_lag3!=0|popnum_qs_aw_lag4!=0|popnum_qs_aw_lag5!=0)
bys plant: gen double_treated_firm = sum(double_treated )
drop if double_treated_firm!=0

*5 years before EQ
gen year_of_EQ = year if EQ ==1
sort plant year_of_EQ
bys plant: replace year_of_EQ = year_of_EQ[_n-1] if year_of_EQ==.
drop if year_of_EQ==.

sort plant year
gen num_of_leads = year_of_EQ-year_min
gen num_of_lags = year_max-year_of_EQ
keep if num_of_lags>=5&num_of_leads>=5
gen five_leads_ago = year_of_EQ-5
drop if year < five_leads_ago
gen five_next_lags = year_of_EQ+5
drop if year > five_next_lags

gen leads = 1 if year< year_of_EQ
gen lags = 1 if year>year_of_EQ


collapse (mean) log_rvad_to_lbr log_OUTPUT log_lbr log_rvad, by(plant leads lags EQ)


sum log_rvad_to_lbr if lags == 1
local mean_lag = r(mean)
sum log_rvad_to_lbr if leads == 1
local mean_lead = r(mean)
sum log_rvad_to_lbr if EQ == 1
local mean_eq = r(mean)

twoway (hist log_rvad_to_lbr  if lags==1, color(red%30) freq start(2) width(0.2)) (hist log_rvad_to_lbr if leads == 1, color(blue%30) freq start(2) width(0.2))       ,  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "5 years after earthquake" 2 "5 years before earthquake") position(6)) ytitle("Number of Firms") title("Indonesia: distribution of logged productivity before and after earthquake (1988-2015)")  xline(`mean_lag', lcolor(red%70) noextend)  xline(`mean_lead', lcolor(blue%70) noextend) 


 
sum log_OUTPUT if lags == 1
local mean_lag = r(mean)
sum log_OUTPUT if leads == 1
local mean_lead = r(mean)

twoway (hist log_OUTPUT  if lags==1, color(red%30) freq start(2) width(0.2)) (hist log_OUTPUT if leads == 1, color(blue%30) freq start(2) width(0.2))       ,  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "5 years after earthquake" 2 "5 years before earthquake") position(6)) ytitle("Number of Firms") title("Indonesia: distribution of logged output before and after earthquake (1988-2015)")  xline(`mean_lag', lcolor(red%70) noextend)  xline(`mean_lead', lcolor(blue%70) noextend) 



 
sum log_lbr if lags == 1
local mean_lag = r(mean)
sum log_lbr if leads == 1
local mean_lead = r(mean)

twoway (hist log_lbr  if lags==1, color(red%30) freq start(0) width(0.2)) (hist log_lbr if leads == 1, color(blue%30) freq start(0) width(0.2))       ,  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "5 years after earthquake" 2 "5 years before earthquake") position(6)) ytitle("Number of Firms") title("Indonesia: distribution of logged labor before and after earthquake (1988-2015)")  xline(`mean_lag', lcolor(red%70) noextend)  xline(`mean_lead', lcolor(blue%70) noextend) 




sum log_rvad if lags == 1
local mean_lag = r(mean)
sum log_rvad if leads == 1
local mean_lead = r(mean)

twoway (hist log_rvad  if lags==1, color(red%30) freq start(0) width(0.2)) (hist log_rvad if leads == 1, color(blue%30) freq start(0) width(0.2))       ,  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "5 years after earthquake" 2 "5 years before earthquake") position(6)) ytitle("Number of Firms") title("Indonesia: distribution of logged VA before and after earthquake (1988-2015)")  xline(`mean_lag', lcolor(red%70) noextend)  xline(`mean_lead', lcolor(blue%70) noextend) 

********************************************************************************/

/*preserve 

*new type of histograms
* drop if no productivity in dataset 
drop if log_rvad_to_lbr==.

sort plant year
bys plant: gen n = _n
bys plant: gen N = _N

*drop firms with weird gaps
bys plant: egen year_min = min(year)
bys plant: egen year_max = max(year)
gen th = year_max-year_min+1
drop if th!=N

*keep only firms hit by EQ once in the period of existence
gen EQ = 1 if popnum_qs_aw > 0
bys plant: egen tot_EQ = total(EQ)
keep if tot_EQ==1
drop tot_EQ

*drop firms that experienced EQ 5 years or later before the EQ started (otherwise they are treated twice)
gen double_treated = 1 if (EQ == 1)&(popnum_qs_aw_lag1!=0|popnum_qs_aw_lag2!=0|popnum_qs_aw_lag3!=0|popnum_qs_aw_lag4!=0|popnum_qs_aw_lag5!=0)
bys plant: gen double_treated_firm = sum(double_treated )
drop if double_treated_firm!=0

gen EQ_lag1 = 0
replace EQ_lag1 = 1 if popnum_qs_aw_lag1!=0&popnum_qs_aw_lag1!=.
bys plant: egen EQ_lag1_total = total(EQ_lag1)

gen EQ_lead1 = 0
replace EQ_lead1 = 1 if popnum_qs_aw_lead1!=0&popnum_qs_aw_lead1!=.
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

*get difference
sort plant year
bys plant: gen diff = log_rvad_to_lbr-log_rvad_to_lbr[_n-1] if _n!=1

gen lbr_before_shock = lbr if  EQ_lead1==1
xtile terc = lbr_before_shock, nq(3)
sort plant year
bys plant: replace terc = terc[_n-1] if terc==.

gen output_before_shock = OUTPUT if  EQ_lead1==1
xtile terc_out = output_before_shock, nq(3)
sort plant year
bys plant: replace terc_out = terc_out[_n-1] if terc_out==.

xtile q_out = output_before_shock, nq(4)
sort plant year
bys plant: replace q_out = q_out[_n-1] if q_out==.


gen vad_before_shock = rvad if  EQ_lead1==1
xtile terc_vad = vad_before_shock, nq(3)
sort plant year
bys plant: replace terc_vad = terc_vad[_n-1] if terc_vad==.


*biggest firms in terms of labor
sum log_rvad_to_lbr if EQ_lag1 == 1 & q_out==4
local mean_lag = r(mean)
sum log_rvad_to_lbr if EQ_lead1 == 1 & q_out==4
local mean_lead = r(mean)

twoway (hist log_rvad_to_lbr  if EQ_lag1==1& q_out==4, color(red%30) freq start(2) width(0.25)) (hist log_rvad_to_lbr if EQ_lead1 == 1& q_out==4, color(blue%30) freq start(2) width(0.25)),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "1 year after earthquake" 2 "1 year before earthquake" ) position(6)) ytitle("Number of Firms") title("Indonesia: distribution of logged productivity before and after earthquake (1988-2015)")  xline(`mean_lag', lcolor(red%70) noextend)  xline(`mean_lead', lcolor(blue%70) noextend) note("Firms at top quartile by real output (defined in year pre-shock)")
 
 
sum log_rvad_to_lbr if EQ_lag1 == 1 & q_out==1
local mean_lag = r(mean)
sum log_rvad_to_lbr if EQ_lead1 == 1 & q_out==1
local mean_lead = r(mean)

twoway (hist log_rvad_to_lbr  if EQ_lag1==1& q_out==1, color(red%30) freq start(0) width(0.25)) (hist log_rvad_to_lbr if EQ_lead1 == 1& q_out==1, color(blue%30) freq start(0) width(0.25)),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "1 year after earthquake" 2 "1 year before earthquake" ) position(6)) ytitle("Number of Firms") title("Indonesia: distribution of logged productivity before and after earthquake (1988-2015)")  xline(`mean_lag', lcolor(red%70) noextend)  xline(`mean_lead', lcolor(blue%70) noextend) note("Firms at bottom quartile by real output (defined in year pre-shock)")
 
 
sum log_rvad if EQ_lag1 == 1 & q_out==4
local mean_lag = r(mean)
sum log_rvad if EQ_lead1 == 1 & q_out==4
local mean_lead = r(mean)

twoway (hist log_rvad  if EQ_lag1==1& q_out==4, color(red%30) freq start(4) width(0.25)) (hist log_rvad if EQ_lead1 == 1& q_out==4, color(blue%30) freq start(4) width(0.25)),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "1 year after earthquake" 2 "1 year before earthquake" ) position(6)) ytitle("Number of Firms") title("Indonesia: distribution of logged output before and after earthquake (1988-2015)")  xline(`mean_lag', lcolor(red%70) noextend)  xline(`mean_lead', lcolor(blue%70) noextend) note("Firms at top quartile by real output (defined in year pre-shock)")
 
sum log_rvad if EQ_lag1 == 1 & q_out==1
local mean_lag = r(mean)
sum log_rvad if EQ_lead1 == 1 & q_out==1
local mean_lead = r(mean)

twoway (hist log_rvad  if EQ_lag1==1& q_out==1, color(red%30) freq start(3) width(0.25)) (hist log_rvad if EQ_lead1 == 1& q_out==1, color(blue%30) freq start(3) width(0.25)),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "1 year after earthquake" 2 "1 year before earthquake" ) position(6)) ytitle("Number of Firms") title("Indonesia: distribution of logged output before and after earthquake (1988-2015)")  xline(`mean_lag', lcolor(red%70) noextend)  xline(`mean_lead', lcolor(blue%70) noextend) note("Firms at bottom quartile by real output (defined in year pre-shock)")

sum log_lbr if EQ_lag1 == 1 & q_out==1
local mean_lag = r(mean)
sum log_lbr if EQ_lead1 == 1 & q_out==1
local mean_lead = r(mean)

twoway (hist log_lbr  if EQ_lag1==1& q_out==1, color(red%30) freq start(1) width(0.05)) (hist log_lbr if EQ_lead1 == 1& q_out==1, color(blue%30) freq start(1) width(0.05)),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "1 year after earthquake" 2 "1 year before earthquake" ) position(6)) ytitle("Number of Firms") title("Indonesia: distribution of logged labor before and after earthquake (1988-2015)")  xline(`mean_lag', lcolor(red%70) noextend)  xline(`mean_lead', lcolor(blue%70) noextend) note("Firms at bottom quartile by real output (defined in year pre-shock)")
 
sum log_lbr if EQ_lag1 == 1 & q_out==1
local mean_lag = r(mean)
sum log_lbr if EQ_lead1 == 1 & q_out==1
local mean_lead = r(mean)

twoway (hist log_lbr  if EQ_lag1==1& q_out==1, color(red%30) freq start(1) width(0.05)) (hist log_lbr if EQ_lead1 == 1& q_out==1, color(blue%30) freq start(1) width(0.05)),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "1 year after earthquake" 2 "1 year before earthquake" ) position(6)) ytitle("Number of Firms") title("Indonesia: distribution of logged labor before and after earthquake (1988-2015)")  xline(`mean_lag', lcolor(red%70) noextend)  xline(`mean_lead', lcolor(blue%70) noextend) note("Firms at bottom quartile by real output (defined in year pre-shock)")
 

restore */



* 3. Table with descriptive statistics 
quietly: estpost summarize lbr OUTPUT_th rvad_th rmat_th kap_th rvad_to_lbr rwage_th avg_wage_th, detail
esttab . using "./output/Indonesia/tables/summary_firms_levels_Ind.tex", cells("mean(fmt(1)) min p10 p50 p90 max count(fmt(0))") noobs label replace


















