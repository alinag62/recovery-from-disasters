*Harmonizing Regions in Firm data

local path "/Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters"
cd `path'

*Find all possible patterns of IDs changes (from official data on Indonesia, 1988-2015)
use "./data/shapefiles/regions_codes/crosswalk_1988_2015.dta", clear
gen i = _n

*save id crosswalk
preserve
keep i i_harmonize_to_1988
tempfile ids
save "`ids'"
restore

drop name_year* i_harmonize_to_1988
reshape long id_year, i(i) j(year)

*save long format (we will use them for plants with no changes)
preserve 
merge m:1 i using `ids'
drop i _m
rename id_year id1
duplicates drop
bys id1 year:gen N = _N
drop if N>1
save "./data/shapefiles/regions_codes/patterns_regions_with_no_change.dta", replace
restore

sort i year
gen year2 = year
collapse (min) year (max) year2 , by(i id_year)
sort i year
bys i: gen n = _n
drop year*
rename id_year id
reshape wide id, i(i) j(n)
merge 1:1 i using `ids'
drop _m i
order i_harmonize_to_1988
drop if id2==""

*Do the following part in Excel (because i don't know how to do it otherwise)

import excel "./data/shapefiles/regions_codes/all_possible_patterns.xlsx", sheet("Sheet1") firstrow clear
drop if id1==.

*Save all possible patterns
preserve
drop if id2==.
tostring id*, replace
gen sum_concat = id1+id2+id3+id4+id5
duplicates drop
*check that we don't have repeated things
bys sum_concat: gen n = _n
drop if n>1
drop sum_concat n
destring id*, replace
save "./data/shapefiles/regions_codes/patterns_of_change.dta", replace
restore

****************************************************************************************
****************************************************************************************
use "./data/firm-data/Indonesia_worldbank/maindata_v1.dta", clear

*Drop 2017 since it contains different PSIDs
drop if year==2017 

*Drop East Timor since it's independent now
drop if prov == "54"

*clean
rename DPROVI province_id_wb
rename DKABUP district_id_wb
gen id = province_id_wb +district_id_wb

*record how IDs change 
drop if id=="-"
drop if district_id==""
drop if district_id=="00"
drop if district_id=="."
gen year2 = year
collapse (min) year (max) year2 , by(PSID id)
rename year year_min
rename year2 year_max

*Match Regions with no Changes
preserve
bys PSID: gen N = _N
keep if N==1
gen diff = year_max-year_min
gen year = year_min if diff==0
replace year = year_min+1 if diff!=0
keep PSID id year
rename id id1
merge m:1 id1 year using "./data/shapefiles/regions_codes/patterns_regions_with_no_change.dta"
drop if _m==2
drop _m

rename year year_old
rename i_harmonize_to_1988 i_harmonize_to_1988_old
gen year = year_old+1
merge m:1 id1 year using "./data/shapefiles/regions_codes/patterns_regions_with_no_change.dta"
drop if _m==2
drop _m

rename year year_old2
rename i_harmonize_to_1988 i_harmonize_to_1988_old2
gen year = year_old-1
merge m:1 id1 year using "./data/shapefiles/regions_codes/patterns_regions_with_no_change.dta"
drop if _m==2

replace i_harmonize_to_1988_old = i_harmonize_to_1988 if i_harmonize_to_1988_old==.&i_harmonize_to_1988!=.
replace i_harmonize_to_1988_old = i_harmonize_to_1988_old2 if i_harmonize_to_1988_old==.&i_harmonize_to_1988_old2!=.
drop i_harmonize_to_1988_old2 i_harmonize_to_1988 year_old2 year
drop _m

gen year = year_old+2
merge m:1 id1 year using "./data/shapefiles/regions_codes/patterns_regions_with_no_change.dta"
drop if _m==2
drop _m
drop year
rename year_old year
replace i_harmonize_to_1988_old = i_harmonize_to_1988 if i_harmonize_to_1988_old==.&i_harmonize_to_1988!=.
drop i_harmonize_to_1988
rename i_harmonize_to_1988_old i_harmonize_to_1988

*MANUAL CHANGES

replace i_harmonize_to_1988=4 if id1=="1117"&i_harmonize_to_1988==.
replace i_harmonize_to_1988=45 if id1=="1406"&i_harmonize_to_1988==.
replace i_harmonize_to_1988=46 if id1=="1473"&i_harmonize_to_1988==.
replace i_harmonize_to_1988=53 if id1=="1506"&i_harmonize_to_1988==.
replace i_harmonize_to_1988=44 if id1=="2001"&i_harmonize_to_1988==.
replace i_harmonize_to_1988=44 if id1=="2002"&i_harmonize_to_1988==.
replace i_harmonize_to_1988=48 if id1=="2071"&i_harmonize_to_1988==.
replace i_harmonize_to_1988=77 if id1=="3101"&i_harmonize_to_1988==.
replace i_harmonize_to_1988=95 if id1=="3275"&i_harmonize_to_1988==.
replace i_harmonize_to_1988=273 if id1=="8104"&i_harmonize_to_1988==.
replace i_harmonize_to_1988=277 if id1=="9371"&i_harmonize_to_1988==.
drop if i_harmonize_to_1988==.
keep PSID i_harmonize_to_1988
rename i_harmonize_to_1988 i_harmonize_to_1988_1
save "./data/shapefiles/regions_codes/patterns_plants_part1.dta", replace
restore

*Match by Pattern
preserve
sort PSID year_min
bys PSID: gen n = _n
drop year*

*Reshape Data
reshape wide id, i(PSID) j(n)
drop if id2==""
destring id*, replace
merge m:1 id1 id2 id3 id4 id5 using "./data/shapefiles/regions_codes/patterns_of_change.dta"
keep if _m==3

keep PSID i_harmonize_to_1988
rename i_harmonize_to_1988 i_harmonize_to_1988_2
save "./data/shapefiles/regions_codes/patterns_plants_part2.dta", replace
restore


****************************************************************************************
use "./data/firm-data/Indonesia_worldbank/maindata_v1.dta", clear

*clean again
drop if year==2017 
drop if prov == "54"
rename DPROVI province_id
rename DKABUP district_id
gen id = province_id +district_id
destring id, replace
drop if district_id==""
drop if district_id=="00"
drop if district_id=="."

merge m:1 PSID using "./data/shapefiles/regions_codes/patterns_plants_part1.dta"
drop _m

merge m:1 PSID using "./data/shapefiles/regions_codes/patterns_plants_part2.dta"
drop _m

gen i_harmonize_to_1988 = i_harmonize_to_1988_1 if i_harmonize_to_1988_1!=.
replace i_harmonize_to_1988 = i_harmonize_to_1988_2 if i_harmonize_to_1988_2!=.


*Deal with the rest!
preserve
keep if i_harmonize_to_1988==.

gen year2 = year
collapse (min) year (max) year2 , by(PSID id)
rename year year_min
rename year2 year_max
sort PSID year_min

*if a plant change location for 1 year, and then comes back, it's seemingly a "typo" (is it true???)
bys PSID: gen N = _N
drop if N==1
bys PSID : gen last_year = year_max[_n-1]
gen diff = year_max-last_year
gen diff2 = year_max-year_min
drop if diff<0&diff2==0
tempfile full
save "`full'"

*match with patterns
sort PSID year_min
bys PSID: gen n = _n
keep PSID id n
reshape wide id, i(PSID) j(n)
drop if id2==.
merge m:1 id1 id2 id3 id4 id5 using "./data/shapefiles/regions_codes/patterns_of_change.dta"
keep if _m==3
keep PSID i_harmonize_to_1988
rename i_harmonize_to_1988 i_harmonize_to_1988_3
save "./data/shapefiles/regions_codes/patterns_plants_part3.dta", replace

*match the ones that don't change 
use `full', clear
drop N
sort PSID year_min
bys PSID: gen N = _N
keep if N==1
keep PSID year_min year_max id
gen diff = year_max-year_min
gen year = year_min if diff==0
replace year = year_min+1 if diff!=0
keep PSID id year
rename id id1
tostring id1, replace
merge m:1 id1 year using "./data/shapefiles/regions_codes/patterns_regions_with_no_change.dta"
replace i_harmonize_to_1988 = 48 if id1=="1472"&_m==1
replace i_harmonize_to_1988 = 95 if id1=="3275"&_m==1
drop if i_harmonize_to_1988==.
drop if PSID==.
keep PSID i_harmonize_to_1988
rename i_harmonize_to_1988 i_harmonize_to_1988_4
save "./data/shapefiles/regions_codes/patterns_plants_part4.dta", replace
restore


****************************************************************************************
*One more attempt to match everything
****************************************************************************************
use "./data/firm-data/Indonesia_worldbank/maindata_v1.dta", clear

*clean again
drop if year==2017 
drop if prov == "54"
rename DPROVI province_id
rename DKABUP district_id
gen id = province_id +district_id
destring id, replace
drop if district_id==""
drop if district_id=="00"
drop if district_id=="."

merge m:1 PSID using "./data/shapefiles/regions_codes/patterns_plants_part1.dta"
drop _m

merge m:1 PSID using "./data/shapefiles/regions_codes/patterns_plants_part2.dta"
drop _m

merge m:1 PSID using "./data/shapefiles/regions_codes/patterns_plants_part3.dta"
drop _m

merge m:1 PSID using "./data/shapefiles/regions_codes/patterns_plants_part4.dta"
drop _m

gen i_harmonize_to_1988 = i_harmonize_to_1988_1 if i_harmonize_to_1988_1!=.
replace i_harmonize_to_1988 = i_harmonize_to_1988_2 if i_harmonize_to_1988_2!=.
replace i_harmonize_to_1988 = i_harmonize_to_1988_3 if i_harmonize_to_1988_3!=.
replace i_harmonize_to_1988 = i_harmonize_to_1988_4 if i_harmonize_to_1988_4!=.

preserve
drop if i_harmonize_to_1988==.
drop i_harmonize_to_1988_1 i_harmonize_to_1988_2 i_harmonize_to_1988_3 i_harmonize_to_1988_4
save "./data/firm-data/Indonesia_worldbank/maindata_clean_95perc.dta",replace
restore


*Deal with the rest!
preserve
keep if i_harmonize_to_1988==.
drop i_harmonize_to_1988_1 i_harmonize_to_1988_2 i_harmonize_to_1988_3 i_harmonize_to_1988_4
save "./data/firm-data/Indonesia_worldbank/maindata_dirty_5perc.dta", replace
restore









