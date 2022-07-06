cd /Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters

* Housekeeping
clear
clear matrix
set more off

/*import delimited "./data/tropical-cyclones/intermediate/India/maxWindsADM2_with_population.csv", encoding(ISO-8859-9) clear 
drop v1
rename id_2 ID_2
save "./data/tropical-cyclones/intermediate/India/maxWindsADM2_with_population.dta", replace */

use "./data/tropical-cyclones/intermediate/India/maxWindsADM2_with_population.dta",clear
*#############################################################################
set scheme plottig 
grstyle init
grstyle set imesh, horizontal minor
grstyle set ci 538, select(13 10) opacity(60)
grstyle set color "35 35 35" "35 35 35"  "62 102 206"  "62 102 206"
graph set window fontface "Helvetica Light"

*#############################################################################
*merge with a map
merge m:1 ID_2 using "./data/firm-data/India/Shapefile/IND_adm_shp/IND_adm2.dta"
drop _m NAME_1 NAME_2 HASC_2 CCN_2 CCA_2 TYPE_2 ENGTYPE_2 NL_NAME_2 VARNAME_2 ID_1 NAME_0 ISO ID_0

* Number of years with storms at least at 1 pixel

preserve

gen storm_this_year = 0
replace storm_this_year = 1 if weighted_pop_storm>0

collapse (sum) storm_this_year, by(_ID)

replace storm_this_year = . if storm_this_year==0

spmap storm_this_year using "/Users/alina/Downloads/IND_adm2_coordinates.dta", id(_ID) title("Years with Storms" "At at least 1 pixel (1975-2011)", size(*0.8)) clm(c) clb(0 1 2 3 5 10 19) fcolor("255 255 204" "254 178 76" "253 141 60" "252 78 42" "227 26 28" "189 0 38" "128 0 38") legend(title("Years with Storms", size(*0.6))  size(*0.9) position(4) bmargin(large)) 
graph export "./output/India/figs/years_with_storms_India.png", as(png) width(3000) replace

restore

