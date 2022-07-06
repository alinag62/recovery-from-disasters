
cd /Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters
cd /Users/alinagafanova/Library/CloudStorage/Box-Box/recovery-from-disasters

* Housekeeping
clear
clear matrix
set more off

use  "./data/firm-data/Vietnam/Vietnam_worldbank_data/firms_VNM_clean.dta", clear

*#############################################################################
set scheme plottig 
grstyle init
grstyle set imesh, horizontal minor
grstyle set ci 538, select(13 10) opacity(60)
grstyle set color "35 35 35" "35 35 35"  "62 102 206"  "62 102 206"
graph set window fontface "Helvetica Light"

*#############################################################################

label var rK "Capital"
label var LPV "Labor Productivity (Real VA / Labor)"
rename id plant
drop region
rename ID_2 region
gen rtot_wage = rwage*L
label var rtot_wage "Real Total Wage"

*create logged vars
foreach dep in rS rM rV rLC rK LPV rwage L rtot_wage{
	gen log_`dep' = log10(`dep')
	local label_dep: var label `dep'
	label var log_`dep'`"Logged `label_dep'"' 
}

********************************************************************************
/*1. Unique plants in each region
preserve

*leave 1 observation per firm
duplicates drop plant, force

*generic unit
gen i = 1

*count firms
collapse (sum) i, by(_ID)

*add ADM2 with no firms
merge m:1 _ID using "./data/firm-data/Vietnam/gadm36_VNM_shp/VNM_adm2.dta"
drop _m

*create a map
spmap i using "./data/firm-data/Vietnam/gadm36_VNM_shp/VNM_adm2_coordinates.dta", id(_ID) clm(c) clb(1 45 100 200 500 1500 4000 19000) fcolor(Greens)  title("Number of Unique Firms in Vietnam" "by ADM2, 1977-2013", size(*1.3)) legend(label(1 "No firms") title("Number of Unique Firms",  size(*0.8)) size(*1.9) pos(9)) 
graph export "./output/Vietnam/maps/number_unique_firms_adm2.png", as(png) width(3000) replace

restore  

********************************************************************************/

********************************************************************************
/*2. Maps with Averages across districts
preserve

gen i = 1

*replace units to mln 
gen sales_mln = sales/1000

*count non-missing values (assume it doesn't mean non-zero')
foreach var in sales_mln L LPV {
	*only use non-negative variables
	replace `var' = . if `var'<0
	gen `var'_count = 1 if `var'!=.
}

*sum over regions
collapse (sum) sales_mln L LPV i (count) sales_mln_count L_count LPV_count, by(year _ID)

*find averages
foreach var in sales_mln L LPV {
	gen `var'_avg = `var'/`var'_count
}
keep _ID year sales_mln_avg L_avg LPV_avg sales_mln L LPV

*change format for neat legends
format (sales_mln_avg L_avg LPV_avg sales_mln L LPV) %9.0f

*add ADM2 with no firms
merge m:1 _ID using "./data/firm-data/Vietnam/gadm36_VNM_shp/VNM_adm2.dta"
drop _m
fillin year _ID
drop if year==.

*Plot averages

foreach year in 2007 2010 2013 {
	*total sales
	spmap sales_mln if year==`year' using "./data/firm-data/Vietnam/gadm36_VNM_shp/VNM_adm2_coordinates.dta", id(_ID) clnumber(5) fcolor(Oranges) title("Total Sales (nominal VND, mln)" "by ADM2, `year'", size(*1.3)) legend(title("Total Sales (mln VND)",  size(*0.9)) size(*2.1) pos(9))  
	graph export "./output/Vietnam/maps/sales_totals_`year'.png", as(png) width(3000) replace
	
	*avg sales
	spmap sales_mln_avg if year==`year' using "./data/firm-data/Vietnam/gadm36_VNM_shp/VNM_adm2_coordinates.dta", id(_ID) clnumber(5) fcolor(Oranges) title("Average Sales (nominal VND, mln)" "by ADM2, `year'", size(*1.3)) legend(title("Average Sales (mln VND)",  size(*0.9)) size(*2.1) pos(9))  
	graph export "./output/Vietnam/maps/sales_avg_`year'.png", as(png) width(3000) replace
	
	*total labor
	spmap L if year==`year' using "./data/firm-data/Vietnam/gadm36_VNM_shp/VNM_adm2_coordinates.dta", id(_ID) clnumber(5) fcolor(Oranges) title("Total Labor by ADM2, `year'", size(*1.3)) legend(title("Total Labor",  size(*0.9)) size(*2.1) pos(9))  
	graph export "./output/Vietnam/maps/labor_totals_`year'.png", as(png) width(3000) replace
	
	*avg labor
	spmap L_avg if year==`year' using "./data/firm-data/Vietnam/gadm36_VNM_shp/VNM_adm2_coordinates.dta", id(_ID) clnumber(5) fcolor(Oranges) title("Average Labor by ADM2, `year'", size(*1.3)) legend(title("Average Labor",  size(*0.9)) size(*2.1) pos(9))  
	graph export "./output/Vietnam/maps/labor_avg_`year'.png", as(png) width(3000) replace
	
	*avg labor productivity
	cap: spmap LPV_avg if year==`year' using "./data/firm-data/Vietnam/gadm36_VNM_shp/VNM_adm2_coordinates.dta", id(_ID) clnumber(5) fcolor(Oranges) title("Average Labor Productivity" "(real VA/Labor) by ADM2, `year'", size(*1.3)) legend(title("Average Labor Productivity",  size(*0.9)) size(*2.1) pos(9))  
	cap: graph export "./output/Vietnam/maps/labor_prod_avg_`year'.png", as(png) width(3000) replace
	
	

}

restore 
********************************************************************************/

/* 3. Table with descriptive statistics 
quietly: estpost summarize L rS rV rM rK LPV rLC rtot_wage rwage, detail
esttab . using "./output/Vietnam/tables/summary_firms_levels.tex", cells("mean(fmt(1)) min p10 p50 p90 max count(fmt(0))") noobs label
quietly: estpost summarize log_L log_rS log_rV log_rM log_rK log_LPV log_rLC log_rtot_wage log_rwage, detail
esttab . using "./output/Vietnam/tables/summary_firms_logs.tex", cells("mean(fmt(1)) min p10 p50 p90 max count(fmt(0))") noobs label */

















