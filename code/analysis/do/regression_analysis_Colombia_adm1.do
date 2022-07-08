*#############################################################################
cd /Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters

* Housekeeping
clear
clear matrix
set more off

local path2save_shake "./data/earthquakes/intermediate/Colombia_adm1"
local firms_folder "./data/firm-data/Colombia"
local r2r_folder "./data/firm-data/clean-with-eq-ready-to-regress/"
local country Colombia
local ID ID_2
local ID_in_survey id_used

*#############################################################################
set scheme plottig 
grstyle init
grstyle set imesh, horizontal minor
grstyle set ci 538, select(13 10) opacity(60)
grstyle set color "35 35 35" "35 35 35"  "62 102 206"  "62 102 206"

*#############################################################################
*0. Load and clean dataset
*#############################################################################
use "`path2save_shake'/region_panel/panel_earthquakes_thresh_10.dta", clear

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

rename region region_adm1
tempfile shaking
save "`shaking'"

*merge shaking with firm data 
use "`firms_folder'/Final-Dataset/`country'_survey_readytoregress.dta"
rename id_used_adm1 region_adm1
bys region_adm1 year: gen firms_that_year_in_region = _N
merge m:1 region_adm1 year using "`shaking'"  
rename id_used region_adm2
keep if _m==3
drop _m

rename wage_tot wages
rename tot_emp labor
rename totasst_val capital
rename prod_val output
rename tot_sales sales
rename netinv_val tot_invest

*convert some vars to thousands
gen wages_th = wages/1000
gen sales_th = sales/1000
gen tot_invent_eoy_th = tot_invent_eoy/1000
gen capital_th = capital/1000
gen exports_th = exports/1000
gen bldings_val_th = bldings_val/1000
gen tot_invest_th = tot_invest/1000


label var wages_th "Wages Total, in ths"
label var sales_th "Total Sales, in ths"
label var tot_invent_eoy_th "Total Inventories (end of the year), in ths"
label var capital_th "Total Assets Value, in ths"
label var exports_th "Total Exports, in ths"
label var bldings_val_th "Book Value of Buildings and Structures, in ths"
label var tot_invest_th "Total Net Investment, in ths"


*create logged vars
foreach dep in labor wages tot_invent_eoy capital exports bldings_val tot_invest output dom_sales sales {
	gen log_`dep' = log(`dep')
	local label_dep: var label `dep'
	label var log_`dep'`"Logged `label_dep'"' 
}

*create 1 diff of logs
sort plant year
foreach dep in labor wages tot_invent_eoy capital exports bldings_val tot_invest output dom_sales sales {
	bys plant:gen log_`dep'_diff = log_`dep'-log_`dep'[_n-1]
	local label_dep: var label `dep'
	label var log_`dep'_diff `"Logged `label_dep' (first difference)"' 
}

*change again to region to not rename it in the rest of the code that i copied from adm2
rename region_adm1 region 

