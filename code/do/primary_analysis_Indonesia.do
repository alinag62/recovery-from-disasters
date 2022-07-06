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
*Part 0. Add labels from a different file
*#############################################################################
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

use "`firms_folder'/Final-Dataset/`country'_survey_readytoregress2.dta", clear
do ./code/do/my_labels_IDN.do
rm ./code/do/my_labels_IDN.do


*#############################################################################
*Part I. Analysing the survey
*#############################################################################
rename PSID plant
order plant year





tempfile survey
save "`survey'"

*#############################################################################*/
*Part II. Analysing the shaking data
*#############################################################################

use "`path2save_shake'/region_panel/panel_earthquakes_thresh_10.dta", clear
rename region ID_2
merge m:1  ID_2 using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2.dta"
rename ID_2 region 
drop _m

*create lags
sort region year
foreach i of num 1/10 {
	by region: gen mpga_aw_lag`i' = mpga_aw[_n-`i']
	by region: gen num_qs_aw_lag`i' = num_qs_aw[_n-`i']
}

*number of years when shaking occurs
gen shaking_year = 0
replace shaking_year = 1 if num_qs_aw>0
bys region: egen years_shaking = total(shaking_year)
label var years_shaking "Years with shaking (from 31)"

*top and bottom regions
preserve
collapse (mean) mpga_aw, by(region)
egen bottom_1_shaking = pctile(mpga_aw), p(1)
egen top_3_shaking = pctile(mpga_aw), p(97)
keep if (mpga_aw>=top_3_shaking)|(mpga_aw<=bottom_1_shaking)
bys mpga_aw: drop if _n>6
keep region
tempfile ranking
save "`ranking'" 
restore

/*a few maps with sum stats
preserve
bys region: drop if _n>1
rename region ID_2
replace years_shaking=. if years_shaking==0
spmap years_shaking using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2_coordinates.dta",   id(_ID) fcolor(Reds) clnumber(7) legend(label(1 "No shaking") label(2 "1 year with earthquakes") label(3 "2 years with earthquakes") label(4 "3 years with earthquakes") label(5 "4-9 years with earthquakes")) title("Years with earthquakes from 31 years", size(*0.7))
graph export "./output/Indonesia/fig2_IDN.png", as(png) replace
restore  

preserve
rename region ID_2
merge m:1  ID_2 using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2.dta"
collapse (mean) mpga_aw, by(ID_2 _ID)
replace mpga_aw=. if mpga_aw==0
spmap mpga_aw using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2_coordinates.dta", id(_ID) fcolor(Oranges) legend(label(1 "No shaking" ) size(vsmall)) title("Mean mpga_aw for 31 years", size(*0.7))
graph export "./output/Indonesia/fig3_IDN.png", as(png) replace
restore 
*/

*plot distribution of shaking by years in regions with firm data
*graph bar (sum) shaking_year, over(year) ytitle("Regions with Shaking")



/*plot distribution of shaking by years in regions with firm data
graph bar (sum) shaking_year, over(year,label(angle(45))) ytitle("Regions with Shaking") 
graph export "./output/Indonesia/fig5_IDN.png", as(png) replace*/


/* maps of exposure by year, animation
preserve
rename region ID_2
replace mpga_aw=. if mpga_aw==0
forval year = 1973/1995 {
	spmap mpga_aw if year==`year' using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2_coordinates.dta", id(_ID) clm(c) clb(0 0.1 0.5 1 2 41) fcolor(Reds) legend(label(1 "No shaking")) title(`year', size(*0.8))
	graph export "./output/Indonesia/gif_mpga_aw_`year'.png", as(png) width(3000) replace
}
restore

preserve
rename region ID_2
replace num_qs_aw=. if num_qs_aw==0
forval year = 1973/1995 {
	spmap num_qs_aw if year==`year' using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2_coordinates.dta", id(_ID) clm(c) clb(0 0.1 0.2 0.5 0.75 1 2) fcolor(Reds) legend(label(1 "No shaking")) title(`year', size(*0.8))
	graph export "./output/Indonesia/gif_num_qs_aw_`year'.png", as(png) width(3000) replace
}
restore */


