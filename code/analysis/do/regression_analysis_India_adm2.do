/*
###########################################################################
                    Intro
########################################################################### */

cd /Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters

* Housekeeping
clear
clear matrix
set more off

local country India
local ID ID_2
local ID_in_survey id_used

local path2save_shake "./data/earthquakes/intermediate/India_adm2"
local firms_folder "./data/firm-data/India"
local path2shp_dta "./data/firm-data/India/Shapefile/IND_adm_shp/IND_adm2.dta"
local r2r_folder "./data/firm-data/clean-with-eq-ready-to-regress/"

*#############################################################################
set scheme plottig 
grstyle init
grstyle set imesh, horizontal minor
grstyle set ci 538, select(13 10) opacity(60)
grstyle set color "35 35 35" "35 35 35"  "62 102 206"  "62 102 206"
*#############################################################################

*#############################################################################
*0. Load and clean dataset
*#############################################################################

use "`firms_folder'/Final-Dataset/India_survey_readytoregress.dta", clear
keep if year>=1985&year<=2011
drop if panelID==.
rename id_used region
drop if region == .

tempfile survey
save "`survey'"  

use "`path2save_shake'/region_panel/panel_earthquakes_thresh_10.dta"
keep if year>=1975&year<=2011

rename region ID_2
merge m:1  ID_2 using "./data/firm-data/India/Shapefile/IND_adm_shp/IND_adm2.dta"
drop _m
rename ID_2 region
drop NAME_0 ID_0 ISO ID_1 NAME_1 HASC_2 CCN_2 CCA_2 TYPE_2 ENGTYPE_2 NL_NAME_2 VARNAME_2 _ID

*rename since the names are too long
rename populatedmpga_aw popmpga_aw
rename populatednum_qs_aw popnum_qs_aw
rename populatedmpga_aw10 popmpga_aw10
rename populatednum_qs_aw10 popnum_qs_aw10

*add lags
sort region year
foreach i of num 1/10 {
	foreach var in mpga_aw popmpga_aw urbanmpga_aw ruralmpga_aw num_qs_aw popnum_qs_aw urbannum_qs_aw ruralnum_qs_aw mpga_aw10 urbanmpga_aw10 ruralmpga_aw10 popmpga_aw10 num_qs_aw10 urbannum_qs_aw10 ruralnum_qs_aw10 popnum_qs_aw10 {
		by region: gen `var'_lag`i' = `var'[_n-`i']
		label var `var'_lag`i' "Lag `i'"
	}
}

foreach var in mpga_aw popmpga_aw urbanmpga_aw ruralmpga_aw num_qs_aw popnum_qs_aw urbannum_qs_aw ruralnum_qs_aw mpga_aw10 urbanmpga_aw10 ruralmpga_aw10 popmpga_aw10 num_qs_aw10 urbannum_qs_aw10 ruralnum_qs_aw10 popnum_qs_aw10 {
		label var `var' "`var'"
}

tempfile shaking
save "`shaking'"  


use "`survey'"
bys region year: gen firms_that_year_in_region = _N

merge m:1 region year using "`shaking'"
order panelID year region 
keep if _m==3

****************************************************
****************************************************
* Important notes on Indian data:
* a) 2008-2011 have only 1-3% of obs of other years
* b) there is a dummy called "open"
* c) some firms have reported data for multiple plants 
****************************************************
****************************************************

*keep only open plants
keep if open==1

*rename to not manipulate reg code
rename panelID plant

*new var
gen dom_sales = sales-exports
label var dom_sales "Domestic Sales"

*convert some vars to thousands 
gen wages_th = wages/1000
gen sales_th = sales/1000
gen tot_invent_eoy = stfgclose+ stsfgclose+ stmfsclose
gen tot_invent_eoy_th = tot_invent_eoy/1000
gen capital_th = capital/1000
gen exports_th = exports/1000

