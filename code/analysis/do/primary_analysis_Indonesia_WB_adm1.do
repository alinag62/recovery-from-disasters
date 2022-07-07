/*
###########################################################################
                    Intro
########################################################################### */

cd /Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters

* Housekeeping
clear
clear matrix
set more off

use "./data/firm-data/Indonesia_worldbank/maindata_v1.dta",clear

*#############################################################################
*0. Clean
*#############################################################################
destring prov, replace

*Drop 2017 since it contains different PSIDs
drop if year==2017 

*Drop East Timor since it's independent now
drop if prov == 54

*Merge with ADM1 IDs from the map
merge m:1 prov using "./data/firm-data/Indonesia_worldbank/Shapefile/IDN_adm_shp/adm1_id_match.dta"
rename id_1 ID_1
drop _m

*shp2dta using "./data/firm-data/Indonesia_worldbank/Shapefile/IDN_adm_shp/IDN_adm1_dissolved.shp", data("./data/firm-data/Indonesia_worldbank/Shapefile/IDN_adm_shp/IDN_adm1_dissolved.dta")  coor("./data/firm-data/Indonesia_worldbank/Shapefile/IDN_adm_shp/IDN_adm1_dissolved_coordinates.dta") replace
merge m:1 ID_1 using "./data/firm-data/Indonesia_worldbank/Shapefile/IDN_adm_shp/IDN_adm1_dissolved.dta"
drop _m

* clean
rename prov province_id
rename DKABUP district_id
rename PSID plant
order plant year

*#############################################################################
*Part I. Analysing the survey
*#############################################################################

* Some maps (until I can perfectly match for ADM2)


********************************************************************************
/*count firms in each year, annually
preserve
*generic unit
gen i = 1

*count firms
collapse (sum) i, by(year _ID)

*create a map for each year
forval year = 1988/2015 {
	spmap i if year==`year' using "./data/firm-data/Indonesia_worldbank/Shapefile/IDN_adm_shp/IDN_adm1_dissolved_coordinates.dta", id(_ID) fcolor(Reds) clm(c) clb(7 60 120 360 3000 7000)  title("Number of Firms in Indonesia by province, `year'", size(*0.8)) legend(title("Number of Firms",  size(*0.6)) size(*1.3) )
	graph export "./output/Indonesia_worldbank/maps/number_firms_adm1_`year'.png", as(png) width(3000) replace
}

restore */

********************************************************************************


********************************************************************************
/*count unique plants' IDs for all the period
preserve

*leave 1 observation per firm
duplicates drop plant, force

*generic unit
gen i = 1

*count firms
collapse (sum) i, by(_ID)

*create a map
spmap i using "./data/firm-data/Indonesia_worldbank/Shapefile/IDN_adm_shp/IDN_adm1_dissolved_coordinates.dta", id(_ID) clm(c) clb(70 200 400 1000 6000  12000) fcolor(Reds)  title("Number of Unique Firms in Indonesia by province, 1988-2015", size(*0.8)) legend(title("Number of Firms",  size(*0.6)) size(*1.3) )
graph export "./output/Indonesia_worldbank/maps/number_unique_firms_adm1.png", as(png) width(3000) replace

restore */

********************************************************************************



