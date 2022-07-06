cd /Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters

* Housekeeping
clear
clear matrix
set more off

/*import delimited "./data/tropical-cyclones/intermediate/Vietnam/maxWindsADM2.csv", encoding(ISO-8859-9) clear 
drop v1
rename id_2 ID_2
rename v_s maxs
label var maxs "Spatial Average of Maximum Annual Wind Speed (m/s)"
save "./data/tropical-cyclones/intermediate/Vietnam/maxWindsADM2.dta", replace*/

use "./data/tropical-cyclones/intermediate/Vietnam/maxWindsADM2.dta",clear
*#############################################################################
set scheme plottig 
grstyle init
grstyle set imesh, horizontal minor
grstyle set ci 538, select(13 10) opacity(60)
grstyle set color "35 35 35" "35 35 35"  "62 102 206"  "62 102 206"
graph set window fontface "Helvetica Light"

*#############################################################################
*merge with a map
merge m:1 ID_2 using "./data/firm-data/Vietnam/gadm36_VNM_shp/VNM_adm2.dta"
drop NAME_1 NL_NAME_1 NAME_2 VARNAME_2 NL_NAME_2 TYPE_2 ENGTYPE_2  

/* Map for intensity for each year
preserve
*interpolate data to cities (were not covered by grid, do it later properly. for now just drop)
drop _m
replace maxs = . if maxs==0

*create a map for each year
forval year = 1997/2013 {
	spmap maxs if year==`year' using "./data/firm-data/Vietnam/gadm36_VNM_shp/VNM_adm2_coordinates.dta", id(_ID) clm(c) clb(0 17 32 42 49 58 70 1000) fcolor("255 255 204" "254 178 76" "253 141 60" "252 78 42" "227 26 28" "189 0 38" "128 0 38") legend(label(1 "No cyclones") label(2 "Tropical Depression") label(3 "Tropical Storm") label(4 "Category 1") label(5 "Category 2") label(6 "Category 3") label(7 "Category 4") label(8 "Category 5") title("Saffir-Simpson Scale",  size(*0.8)) size(*1.8) position(9)) title("Tropical Cyclones by" "Maximum Intensity in `year'", size(*1.2))
	graph export "./output/Vietnam/maps/hurr_scale_`year'.png", as(png) height(2500) replace
}

restore */


*Distributions of max speed (by year-region)
/*twoway (hist maxs if maxs>0, freq), title("Distribution of non-zero maximum wind speed, spatially averaged by region and year (m/s)") 
graph export "./output/Vietnam/figs/hurr_hist_non_zero.png", as(png) width(3000) replace

twoway (hist maxs, freq), title("Distribution of maximum wind speed, spatially averaged by region and year (m/s)") 
graph export "./output/Vietnam/figs/hurr_hist.png", as(png) width(3000) replace  */

/* Map of average intensity 

preserve
drop _m
collapse (mean) maxs, by(_ID)

spmap maxs using "./data/firm-data/Vietnam/gadm36_VNM_shp/VNM_adm2_coordinates.dta", id(_ID) title("Average of Annual" "Maximum Wind Speed (1997-2013)", size(*1.2)) clm(c) clb(2 7 12 17 26) fcolor("255 255 204" "254 178 76" "253 141 60" "252 78 42" "227 26 28" "189 0 38" "128 0 38") legend(title("Average of MAXS (m/s)", size(*0.9)) position(9)  size(*2)) 
graph export "./output/Vietnam/figs/hurr_annual_avg_Vietnam.png", as(png) width(3000) replace

restore

*/

*#############################################################################
*Generate lags and leads

*create lags
sort ID_2 year
foreach i of num 1/10 {
	by ID_2: gen maxs_lag`i' = maxs[_n-`i']
	by ID_2: gen maxs_lead`i' = maxs[_n+`i']
}


drop _m
merge 1:m year ID_2 using "./data/firm-data/Vietnam/Vietnam_worldbank_data/firms_VNM_clean.dta"
keep if _m==3
drop _m

label var rK "Capital"
label var LPV "Labor Productivity (Real VA / Labor)"
rename id plant
drop region
rename ID_2 region
gen rtot_wage = rwage*L
label var rtot_wage "Real Total Wage"
*****************