tempfile shaking
save "`shaking'"  



*#############################################################################
*Part III. Analysing survey+shaking
*#############################################################################

use "`survey'"
rename id_used region
bys region year: gen firms_that_year_in_region = _N

merge m:1 region year using "`shaking'"
order plant year region 


*drop regions that have no firm data
gen region_in_survey = region if _m==3
gen keep = .
levelsof region_in_survey, local(keep)
foreach num in `keep' {
	replace keep = 1 if region==`num'
}
keep if keep==1
drop _m

*rename a few varibables since the names are really hard to understand
rename LTLNOU labor
rename FTTLCU tot_invest
rename STDVCU tot_invent_eoy
rename OUTPUT tot_output
rename V1104 bldings_val
rename V1116 capital
rename YPRVCU output
gen exports = output*(PRPREX/100) if PRPREX!=.&PRPREX<=100
rename EELVCU elec
gen wages = (ZPDCCU+ ZPDKCU+ ZNDCCU+ ZNDKCU)

*create logged vars
foreach dep in labor tot_invest tot_invent_eoy capital tot_output bldings_val wages exports output{
	gen log_`dep' = log(`dep')
	local label_dep: var label `dep'
	label var log_`dep'`"Logged `label_dep'"' 
}

*Descriptive stats for plants in EQ years vs not
gen EQ_happened = 0
replace EQ_happened = 1 if num_qs_aw!=0&num_qs_aw!=.
preserve
gen i = 1
keep if tot_output !=.
collapse (first)  EQ_happened (count) i, by(region year)
bys region: egen EQ_ever = max(EQ_happened)
drop if EQ_ever==0
twoway  (spike EQ_happened year, yaxis(2) lwidth(1) lcolor( "62 102 206")) (connected i year, yaxis(1)) if region==274, yline(0, axis(2) lcolor( "62 102 206")) legend(position(6)) title("Region `var'")

restore

/* plot regions' maps
preserve
bys region: drop if _n>1
rename region ID_2
merge m:1  ID_2 using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2.dta"
spmap _m using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2_coordinates.dta",  fcolor( white midgreen) id(_ID) legend(label(2 "No firm data in the survey" )  label(3 "Firms in the survey") size(vsmall))
graph export "./output/Indonesia/fig1_IDN.png", as(png) replace
restore 
*/

/*add ranking of outlying regions and plot raw data
preserve
gen for_graphs = .
merge m:1 region using "`ranking'"
gen reg_ranked = region if _m==3
recast int reg_ranked
levelsof reg_ranked, local(reg_ranked)
foreach num in `reg_ranked' {
	di(`num')
	replace for_graphs = 1 if region==`num'
}

keep if for_graphs==1
collapse (first) mpga_aw (mean) tot_emp tot_output tot_inv elec, by(region year)
label var mpga_aw "Area-weighted average of maximum PGA in the region"
label var tot_inv "Average Total Investment"
label var tot_emp "Average Total Employment"
label var tot_output "Average Total Output"
label var elec "Average Total Electricity (KW: prod+purch+sold)"

levelsof region, local(reg_num)
foreach val in tot_inv tot_emp tot_output elec {
	foreach var in `reg_num' {
	twoway (connected `val' year, yaxis(1)) (spike mpga_aw year, yaxis(2) lwidth(1) lcolor( "62 102 206")) if region==`var', yline(0, axis(2) lcolor( "62 102 206")) legend(position(6)) title("Region `var'")
	graph export "./output/Indonesia/fig_IDN_reg`var'_`val'_aggregated.png", as(png) replace
	}
}


restore*/

