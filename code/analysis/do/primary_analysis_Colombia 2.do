/*
###########################################################################
 0)                     Intro
########################################################################### */

cd /Users/alina/Box/recovery-from-disasters

* Housekeeping
clear
clear matrix
set more off

local path2save_shake "./data/earthquakes/intermediate/Colombia_adm2"
local firms_folder "./data/firm-data/Colombia"
local path2shp_dta "./data/firm-data/Colombia/Shapefile/COL_adm_shp/COL_adm2.dta"
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
*Part I. Analysing the survey
*#############################################################################

use "`firms_folder'/Final-Dataset/`country'_survey_readytoregress.dta"

*dummy for firms that do not have a location
gen region_identified = 1
replace region_identified = 0 if met_area==9
label define reg_dummy 0 "No region"  1 "Region identified"
label values region_identified reg_dummy

*number of time periods per plant
bys plant: gen years_in_survey = _N
label var years_in_survey "Years in survey (from 15)"

*show in thousands
gen ener_cons_q_th = ener_cons_q/1000
gen wage_tot_th = wage_tot/1000
gen tot_sales_th = tot_sales/1000
label var ener_cons_q_th "Energy Consumed, Qty, in ths"
label var wage_tot_th "Wages Total, in ths"
label var tot_sales_th "Total Sales, in ths"

/*compare firms inside and outside identifiable regions 
eststo clear
bys region_identified: eststo: quietly estpost sum years_in_survey tot_emp ener_cons_q_th  wage_tot_th  tot_sales_th , listwise
quietly: eststo Total: estpost summarize years_in_survey tot_emp ener_cons_q_th  wage_tot_th  tot_sales_th , listwise
esttab * using "./output/Colombia/table1_COL.tex", main(mean) aux(sd) nostar nonote label nonumber nodepvar booktabs nonum unstack title(Firms with and without identifiable regions) replace
eststo clear*/

*production size proxy
bys plant: egen tot_sales_sum = total(tot_sales)
gen tot_sales_avg = tot_sales_sum/years_in_survey
egen tot_sales_avg_pct5  = pctile(tot_sales_avg ), p(5)
egen tot_sales_avg_pct95  = pctile(tot_sales_avg ), p(95)

/*compare firms inside and outside identifiable regions, but drop outliers
preserve
drop if tot_sales_avg<tot_sales_avg_pct5
drop if tot_sales_avg>tot_sales_avg_pct95
eststo clear
bys region_identified: eststo: quietly estpost sum years_in_survey tot_emp ener_cons_q_th  wage_tot_th  tot_sales_th , listwise
quietly: eststo Total: estpost summarize years_in_survey tot_emp ener_cons_q_th  wage_tot_th  tot_sales_th , listwise
esttab * using "./output/Colombia/table2_COL.tex", main(mean) aux(sd) nostar nonote label nonumber nodepvar booktabs nonum unstack title(Firms with and without identifiable regions, drop top and bottom $5\%$) replace
eststo clear
restore*/

/*firms' survey - map of adm1 
preserve
bys country_sect: drop if _n>1
drop if country_sect==.
keep country_sect
merge 1:1 _n using "./data/firm-data/Colombia/Shapefile/COL_adm_shp/adm1_transferring.dta"
rename _m m1
merge 1:1 _n using "/Users/alina/Box/recovery-from-disasters/data/firm-data/Colombia/Shapefile/COL_adm_shp/COL_adm1.dta"
spmap m1 using "./data/firm-data/Colombia/Shapefile/COL_adm_shp/COL_adm1_coordinates.dta", id(_ID)  fcolor(white midgreen) clmethod(custom) clbreaks(1 2 3) legend(label(2 "No firm data") label(3 "ADM1 with firm data" ) label() size(vsmall))
graph export "./output/Colombia/fig6_COL.png", as(png) replace
restore*/


*#############################################################################*/
*Part II. Analysing the shaking data
*#############################################################################

use "`path2save_shake'/region_panel/panel_earthquakes_thresh_10.dta", clear

*create lags
sort region year
foreach i of num 1/10 {
	by region: gen mpga_aw10_lag`i' = mpga_aw10[_n-`i']
	by region: gen mpga_aw_lag`i' = mpga_aw[_n-`i']
	by region: gen num_qs_aw_lag`i' = num_qs_aw[_n-`i']
}

