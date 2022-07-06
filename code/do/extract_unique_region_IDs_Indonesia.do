local path "/Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters"
use "`path'/data/firm-data/Indonesia/Final-Dataset/Indonesia_survey_readytoregress2.dta", clear

keep province_name province_id id_used district_name district_id

tostring province_id, replace
tostring  district_id, replace

replace district_id = string(real(district_id),"%02.0f")

duplicates drop

save "/Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters/data/firm-data/Indonesia/Final-Dataset/Indonesia_unique_IDs.dta", replace
