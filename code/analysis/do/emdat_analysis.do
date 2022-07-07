/***************************************************************
Stata code for exploring disaster occurences, EMDat dataset
Author: Alina Gafanova
***************************************************************/

/***************************************************************
Setting
***************************************************************/

* Change working directory
cd "/Users/alina/epic/recovery-from-disasters"

/***************************************************************
I. Read the original EMDat data on earthquakes
***************************************************************/

import excel "data/raw/emdat_earthquakes.xlsx", sheet("emdat data") cellrange(A7:AU1544) firstrow clear

gen n = 1
destring Year, replace
compress

*count annual country-level occurences in 1900-2021
preserve
collapse (sum) n, by(ISO Country)
gsort -n
save "data/intermediate/emdat_earthquakes_occur_1900_2021.dta", replace
export delimited using "data/intermediate/emdat_earthquakes_occur_1900_2021.csv", replace
restore

*count annual country-level occurences in 2000-2021 (check for data quality in time)
preserve
keep if Year>=2000
collapse (sum) n, by(ISO Country)
gsort -n
save "data/intermediate/emdat_earthquakes_occur_2000_2021.dta", replace
export delimited using "data/intermediate/emdat_earthquakes_occur_2000_2021.csv", replace
restore

/***************************************************************
II. Read the original EMDat data on floods
***************************************************************/

import excel "data/raw/emdat_floods.xlsx", sheet("emdat data") cellrange(A7:AU5467) firstrow clear

gen n = 1
destring Year, replace
compress

*count annual country-level occurences in 1900-2021
preserve
collapse (sum) n, by(ISO Country)
gsort -n
save "data/intermediate/emdat_floods_occur_1900_2021.dta", replace
export delimited using "data/intermediate/emdat_floods_occur_1900_2021.csv", replace
restore

*count annual country-level occurences in 2000-2021 (check for data quality in time)
preserve
keep if Year>=2000
collapse (sum) n, by(ISO Country)
gsort -n
save "data/intermediate/emdat_floods_occur_2000_2021.dta", replace
export delimited using "data/intermediate/emdat_floods_occur_2000_2021.csv", replace
restore

/***************************************************************
III. Read the original EMDat data on tropical cyclones
***************************************************************/

import excel "data/raw/emdat_tropical_cyclones.xlsx", sheet("emdat data") cellrange(A7:AU2403) firstrow clear

gen n = 1
destring Year, replace
compress

*count annual country-level occurences in 1900-2021
preserve
collapse (sum) n, by(ISO Country)
gsort -n
save "data/intermediate/emdat_tropical_cyclones_occur_1900_2021.dta", replace
export delimited using "data/intermediate/emdat_tropical_cyclones_occur_1900_2021.csv", replace
restore

*count annual country-level occurences in 2000-2021 (check for data quality in time)
preserve
keep if Year>=2000
collapse (sum) n, by(ISO Country)
gsort -n
save "data/intermediate/emdat_tropical_cyclones_occur_2000_2021.dta", replace
export delimited using "data/intermediate/emdat_tropical_cyclones_occur_2000_2021.csv", replace
restore