/*histograms for shaking-exposed regions during no shaking and years after shaking; drop top 5%
egen tot_emp_pct95  = pctile(tot_emp), p(95)
egen tot_output_pct95  = pctile(tot_output), p(95)
egen tot_inv_pct95 = pctile(tot_inv), p(95)
egen elec_pct95  = pctile(elec), p(95)

*I take random districts (with many observations)
foreach val in tot_emp tot_output tot_inv elec {
	preserve
	drop if `val'>=`val'_pct95
	
	foreach var in 6039 83 102 151 90 171 346 {

	twoway (hist `val' if mpga_aw_lag1>0&region==`var', color(red%30)) (hist `val' if mpga_aw_lag1==0&region==`var', color(blue%30) ) ,  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "Years after years with shaking" 2 "Years after no-shaking years" ) position(6)) title("Region `var'")
	graph export "./output/Indonesia/fig_IDN_reg`var'_`val'_overl_hist_lag1.png", as(png) replace
	
	}
	restore
} */


*plots: distributions over the whole country

*plants affected by EQs in panel
gen EQ_lag1 = 0
replace EQ_lag1 = 1 if num_qs_aw_lag1!=0&num_qs_aw_lag1!=.
bys plant: egen EQ_lag1_total = total(EQ_lag1)
drop if plant==.
 
