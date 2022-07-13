*#############################################################################
*Program for appending local projections results into one column 
*#############################################################################

capt prog drop appendmodels
*! version 1.0.0  14aug2007  Ben Jann
program appendmodels, eclass
    // using first equation of model
    version 8
    syntax namelist
    tempname b V tmp
    foreach name of local namelist {
        qui est restore `name'
        mat `tmp' = e(b)
        local eq1: coleq `tmp'
        gettoken eq1 : eq1
        mat `tmp' = `tmp'[1,"`eq1':"]
        local cons = colnumb(`tmp',"_cons")
        if `cons'<. & `cons'>1 {
            mat `tmp' = `tmp'[1,1..`cons'-1]
        }
        mat `b' = nullmat(`b') , `tmp'
        mat `tmp' = e(V)
        mat `tmp' = `tmp'["`eq1':","`eq1':"]
        if `cons'<. & `cons'>1 {
            mat `tmp' = `tmp'[1..`cons'-1,1..`cons'-1]
        }
        capt confirm matrix `V'
        if _rc {
            mat `V' = `tmp'
        }
        else {
            mat `V' = ///
            ( `V' , J(rowsof(`V'),colsof(`tmp'),0) ) \ ///
            ( J(rowsof(`tmp'),colsof(`V'),0) , `tmp' )
        }
    }
    local names: colfullnames `b'
    mat coln `V' = `names'
    mat rown `V' = `names'
    eret post `b' `V'
    eret local cmd "whatever"
end

*#############################################################################
*cd /Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters
cd /Users/alinagafanova/Library/CloudStorage/Box-Box/recovery-from-disasters

* Housekeeping
clear
clear matrix
set more off

/*import delimited "./data/tropical-cyclones/intermediate/India/maxWindsADM2_with_population.csv", encoding(ISO-8859-9) clear 
drop v1
rename id_2 ID_2
save "./data/tropical-cyclones/intermediate/India/maxWindsADM2_with_population.dta", replace */

*#############################################################################*/
*Part 0. Clean survey
*#############################################################################

use "./data/firm-data/India/Final-Dataset/India_survey_readytoregress.dta", clear 

*drop observations without panel ID 
drop if panelID==.

*after 2008 - only 2 regions exist have spatial IDs
keep if year<2008

merge m:1 year using "./data/firm-data/India/Final-Dataset/wpi_india_2010.dta"
keep if _m==3
drop _m

tempfile survey
save "`survey'"  


*#############################################################################*/
*Part I. Adding lags to the shaking data
*#############################################################################
use "./data/earthquakes/intermediate/India_adm2/region_panel/panel_earthquakes_thresh_10.dta"
keep if year>=1975&year<=2011

*rename since the names are too long
rename populatedmpga_aw popmpga_aw 
rename populatednum_qs_aw popnum_qs_aw
label var popmpga_aw "MPGA (\%g)"
label var popnum_qs_aw "N of EQs"