********************************************************************************
/*Averages across districts
preserve

gen i = 1

*replace units to mln (rupiah)
gen output_mln = OUTPUT/1000000
gen kap_mln = kap/1000000

*count non-missing values (assume it doesn't mean non-zero')
foreach var in output_mln lbr kap_mln labprod {
	*only use non-negative variables
	replace `var' = . if `var'<0
	gen `var'_count = 1 if `var'!=.
}

*sum over regions
collapse (sum) output_mln lbr kap_mln labprod i (count) output_mln_count lbr_count kap_mln_count labprod_count, by(year _ID)

*find averages
foreach var in output_mln lbr kap_mln labprod {
	gen `var'_avg = `var'/`var'_count
}
drop labprod kap_mln_count labprod_count output_mln_count lbr_count i

*change format for neat legends
format (lbr_avg lbr labprod_avg kap_mln_avg kap_mln output_mln_avg output_mln) %9.0f

spmap output_mln_avg if year==2000 using "./data/firm-data/Indonesia_worldbank/Shapefile/IDN_adm_shp/IDN_adm1_dissolved_coordinates.dta", id(_ID) fcolor(Oranges) 
*Plot averages

foreach year in 1988 2000 2015 {
	*total output
	spmap output_mln if year==`year' using "./data/firm-data/Indonesia_worldbank/Shapefile/IDN_adm_shp/IDN_adm1_dissolved_coordinates.dta", id(_ID) clnumber(5) fcolor(Oranges) title("Total Output (mln rupees) by province, `year'", size(*0.8)) legend(title("Total Output (mln rupees)",  size(*0.6)) size(*1.3) )  
	graph export "./output/Indonesia_worldbank/maps/output_totals_`year'.png", as(png) width(3000) replace
	
	*average output 
	spmap output_mln_avg if year==`year' using "./data/firm-data/Indonesia_worldbank/Shapefile/IDN_adm_shp/IDN_adm1_dissolved_coordinates.dta", id(_ID) clnumber(5) fcolor(Oranges) title("Average Firm Output (mln rupees) by province, `year'", size(*0.8)) legend(title("Average Firm Output (mln rupees)",  size(*0.6)) size(*1.3) ) 
	graph export "./output/Indonesia_worldbank/maps/output_avg_`year'.png", as(png) width(3000) replace
	
	*total labor
	spmap lbr if year==`year' using "./data/firm-data/Indonesia_worldbank/Shapefile/IDN_adm_shp/IDN_adm1_dissolved_coordinates.dta", id(_ID) clnumber(5) fcolor(Oranges) title("Total Labor by province, `year'", size(*0.8)) legend(title("Total Labor",  size(*0.6)) size(*1.3) )  
	graph export "./output/Indonesia_worldbank/maps/labor_totals_`year'.png", as(png) width(3000) replace
	
	*average labor
	spmap lbr_avg if year==`year' using "./data/firm-data/Indonesia_worldbank/Shapefile/IDN_adm_shp/IDN_adm1_dissolved_coordinates.dta", id(_ID) clnumber(5) fcolor(Oranges) title("Average Labor by province, `year'", size(*0.8)) legend(title("Average Labor",  size(*0.6)) size(*1.3) ) 
	graph export "./output/Indonesia_worldbank/maps/labor_avg_`year'.png", as(png) width(3000) replace
	
	*total capital
	spmap kap_mln if year==`year' using "./data/firm-data/Indonesia_worldbank/Shapefile/IDN_adm_shp/IDN_adm1_dissolved_coordinates.dta", id(_ID) clnumber(5) fcolor(Oranges) title("Total Capital (mln rupees) by province, `year'", size(*0.8)) legend(title("Total Capital (mln rupees)",  size(*0.6)) size(*1.3) )  
	graph export "./output/Indonesia_worldbank/maps/capital_totals_`year'.png", as(png) width(3000) replace
	
	*average capital 
	spmap output_mln_avg if year==`year' using "./data/firm-data/Indonesia_worldbank/Shapefile/IDN_adm_shp/IDN_adm1_dissolved_coordinates.dta", id(_ID) clnumber(5) fcolor(Oranges) title("Average Firm Capital (mln rupees) by province, `year'", size(*0.8)) legend(title("Average Firm Capital (mln rupees)",  size(*0.6)) size(*1.3) ) 
	graph export "./output/Indonesia_worldbank/maps/capital_avg_`year'.png", as(png) width(3000) replace 
	
	*average productivity
	spmap labprod_avg if year==`year' using "./data/firm-data/Indonesia_worldbank/Shapefile/IDN_adm_shp/IDN_adm1_dissolved_coordinates.dta", id(_ID) clnumber(5) fcolor(Oranges) title("Average Labor Productivity by province, `year'", size(*0.8)) legend(title("Average Labor Productivity",  size(*0.6)) size(*1.3) ) 
	graph export "./output/Indonesia_worldbank/maps/labprod_avg_`year'.png", as(png) width(3000) replace
	
}

*AVERAGE ACROSS YEARS?


restore */
********************************************************************************











