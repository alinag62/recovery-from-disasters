* Harmonize all regions in WB data with Ishan's shapefile

*Open WB data
local path "/Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters"
use "`path'/data/firm-data/Indonesia_worldbank/maindata_v1.dta", clear

*Drop 2017 since it contains different PSIDs
drop if year==2017 

* clean
rename prov province_id_wb
rename DKABUP district_id_wb
gen id_wb = province_id + "-" +district_id

tempfile WB
save "`WB'"

*Open Ishan's dataset and merge
local path "/Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters"
use "`path'/data/firm-data/Indonesia/Final-Dataset/Indonesia_survey_readytoregress2.dta", clear

keep if year>=1988&year<=1995
merge 1:1 PSID year using "`WB'", force
keep if year>=1988&year<=1995
keep if _m==3
keep id_wb id_used year PSID
order PSID
reshape wide id_wb, i(PSID id_used) j(year) 
rename id_wb* id_*
egen nas = rmiss(id_*)
sort PSID nas
bys PSID: drop if _n>1

*I. Just PSID-id_used matching
keep PSID id_used
tempfile matched 
save "`matched'"
local path "/Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters"
use "`path'/data/firm-data/Indonesia_worldbank/maindata_v1.dta", clear
merge m:1 PSID using "`matched'"
keep if _m==3
drop _m
save "`path'/data/firm-data/Indonesia_worldbank/maindata_with_spatial_id_part1.dta", replace










*this doesn't give new info 
/*II. Using this dataset to actually find patterns in original IDs
duplicates drop id_used id_1995 id_1994 id_1993 id_1992 id_1991 id_1990 id_1989 id_1988, force
drop PSID nas
tempfile pattern 
save "`pattern'"

local path "/Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters"
use "`path'/data/firm-data/Indonesia_worldbank/maindata_v1.dta", clear

* clean
keep if year>=1988&year<=1995
rename prov province_id_wb
rename DKABUP district_id_wb
gen id_wb = province_id + "-" +district_id

* create a dataset that records all the changes
drop if id=="-"
drop if district_id==""
drop if district_id=="00"
drop if district_id=="."
keep PSID year id
reshape wide id, i(PSID) j(year) 
duplicates drop id*, force
rename id_wb* id_*

*merge with patterns from the other source
merge m:1 id_1995 id_1994 id_1993 id_1992 id_1991 id_1990 id_1989 id_1988 using "`pattern'"
keep if _m==3
keep PSID id_used
rename id_used id_used2
tempfile matched2
save "`matched2'"

*III. Match with original data 

local path "/Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters"
use "`path'/data/firm-data/Indonesia_worldbank/maindata_v1.dta", clear
merge m:1 PSID using "`matched'"
drop _m
merge m:1 PSID using "`matched2'"
