*distribution of shaking
*hist mpga_aw10
*hist mpgv_aw10
*hist num_qs_aw10

*number of years when shaking occurs
gen shaking_year = 0
replace shaking_year = 1 if mpga_aw>0
bys region: egen years_shaking = total(shaking_year)
label var years_shaking "Years with shaking (from 25)"


*#######################
*#######################
*#######################
*number of years when EQ occurs
gen eq_year = 0
replace eq_year = 1 if num_qs_aw>0
bys region: egen years_eq = total(eq_year)
label var years_eq "Years with EQ (from 25)"
*#######################
*#######################
*#######################



*add region/no region dummy from survey
gen region_identified_in_survey = 0
replace region_identified_in_survey = 1 if region==76|region==141|region==169|region==330|region==568|region==847|region==863|region==1043
label define reg_dummy 0 "No region"  1 "Region identified"
label values region_identified_in_survey reg_dummy


/*shaking frequency in identified vs regions without ADM2
preserve
bys region: drop if _n>1
estpost tab years_shaking  region_identified_in_survey
esttab . using "./output/Colombia/table3_COL.tex", cell(b(fmt(%9.0f)))  eqlabels(, lhs("Years with shaking (from 25)"))     collabels(none) unstack noobs nonumber nomtitle booktabs title(Regions by number of years with shaking) replace
restore */

/*shaking intensity in identified vs regions without ADM2
preserve
collapse (mean) mpga_aw, by(shaking_year years_shaking region_identified_in_survey)
drop if shaking_year==0
drop shaking_year
tab years_shaking  region_identified_in_survey, sum(mpga_aw) nost nofreq
*ESTPOST can't export it, I DO IT MANUALLY
restore*/

/*plot the map of regions with shaking (add shapefile)
preserve
rename region ID_2
merge m:1  ID_2 using "./data/firm-data/Colombia/Shapefile/COL_adm_shp/COL_adm2.dta"
bys ID_2: drop if _n>1


spmap region_identified_in_survey using "./data/firm-data/Colombia/Shapefile/COL_adm_shp/COL_adm2_coordinates.dta", id(ID_2) legend(label(2 "No region") label(3 "Region identified" ) label() size(vsmall)) fcolor(dimgray midgreen white) 
graph export "./output/Colombia/fig1_COL.png", as(png) replace
replace years_shaking=. if years_shaking==0
spmap years_shaking using "./data/firm-data/Colombia/Shapefile/COL_adm_shp/COL_adm2_coordinates.dta", id(ID_2)  clnumber(5) legend(label(6 "7-13 years with shaking") label(5 "5-6 years with shaking") label(4 "4 years with shaking") label(3 "2-3 years with shaking") label(2 "1 year with shaking") label(1 "No shaking in 1967-1991")  size(vsmall)) fcolor(Reds)
graph export "./output/Colombia/fig4_COL.png", as(png) replace

restore*/

/*plot distribution of shaking by years in regions with firm data
graph bar (sum) shaking_year, over(year,label(angle(45))) ytitle("Regions with Shaking") 
graph export "./output/Colombia/fig2_COL.png", as(png) replace
graph bar (sum) shaking_year if region_identified_in_survey==1, over(year,label(angle(45))) ytitle("Regions with Shaking, only identified regions")
graph export "./output/Colombia/fig3_COL.png", as(png) replace  */


/*preserve
rename region ID_2
merge m:1  ID_2 using "./data/firm-data/Colombia/Shapefile/COL_adm_shp/COL_adm2.dta"
collapse (mean) mpga_aw, by(ID_2)
replace mpga_aw=. if mpga_aw==0
spmap mpga_aw using "./data/firm-data/Colombia/Shapefile/COL_adm_shp/COL_adm2_coordinates.dta", id(ID_2) fcolor(Oranges) legend(label(1 "No shaking" ) size(vsmall)) title("Mean mpga_aw for 25 years", size(*0.7))
graph export "./output/Colombia/fig5_COL.png", as(png) replace
restore
*/


tempfile shaking
save "`shaking'"  



*#############################################################################
*Part III. Analysing survey+shaking
*#############################################################################

use "`firms_folder'/Final-Dataset/`country'_survey_readytoregress.dta"
rename id_used region
bys region year: gen firms_that_year_in_region = _N