*create logged vars
foreach dep in rS rM rV rLC rK LPV rwage L rtot_wage{
	gen log_`dep' = log10(`dep')
	local label_dep: var label `dep'
	label var log_`dep'`"Logged `label_dep'"' 
}

sort plant year
*#############################################################################

/*Histograms: before and after cyclone

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

gen num_LPV = 1 if log_LPV!=.
bys plant: egen tot_num_LPV = total(num_LPV)

sum log_LPV if hurr_lag1 == 1&tot_num_LPV==2
local mean_lag = r(mean)
sum log_LPV if hurr_lead1 == 1&tot_num_LPV==2
local mean_lead = r(mean)

twoway (hist log_LPV  if hurr_lag1==1&tot_num_LPV==2, color(red%30) freq start(1) width(0.4)) (hist log_LPV if hurr_lead1 == 1&tot_num_LPV==2, color(blue%30) freq start(1) width(0.4)),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "1 year after cyclone" 2 "1 year before cyclone" ) position(6)) ytitle("Number of Firms") title("Vietnam: distribution of logged productivity before and after cyclone (2007-2013)")  xline(`mean_lag', lcolor(red%70) noextend)  xline(`mean_lead', lcolor(blue%70) noextend) 
graph export "./output/Vietnam/figs/hist_prod.png", as(png) replace

gen num_V = 1 if log_rV!=.
bys plant: egen tot_num_V = total(num_V)

sum log_rV if hurr_lag1 == 1&tot_num_V==2
local mean_lag = r(mean)
sum log_rV if hurr_lead1 == 1&tot_num_V==2
local mean_lead = r(mean)

twoway (hist log_rV  if hurr_lag1==1&tot_num_V==2, color(red%30) freq start(0) width(0.4)) (hist log_rV if hurr_lead1 == 1&tot_num_V==2, color(blue%30) freq start(0) width(0.4)),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "1 year after cyclone" 2 "1 year before cyclone" ) position(6)) ytitle("Number of Firms") title("Vietnam: distribution of logged VA before and after cyclone (2007-2013)")  xline(`mean_lag', lcolor(red%70) noextend)  xline(`mean_lead', lcolor(blue%70) noextend)
graph export "./output/Vietnam/figs/hist_va.png", as(png)  replace


gen num_L = 1 if log_L!=.
bys plant: egen tot_num_L = total(num_L)

sum log_L if hurr_lag1 == 1&tot_num_L==2
local mean_lag = r(mean)
sum log_L if hurr_lead1 == 1&tot_num_L==2
local mean_lead = r(mean)

twoway (hist log_L  if hurr_lag1==1&tot_num_L==2, color(red%30) freq start(-0.5) width(0.4)) (hist log_L if hurr_lead1 == 1&tot_num_L==2, color(blue%30) freq start(-0.5) width(0.4)),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "1 year after cyclone" 2 "1 year before cyclone" ) position(6)) ytitle("Number of Firms") title("Vietnam: distribution of logged labor before and after cyclone (2007-2013)")  xline(`mean_lag', lcolor(red%70) noextend)  xline(`mean_lead', lcolor(blue%70) noextend)
graph export "./output/Vietnam/figs/hist_labor.png", as(png)  replace



gen num_LC = 1 if log_rLC!=.
bys plant: egen tot_num_LC = total(num_LC)

sum log_rLC if hurr_lag1 == 1&tot_num_LC==2
local mean_lag = r(mean)
sum log_rLC if hurr_lead1 == 1&tot_num_LC==2
local mean_lead = r(mean)

twoway (hist log_rLC  if hurr_lag1==1&tot_num_LC==2, color(red%30) freq start(-3) width(0.4)) (hist log_rLC if hurr_lead1 == 1&tot_num_LC==2, color(blue%30) freq start(-3) width(0.4)),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "1 year after cyclone" 2 "1 year before cyclone" ) position(6)) ytitle("Number of Firms") title("Vietnam: distribution of logged labor cost before and after cyclone (2007-2013)")  xline(`mean_lag', lcolor(red%70) noextend)  xline(`mean_lead', lcolor(blue%70) noextend)
graph export "./output/Vietnam/figs/hist_labor_cost.png", as(png) replace


gen num_w = 1 if log_rwage!=.
bys plant: egen tot_num_w = total(num_w)

sum log_rwage if hurr_lag1 == 1&tot_num_w==2
local mean_lag = r(mean)
sum log_rwage if hurr_lead1 == 1&tot_num_w==2
local mean_lead = r(mean)

twoway (hist log_rwage  if hurr_lag1==1&tot_num_w==2, color(red%30) freq start(-3) width(0.4)) (hist log_rwage if hurr_lead1 == 1&tot_num_w==2, color(blue%30) freq start(-3) width(0.4)),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "1 year after cyclone" 2 "1 year before cyclone" ) position(6)) ytitle("Number of Firms") title("Vietnam: distribution of logged average wage before and after cyclone (2007-2013)")  xline(`mean_lag', lcolor(red%70) noextend)  xline(`mean_lead', lcolor(blue%70) noextend)
graph export "./output/Vietnam/figs/hist_avg_wage.png", as(png) replace

gen num_tw = 1 if log_rtot_wage!=.
bys plant: egen tot_num_tw = total(num_tw)

sum log_rtot_wage if hurr_lag1 == 1&tot_num_tw==2
local mean_lag = r(mean)
sum log_rtot_wage if hurr_lead1 == 1&tot_num_tw==2
local mean_lead = r(mean)

twoway (hist log_rtot_wage  if hurr_lag1==1&tot_num_tw==2, color(red%30) freq start(2.2) width(0.4)) (hist log_rtot_wage if hurr_lead1 == 1&tot_num_tw==2, color(blue%30) freq start(2.2) width(0.4)),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "1 year after cyclone" 2 "1 year before cyclone" ) position(6)) ytitle("Number of Firms") title("Vietnam: distribution of logged total wage before and after cyclone (2007-2013)")  xline(`mean_lag', lcolor(red%70) noextend)  xline(`mean_lead', lcolor(blue%70) noextend)
graph export "./output/Vietnam/figs/hist_wage.png", as(png) replace

gen num_S = 1 if log_rS!=.
bys plant: egen tot_num_S = total(num_S)

sum log_rS if hurr_lag1 == 1&tot_num_S==2
local mean_lag = r(mean)
sum log_rS if hurr_lead1 == 1&tot_num_S==2
local mean_lead = r(mean)

twoway (hist log_rS  if hurr_lag1==1&tot_num_S==2, color(red%30) freq start(2.2) width(0.4)) (hist log_rS if hurr_lead1 == 1&tot_num_S==2, color(blue%30) freq start(2.2) width(0.4)),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "1 year after cyclone" 2 "1 year before cyclone" ) position(6)) ytitle("Number of Firms") title("Vietnam: distribution of logged sales before and after cyclone (2007-2013)")  xline(`mean_lag', lcolor(red%70) noextend)  xline(`mean_lead', lcolor(blue%70) noextend)
graph export "./output/Vietnam/figs/hist_sales.png", as(png) replace


restore */

