
cd /Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters

* Housekeeping
clear
clear matrix
set more off

*import delimited "/Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters/data/firm-data/Vietnam/Vietnam_worldbank_data/gov_ids.csv", encoding(UTF-8) clear 
*save "/Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters/data/firm-data/Vietnam/Vietnam_worldbank_data/gov_ids.dta", replace

use "./data/firm-data/Vietnam/Vietnam_worldbank_data/VTN spatial 2007-2013.dta", clear
destring huyen, replace

*splits and merges of regions
replace huyen = 833 if huyen==838
replace huyen = 723 if huyen==726
replace huyen = 721 if huyen==719
replace huyen = 697 if huyen==690|huyen==694
replace huyen = 691 if huyen==688
replace huyen = 925 if huyen==927
replace huyen = 649 if huyen==644
replace huyen = 870 if huyen==868
replace huyen = 103 if huyen==96|huyen==97
replace huyen = 633 if huyen==639
replace huyen = 623 if huyen==634
replace huyen = 19 if huyen==21
replace huyen = 902 if huyen==914
replace huyen = 107 if huyen==108|huyen==112
replace huyen = 110 if huyen==111
replace huyen = 798 if huyen==795
replace huyen = 421 if huyen==432
replace huyen = 589 if huyen==589
replace huyen = 454 if huyen==458
replace huyen = 944 if huyen==942
replace huyen = 946 if huyen==947|huyen==951
replace huyen = 123 if huyen==128
replace huyen = 820 if huyen==817
replace huyen = 823 if huyen==huyen==824|huyen==825
replace huyen = 73 if huyen==71|huyen==72
replace huyen = 246 if huyen==253
replace huyen = 936 if huyen==937
replace huyen = 850 if huyen==851
replace huyen = 447 if huyen==449
replace huyen = 691 if huyen==698

rename huyen district_id 
merge m:1 district_id using "./data/firm-data/Vietnam/Vietnam_worldbank_data/gov_ids.dta"
keep if _m==3
drop _m district_name district_muni pop dens area
drop level1 level2 level3 districtenglishcharacters district_code province_code

tempfile firms
save "`firms'"

*open shapefile
*shp2dta using "./data/firm-data/Vietnam/gadm36_VNM_shp/VNM_adm2.shp", database("./data/firm-data/Vietnam/gadm36_VNM_shp/VNM_adm2.dta") coord("./data/firm-data/Vietnam/gadm36_VNM_shp/VNM_adm2_coordinates.dta")
use "./data/firm-data/Vietnam/gadm36_VNM_shp/VNM_adm2.dta", clear

rename NAME_2 district
rename NAME_1 province 
keep province district _ID ID_2

replace district =subinstr(district,"Quận ","",.)
merge 1:m district province using "`firms'"

*we can add a polygon for 1 island later
keep if _m==3 
drop _m

save "./data/firm-data/Vietnam/Vietnam_worldbank_data/firms_VNM_clean.dta", replace