*add lags
sort region year
foreach i of num 1/10 {
	foreach var in popmpga_aw  popnum_qs_aw{
		by region: gen `var'_lag`i' = `var'[_n-`i']
		label var `var'_lag`i' "Lag `i'"
	}
}

*#############################################################################

/*Testing for autocorrelation: 10 lags

* Partial dataset (1985-2007)

preserve
eststo clear
local treat
local out 
keep if year>=1985&year<=2007
foreach i of num 1/10 {
	local treat `treat' popmpga_aw_lag`i'
	quietly: eststo d`i': areg popmpga_aw `treat', absorb(region) vce(robust)
	local out `out' d`i'
	
}
esttab `out' using ./output/regressions_tex/India/autocorr_1985_2007_simult_num.tex, se label s(N, labels("N") fmt(%9.0f)) replace nocon b(3) mtitles("MPGA" "N" "N" "N" "N" "N" "N" "N" "N" "N")
restore


preserve
eststo clear
local treat
local out 
keep if year>=1985&year<=2007
foreach i of num 1/10 {
	local treat `treat' popnum_qs_aw_lag`i'
	quietly: eststo d`i': areg popnum_qs_aw `treat', absorb(region) vce(robust)
	local out `out' d`i'
	
}
esttab `out' using ./output/regressions_tex/India/autocorr_1985_2007_simult_mpga.tex, se label s(N, labels("N") fmt(%9.0f)) replace nocon b(3) mtitles("N of EQs" "" "" "" "" "" "" "" "" "")
restore

*############################################################################# */


drop if year<1985
drop if year>2007

*#############################################################################*/
*Part II. Combining shaking and survey
*#############################################################################
rename region id_used 
merge 1:m id_used year using "`survey'"  
rename id_used region

*PLENTY OF MISSING SPATIAL IDs 
keep if _m==3
drop _m
rename panelID plant

*generate new vars
gen avg_wage = wages/employees
rename imports importmaterials

*domesticmaterials importmaterials exports

*create real values for a subset of variables
foreach dep in output sales avg_wage labcost materials capital fuels disttotout {
	gen r`dep' = `dep'/wpi2010
}

*create logged vars
foreach dep in routput rsales ravg_wage rlabcost rmaterials rcapital rfuels employees rdisttotout{
	gen log_`dep' = 100*log(`dep')
}

*dummies if variables exist
foreach dep in routput rsales ravg_wage rlabcost rmaterials rcapital rfuels employees rdisttotout{
	gen log_`dep'_exists = 1 if log_`dep'!=.
	replace log_`dep'_exists = 0 if log_`dep'_exists==.
}

******************************************************************************************************

*change variable labels for better titles
label var log_routput "100Log(Output)" 
label var log_rsales "100Log(Sales)" 
label var log_employees "100Log(L)"
label var log_ravg_wage "100Log(Avg Wage)"
label var log_rcapital "100Log(K)"
label var log_rmaterials "100Log(Mat)"
label var log_rlabcost "100Log(L Cost)"
label var log_rfuels "100Log(Fuels)"
label var log_rdisttotout "100Log(Distr Cost)"

gen popmpga_aw_lag0 = popmpga_aw
label var popmpga_aw_lag0 "MPGA (\%g)"

gen popnum_qs_aw_lag0 = popnum_qs_aw
label var popnum_qs_aw_lag0 "N of EQs"

******************************************************************************************************


keep if log_routput_exists==1&log_routput_exists==1&log_rsales_exists==1&log_ravg_wage_exists==1&log_rlabcost_exists==1&log_rmaterials_exists==1&log_rcapital_exists==1&log_rfuels_exists==1&log_employees_exists==1&log_rdisttotout_exists==1

preserve
sort plant year
eststo clear


foreach var in popmpga_aw popnum_qs_aw  {
	
	foreach dep in log_routput log_rsales log_employees log_ravg_wage log_rlabcost {		
		foreach val of numlist 0/5 {
			eststo est`val': quietly: reghdfe `dep' `var'_lag`val', absorb(plant year) vce(cluster plant region#year) 
		}
		eststo combined_`dep': appendmodels est0 est1 est2 est3 est4 est5
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace
		quietly: estadd local N "439138" , replace
	}
	esttab combined_log_routput combined_log_rsales combined_log_employees combined_log_ravg_wage combined_log_rlabcost  using ./output/regressions_tex/India/table_`var'_jorda_p1.tex, se noconstant title("India, ground shaking, 1985-2007, Jorda method (p.1)") replace booktabs compress addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level." "All the results are from local projections, following Jorda (2005).") s(N firm year , labels("N" "Plant FE" "Year FE" )) label mtitles("100Log(Output)" "100Log(Sales)" "100Log(L)"  "100Log(Avg Wage)" "100Log(L Cost)")
}



eststo clear

foreach var in popmpga_aw popnum_qs_aw  {
	
	foreach dep in log_rcapital log_rmaterials log_rfuels log_rdisttotout {		
		foreach val of numlist 0/5 {
			eststo est`val': quietly: reghdfe `dep' `var'_lag`val', absorb(plant year) vce(cluster plant region#year) 
		}
		eststo combined_`dep': appendmodels est0 est1 est2 est3 est4 est5
		quietly: estadd local firm "Yes" , replace
		quietly: estadd local year "Yes" , replace
		quietly: estadd local N "439138" , replace
	}
	esttab combined_log_rcapital combined_log_rmaterials combined_log_rfuels combined_log_rdisttotout using ./output/regressions_tex/India/table_`var'_jorda_p2.tex, se noconstant title("India, ground shaking, 1985-2007, Jorda method (p.2)") replace booktabs compress addnotes("Plant and year fixed effects are included in each specification. All variables are real values." "Errors are clustered on both plant-level and region-by-year level." "All the results are from local projections, following Jorda (2005).") s(N firm year , labels("N" "Plant FE" "Year FE" )) label mtitles("100Log(K)" "100Log(Mat)" "100Log(Fuels)" "100Log(Distr Cost)")
}

restore





id
668870
203964















 
