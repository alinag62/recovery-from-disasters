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

*#############################################################################
set scheme plottig 
grstyle init
grstyle set imesh, horizontal minor
grstyle set ci 538, select(13 10) opacity(60)
grstyle set color "35 35 35" "35 35 35"  "62 102 206"  "62 102 206"
*#############################################################################

*#############################################################################
*Part 1. Cleaning and analyzing the survey
*#############################################################################

use "`firms_folder'/Final-Dataset/India_survey_readytoregress.dta", clear
keep if year>=1985&year<=2011
drop if panelID==.
rename id_used region
drop if region == .

/* plot regions' maps
preserve
bys region: drop if _n>1
rename region ID_2
merge m:1 ID_2 using "./data/firm-data/India/Shapefile/IND_adm_shp/IND_adm2.dta"
spmap _m using "./data/firm-data/India/Shapefile/IND_adm_shp/IND_adm2_coordinates.dta",  fcolor(  white midgreen) id(_ID) clnumber(5) osize(0.1 ...) legend(label(2 "No firm data in the survey" )  label(3 "Firms in the survey") size(vsmall))
graph export "./output/India/fig1_IND.png", as(png) replace
restore  */


tempfile survey
save "`survey'"  


*#############################################################################*/
*Part II. Analysing the shaking data
*#############################################################################
use "`path2save_shake'/region_panel/panel_earthquakes_thresh_10.dta"
keep if year>=1975&year<=2011

*create lags
sort region year
foreach i of num 1/10 {
	by region: gen mpga_aw_lag`i' = mpga_aw[_n-`i']
}

*number of years when shaking occurs
gen shaking_year = 0
replace shaking_year = 1 if num_qs_aw>0
bys region: egen years_shaking = total(shaking_year)
label var years_shaking "Years with earthquakes (from 37)"

/* plot regions' maps
preserve
bys region: drop if _n>1
rename region ID_2
merge m:1 ID_2 using "./data/firm-data/India/Shapefile/IND_adm_shp/IND_adm2.dta"
replace years_shaking = . if years_shaking==0
spmap years_shaking using "./data/firm-data/India/Shapefile/IND_adm_shp/IND_adm2_coordinates.dta",   id(_ID) fcolor(Reds) clnumber(7) osize(0.1 ...) ndsize(0.1 ...) legend(label(1 "No earthquakes") size(vsmall)) title("Years with earthquakes from 37 years", size(*0.7))
graph export "./output/India/fig2_IND.png", as(png) replace
restore

preserve
rename region ID_2
merge m:1 ID_2 using "./data/firm-data/India/Shapefile/IND_adm_shp/IND_adm2.dta"
collapse (mean) mpga_aw, by(ID_2 _ID)
replace mpga_aw=. if mpga_aw==0
spmap mpga_aw using "./data/firm-data/India/Shapefile/IND_adm_shp/IND_adm2_coordinates.dta", id(_ID) fcolor(Oranges) legend(label(1 "No shaking" ) size(vsmall)) title("Mean mpga_aw for 37 years", size(*0.7)) osize(0.1 ...) ndsize(0.1 ...)
graph export "./output/India/fig3_IND.png", as(png) replace
restore */


/*plot distribution of shaking by years in regions with firm data
graph bar (sum) shaking_year, over(year,label(angle(45))) ytitle("Regions with Shaking") 
graph export "./output/India/fig4_IND.png", as(png) replace */

* maps of exposure by year, animation
preserve
rename region ID_2
merge m:1 ID_2 using "./data/firm-data/India/Shapefile/IND_adm_shp/IND_adm2.dta"
replace mpga_aw=. if mpga_aw==0
forval year = 1975/2011 {
	spmap mpga_aw if year==`year' using "./data/firm-data/India/Shapefile/IND_adm_shp/IND_adm2_coordinates.dta", id(_ID) clm(c) clb(0 0.1 0.5 1 2 60) fcolor(Reds) legend(label(1 "No shaking")) title(`year', size(*0.8)) osize(0.1 ...) ndsize(0.1 ...)
	graph export "./output/India/gif_mpga_aw_`year'.png", as(png) width(1300) replace
}
restore

preserve
rename region ID_2
merge m:1 ID_2 using "./data/firm-data/India/Shapefile/IND_adm_shp/IND_adm2.dta"
replace num_qs_aw=. if num_qs_aw==0
forval year = 1975/2011 {
	spmap num_qs_aw if year==`year' using "./data/firm-data/India/Shapefile/IND_adm_shp/IND_adm2_coordinates.dta", id(_ID) clm(c) clb(0 0.1 0.2 0.5 0.75 1 5) fcolor(Reds) legend(label(1 "No earthquakes")) title(`year', size(*0.8)) osize(0.1 ...) ndsize(0.1 ...)
	graph export "./output/India/gif_num_qs_aw_`year'.png", as(png) width(1300) replace
}
restore 


tempfile shaking
save "`shaking'"  




*#############################################################################
*Part III. Analysing survey+shaking
*#############################################################################

use "`survey'"
bys region year: gen firms_that_year_in_region = _N

merge m:1 region year using "`shaking'"
order panelID year region 

/*how balanced is the panel data?
preserve
keep if _m==3
collapse (first) panelID, by(region year)
gen a =1
collapse (sum) a, by(region)
hist a, xtitle("Regions by number of years with at least 1 operating plant (out of 27 years)")
graph export "./output/India/fig5_IND.png", as(png) replace
restore */




/*plot raw data (random regions)
preserve

collapse (first) mpga_aw (mean) labor sales capital_close transportcaptl, by(region year)
label var mpga_aw "Area-weighted average of maximum PGA in the region"
label var capital_close "Average Net Value of Fixed Assets (at year's end)"
label var transportcaptl "Average Net Value of Transport Equipment"
label var sales "Average Gross Sales"
label var labor "Average Total Employment"

foreach val in labor sales capital_close transportcaptl {
	foreach var in 415 40 359 288 439 183 40 500 373 {
	twoway (connected `val' year, yaxis(1)) (spike mpga_aw year, yaxis(2) lwidth(1) lcolor( "62 102 206")) if region==`var', yline(0, axis(2) lcolor( "62 102 206")) legend(position(6)) title("Region `var'")
	graph export "./output/India/fig_IND_reg`var'_`val'_aggregated.png", as(png) replace
	}
}

restore */

*histograms for shaking-exposed regions during no shaking and years after shaking; drop top 5%
egen capital_close_pct95  = pctile(capital_close), p(95)
egen transportcaptl_pct95  = pctile(transportcaptl), p(95)
egen sales_pct95 = pctile(sales), p(95)
egen labor_pct95  = pctile(labor), p(95)

*I take random districts (with many observations)
foreach val in labor sales capital_close transportcaptl {
	preserve
	drop if `val'>=`val'_pct95
	
	foreach var in 415 40 359 288 439 183 40 500 373 {

	twoway (hist `val' if mpga_aw_lag1>0&region==`var', color(red%30)) (hist `val' if mpga_aw_lag1==0&region==`var', color(blue%30) ) ,  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "Years after years with shaking" 2 "Years after no-shaking years" ) position(6)) title("Region `var'")
	graph export "./output/India/fig_IND_reg`var'_`val'_overl_hist_lag1.png", as(png) replace
	
	}
	restore
} 

