*check if that ID was the same as ID in shape file*****
*rename id_used ID_2
*merge m:1 ID_2 using "`firms_folder'/Shapefile/COL_adm_shp/COL_adm2.dta"
*keep ID_2 met_area NAME_2 
*tab ID_2 met_area

merge m:1 region year using "`shaking'"
keep if region==76|region==141|region==169|region==330|region==568|region==847|region==863|region==1043
drop _m

*Plotting raw time-series
/*preserve
collapse (first) mpga_aw mag_aw mag_aw10 mpga_aw10 num_qs_aw num_qs_aw10 met_area (mean) insur_paym tot_emp netinv_val tot_sales ener_cons_q totasst_val firms_that_year_in_region, by(region year)

label var mpga_aw "Area-weighted average of maximum PGA in the region"
label var mpga_aw10 "Area-weighted average of maximum PGA in the region, top 10%"
label var insur_paym "Average Insurance Payments"
label var netinv_val "Average Net Investment Value"
label var tot_emp "Average Total Employment"
label var tot_sales "Average Total Sales"
label var ener_cons_q "Average Energy Consumption (Quantity)"
label var firms_that_year_in_region "Number of Operating Firms"
label var totasst_val "Average Total Assets (book value)"

levelsof region, local(reg_num)
foreach val in insur_paym tot_emp netinv_val tot_sales ener_cons_q firms_that_year_in_region totasst_val {
	foreach var in `reg_num' {
	local met_name = met_area if region==`var'&year==1980
	twoway (connected `val' year, yaxis(1)) (spike mpga_aw year, yaxis(2) lwidth(1) lcolor( "62 102 206")) if region==`var', yline(0, axis(2) lcolor( "62 102 206")) legend(position(6)) title("Region `var'")
	graph export "./output/Colombia/fig_COL_reg`var'_`val'_aggregated.png", as(png) replace
	}
}
restore*/


*histograms for shaking-exposed regions during no shaking and years after shaking; drop top 5%
egen insur_paym_pct95  = pctile(insur_paym), p(95)
egen tot_emp_pct95  = pctile(tot_emp), p(95)
egen netinv_val_pct95 = pctile(netinv_val), p(95)
egen tot_sales_pct95  = pctile(tot_sales), p(95)
egen ener_cons_q_pct95  = pctile(ener_cons_q), p(95)
egen totasst_val_pct95 = pctile(totasst_val), p(95)


/*foreach val in insur_paym tot_emp tot_sales ener_cons_q {
	preserve
	drop if `val'>=`val'_pct95
	foreach var in 76 330 568 847 1043 {
	hist `val' if mpga_aw==0&region==`var',name("no_shaking") title("no shaking years, region `var'")
	hist `val' if mpga_aw>0&region==`var',name("shaking") title("shaking years, region `var'")
	gr combine no_shaking shaking, ycommon xcommon iscale(.5)
	graph export "./output/Colombia/fig_COL_reg`var'_`val'_hist.png", as(png) replace
	gr drop no_shaking shaking
	
	hist `val' if mpga_aw_lag1==0&region==`var',name("no_shaking") title("years after a non-shaking year, region `var'")
	hist `val' if mpga_aw_lag1>0&region==`var',name("shaking") title("years after a shaking year, region `var'")
	gr combine no_shaking shaking, ycommon xcommon iscale(.5)
	graph export "./output/Colombia/fig_COL_reg`var'_`val'_hist_lag1.png", as(png) replace
	gr drop no_shaking shaking
	}
	restore
}


preserve
drop if netinv_val>=netinv_val_pct95
foreach var in 76 330 847 1043 {
	hist netinv_val if mpga_aw10==0&region==`var',name("no_shaking") title("no shaking years, region `var'")
	hist netinv_val if mpga_aw10>0&region==`var',name("shaking") title("shaking years, region `var'")
	gr combine no_shaking shaking, ycommon xcommon iscale(.5)
	graph export "./output/Colombia/fig_COL_reg`var'_netinv_val_hist.png", as(png) replace
	gr drop no_shaking shaking
}
restore  */