save `r2r_folder'/Colombia_adm1_ready2regress_with_eq.dta, replace

*drop observations that don't have all 10 lags (balanced panel)
drop if mpga_aw_lag10==.

*#############################################################################
*1. Running regressions
*#############################################################################

/*local results_country ./output/regressions_tex/Colombia_adm1/levels

foreach var in mpga_aw popmpga_aw urbanmpga_aw ruralmpga_aw num_qs_aw popnum_qs_aw urbannum_qs_aw ruralnum_qs_aw mpga_aw10 urbanmpga_aw10 ruralmpga_aw10 popmpga_aw10 num_qs_aw10 urbannum_qs_aw10 ruralnum_qs_aw10 popnum_qs_aw10 {
	foreach dep in tot_emp wage_tot_th tot_invent_eoy_th totasst_val_th tot_sales_th exports_th bldings_val_th {
		
		**********
		* Year and plant fixed effects; t=0 included
		**********

		eststo clear
		local treat `var'
		quietly: areg `dep' `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m0
		
		foreach i of num 1/10 {
		local treat `treat' `var'_lag`i'
		*di("`treat'")
		quietly: areg `dep' `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m`i'
		}

		local results 
		foreach i of num 0/10 {
		local results `results' m`i'
		*di("`results'")
		}

		esttab `results' using `results_country'/reg_year_plant_fe_`var'_`dep'.tex, se noconstant nomtitles title("Colombia ADM1. Dependent variable: `: var label `dep''.") replace booktabs compress keep(`treat') addnotes("Year and plant fixed effects are included in each specification.")

		**********
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

		esttab `results' using `results_country'/reg_year_plant_fe_no_t0_`var'_`dep'.tex, se noconstant nomtitles title("Colombia ADM1. Dependent variable: `: var label `dep''.") replace booktabs compress keep(`treat') addnotes("Year and plant fixed effects are included in each specification.")

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

		esttab `results' using `results_country'/reg_year_plant_district_fe_`var'_`dep'.tex, se noconstant nomtitles title("Colombia ADM1. Dependent variable: `: var label `dep''.") replace booktabs compress keep(`treat') addnotes("Year, district and plant fixed effects are included in each specification.")

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

		esttab `results' using `results_country'/reg_year_plant_fe_district_trend_`var'_`dep'.tex, se noconstant nomtitles title("Colombia ADM1. Dependent variable: `: var label `dep''.") replace booktabs compress keep(`treat') addnotes("Year and plant fixed effects are included in each specification. District-year linear trends are included.") 

		
	}
} */

*running log-linear specification

/*local results_country ./output/regressions_tex/Colombia_adm1/logs

foreach var in mpga_aw popmpga_aw urbanmpga_aw ruralmpga_aw num_qs_aw popnum_qs_aw urbannum_qs_aw ruralnum_qs_aw mpga_aw10 urbanmpga_aw10 ruralmpga_aw10 popmpga_aw10 num_qs_aw10 urbannum_qs_aw10 ruralnum_qs_aw10 popnum_qs_aw10 {
	foreach dep in log_tot_emp log_wage_tot log_tot_invent_eoy log_totasst_val  log_exports log_bldings_val {
		
		**********
		* Year and plant fixed effects; t=0 included
		**********

		eststo clear
		local treat `var'
		quietly: areg `dep' `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m0
		
		foreach i of num 1/10 {
		local treat `treat' `var'_lag`i'
		*di("`treat'")
		quietly: areg `dep' `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m`i'
		}

		local results 
		foreach i of num 0/10 {
		local results `results' m`i'
		*di("`results'")
		}

		esttab `results' using `results_country'/reg_year_plant_fe_`var'_`dep'.tex, se noconstant nomtitles title("Colombia ADM1. Dependent variable: `: var label `dep''.") replace booktabs label compress keep(`treat') addnotes("Year and plant fixed effects are included in each specification.")

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

		esttab `results' using `results_country'/reg_year_plant_fe_no_t0_`var'_`dep'.tex, se noconstant nomtitles title("Colombia ADM1. Dependent variable: `: var label `dep''.") replace booktabs compress keep(`treat') addnotes("Year and plant fixed effects are included in each specification.")

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

		esttab `results' using `results_country'/reg_year_plant_district_fe_`var'_`dep'.tex, se noconstant nomtitles title("Colombia ADM1. Dependent variable: `: var label `dep''.") replace booktabs compress keep(`treat') addnotes("Year, district and plant fixed effects are included in each specification.")

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

		esttab `results' using `results_country'/reg_year_plant_fe_district_trend_`var'_`dep'.tex, se noconstant nomtitles title("Colombia ADM1. Dependent variable: `: var label `dep''.") replace booktabs compress keep(`treat') addnotes("Year and plant fixed effects are included in each specification. District-year linear trends are included.")  */

		
	}
} */


