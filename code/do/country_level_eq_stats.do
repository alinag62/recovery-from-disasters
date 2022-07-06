cd /Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters

*#############################################################################
set scheme plottig 
grstyle init
grstyle set imesh, horizontal minor
grstyle set ci 538, select(13 10) opacity(60)
grstyle set color "35 35 35" "35 35 35"  "62 102 206"  "62 102 206"
*#############################################################################

*append all files with countries' stats (remake it later with a loop)
import delimited "./data/earthquakes/intermediate/summary_stats/Chile.csv", encoding(UTF-8) clear 
gen country = "Chile"

tempfile to_append 
sa "`to_append'"

import delimited "./data/earthquakes/intermediate/summary_stats/Colombia.csv", encoding(UTF-8) clear 
gen country = "Colombia"
append using `to_append'

tempfile to_append 
sa "`to_append'"

import delimited "./data/earthquakes/intermediate/summary_stats/Côte d'Ivoire.csv", encoding(UTF-8) clear 
gen country = "Côte d'Ivoire"
append using `to_append'

tempfile to_append 
sa "`to_append'"

import delimited "./data/earthquakes/intermediate/summary_stats/El Salvador.csv", encoding(UTF-8) clear 
gen country = "El Salvador"
append using `to_append'

tempfile to_append 
sa "`to_append'"

import delimited "./data/earthquakes/intermediate/summary_stats/Ethiopia.csv", encoding(UTF-8) clear 
gen country = "Ethiopia"
append using `to_append'

tempfile to_append 
sa "`to_append'"

import delimited "./data/earthquakes/intermediate/summary_stats/Indonesia.csv", encoding(UTF-8) clear 
gen country = "Indonesia"
append using `to_append'

tempfile to_append 
sa "`to_append'"

import delimited "./data/earthquakes/intermediate/summary_stats/Moldova.csv", encoding(UTF-8) clear 
gen country = "Moldova"
append using `to_append'

tempfile to_append 
sa "`to_append'"

import delimited "./data/earthquakes/intermediate/summary_stats/Vietnam.csv", encoding(UTF-8) clear 
gen country = "Vietnam"
append using `to_append'

tempfile to_append 
sa "`to_append'"

import delimited "./data/earthquakes/intermediate/summary_stats/Philippines.csv", encoding(UTF-8) clear 
gen country = "Philippines"
append using `to_append'

tempfile to_append 
sa "`to_append'"

import delimited "./data/earthquakes/intermediate/summary_stats/Mexico.csv", encoding(UTF-8) clear 
gen country = "Mexico"
append using `to_append'

tempfile to_append 
sa "`to_append'"

import delimited "./data/earthquakes/intermediate/summary_stats/Japan.csv", encoding(UTF-8) clear 
gen country = "Japan"
append using `to_append'

tempfile to_append 
sa "`to_append'"

import delimited "./data/earthquakes/intermediate/summary_stats/India.csv", encoding(UTF-8) clear 
gen country = "India"
append using `to_append'

tempfile to_append 
sa "`to_append'"

import delimited "./data/earthquakes/intermediate/summary_stats/United States of America.csv", encoding(UTF-8) clear 
gen country = "USA"
append using `to_append'

tempfile to_append 
sa "`to_append'" 

*clean

rename v1 id
rename v2 year
rename v3 mpga
rename v4 area_pga_more1
rename v5 area_pga_more2
rename v6 area_pga_more10