*Overlaying histograms for shaking-exposed regions; drop outliers
egen insur_paym_pct5  = pctile(insur_paym), p(5)
egen tot_emp_pct5  = pctile(tot_emp), p(5)
egen netinv_val_pct5 = pctile(netinv_val), p(5)
egen tot_sales_pct5  = pctile(tot_sales), p(5)
egen ener_cons_q_pct5  = pctile(ener_cons_q), p(5)
egen totasst_val_pct5 = pctile(totasst_val), p(5)

/*foreach val in insur_paym tot_emp tot_sales ener_cons_q {
	preserve
	drop if `val'>=`val'_pct95
	drop if `val'<=`val'_pct5
	foreach var in 76 330 568 847 1043 {
	twoway (hist `val' if mpga_aw>0&region==`var', color(red%30)) (hist `val' if mpga_aw==0&region==`var', color(blue%30) ) ,  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "Year with shaking" 2 "No shaking year" ) position(6)) title("Region `var'")
	graph export "./output/Colombia/fig_COL_reg`var'_`val'_overl_hist.png", as(png) replace
	
	twoway (hist `val' if mpga_aw_lag1>0&region==`var', color(red%30)) (hist `val' if mpga_aw_lag1==0&region==`var', color(blue%30) ) ,  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "Years after years with shaking" 2 "Years after no-shaking years" ) position(6)) title("Region `var'")
	graph export "./output/Colombia/fig_COL_reg`var'_`val'_overl_hist_lag1.png", as(png) replace
	}
	restore
} */


/*foreach val in insur_paym tot_emp tot_sales ener_cons_q {
	preserve
	drop if `val'>=`val'_pct95
	drop if `val'<=`val'_pct5
	foreach var in 76 330 568 847 1043 {
	twoway (hist `val' if num_qs_aw_lag1>0&region==`var', color(red%30)) (hist `val' if num_qs_aw_lag1==0&region==`var', color(blue%30) ) ,  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "Years after years with EQ" 2 "Years after no-EQ years" ) position(6)) title("Region `var'")
	graph export "./output/Colombia/fig_COL_reg`var'_`val'_overl_hist_EQ_lag1.png", as(png) replace
	}
	restore
} */

/*preserve
drop if netinv_val>=netinv_val_pct95
drop if netinv_val<=netinv_val_pct5
foreach var in 76 330 847 1043 {
twoway (hist netinv_val if mpga_aw>0&region==`var',  color(red%30)) (hist netinv_val if mpga_aw==0&region==`var', color(blue%30) ) ,  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "Year with shaking" 2 "No shaking year" ) position(6)) title("Region `var'")
graph export "./output/Colombia/fig_COL_reg`var'_netinv_val_overl_hist.png", as(png) replace

twoway (hist netinv_val if mpga_aw_lag1>0&region==`var', color(red%30)) (hist netinv_val if mpga_aw_lag1==0&region==`var', color(blue%30) ) ,  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "Years after years with shaking" 2 "Years after no-shaking years" ) position(6)) title("Region `var'")
graph export "./output/Colombia/fig_COL_reg`var'_netinv_val_overl_hist_lag1.png", as(png) replace
}
restore */

*#############################################################################
*#############################################################################
*#############################################################################

*ADD logged vars

/*regression 
foreach var in dom_sales output_gross real_val_prod prod_val wage_tot tot_emp dom_work_paym netinv_val tot_gen_paym tot_ind_exp tot_invent_boy totasst_dep transp_dep ener_cons_q ener_cons_val goods_fin_boy goods_fin_eoy mach_dep mach_new_purch mach_prod mach_reapp mach_sales mach_used_purch mach_val bldings_dep bldings_new_purch bldings_prod bldings_reapp bldings_sales bldings_used_purch bldings_val raw_mat_boy raw_mat_eoy rawmat_for {
	quietly: areg `var' mpga_aw10  c.year, absorb(plant) vce(cluster plant)
	est sto m1
	quietly: areg `var' mpga_aw10 mpgv_aw10_lag1  c.year, absorb(plant) vce(cluster plant)
	est sto m2
	quietly: areg `var' mpga_aw10 mpgv_aw10_lag1 mpgv_aw10_lag2 c.year, absorb(plant) vce(cluster plant)
	est sto m3
	esttab m1 m2 m3, se noconstant label append
	*esttab m1 m2 m3 using example.tex, se noconstant append
	eststo clear

} */