label var wages_th "Wages Total, in ths"
label var sales_th "Total Sales, in ths"
label var tot_invent_eoy "Total Inventories (end of the year)"
label var tot_invent_eoy_th "Total Inventories (end of the year), in ths"
label var capital_th "Total Assets Value, in ths"
label var exports_th "Total Exports, in ths"

*create logged vars
foreach dep in wages sales tot_invent_eoy capital exports labor output dom_sales {
	gen log_`dep' = log(`dep')
	local label_dep: var label `dep'
	label var log_`dep'`"Logged `label_dep'"' 
}

*create 1 diff of logs
sort plant year
foreach dep in wages sales tot_invent_eoy capital exports labor output dom_sales {
	bys plant:gen log_`dep'_diff = log_`dep'-log_`dep'[_n-1]
	
	local label_dep: var label `dep'
	label var log_`dep'_diff `"Logged `label_dep' (first difference)"' 
}

/* demeaning vars since running regressions is otherwise too slow
foreach var in log_wages_diff log_sales_diff log_tot_invent_eoy_diff log_capital_diff log_exports_diff log_labor_diff mpga_aw popmpga_aw urbanmpga_aw ruralmpga_aw num_qs_aw popnum_qs_aw urbannum_qs_aw ruralnum_qs_aw mpga_aw10 urbanmpga_aw10 ruralmpga_aw10 popmpga_aw10 num_qs_aw10 urbannum_qs_aw10 ruralnum_qs_aw10 popnum_qs_aw10 {
	egen mean_`var' = mean(`var'), by(plant)
	gen demeaned_`var' = `var'- mean_`var'
	
	local label_var: var label `var'
	label var demeaned_`var' "`label_var'"
	
}

foreach i of num 1/10 {
	foreach var in mpga_aw popmpga_aw urbanmpga_aw ruralmpga_aw num_qs_aw popnum_qs_aw urbannum_qs_aw ruralnum_qs_aw mpga_aw10 urbanmpga_aw10 ruralmpga_aw10 popmpga_aw10 num_qs_aw10 urbannum_qs_aw10 ruralnum_qs_aw10 popnum_qs_aw10 {
		bys plant: egen mean_`var'_lag`i' = mean(`var'_lag`i')
		gen demeaned_`var'_lag`i' = `var'_lag`i'- mean_`var'_lag`i'
	
		local label_var: var label `var'
		label var demeaned_`var' "`label_var'"
	}
}*/

xtset plant year

