cd /Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters

* Housekeeping
clear
clear matrix
set more off

use "data/earthquakes/intermediate/Chile_adm3/region_panel/panel_earthquakes_thresh_10.dta",clear

*#############################################################################
set scheme plottig 
grstyle init
grstyle set imesh, horizontal minor
grstyle set ci 538, select(13 10) opacity(60)
grstyle set color "35 35 35" "35 35 35"  "62 102 206"  "62 102 206"
graph set window fontface "Helvetica Light"
*#############################################################################
rename region ID_3 

*merge with a map
merge m:1 ID_3 using "./data/firm-data/Chile/Shapefile/CHL_adm_shp/CHL_adm3.dta"

drop _m
rename ID_3 region

* Map for intensity for each year
/*preserve

replace mpga_aw = . if mpga_aw==0

*create a map for each year
forval year = 1985/2015 {
	spmap mpga_aw if year==`year' using "./data/firm-data/Chile/Shapefile/CHL_adm_shp/CHL_adm3_coordinates.dta", id(_ID) clm(c) clb(0 1 5 10 15 36) fcolor("254 178 76" "253 141 60" "252 78 42" "227 26 28" "189 0 38" "128 0 38") legend(title("Max PGA", size(*1.2)) size(*2.7) position(3)) title("Shaking Intensity (MPGA)" "Chile in `year'", size(*1.4)) ysize(40) xsize(17)
	graph export "./output/Chile/maps/eq_`year'.png", as(png) height(2500) replace
}

restore  */

*#############################################################################


*number of years when shaking occurs
gen shaking_year = 0
replace shaking_year = 1 if num_qs_aw>0
bys region: egen years_shaking = total(shaking_year)
label var years_shaking "Years with earthquakes in 1985-2015"

preserve
rename region ID_3
collapse (mean) mpga_aw, by(ID_3 _ID)
replace mpga_aw=. if mpga_aw==0
format (mpga_aw) %12.2f
spmap mpga_aw using "./data/firm-data/Chile/Shapefile/CHL_adm_shp/CHL_adm3_coordinates.dta", id(_ID) fcolor(Reds) legend(title("Mean MPGA", size(*1.2)) label(1 "No shaking" ) size(*2.7) position(3)) title("Mean MPGA for 31 years" "(1985-2015)", size(*1.3))  ysize(40) xsize(17)
graph export "./output/Chile/maps/CHL_mpga.png", as(png) replace
restore  

preserve
bys region: drop if _n>1
rename region ID_3
replace years_shaking=. if years_shaking==0
spmap years_shaking using "./data/firm-data/Chile/Shapefile/CHL_adm_shp/CHL_adm3_coordinates.dta", id(_ID) fcolor(Oranges) clnumber(7) title("Years with earthquakes from" "31 years (1985-2015)", size(*1.3)) ysize(40) xsize(17) legend(label(1 "No EQs") label(2 "1-2 year with earthquakes") label(3 "3 years with earthquakes") label(4 "4 years with earthquakes") label(5 "5 years with earthquakes") label(6 "5-6 years with earthquakes") label(7 "6-13 years with earthquakes") size(*2.7) position(3))


graph export "./output/Chile/maps/CHL_num.png", as(png) replace height(2500)
restore  















