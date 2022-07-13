* check if my region codes are the same as in official data

local path "/Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters"
cd `path'

*Crosswalk I created
use "./data/shapefiles/regions_codes/crosswalk_1988_2015.dta", clear


rename id_year2015 bps_2015
destring bps_2015, replace
merge 1:m bps_2015 using "./data/firm-data/Indonesia_worldbank/crosswalk_frame514_mar18_final.dta"
keep if _m==3
keep bps* id_year*
destring id_year*, replace

foreach year of num 1993/2009 {
	gen diff_`year' = (bps_`year'==id_year`year')
}

gen diff_2014 = (bps_2014==id_year2014)

egen sum = rowtotal(diff*)
drop if sum==18
sort sum
