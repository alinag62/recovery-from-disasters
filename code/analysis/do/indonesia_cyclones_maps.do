/*
###########################################################################
                    Intro
########################################################################### */

cd /Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters

* Housekeeping
clear
clear matrix
set more off

use "./data/tropical-cyclones/intermediate/Indonesia/maxWindsADM2.dta",clear
label var maxs "Spatial Average of Maximum Annual Wind Speed (m/s)"
*#############################################################################
set scheme plottig 
grstyle init
grstyle set imesh, horizontal minor
grstyle set ci 538, select(13 10) opacity(60)
grstyle set color "35 35 35" "35 35 35"  "62 102 206"  "62 102 206"
graph set window fontface "Helvetica Light"

*#############################################################################
*1. merge with a map
rename id_2 ID_2
merge m:1 ID_2 using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2.dta"

/* Map for intensity for each year
preserve
*interpolate data to cities (were not covered by grid, do it later properly. for now just drop)
drop _m
fillin year ID_2
drop if year==.
replace maxs = . if maxs==0

*create a map for each year
forval year = 1977/2015 {
	spmap maxs if year==`year' using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2_coordinates.dta", id(_ID) fcolor(YlOrRd) clm(c) clb(0 17 32 42 49 58 70 1000) legend(label(1 "No cyclones") label(2 "Tropical Depression") label(3 "Tropical Storm") label(4 "Category 1") label(5 "Category 2") label(6 "Category 3") label(7 "Category 4") label(8 "Category 5") title("Saffir-Simpson Scale",  size(*0.8)) size(*1.8) ) title("Tropical Cyclones by Maximum Intensity in `year'", size(*1.2))
	graph export "./output/Indonesia/maps/hurr_scale_`year'.png", as(png) width(3000) replace
}
restore */

/*Distributions of max speed (by year-region)
twoway (hist maxs if maxs>0, freq), title("Distribution of non-zero maximum wind speed, spatially averaged by region and year (m/s)") 
graph export "./output/Indonesia/figs/hurr_hist_non_zero.png", as(png) width(3000) replace

twoway (hist maxs, freq), title("Distribution of maximum wind speed, spatially averaged by region and year (m/s)") 
graph export "./output/Indonesia/figs/hurr_hist.png", as(png) width(3000) replace */

*#############################################################################

*Generate lags and leads
keep if _m==3
drop _m

rename ADM2_id_in ADM2_id_in_shp_88
destring ADM2_id_in_shp_88, replace
merge m:1 ADM2_id_in_shp_88 using "./data/shapefiles/regions_codes/crosswalk_1988_2015_to_shp.dta"
keep if _m==3
drop _m

*create lags
sort ID_2 year
foreach i of num 1/10 {
	by ID_2: gen maxs_lag`i' = maxs[_n-`i']
	by ID_2: gen maxs_lead`i' = maxs[_n+`i']
}

merge 1:m i_harmonize_to_1988 year using "./data/firm-data/Indonesia/Final-Dataset/maindata_clean_95perc.dta"
keep if _m==3
drop _m
rename PSID plant
rename i_harmonize_to_1988 region

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
foreach dep in OUTPUT lbr kap labprod out rvad_to_lbr rvad {
	gen log_`dep' = log10(`dep')
	local label_dep: var label `dep'
	label var log_`dep'`"Logged `label_dep'"' 
}

*#############################################################################

*Histograms(?)

preserve 
sort plant year
bys plant: gen n = _n
bys plant: gen N = _N

*drop firms with weird gaps
bys plant: egen year_min = min(year)
bys plant: egen year_max = max(year)
gen th = year_max-year_min+1
drop if th!=N

*keep only firms hit by tropical cyclone (17m/s) once in the period of existence
gen hurr = 1 if maxs >= 17
bys plant: egen tot_hurr = total(hurr)
keep if tot_hurr==1
drop tot_hurr

*gen year before and after
gen hurr_lag1 = 0
replace hurr_lag1 = 1 if maxs_lag1>=17&maxs_lag1!=.

gen hurr_lead1 = 0
replace hurr_lead1 = 1 if maxs_lead1>=17&maxs_lead1!=.

keep if hurr_lag1==1|hurr_lead1==1

*only keep if the pair lead-lag exists (for 1 before and 1 after)
drop if hurr_lag1==1&n<3
drop if hurr_lead1==1&n==N
drop if hurr_lead1==1&n==N-1
sort plant year
bys plant: gen next_year = year[_n+1]
bys plant: gen last_year = year[_n-1]
gen next_year_theory = year + 2 if hurr_lead1 == 1 
gen last_year_theory = year - 2 if hurr_lag1 == 1 
keep if (next_year==next_year_theory&hurr_lead1 == 1)|hurr_lag1==1
keep if (last_year==last_year_theory&hurr_lag1==1)|hurr_lead1 == 1

sum log_rvad_to_lbr if hurr_lag1 == 1
local mean_lag = r(mean)
sum log_rvad_to_lbr if hurr_lead1 == 1
local mean_lead = r(mean)

twoway (hist log_rvad_to_lbr  if hurr_lag1==1, color(red%30) freq start(-3) width(0.4)) (hist log_rvad_to_lbr if hurr_lead1 == 1, color(blue%30) freq start(-3) width(0.4)),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "1 year after cyclone" 2 "1 year before cyclone" ) position(6)) ytitle("Number of Firms") title("Indonesia: distribution of logged productivity before and after cyclone (1988-2015)")  xline(`mean_lag', lcolor(red%70) noextend)  xline(`mean_lead', lcolor(blue%70) noextend)



restore





















