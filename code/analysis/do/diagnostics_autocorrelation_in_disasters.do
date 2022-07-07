cd /Users/alinagafanova/Library/CloudStorage/Box-Box/recovery-from-disasters/
clear all

*#############################################################################
set scheme plottig 
grstyle init
grstyle set imesh, horizontal minor
grstyle set ci 538, select(13 10) opacity(60)
grstyle set color "35 35 35" "35 35 35"  "62 102 206"  "62 102 206"
graph set window fontface "Helvetica Light"
*#############################################################################

*VIETNAM - no EQs*

*Comparing ADM2 data

* I. Raw data, cyclones
import delimited "./data/tropical-cyclones/intermediate/Vietnam/raw_data_points_adm2_lvl.csv"
keep if track_type=="main"
gen V_m = usa_wind
keep if V_m!=.
keep V_m season id_2
gen V_m_2 = V_m
collapse (mean) V_m (max) V_m_2, by(season id_2)
rename season year
rename id_2 adm2
rename V_m mean_wind_speed
rename V_m_2 max_wind_speed
tsset adm2 year
tsfill, full
replace mean_wind_speed = 0 if mean_wind_speed==.
replace max_wind_speed = 0 if max_wind_speed==.
sort adm2 year
keep if year>=1987&year<=2013
 
foreach var in 26 70 128 530  {
	hist max_wind_speed if adm2==`var', title("Distribution of maximum speeds of cyclones in region `var': raw data") xtitle("Maximum Speed")  width(1) 
	graph save adm2_cyc_raw_`var'
}

* II. Proccessed data, cyclones

clear all
use "./data/tropical-cyclones/intermediate/Vietnam/maxWindsADM2_with_population.dta",clear

foreach var in 26 70 128 530  {
	hist weighted_v_s if ID_2==`var', title("Distribution of maximum speeds of cyclones in region `var': processed data") xtitle("MPGA")  width(1)
	graph save adm2_cyc_proc_`var'
}


* III. Combine

foreach var in 26 70 128 530 {
	gr combine adm2_cyc_raw_`var'.gph adm2_cyc_proc_`var'.gph, col(1)
	graph export ./output/diagnostics_autocorrelation/cyclones_adm2_`var'.pdf, replace
}



*Comparing ADM1 data

* I. Raw data, cyclones
clear all

import delimited "./data/tropical-cyclones/intermediate/Vietnam/raw_data_points_adm1_lvl.csv"
keep if track_type=="main"
gen V_m = usa_wind
keep if V_m!=.
keep V_m season gid_1
gen V_m_2 = V_m
collapse (mean) V_m (max) V_m_2, by(season gid_1)
rename season year
rename gid_1 adm1
rename V_m mean_wind_speed
rename V_m_2 max_wind_speed
encode adm1, gen(adm1_encoded)
tsset adm1_encoded year
tsfill, full
drop adm1
rename adm1_encoded adm1
replace mean_wind_speed = 0 if mean_wind_speed==.
replace max_wind_speed = 0 if max_wind_speed==.
sort adm1 year

keep if year>=1987&year<=2013
decode adm1, gen(adm1_dec)
drop adm1
gen adm1_extract = substr(adm1_dec, strpos(adm1_dec, ".") + 1, .)
replace adm1_extract = substr( adm1_extract , 1, strlen( adm1_extract) - 2)
rename adm1_extract adm1
drop adm1_dec
destring adm1, replace

foreach var in 10 27 49 62  {
	hist max_wind_speed if adm1==`var', title("Distribution of maximum speeds of cyclones in region `var': raw data") xtitle("Maximum Speed")  width(1) 
	graph save adm1_cyc_raw_`var'
}

* II. Proccessed data, cyclones

clear all
import delimited "./data/tropical-cyclones/intermediate/Vietnam/maxWindsADM1.csv", clear
drop v1
rename id_1 adm1

foreach var in 10 27 49 62  {
	hist weighted_v_s if adm1==`var', title("Distribution of maximum speeds of cyclones in region `var': processed data") xtitle("MPGA")  width(1) 
	graph save adm1_cyc_proc_`var'
}

* III. Combine

foreach var in 10 27 49 62  {
	gr combine adm1_cyc_raw_`var'.gph adm1_cyc_proc_`var'.gph, col(1)
	graph export ./output/diagnostics_autocorrelation/cyclones_adm1_`var'.pdf, replace
}



*#############################################################################

*INDIA - no EQs*
























