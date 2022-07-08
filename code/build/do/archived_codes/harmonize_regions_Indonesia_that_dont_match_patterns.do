*Harmonizing Regions in Firm data

local path "/Users/alinagafanova/Library/CloudStorage/Box-Box/recovery-from-disasters"
cd `path'


use "./data/firm-data/Indonesia_worldbank/maindata_dirty_5perc.dta", clear
drop i_harmonize_to_1988
/*gen year2 = year
collapse (min) year (max) year2 , by(PSID id)
sort PSID year
bys PSID: gen n = _n
drop year*
reshape wide id, i(PSID) j(n)
sort id1

*Some of the plants have IDs that I cannot match with ANYTHING, and they don't look like obvious typos
* I cleaned all plants with 1 entry, so we can drop them
gen no_idea =.
replace no_idea = 1 if id2==.
drop if no_idea == 1 */

*The rest is probably migration
*Let's plot destination and origin migration on maps

bys PSID: gen N = _N
drop if N==1
sort PSID year*
bys PSID: gen n = _n
keep if n==1|n==N
gen origin = 1 if n==1
replace origin=0 if origin==.
gen dest = 1 if n!=1
replace dest=0 if dest==.

*kinda inaccurate match
rename id id1
tostring id1, replace
merge m:1 id1 year using "./data/firm-data/Indonesia/regions_codes/patterns_regions_with_no_change.dta"
drop if _m==2
replace i_harmonize_to_1988=85 if id1=="3278"&i_harmonize_to_1988==.
keep PSID i_harmonize_to_1988 year origin dest
drop if i_harmonize_to_1988==.

*merge with shapefile and plot
merge m:1 i_harmonize_to_1988 using "./data/firm-data/Indonesia/regions_codes/crosswalk_1988_2015_to_shp.dta"
keep if _m==3
drop _m
rename ADM2_id_in_shp_88 ADM2_id_in
tostring ADM2_id_in, replace
merge m:1 ADM2_id_in using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2.dta"
keep if _m==3
drop _m

collapse (count) PSID, by(_ID origin dest)
/*bys _ID: gen n = _n
fillin _ID n
sort _ID dest
bys _ID: replace dest = dest[_n-1]&dest==.
bys _ID: replace orig = orig[_n-1]&orig==.
replace dest = 0 if _fillin==1&dest==1 
replace dest = 1 if _fillin==1&dest==0
replace orig = 0 if _fillin==1&orig==1  
replace orig = 1 if _fillin==1&orig==0 */

merge m:1 _ID using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2.dta"
replace origin = 1 if origin ==.
replace dest = 1 if dest ==.

spmap PSID if origin==1 using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2_coordinates.dta", id(_ID) fcolor(Reds)  title("Destinations of Firms' Migration", size(*0.8)) 
spmap PSID if dest==1 using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2_coordinates.dta", id(_ID) fcolor(Reds)  title("Destinations of Firms' Migration", size(*0.8)) 



/*Track changes in Provinces, as well (not clean in data)


bys id1 id2: gen N = _N

sort N id1 id2

*Some of the plants have IDs that I cannot match with ANYTHING, and they don't look like obvious typos
* I cleaned all plants with 1 entry, so we can drop them
gen no_idea =.
replace no_idea = 1 if id2==.
drop if no_idea == 1



/*dummy for potential migration! (that makes sense based on locations)
gen migr = .
*from one part of Jakarta or its suburbs to another
replace migr=1 if id1==3275&id2==3271 
replace migr=1 if id1==3171&id2==3172
replace migr=1 if id1==3171&id2==3173
replace migr=1 if id1==3171&id2==3174
replace migr=1 if id1==3171&id2==3175
replace migr=1 if id1==3172&id2==3175 
replace migr=1 if id1==3172&id2==3174
replace migr=1 if id1==3172&id2==3173
replace migr=1 if id1==3172&id2==3171
replace migr=1 if id1==3173&id2==3171
replace migr=1 if id1==3173&id2==3172 
replace migr=1 if id1==3173&id2==3174 
replace migr=1 if id1==3173&id2==3175
replace migr=1 if id1==3174&id2==3175
replace migr=1 if id1==3174&id2==3173
replace migr=1 if id1==3174&id2==3171
replace migr=1 if id1==3174&id2==3172
replace migr=1 if id1==3175&id2==3172
replace migr=1 if id1==3175&id2==3173
replace migr=1 if id1==3175&id2==3174
replace migr=1 if id1==3175&id2==3171
drop if migr==1


*from BANDUNG to its capital
replace migr=1 if id1==3206&id2==3273 
drop if migr==1

*from Bogor to its capital
replace migr = 1 if id1==3203&id2==3271
drop if migr==1

*from Malang to its capital
replace migr = 1 if id1==3507&id2==3573
drop if migr==1

*from PEKALONGAN to its capital
replace migr = 1 if id1==3326&id2==3375
drop if migr==1


*between two regencies in Jambi (more questionable)
replace migr = 1 if id1==1503&id2==1504
drop if migr==1