/*#############################################################################
*Indonesia Detailed Stats: 1973-2018
*#############################################################################
preserve

append using "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/adm2_areas.dta"

*Histogram: ADM2 regions area vs area of EQ: 1/2/10*

twoway (hist indonesia_adm2_area_sqkm, color(green%40) width(5000) start(0) percent) (hist area_pga_more1 if country=="Indonesia",  color(red%30) width(5000) start(0) percent),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "Areas of ADM2 regions" 2 "Areas of EQ (PGA >1)" ) position(6))
graph export "./output/Indonesia/figs/area_eq_pga1_distr.png", as(png) replace

twoway (hist indonesia_adm2_area_sqkm if indonesia_adm2_area_sqkm<100000, color(green%40) width(2500) start(0) percent) (hist area_pga_more1 if country=="Indonesia"&area_pga_more1<100000,  color(red%30) width(2500) start(0) percent),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "Areas of ADM2 regions" 2 "Areas of EQ (PGA >1)" ) position(6))
graph export "./output/Indonesia/figs/area_eq_pga1_distr_no_outliers.png", as(png) replace

twoway (hist indonesia_adm2_area_sqkm, color(green%40) width(5000) start(0) percent) (hist area_pga_more2 if country=="Indonesia",  color(red%30) width(5000) start(0) percent),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "Areas of ADM2 regions" 2 "Areas of EQ (PGA >2)" ) position(6))
graph export "./output/Indonesia/figs/area_eq_pga2_distr.png", as(png) replace

twoway (hist indonesia_adm2_area_sqkm if indonesia_adm2_area_sqkm<100000, color(green%40) width(5000) start(0) percent) (hist area_pga_more2 if country=="Indonesia"&area_pga_more2<100000,  color(red%30) width(5000) start(0) percent),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "Areas of ADM2 regions" 2 "Areas of EQ (PGA >2)" ) position(6))
graph export "./output/Indonesia/figs/area_eq_pga2_distr_no_outliers.png", as(png) replace

twoway (hist indonesia_adm2_area_sqkm, color(green%40) width(2500) start(0) percent) (hist area_pga_more10 if country=="Indonesia",  color(red%30) width(2500) start(0) percent),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "Areas of ADM2 regions" 2 "Areas of EQ (PGA >10)" ) position(6))
graph export "./output/Indonesia/figs/area_eq_pga10_distr.png", as(png) replace

twoway (hist indonesia_adm2_area_sqkm if indonesia_adm2_area_sqkm<25000, color(green%40) width(1000) start(0) percent) (hist area_pga_more10 if country=="Indonesia"&area_pga_more10<25000,  color(red%30) width(1000) start(0) percent),  plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) legend(order(1 "Areas of ADM2 regions" 2 "Areas of EQ (PGA >10)" ) position(6))
graph export "./output/Indonesia/figs/area_eq_pga10_distr_no_outliers.png", as(png) replace


*Histogram: distribution of max pga*

twoway (hist mpga if country=="Indonesia", color(orange%40) width(2.5) start(0) percent), plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) xtitle("Distribution of Maximum PGA by Shaking Events")
graph export "./output/Indonesia/figs/mpga_distr.png", as(png) replace


* Scatter Plot: area vs year*
twoway (scatter area_pga_more1 year if country=="Indonesia", color(orange%40)), plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) ytitle("Area of Shaking (PGA >1)")
graph export "./output/Indonesia/figs/pga1_vs_year.png", as(png) replace

twoway (scatter area_pga_more10 year if country=="Indonesia", color(orange%40)), plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) ytitle("Area of Shaking (PGA >10)")
graph export "./output/Indonesia/figs/pga10_vs_year.png", as(png) replace


twoway (scatter area_pga_more10 year if country=="Indonesia"&area_pga_more1<50000, color(orange%40)) (lfit  area_pga_more10 year if country=="Indonesia"&area_pga_more1<50000, lcolor(black%40) leg(off)), plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) ytitle("Area of Shaking (PGA >10)")
graph export "./output/Indonesia/figs/pga10_vs_year_no_outliers.png", as(png) replace


* Scatter Plot: mpga vs year

twoway (scatter mpga year if country=="Indonesia", color(orange%40)) (lfit  mpga year if country=="Indonesia", lcolor(black%40) leg(off)), plotregion(  fcolor(white) ) xlabel(,grid glcolor(black%5)) ylabel(,grid glcolor(black%5)) ytitle("Maximum PGA")
graph export "./output/Indonesia/figs/mpga_vs_year.png", as(png) replace

restore */

*#############################################################################
*Comparing Countries: 1973-2018
*#############################################################################

keep if mpga>1

gen i = 1

bys country: egen median_mpga = median(mpga)
bys country: egen area_median_pga1 = median(area_pga_more1)
bys country: egen area_median_pga2 = median(area_pga_more2)
bys country: egen area_median_pga10 = median(area_pga_more10)
bys country: egen area_mean_pga10 = mean(area_pga_more10)

collapse (first) median_mpga area_median_pga1 area_median_pga2 area_median_pga10 area_mean_pga10 (sum) i, by(country)

order country i









