*#############################################################################


/*Surviving firms vs dying firms in t-1 (before cyclone)

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
gen hurr = 1 if maxs>=17
bys plant: egen tot_hurr = total(hurr)
keep if tot_hurr==1
drop tot_hurr

*gen year before and after
gen hurr_lag1 = 0
replace hurr_lag1 = 1 if maxs_lag1>=17&maxs_lag1!=.

gen hurr_lead1 = 0
replace hurr_lead1 = 1 if maxs_lead1>=17&maxs_lead1!=.

keep if hurr_lag1==1|hurr_lead1==1

* drop if firm only existed for 1 period
drop if N==1

*drop if observation is both lag and lead-lag
drop if hurr_lead1==1&hurr_lag1==1
drop n N

*keep lead-lag pairs
bys plant: gen N = _N
drop if N>2
bys plant: gen next_year = year[_n+1] if N==2
bys plant: gen last_year = year[_n-1] if N==2
gen next_year_theory = year + 2 if hurr_lead1 == 1 & N==2
gen last_year_theory = year - 2 if hurr_lag1 == 1 & N==2
keep if (next_year==next_year_theory&hurr_lead1 == 1& N==2)|(hurr_lag1==1& N==2)|(N==1)
keep if (last_year==last_year_theory&hurr_lag1==1& N==2)|(hurr_lead1 == 1)|(N==1)

*only keep t-1
sort plant year
bys plant: gen n = _n
drop if n==2
drop if n==1&hurr_lag1==1

*plot labor (density not frequency)

sum log_L if N==1
local mean_d = r(mean)
sum log_L if N==2
local mean_s = r(mean)

twoway (hist log_L if N==1, color(red%30) start(0) width(0.4)) (hist log_L if N==2, color(green%30) start(0) width(0.4)),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "Firm Exited after Cyclone" 2 "Firm Survived the Cyclone" ) position(6)) title("Vietnam: labor before cyclone (2007-2013)")  xline(`mean_d', lcolor(red%70) noextend)  xline(`mean_s', lcolor(green%70) noextend)
graph export "./output/Vietnam/figs/labor_t-1.png", as(png)  replace

*plot real sales

sum log_rS if N==1
local mean_d = r(mean)
sum log_rS if N==2
local mean_s = r(mean)

twoway (hist log_rS if N==1, color(red%30) start(0) width(0.4)) (hist log_rS if N==2, color(green%30) start(0) width(0.4)),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "Firm Exited after Cyclone" 2 "Firm Survived the Cyclone" ) position(6)) title("Vietnam: sales before cyclone (2007-2013)")  xline(`mean_d', lcolor(red%70) noextend)  xline(`mean_s', lcolor(green%70) noextend)
graph export "./output/Vietnam/figs/sales_t-1.png", as(png)  replace

*plot productivity

sum log_LPV if N==1
local mean_d = r(mean)
sum log_LPV if N==2
local mean_s = r(mean)

twoway (hist log_LPV if N==1, color(red%30) start(1) width(0.4)) (hist log_LPV if N==2, color(green%30) start(1) width(0.4)),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "Firm Exited after Cyclone" 2 "Firm Survived the Cyclone" ) position(6)) title("Vietnam: labor productivity before cyclone (2007-2013)")  xline(`mean_d', lcolor(red%70) noextend)  xline(`mean_s', lcolor(green%70) noextend)
graph export "./output/Vietnam/figs/lab_prod_t-1.png", as(png)  replace


*plot productivity

sum log_LPV if N==1
local mean_d = r(mean)
sum log_LPV if N==2
local mean_s = r(mean)

twoway (hist log_LPV if N==1, color(red%30) start(1) width(0.4)) (hist log_LPV if N==2, color(green%30) start(1) width(0.4)),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "Firm Exited after Cyclone" 2 "Firm Survived the Cyclone" ) position(6)) title("Vietnam: labor productivity before cyclone (2007-2013)")  xline(`mean_d', lcolor(red%70) noextend)  xline(`mean_s', lcolor(green%70) noextend)
graph export "./output/Vietnam/figs/lab_prod_t-1.png", as(png)  replace 

restore
*/
*#############################################################################

