cd /Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters

*#############################################################################
set scheme plottig 
grstyle init
grstyle set imesh, horizontal minor
grstyle set ci 538, select(13 10) opacity(60)
grstyle set color "35 35 35" "35 35 35"  "62 102 206"  "62 102 206"
*#############################################################################

*append all files with countries' stats 

import delimited "./data/tropical-cyclones/intermediate/cyclones_COL.csv", encoding(UTF-8) clear 
gen country = "Colombia"

tempfile to_append 
sa "`to_append'"

import delimited "./data/tropical-cyclones/intermediate/cyclones_JPN.csv", encoding(UTF-8) clear 
gen country = "Japan"
append using `to_append', force

tempfile to_append 
sa "`to_append'"


import delimited "./data/tropical-cyclones/intermediate/cyclones_MEX.csv", encoding(UTF-8) clear 
gen country = "Mexico"
append using `to_append', force

tempfile to_append 
sa "`to_append'"

import delimited "./data/tropical-cyclones/intermediate/cyclones_SLV.csv", encoding(UTF-8) clear 
gen country = "El Salvador"
append using `to_append', force

tempfile to_append 
sa "`to_append'"

import delimited "./data/tropical-cyclones/intermediate/cyclones_VNM.csv", encoding(UTF-8) clear 
gen country = "Vietnam"
append using `to_append', force

tempfile to_append 
sa "`to_append'"

import delimited "./data/tropical-cyclones/intermediate/cyclones_ETH.csv", encoding(UTF-8) clear 
gen country = "Ethiopia"
append using `to_append', force

tempfile to_append 
sa "`to_append'"

import delimited "./data/tropical-cyclones/intermediate/cyclones_CIV.csv", encoding(UTF-8) clear 
gen country = "Cote d'Ivoire'"
append using `to_append', force

tempfile to_append 
sa "`to_append'"

import delimited "./data/tropical-cyclones/intermediate/cyclones_PHL.csv", encoding(UTF-8) clear 
gen country = "Philippines"
append using `to_append', force

tempfile to_append 
sa "`to_append'"

import delimited "./data/tropical-cyclones/intermediate/cyclones_IND.csv", encoding(UTF-8) clear 
gen country = "India"
append using `to_append', force

tempfile to_append 
sa "`to_append'"

import delimited "./data/tropical-cyclones/intermediate/cyclones_US.csv", encoding(UTF-8) clear 
gen country = "USA"
append using `to_append', force

tempfile to_append 
sa "`to_append'"


import delimited "./data/tropical-cyclones/intermediate/cyclones_IDN.csv", encoding(UTF-8) clear 
gen country = "Indonesia"
append using `to_append', force

tempfile to_append 
sa "`to_append'" 




order country


*Keep only 1973-2018
keep if (year>=1973&year<=2018)

* Based on the papers: we keep only main observations to avoid spurs
keep if track_type=="main"

* Since different sources of data are not comparable, I choose the agency with most observations
keep country sid usa_wind

collapse (max) usa_wind, by(sid country)
gen i = 1
collapse (median) usa_wind (sum) i, by(country)

*Chile and Moldova have no cyclones in this time period

set obs `=_N+1'
replace country = "Moldova" if  country ==""
set obs `=_N+1'
replace country = "Chile" if  country ==""
set obs `=_N+1'
replace country = "Cote d'Ivoire'" if  country ==""

order country i usa_wind
sort country















