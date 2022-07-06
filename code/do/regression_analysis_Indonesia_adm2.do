/*
###########################################################################
                    Intro
########################################################################### */
cd /Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters

* Housekeeping
clear
clear matrix
set more off

local path2save_shake "./data/earthquakes/intermediate/Indonesia_adm2"
local firms_folder "./data/firm-data/Indonesia"
local path2shp_dta "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2.dta"
local r2r_folder "./data/firm-data/clean-with-eq-ready-to-regress/"
local country Indonesia
local ID ID_2
local ID_in_survey id_used

*#############################################################################
set scheme plottig  
grstyle init
grstyle set imesh, horizontal minor
grstyle set ci 538, select(13 10) opacity(60)
grstyle set color "35 35 35" "35 35 35"  "62 102 206"  "62 102 206"

*#############################################################################
*0. Cleaning dataset
*#############################################################################

*################
*add labels from a different document
import excel "./data/firm-data/Indonesia/Final-Dataset/VarList-Whole.xls", sheet("Var List (SI Cross)") firstrow  clear
gen clean_var = substr(VAR_NEW, 2, .)
keep clean_var LABEL

tempname fh
local N = c(N)
di(`N')

// create a new do-file
file open `fh' using ./code/do/my_labels_IDN.do , write replace
forvalues i = 1/`N' {
	file write `fh' "cap " 
    file write `fh' "label variable `= clean_var[`i']' "
    file write `fh' `""`= LABEL[`i']'""' _newline
}
file close `fh'
type ./code/do/my_labels_IDN.do

use "`firms_folder'/Final-Dataset/`country'_survey_readytoregress.dta", clear
do ./code/do/my_labels_IDN.do
rm ./code/do/my_labels_IDN.do
*################

rename PSID plant
order plant year

tempfile survey
save "`survey'"

use "`path2save_shake'/region_panel/panel_earthquakes_thresh_10.dta", clear

rename region ID_2
merge m:1  ID_2 using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2.dta"
drop _m
rename ID_2 region
drop NAME_0 ID_0 ISO ID_1 NAME_1 HASC_2 CCN_2 CCA_2 TYPE_2 ENGTYPE_2 VARNAME_2 _ID

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
rename id_used region
bys region year: gen firms_that_year_in_region = _N

*get final dataset
merge m:1 region year using "`shaking'"
order plant year region
keep if _m==3

rename LTLNOU labor
rename FTTLCU tot_invest
rename STDVCU tot_invent_eoy
rename OUTPUT output
rename V1104 bldings_val
rename V1116 capital
*rename YPRVCU goods_prod
gen exports = output*(PRPREX/100) if PRPREX!=.&PRPREX<=100

label var exports "Goods Exported"

*convert some vars to thousands 
gen tot_invest_th = tot_invest/1000
gen tot_invent_eoy_th = tot_invent_eoy/1000
gen wages = (ZPDCCU+ ZPDKCU+ ZNDCCU+ ZNDKCU)
gen wages_th = (ZPDCCU+ ZPDKCU+ ZNDCCU+ ZNDKCU)/1000
gen bldings_val_th = bldings_val/1000
gen capital_th = capital/1000

label var tot_invest_th "Total Investment, in ths"
label var tot_invent_eoy_th "Total Inventories (end of the year), in ths"
label var wages_th "Wages Total, in ths"
label var capital_th "Total Assets Book Value, in ths"
label var bldings_val_th "Book Value of Buildings and Structures, in ths"

*create logged vars
foreach dep in labor tot_invest tot_invent_eoy capital bldings_val output wages exports{
	gen log_`dep' = log(`dep')
	local label_dep: var label `dep'
	label var log_`dep'`"Logged `label_dep'"' 
}

*create 1 diff of logs
sort plant year
foreach dep in labor tot_invest tot_invent_eoy capital bldings_val output wages exports{
	bys plant: gen log_`dep'_diff = log_`dep'-log_`dep'[_n-1]
	
	local label_dep: var label `dep'
	label var log_`dep'_diff `"Logged `label_dep' (first difference)"' 
}

*create logged vars with constant if 0
foreach dep in labor tot_invest tot_invent_eoy capital bldings_val output wages exports{
	gen log_`dep'_const = log(`dep'+0.001)
}

*create 1 diff of logs with constant if 0
sort plant year
foreach dep in labor tot_invest tot_invent_eoy capital bldings_val output wages exports{
	bys plant: gen log_`dep'_diff_const = log_`dep'_const-log_`dep'_const[_n-1]
}

*enumerate all observation years before dropping them
bys plant: gen n = _n

save `r2r_folder'/Indonesia_adm2_ready2regress_with_eq.dta, replace

*drop observations that don't have all 10 lags (balanced panel)
keep if mpga_aw_lag10!=.

*#############################################################################*/
*1. Running regressions
*#############################################################################

* Levels regression
/*local results_country ./output/regressions_tex/Indonesia_adm2/levels

foreach var in mpga_aw populatedmpga_aw urbanmpga_aw ruralmpga_aw num_qs_aw populatednum_qs_aw urbannum_qs_aw ruralnum_qs_aw mpga_aw10 urbanmpga_aw10 ruralmpga_aw10 populatedmpga_aw10 num_qs_aw10 urbannum_qs_aw10 ruralnum_qs_aw10 populatednum_qs_aw10 {
	foreach dep in labor tot_invest_th tot_invent_th wage_tot_th output_th capital_th bldings_val_th {
		
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


*running log-linear specification; dep variable in growth rates

local results_country ./output/regressions_tex/Indonesia_adm2/growth_rates

foreach var in mpga_aw popmpga_aw urbanmpga_aw ruralmpga_aw num_qs_aw popnum_qs_aw urbannum_qs_aw ruralnum_qs_aw mpga_aw10 urbanmpga_aw10 ruralmpga_aw10 popmpga_aw10 num_qs_aw10 urbannum_qs_aw10 ruralnum_qs_aw10 popnum_qs_aw10 {		
	foreach dep in log_labor_diff log_tot_invest_diff log_tot_invent_eoy_diff log_capital_diff log_bldings_val_diff log_output_diff log_wages_diff log_exports_diff {
		
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

		esttab `results' using `results_country'/reg_year_plant_fe_`var'_`dep'.tex, se noconstant nomtitles title("Indonesia ADM2. Dependent variable: `: var label `dep''.") replace booktabs label compress keep(`treat') addnotes("Year and plant fixed effects are included in each specification.")  


	
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

		esttab `results' using `results_country'/reg_year_plant_fe_no_t0_`var'_`dep'.tex, se noconstant nomtitles title("Indonesia ADM2. Dependent variable: `: var label `dep''.") replace booktabs label compress keep(`treat') addnotes("Year and plant fixed effects are included in each specification.")

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

		esttab `results' using `results_country'/reg_year_plant_district_fe_`var'_`dep'.tex, se noconstant nomtitles title("Indonesia ADM2. Dependent variable: `: var label `dep''.") replace booktabs label compress keep(`treat') addnotes("Year, district and plant fixed effects are included in each specification.")

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

		esttab `results' using `results_country'/reg_year_plant_fe_district_trend_`var'_`dep'.tex, se noconstant nomtitles title("Indonesia ADM2. Dependent variable: `: var label `dep''.") replace booktabs label compress keep(`treat') addnotes("Year and plant fixed effects are included in each specification. District-year linear trends are included.")  
	}*/
	
} 