save `r2r_folder'/India_adm2_ready2regress_with_eq.dta, replace

*drop observations that don't have all 10 lags (balanced panel)
drop if mpga_aw_lag10==.

*#############################################################################
*1. Running regressions
*#############################################################################
/*local results_country ./output/regressions_tex/India_adm2

foreach var in mpga_aw populatedmpga_aw urbanmpga_aw ruralmpga_aw num_qs_aw populatednum_qs_aw urbannum_qs_aw ruralnum_qs_aw mpga_aw10 urbanmpga_aw10 ruralmpga_aw10 populatedmpga_aw10 num_qs_aw10 urbannum_qs_aw10 ruralnum_qs_aw10 populatednum_qs_aw10 {
	foreach dep in labor wages_th sales_th tot_invent_eoy_th capital_th exports_th {
		
		**********
		* Year and plant fixed effects; t=0 included
		**********

		eststo clear
		local treat `var'
		quietly: areg `dep' `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m0
		
		foreach i of num 1/10 {
		local treat `treat' `var'_lag`i'
		di("`treat'")
		quietly: areg `dep' `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m`i'
		}

		local results 
		foreach i of num 0/10 {
		local results `results' m`i'
		di("`results'")
		}

		esttab `results' using `results_country'/reg_year_plant_fe_`var'_`dep'.tex, se noconstant nomtitles title("India ADM2. Dependent variable: `: var label `dep''.") replace booktabs compress keep(`treat') addnotes("Year and plant fixed effects are included in each specification.")

		**********
		* Year and plant fixed effects; t=0 excluded
		**********

		eststo clear
		local treat
		foreach i of num 1/10 {
			local treat `treat ' `var'_lag`i'
			di("`treat'")
			quietly: areg `dep' `treat'  i.year, absorb(plant) vce(cluster plant)
			est sto m`i'
		}

		local results 
		foreach i of num 1/10 {
			local results `results' m`i'
			di("`results'")
		}

		esttab `results' using `results_country'/reg_year_plant_fe_no_t0_`var'_`dep'.tex, se noconstant nomtitles title("India ADM2. Dependent variable: `: var label `dep''.") replace booktabs compress keep(`treat') addnotes("Year and plant fixed effects are included in each specification.")

		**********
		* Year, district and plant fixed effects; t=0 included
		**********

		eststo clear 
		local treat `var'
		quietly: areg `dep' `treat'  i.year i.region, absorb(plant) vce(cluster plant)
		est sto m0
		
		foreach i of num 1/10 {
			local treat `treat ' `var'_lag`i'
			di("`treat'")
			quietly: areg `dep' `treat'  i.year i.region, absorb(plant) vce(cluster plant)
			est sto m`i'
		}

		local results 
		foreach i of num 0/10 {
			local results `results' m`i'
			di("`results'")
		}

		esttab `results' using `results_country'/reg_year_plant_district_fe_`var'_`dep'.tex, se noconstant nomtitles title("India ADM2. Dependent variable: `: var label `dep''.") replace booktabs compress keep(`treat') addnotes("Year, district and plant fixed effects are included in each specification.")

		**********
		* Year and plant fixed effects; t=0 included; region-specific time trend
		**********

		eststo clear
		local treat `var'
		quietly: areg `dep' `treat' i.year c.year##i.region, absorb(plant) vce(cluster plant)
		est sto m0
		
		foreach i of num 1/10 {
			local treat `treat ' `var'_lag`i'
			di("`treat'")
			quietly: areg `dep' `treat' i.year c.year##i.region, absorb(plant) vce(cluster plant)
			est sto m`i'
		}

		local results 
		foreach i of num 0/10 {
			local results `results' m`i'
			di("`results'")
		}

		esttab `results' using `results_country'/reg_year_plant_fe_district_trend_`var'_`dep'.tex, se noconstant nomtitles title("India ADM2. Dependent variable: `: var label `dep''.") replace booktabs compress keep(`treat') addnotes("Year and plant fixed effects are included in each specification. District-year linear trends are included.") 

		
	}
} */


