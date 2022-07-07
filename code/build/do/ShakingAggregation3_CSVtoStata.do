/*
###########################################################################
 0)                     Intro
########################################################################### */

* Housekeeping
clear
clear matrix
set more off

local pathbuilt $path2save_shake

/*
###########################################################################
                 *Save csv files as dta file
########################################################################### */


global filelist : dir "`pathbuilt'/region_csvs/" files "*.csv"

foreach file in $filelist {
	insheet using "`pathbuilt'/region_csvs/`file'", clear name
	local name = substr("`file'", 1, strlen("`file'") - 4)
	save "`pathbuilt'/region_dtas/`name'.dta", replace
} 
