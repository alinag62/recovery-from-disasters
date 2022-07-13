cd /Users/alinagafanova/Library/CloudStorage/Box-Box/recovery-from-disasters/
clear all
******************************************************************************
*II. India: ADM2 data
clear all
import delimited "./data/tropical-cyclones/intermediate/India/raw_data_points_adm2_lvl.csv"
keep if track_type=="main"
gen V_m = usa_wind
keep if V_m!=.
keep V_m season id_2
gen V_m_2 = V_m
collapse (mean) V_m (max) V_m_2, by(season id_2)
rename season year
rename id_2 adm2
rename V_m mean_wind_speed
rename V_m_2 max_wind_speed

*generate lags
tsset adm2 year
tsfill, full
replace mean_wind_speed = 0 if mean_wind_speed==.
replace max_wind_speed = 0 if max_wind_speed==.
sort adm2 year

foreach i of num 1/20 {
	by adm2: gen mean_wind_speed_lag`i' = mean_wind_speed[_n-`i']
	by adm2: gen max_wind_speed_lag`i' = max_wind_speed[_n-`i']
	
	label var mean_wind_speed_lag`i' "Lag `i'"
	label var max_wind_speed_lag`i' "Lag `i'"
}

*II.I. All years

preserve
eststo clear
keep if year>=1992
foreach var in max_wind_speed {
	eststo clear
	local treat
	local out 
	foreach i of num 1/10 {
		local treat `treat' `var'_lag`i'
		quietly: eststo d`i': areg `var' `treat', absorb(adm2) vce(robust)
		local out `out' d`i'
	}
	esttab `out' using ./output/regressions_tex/India/autocorr_raw_data_since_1965_`var'_adm2.tex, se label s(N, labels("N") fmt(%9.0f)) replace nocon b(3) mtitles("?" "" "" "" "" "" "" "" "" "") title("Results of autoregressions of cyclones in India (ADM2), 1992-2020")
	eststo clear
}

eststo clear
foreach var in max_wind_speed {
	eststo clear
	local treat
	local part1
	local part2
	local out 
	
	foreach i of num 1/10 {
		local treat `treat' `var'_lag`i'
	}
	
	foreach i of num 1/10 {
		local part1 `part1' `var'_lag`i'
	}

	foreach i of num 11/20 {
		local part2 `part2' `var'_lag`i'
	}

	foreach i of num 11/20 {
		local treat `treat' `var'_lag`i'
		quietly: eststo d`i': areg `var' `treat', absorb(adm2) vce(robust)
		local out `out' d`i'
	}
	
	esttab `out' using ./output/regressions_tex/India/autocorr_raw_data_since_1965_`var'_adm2_20lags_p1.tex, se label s(N, labels("N") fmt(%9.0f)) replace nocon b(3) mtitles("?" "" "" "" "" "" "" "" "" "") title("Results of autoregressions of cyclones in India (ADM2), 1992-2020") keep(`part1')
	esttab `out' using ./output/regressions_tex/India/autocorr_raw_data_since_1965_`var'_adm2_20lags_p2.tex, se label s(N, labels("N") fmt(%9.0f)) replace nocon b(3) mtitles("?" "" "" "" "" "" "" "" "" "") title("Results of autoregressions of cyclones in India (ADM2), 1992-2020") keep(`part2')
	
}

restore
