/*Histograms: before and after cyclone: pulled (not only 1 cyclone)

preserve
sort plant year
bys plant: gen n = _n
bys plant: gen N = _N

*gen cyclone years
gen hurr = 1 if maxs>=17
bys plant: egen tot_hurr = total(hurr)

*gen year before and after
gen hurr_lag1 = 0
replace hurr_lag1 = 1 if maxs_lag1>=17&maxs_lag1!=.

gen hurr_lead1 = 0
replace hurr_lead1 = 1 if maxs_lead1>=17&maxs_lead1!=.

*keep only lag/lead or cyclone year
keep if hurr_lead1 ==1|hurr_lag1 == 1 | hurr == 1 

*plot labor (density not frequency)
sum log_L if hurr_lag1 == 1
local mean_lag = r(mean)
sum log_L if hurr_lead1 ==1
local mean_lead = r(mean)

twoway (hist log_L if hurr_lag1 == 1, color(red%30) start(0) width(0.4)) (hist log_L if hurr_lead1 ==1, color(blue%30) start(0) width(0.4)),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "Firm after the Cyclone" 2 "Firm before the Cyclone" ) position(6)) title("Vietnam: labor and cyclones (2007-2013)")  xline(`mean_lag', lcolor(red%70) noextend)  xline(`mean_lead', lcolor(blue%70) noextend) 
graph export "./output/Vietnam/figs/labor_pulled_t-1.png", as(png)  replace

*plot sales (density not frequency)
sum log_rS if hurr_lag1 == 1
local mean_lag = r(mean)
sum log_rS if hurr_lead1 ==1
local mean_lead = r(mean)

twoway (hist log_rS if hurr_lag1 == 1, color(red%30) start(0) width(0.4)) (hist log_rS if hurr_lead1 ==1, color(blue%30) start(0) width(0.4)),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "Firm after the Cyclone" 2 "Firm before the Cyclone" ) position(6)) title("Vietnam: real sales and cyclones (2007-2013)")  xline(`mean_lag', lcolor(red%70) noextend)  xline(`mean_lead', lcolor(blue%70) noextend) 
graph export "./output/Vietnam/figs/sales_pulled_t-1.png", as(png)  replace

*plot productivity (density not frequency)
sum log_LPV if hurr_lag1 == 1
local mean_lag = r(mean)
sum log_LPV if hurr_lead1 ==1
local mean_lead = r(mean)

twoway (hist log_LPV if hurr_lag1 == 1, color(red%30) start(0) width(0.4)) (hist log_LPV if hurr_lead1 ==1, color(blue%30) start(0) width(0.4)),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "Firm after the Cyclone" 2 "Firm before the Cyclone" ) position(6)) title("Vietnam: real labor productivity and cyclones (2007-2013)")  xline(`mean_lag', lcolor(red%70) noextend)  xline(`mean_lead', lcolor(blue%70) noextend) 
graph export "./output/Vietnam/figs/prod_pulled_t-1.png", as(png)  replace

*plot VA (density not frequency)
sum log_rV if hurr_lag1 == 1
local mean_lag = r(mean)
sum log_rV if hurr_lead1 ==1
local mean_lead = r(mean)

twoway (hist log_rV if hurr_lag1 == 1, color(red%30) start(0) width(0.4)) (hist log_rV if hurr_lead1 ==1, color(blue%30) start(0) width(0.4)),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "Firm after the Cyclone" 2 "Firm before the Cyclone" ) position(6)) title("Vietnam: real VA and cyclones (2007-2013)")  xline(`mean_lag', lcolor(red%70) noextend)  xline(`mean_lead', lcolor(blue%70) noextend) 
graph export "./output/Vietnam/figs/va_pulled_t-1.png", as(png)  replace

*plot labor cost (density not frequency)
sum log_rLC if hurr_lag1 == 1
local mean_lag = r(mean)
sum log_rLC if hurr_lead1 ==1
local mean_lead = r(mean)

twoway (hist log_rLC if hurr_lag1 == 1, color(red%30) start(0) width(0.4)) (hist log_rLC if hurr_lead1 ==1, color(blue%30) start(0) width(0.4)),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "Firm after the Cyclone" 2 "Firm before the Cyclone" ) position(6)) title("Vietnam: real labor cost and cyclones (2007-2013)")  xline(`mean_lag', lcolor(red%70) noextend)  xline(`mean_lead', lcolor(blue%70) noextend) 
graph export "./output/Vietnam/figs/lbrcost_pulled_t-1.png", as(png)  replace

*plot wages (density not frequency)
sum log_rtot_wage if hurr_lag1 == 1
local mean_lag = r(mean)
sum log_rtot_wage if hurr_lead1 ==1
local mean_lead = r(mean)

twoway (hist log_rtot_wage if hurr_lag1 == 1, color(red%30) start(0) width(0.4)) (hist log_rtot_wage if hurr_lead1 ==1, color(blue%30) start(0) width(0.4)),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "Firm after the Cyclone" 2 "Firm before the Cyclone" ) position(6)) title("Vietnam: real total wages and cyclones (2007-2013)")  xline(`mean_lag', lcolor(red%70) noextend)  xline(`mean_lead', lcolor(blue%70) noextend) 
graph export "./output/Vietnam/figs/totwage_pulled_t-1.png", as(png)  replace


*plot avg wages (density not frequency)
sum log_rwage if hurr_lag1 == 1
local mean_lag = r(mean)
sum log_rwage if hurr_lead1 ==1
local mean_lead = r(mean)

twoway (hist log_rwage if hurr_lag1 == 1, color(red%30) start(0) width(0.4)) (hist log_rwage if hurr_lead1 ==1, color(blue%30) start(0) width(0.4)),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "Firm after the Cyclone" 2 "Firm before the Cyclone" ) position(6)) title("Vietnam: real average wage and cyclones (2007-2013)")  xline(`mean_lag', lcolor(red%70) noextend)  xline(`mean_lead', lcolor(blue%70) noextend) 
graph export "./output/Vietnam/figs/avgwage_pulled_t-1.png", as(png)  replace



restore*/















