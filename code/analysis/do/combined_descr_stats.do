* Descriptive Tables: all countries
* Using the original data with few changes

/*
###########################################################################
                    Intro
########################################################################### */

cd /Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters

/*
###########################################################################
I. Zero amd missing values
########################################################################### */

clear
gen country = ""
tempfile empty 
save "`empty'"

local r2r_folder "./data/firm-data/clean-with-eq-ready-to-regress/"

foreach country in Indonesia Colombia India {
	use `r2r_folder'/`country'_adm2_ready2regress_with_eq.dta, clear
	
	cap: rename tot_invent_eoy tot_invent
	
	gen N = _N
	
	*check which vars exist
	isvar labor wages tot_invent capital output exports dom_sales tot_invest bldings_val 
	local vars `r(varlist)'
	keep `vars' N
	
	foreach var in `vars' {

		* missing values
		gen missing_`var' = 0
		replace missing_`var' = 1 if `var' == .		
		
		* value==0
		gen zero_`var' = 0
		replace zero_`var' = 1 if `var' == 0
	}
	
	
	gen country = "`country'"
	collapse (sum) missing_* zero_* (first) N, by(country)
	
	local list_miss_shares ""
	local list_zero_shares ""
	
	foreach var in `vars' {
		local list_miss_shares `list_miss_shares' share_missing_`var'
		gen share_missing_`var' = missing_`var'/N
		
		local list_zero_shares `list_zero_shares' share_zero_`var'
		gen non_missing_`var' = N - missing_`var'
		gen share_zero_`var' = zero_`var'/non_missing_`var'
		
		drop missing_`var' non_missing_`var' zero_`var'
	}
	
	append using "`empty'"
	
	tempfile empty 
	save "`empty'"
	
}

label var share_missing_labor "Labor"
label var share_missing_wages "Wages"
label var share_missing_tot_invent "Inventories"
label var share_missing_capital "Capital"
label var share_missing_output "Output"
label var share_missing_exports "Exports"
label var share_missing_dom_sales "Domestic Sales"
label var share_missing_tot_invest "Investment"
label var share_missing_bldings_val "Buildings Value"
label var share_zero_labor "Labor"
label var share_zero_wages "Wages"
label var share_zero_tot_invent "Inventories"
label var share_zero_capital "Capital"
label var share_zero_output "Output"
label var share_zero_exports "Exports"
label var share_zero_dom_sales "Domestic Sales"
label var share_zero_tot_invest "Investment"
label var share_zero_bldings_val "Buildings Value"             

order country N share_missing* share_zero*
order country N share_zero* 

/*
###########################################################################
II. Variables - by year
########################################################################### */