*******
eststo clear
local treat mpga_aw
foreach i of num 1/10 {
	local treat `treat ' mpga_aw_lag`i'
	di("`treat'")
	quietly: areg tot_emp `treat'  i.year, absorb(plant) vce(cluster plant)
	est sto m`i'
}

local results 
foreach i of num 1/10 {
	local results `results' m`i'
	di("`results'")
}

esttab `results' using example.tex, se noconstant replace booktabs compress keep(`treat') addnotes("Year and plant fixed effects are included in each specification.")


*******

eststo clear
local treat num_qs_aw
foreach i of num 1/10 {
	local treat `treat ' num_qs_aw_lag`i'
	di("`treat'")
	quietly: areg tot_emp `treat'  i.year, absorb(plant) vce(cluster plant)
	est sto m`i'
}

local results 
foreach i of num 1/10 {
	local results `results' m`i'
	di("`results'")
}

esttab `results' using example2.tex, se noconstant replace booktabs compress keep(`treat') addnotes("Year and plant fixed effects are included in each specification.")


***********

eststo clear
local treat
foreach i of num 1/10 {
	local treat `treat ' mpga_aw_lag`i'
	di("`treat'")
	quietly: areg tot_emp `treat'  i.year, absorb(plant) vce(cluster plant)
	est sto m`i'
}

local results 
foreach i of num 1/10 {
	local results `results' m`i'
	di("`results'")
}

esttab `results' using example3.tex, se noconstant replace booktabs compress keep(`treat') addnotes("Year and plant fixed effects are included in each specification.")


*******

eststo clear
local treat
foreach i of num 1/10 {
	local treat `treat ' num_qs_aw_lag`i'
	di("`treat'")
	quietly: areg tot_emp `treat'  i.year, absorb(plant) vce(cluster plant)
	est sto m`i'
}

local results 
foreach i of num 1/10 {
	local results `results' m`i'
	di("`results'")
}

esttab `results' using example4.tex, se noconstant replace booktabs compress keep(`treat') addnotes("Year and plant fixed effects are included in each specification.")


***********



eststo clear 
local treat mpga_aw
foreach i of num 1/10 {
	local treat `treat ' mpga_aw_lag`i'
	di("`treat'")
	quietly: areg tot_emp `treat'  i.year c.region, absorb(plant) vce(cluster plant)
	est sto m`i'
}

local results 
foreach i of num 1/10 {
	local results `results' m`i'
	di("`results'")
}

esttab `results' using example5.tex, se noconstant replace booktabs compress keep(`treat') addnotes("Year, district and plant fixed effects are included in each specification.")


*******

eststo clear
local treat num_qs_aw
foreach i of num 1/10 {
	local treat `treat ' num_qs_aw_lag`i'
	di("`treat'")
	quietly: areg tot_emp `treat'  i.year c.region, absorb(plant) vce(cluster plant)
	est sto m`i'
}

local results
foreach i of num 1/10 {
	local results `results' m`i'
	di("`results'")
}

esttab `results' using example6.tex, se noconstant replace booktabs compress keep(`treat') addnotes("Year, district and plant fixed effects are included in each specification.")


***********

eststo clear
local treat mpga_aw
foreach i of num 1/10 {
	local treat `treat ' mpga_aw_lag`i'
	di("`treat'")
	quietly: areg tot_emp `treat' i.year c.year##i.region, absorb(plant) vce(cluster plant)
	est sto m`i'
}

local results 
foreach i of num 1/10 {
	local results `results' m`i'
	di("`results'")
}

esttab `results' using example7.tex, se noconstant replace booktabs compress keep(`treat') addnotes("Year, and plant fixed effects are included in each specification. District-year linear trends are included.")


*******

eststo clear
local treat num_qs_aw
foreach i of num 1/10 {
	local treat `treat ' num_qs_aw_lag`i'
	di("`treat'")
	quietly: areg tot_emp `treat' i.year c.year##i.region, absorb(plant) vce(cluster plant)
	est sto m`i'
}

local results 
foreach i of num 1/10 {
	local results `results' m`i'
	di("`results'")
}

esttab `results' using example8.tex, se noconstant replace booktabs compress keep(`treat') addnotes("Year and plant fixed effects are included in each specification. District-year linear trends are included.")