/*preserve

drop if  EQ_lag1_total==0

* LABOR
label var log_labor `"Logged Total Number of Workers"' 

sum log_labor if EQ_lag1 == 0
local mean_no_EQ = r(mean)
sum log_labor if EQ_lag1 == 1
local mean_after_EQ = r(mean)

twoway (hist log_labor  if num_qs_aw_lag1>0, color(red%30) width(0.18) ) (hist log_labor if num_qs_aw_lag1==0, color(blue%30) width(0.18)  ) ,  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "Firms in districts affected by EQ in year t-1" 2 "Firms not affected by EQ in year t-1" ) position(6)) title("Indonesia: distribution of labor by earthquake (EQ) impact (1975-1995)") xline(`mean_after_EQ', lcolor(red%70) noextend)  xline(`mean_no_EQ', lcolor(blue%70) noextend) text(1.124 3.5 "Mean after EQ", size(vsmall) color(red%80)) text(1.09 4.7 "Mean after no EQ", size(vsmall) color(blue%80)) 

graph export "./output/Indonesia/fig_IDN_labor_distr.png", as(png) replace

*INVESTMENT
label var log_tot_invest `"Logged Total Investment"' 

sum log_tot_invest if EQ_lag1 == 0
local mean_no_EQ = r(mean)
sum log_tot_invest if EQ_lag1 == 1
local mean_after_EQ = r(mean)

twoway (hist log_tot_invest  if num_qs_aw_lag1>0, color(red%30) width(0.3) ) (hist log_tot_invest if num_qs_aw_lag1==0, color(blue%30) width(0.3)  ) ,  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "Firms in districts affected by EQ in year t-1" 2 "Firms not affected by EQ in year t-1" ) position(6)) title("Indonesia: distribution of investment by earthquake (EQ) impact (1975-1995)") xline(`mean_after_EQ', lcolor(red%70) noextend)  xline(`mean_no_EQ', lcolor(blue%70) noextend) text(0.319 10.2 "Mean after EQ", size(vsmall) color(red%80)) text(0.3 12.5 "Mean after no EQ", size(vsmall) color(blue%80)) 
 
graph export "./output/Indonesia/fig_IDN_inv_distr.png", as(png) replace


* CAPITAL 
label var log_capital `"Logged Book Value of Assets"' 

sum log_capital if EQ_lag1 == 0
local mean_no_EQ = r(mean)
sum log_capital if EQ_lag1 == 1
local mean_after_EQ = r(mean)

twoway (hist log_capital  if num_qs_aw_lag1>0, color(red%30) width(0.2) ) (hist log_capital if num_qs_aw_lag1==0, color(blue%30) width(0.2)  ) ,  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "Firms in districts affected by EQ in year t-1" 2 "Firms not affected by EQ in year t-1" ) position(6)) title("Indonesia: distribution of capital by earthquake (EQ) impact (1975-1995)") xline(`mean_after_EQ', lcolor(red%90) noextend)  xline(`mean_no_EQ', lcolor(blue%70) noextend) text(0.33 10.5 "Mean after EQ", size(vsmall) color(red%80)) text(0.3 13.3 "Mean after no EQ", size(vsmall) color(blue%80)) 
 
graph export "./output/Indonesia/fig_IDN_cap_distr.png", as(png) replace

* OUTPUT 
label var log_tot_output `"Logged Total Output"' 

sum log_tot_output if EQ_lag1 == 0
local mean_no_EQ = r(mean)
sum log_tot_output if EQ_lag1 == 1
local mean_after_EQ = r(mean)

twoway (hist log_tot_output  if num_qs_aw_lag1>0, color(red%30) width(0.2) ) (hist log_tot_output if num_qs_aw_lag1==0, color(blue%30) width(0.2)  ) ,  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "Firms in districts affected by EQ in year t-1" 2 "Firms not affected by EQ in year t-1" ) position(6)) title("Indonesia: distribution of output by earthquake (EQ) impact (1975-1995)") xline(`mean_after_EQ', lcolor(red%90) noextend)  xline(`mean_no_EQ', lcolor(blue%70) noextend) text(0.42 12.1 "Mean after EQ", size(vsmall) color(red%80)) text(0.38 14 "Mean after no EQ", size(vsmall) color(blue%80)) 
 
graph export "./output/Indonesia/fig_IDN_output_distr.png", as(png) replace


* WAGES

label var log_wages `"Logged Total Wages"' 

sum log_wages if EQ_lag1 == 0
local mean_no_EQ = r(mean)
sum log_wages if EQ_lag1 == 1
local mean_after_EQ = r(mean)

twoway (hist log_wages  if num_qs_aw_lag1>0, color(red%30) width(0.23) ) (hist log_wages if num_qs_aw_lag1==0, color(blue%30) width(0.23)  ) ,  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "Firms in districts affected by EQ in year t-1" 2 "Firms not affected by EQ in year t-1" ) position(6)) title("Indonesia: distribution of wages by earthquake (EQ) impact (1975-1995)") xline(`mean_after_EQ', lcolor(red%90) noextend)  xline(`mean_no_EQ', lcolor(blue%70) noextend) text(0.4 9 "Mean after EQ", size(vsmall) color(red%80)) text(0.4 11.5 "Mean after no EQ", size(vsmall) color(blue%80)) 
 
graph export "./output/Indonesia/fig_IDN_wages_distr.png", as(png) replace


*EXPORTS

label var log_exports `"Logged Total Exports"' 

sum log_exports if EQ_lag1 == 0
local mean_no_EQ = r(mean)
sum log_exports if EQ_lag1 == 1
local mean_after_EQ = r(mean)

twoway (hist log_exports  if num_qs_aw_lag1>0, color(red%30) width(0.35) ) (hist log_exports if num_qs_aw_lag1==0, color(blue%30) width(0.35)  ) ,  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "Firms in districts affected by EQ in year t-1" 2 "Firms not affected by EQ in year t-1" ) position(6)) title("Indonesia: distribution of exports by earthquake (EQ) impact (1975-1995)") xline(`mean_after_EQ', lcolor(red%90) noextend)  xline(`mean_no_EQ', lcolor(blue%70) noextend) text(0.255 12.5 "Mean after EQ", size(vsmall) color(red%80)) text(0.255 14.6 "Mean after no EQ", size(vsmall) color(blue%80)) 
 
graph export "./output/Indonesia/fig_IDN_exp_distr.png", as(png) replace

restore*/




