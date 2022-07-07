
use "/Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters/data/firm-data/clean-with-eq-ready-to-regress/Indonesia_adm2_ready2regress_with_eq.dta", clear

*drop 1st obs (since it doesn't have defined growth)
sort plant year
drop if n ==1 //defined previously as the first year
bys plant: gen obs = _N

*all firm-years have labor diff observations
*sum log_labor_diff




*bys plant: egen size = mean(labor)


* For labor - 6th lag is always positive and stat sign. Why?
* for larger firms this effect is bigger
*areg log_labor_diff mpga_aw_lag6 i.year, absorb(plant) vce(cluster plant)
*areg log_labor_diff mpga_aw_lag6 i.year [aweight = size], absorb(plant) vce(cluster plant)
*areg log_labor_diff mpga_aw_lag* c.year##i.region, absorb(plant) vce(cluster plant)


* how to identify influential observation/subsample that drives result



*
preserve
bys region year: drop if _n>1
restore 




* just a draft for understnading the magical 7th lag


sort plant year
bys plant: drop if _n==1
bys plant: gen obs = _N

gen log_capital_diff_exits = 1 if !missing(log_capital_diff)
bys plant: egen obs_log_capital_diff_exists = total(log_capital_diff_exits)
        
tab obs obs_log_capital_diff_exists

gen non_zero = 1 if obs ==  obs_log_capital_diff_exits



areg log_capital_diff_const mpga_aw_lag7 i.year if obs==7, absorb(plant) vce(cluster plant)

 






