/*running log-linear specification; first differences

local results_country ./output/regressions_tex/India_adm2/growth_rates

foreach var in mpga_aw popmpga_aw urbanmpga_aw ruralmpga_aw num_qs_aw popnum_qs_aw urbannum_qs_aw ruralnum_qs_aw mpga_aw10 urbanmpga_aw10 ruralmpga_aw10 popmpga_aw10 num_qs_aw10 urbannum_qs_aw10 ruralnum_qs_aw10 popnum_qs_aw10 {
	foreach dep in log_wages_diff log_sales_diff log_tot_invent_eoy_diff log_capital_diff log_exports_diff log_labor_diff {
		
		**********
		* Year and plant fixed effects; t=0 included
		**********

		eststo clear
		local treat demeaned_`var'
		di("`treat'")
		quietly: reg demeaned_`dep' `treat'  i.year, vce(cluster plant)
		est sto m0
		
		foreach i of num 1/10 {
		local treat `treat' demeaned_`var'_lag`i'
		di("`treat'")
		quietly: reg demeaned_`dep' `treat'  i.year, vce(cluster plant)
		est sto m`i'
		}

		local results 
		foreach i of num 0/10 {
		local results `results' m`i'
		di("`results'")
		}

		esttab `results' using `results_country'/reg_year_plant_fe_`var'_`dep'.tex, se noconstant nomtitles title("India ADM2. Dependent variable: `: var label `dep''.") replace booktabs label compress keep(`treat') addnotes("Year and plant fixed effects are included in each specification.")  


	
		/**********
		* Year and plant fixed effects; t=0 excluded
		**********

		eststo clear
		local treat
		foreach i of num 1/10 {
			local treat `treat ' `var'_lag`i'
			*di("`treat'")
			quietly: areg `dep' `treat'  i.year, absorb(plant) vce(cluster plant)
			est sto m`i'
		}

		local results 
		foreach i of num 1/10 {
			local results `results' m`i'
			*di("`results'")
		}

		esttab `results' using `results_country'/reg_year_plant_fe_no_t0_`var'_`dep'.tex, se noconstant nomtitles title("India ADM2. Dependent variable: `: var label `dep''.") replace booktabs label compress keep(`treat') addnotes("Year and plant fixed effects are included in each specification.")

		**********
		* Year, district and plant fixed effects; t=0 included
		**********

		eststo clear 
		local treat `var'
		quietly: areg `dep' `treat'  i.year i.region, absorb(plant) vce(cluster plant)
		est sto m0
		
		foreach i of num 1/10 {
			local treat `treat ' `var'_lag`i'
			*di("`treat'")
			quietly: areg `dep' `treat'  i.year i.region, absorb(plant) vce(cluster plant)
			est sto m`i'
		}

		local results 
		foreach i of num 0/10 {
			local results `results' m`i'
			*di("`results'")
		}

		esttab `results' using `results_country'/reg_year_plant_district_fe_`var'_`dep'.tex, se noconstant nomtitles title("India ADM2. Dependent variable: `: var label `dep''.") replace booktabs label compress keep(`treat') addnotes("Year, district and plant fixed effects are included in each specification.")

		**********
		* Year and plant fixed effects; t=0 included; region-specific time trend
		**********

		eststo clear
		local treat `var'
		quietly: areg `dep' `treat' i.year c.year##i.region, absorb(plant) vce(cluster plant)
		est sto m0
		
		foreach i of num 1/10 {
			local treat `treat ' `var'_lag`i'
			*di("`treat'")
			quietly: areg `dep' `treat' i.year c.year##i.region, absorb(plant) vce(cluster plant)
			est sto m`i'
		}

		local results 
		foreach i of num 0/10 {
			local results `results' m`i'
			*di("`results'")
		}

		esttab `results' using `results_country'/reg_year_plant_fe_district_trend_`var'_`dep'.tex, se noconstant nomtitles title("India ADM2. Dependent variable: `: var label `dep''.") replace booktabs label compress keep(`treat') addnotes("Year and plant fixed effects are included in each specification. District-year linear trends are included.")  */
		
	}
} */

local results_country ./output/regressions_tex/India_adm2/growth_rates

foreach var in mpga_aw popmpga_aw urbanmpga_aw ruralmpga_aw num_qs_aw popnum_qs_aw urbannum_qs_aw ruralnum_qs_aw mpga_aw10 urbanmpga_aw10 ruralmpga_aw10 popmpga_aw10 num_qs_aw10 urbannum_qs_aw10 ruralnum_qs_aw10 popnum_qs_aw10 {
	foreach dep in log_wages_diff log_sales_diff log_tot_invent_eoy_diff log_capital_diff log_exports_diff log_labor_diff log_output_diff log_dom_sales_diff {
		
		**********
		* Year and plant fixed effects; t=0 included
		**********

		eststo clear
		local treat `var'
		quietly: xtreg `dep' `treat'  i.year, fe vce(cluster plant)
		est sto m0
		
		foreach i of num 1/10 {
		local treat `treat' `var'_lag`i'
		di("`treat'")
		quietly: xtreg `dep' `treat'  i.year, fe vce(cluster plant)
		est sto m`i'
		}

		local results 
		foreach i of num 0/10 {
		local results `results' m`i'
		di("`results'")
		}

		esttab `results' using `results_country'/reg_year_plant_fe_`var'_`dep'.tex, se noconstant nomtitles title("India ADM2. Dependent variable: `: var label `dep''.") replace booktabs label compress keep(`treat') addnotes("Year and plant fixed effects are included in each specification.")  


	}
}







