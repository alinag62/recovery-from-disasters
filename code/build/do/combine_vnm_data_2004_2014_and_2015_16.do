
cd /Users/alinagafanova/Library/CloudStorage/Box-Box/recovery-from-disasters/

*I. Get id-macs matching and check if it's unique
use "./data/firm-data/Vietnam/Vietnam_worldbank_data_larger_panel/VNM_2004_2014.dta", clear

keep ma_thue id

*keep unique pairs
duplicates drop
*check if each mac corresponds to unique firm
bys ma_thue: gen dup = _N-1
