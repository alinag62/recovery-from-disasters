cd /Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters

* Housekeeping
clear
clear matrix
set more off

use "data/earthquakes/intermediate/Vietnam_adm2/region_panel/panel_earthquakes_thresh_10.dta",clear

*#############################################################################
set scheme plottig 
grstyle init
grstyle set imesh, horizontal minor
grstyle set ci 538, select(13 10) opacity(60)
grstyle set color "35 35 35" "35 35 35"  "62 102 206"  "62 102 206"
graph set window fontface "Helvetica Light"
*#############################################################################
rename region ID_2 

*merge with a map
merge m:1 ID_2 using "./data/firm-data/Vietnam/gadm36_VNM_shp/VNM_adm2.dta"

drop _m
rename ID_2 region

* Map for intensity for each year
/*preserve
*interpolate data to cities (were not covered by grid, do it later properly. for now just drop)
replace mpga_aw = . if mpga_aw==0

*create a map for each year
forval year = 1997/2013 {
	spmap mpga_aw if year==`year' using "./data/firm-data/Vietnam/gadm36_VNM_shp/VNM_adm2_coordinates.dta", id(_ID) clm(c) clb(0 0.1 0.5 1 2 2.6) fcolor("254 178 76" "253 141 60" "252 78 42" "227 26 28" "189 0 38" "128 0 38") legend(title("Max PGA") size(*2.5) position(9)) title("Shaking Intensity (MPGA)" "Vietnam in `year'", size(*1.2))
	graph export "./output/Vietnam/maps/eq_`year'.png", as(png) height(2500) replace
}

restore  */

*#############################################################################
/*number of years when shaking occurs
gen shaking_year = 0
replace shaking_year = 1 if num_qs_aw>0
bys region: egen years_shaking = total(shaking_year)
label var years_shaking "Years with earthquakes in 1997-2013"

preserve
rename region ID_2
collapse (mean) mpga_aw, by(ID_2 _ID)
replace mpga_aw=. if mpga_aw==0
format (mpga_aw) %12.2f
spmap mpga_aw using "./data/firm-data/Vietnam/gadm36_VNM_shp/VNM_adm2_coordinates.dta", id(_ID) fcolor(Reds) legend(title("Mean MPGA", size(*0.9)) label(1 "No shaking" ) size(*2.1) position(9)) title("Mean MPGA for 17 years" "(1997-2013)", size(*1.3)) 
graph export "./output/Vietnam/maps/VNM_mpga.png", as(png) replace
restore  
*/


*#############################################################################
