/*running log-linear specification; first differences

local results_country ./output/regressions_tex/Colombia_adm1/growth_rates

foreach var in mpga_aw popmpga_aw urbanmpga_aw ruralmpga_aw num_qs_aw popnum_qs_aw urbannum_qs_aw ruralnum_qs_aw mpga_aw10 urbanmpga_aw10 ruralmpga_aw10 popmpga_aw10 num_qs_aw10 urbannum_qs_aw10 ruralnum_qs_aw10 popnum_qs_aw10 {
	foreach dep in log_tot_emp_diff log_wage_tot_diff log_tot_invent_eoy_diff log_totasst_val_diff  log_exports_diff log_bldings_val_diff {
		
		**********
		* Year and plant fixed effects; t=0 included
		**********

		eststo clear
		local treat `var'
		quietly: areg `dep' `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m0
		
		foreach i of num 1/10 {
		local treat `treat' `var'_lag`i'
		*di("`treat'")
		quietly: areg `dep' `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m`i'
		}

		local results 
		foreach i of num 0/10 {
		local results `results' m`i'
		*di("`results'")
		}

		esttab `results' using `results_country'/reg_year_plant_fe_`var'_`dep'.tex, se noconstant nomtitles title("Colombia ADM1. Dependent variable: `: var label `dep''.") replace booktabs label compress keep(`treat') addnotes("Year and plant fixed effects are included in each specification.")  


	
		**********
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

		esttab `results' using `results_country'/reg_year_plant_fe_no_t0_`var'_`dep'.tex, se noconstant nomtitles title("Colombia ADM1. Dependent variable: `: var label `dep''.") replace booktabs label compress keep(`treat') addnotes("Year and plant fixed effects are included in each specification.")

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

		esttab `results' using `results_country'/reg_year_plant_district_fe_`var'_`dep'.tex, se noconstant nomtitles title("Colombia ADM1. Dependent variable: `: var label `dep''.") replace booktabs label compress keep(`treat') addnotes("Year, district and plant fixed effects are included in each specification.")

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

		esttab `results' using `results_country'/reg_year_plant_fe_district_trend_`var'_`dep'.tex, se noconstant nomtitles title("Colombia ADM1. Dependent variable: `: var label `dep''.") replace booktabs label compress keep(`treat') addnotes("Year and plant fixed effects are included in each specification. District-year linear trends are included.")  
	}
} */



local results_country ./output/regressions_tex/Colombia_adm1/growth_rates

foreach var in mpga_aw popmpga_aw urbanmpga_aw ruralmpga_aw num_qs_aw popnum_qs_aw urbannum_qs_aw ruralnum_qs_aw mpga_aw10 urbanmpga_aw10 ruralmpga_aw10 popmpga_aw10 num_qs_aw10 urbannum_qs_aw10 ruralnum_qs_aw10 popnum_qs_aw10 {
	foreach dep in log_tot_invest_diff log_output_diff log_dom_sales_diff log_sales_diff {
		
		**********
		* Year and plant fixed effects; t=0 included
		**********

		eststo clear
		local treat `var'
		quietly: areg `dep' `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m0
		
		foreach i of num 1/10 {
		local treat `treat' `var'_lag`i'
		*di("`treat'")
		quietly: areg `dep' `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m`i'
		}

		local results 
		foreach i of num 0/10 {
		local results `results' m`i'
		*di("`results'")
		}

		esttab `results' using `results_country'/reg_year_plant_fe_`var'_`dep'.tex, se noconstant nomtitles title("Colombia ADM1. Dependent variable: `: var label `dep''.") replace booktabs label compress keep(`treat') addnotes("Year and plant fixed effects are included in each specification.")  


	
		**********
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

		esttab `results' using `results_country'/reg_year_plant_fe_no_t0_`var'_`dep'.tex, se noconstant nomtitles title("Colombia ADM1. Dependent variable: `: var label `dep''.") replace booktabs label compress keep(`treat') addnotes("Year and plant fixed effects are included in each specification.")

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

		esttab `results' using `results_country'/reg_year_plant_district_fe_`var'_`dep'.tex, se noconstant nomtitles title("Colombia ADM1. Dependent variable: `: var label `dep''.") replace booktabs label compress keep(`treat') addnotes("Year, district and plant fixed effects are included in each specification.")

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

		esttab `results' using `results_country'/reg_year_plant_fe_district_trend_`var'_`dep'.tex, se noconstant nomtitles title("Colombia ADM1. Dependent variable: `: var label `dep''.") replace booktabs label compress keep(`treat') addnotes("Year and plant fixed effects are included in each specification. District-year linear trends are included.")  
	}
} 



































