*
* Running basic regressions for 3 countries to compare those
*

/*
###########################################################################
                    Intro
########################################################################### */
cd /Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters

* Housekeeping
clear
clear matrix
set more off

local r2r_folder "./data/firm-data/clean-with-eq-ready-to-regress/"
local results_country "./output/regressions_tex/simultaneous_regs"

*#############################################################################
*1. Running regressions
*#############################################################################

/*#############################################################################
*1. first few lags
*#############################################################################

foreach dep in labor wages tot_invent_eoy capital output exports dom_sales tot_invest bldings_val {
	
	use `r2r_folder'/Indonesia_adm2_ready2regress_with_eq.dta

	*drop observations that don't have all 10 lags (balanced panel)
	drop if mpga_aw_lag10==.
	
	eststo clear
	local treat mpga_aw
	quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
	est sto m0_idn

	foreach i of num 1/3 {
	local treat `treat' mpga_aw_lag`i'
	di("`treat'")
	quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
	est sto m`i'_idn
	}

	use `r2r_folder'/India_adm2_ready2regress_with_eq.dta

	*drop observations that don't have all 10 lags (balanced panel)
	drop if mpga_aw_lag10==.
	
	local treat mpga_aw
	quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
	est sto m0_ind

	foreach i of num 1/3 {
	local treat `treat' mpga_aw_lag`i'
	di("`treat'")
	quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
	est sto m`i'_ind
	}

	use `r2r_folder'/Colombia_adm2_ready2regress_with_eq.dta

	*drop observations that don't have all 10 lags (balanced panel)
	drop if mpga_aw_lag10==.
	
	local treat mpga_aw
	quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
	est sto m0_col

	foreach i of num 1/3 {
	local treat `treat' mpga_aw_lag`i'
	di("`treat'")
	quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
	est sto m`i'_col
	}

	local results_country "./output/regressions_tex/simultaneous_regs"
	local treat mpga_aw_lag1 mpga_aw_lag2 mpga_aw_lag3 mpga_aw
	local results m0_idn m1_idn m2_idn m3_idn m0_ind m1_ind m2_ind m3_ind m0_col m1_col m2_col m3_col

	esttab `results' using `results_country'/`dep'.tex, se noconstant nomtitles keep(`treat') replace booktabs label compress title("Dependent variable: `: var label `dep''. Indonesia: (1)-(4), India: (5)-(8), Colombia: (9)-(12).")
	
	clear all

}
*/
/*#############################################################################
*2. 5 and 10 lags
*#############################################################################

foreach dep in labor wages tot_invent_eoy capital output exports {
	use `r2r_folder'/Indonesia_adm2_ready2regress_with_eq.dta, clear
	
	*drop observations that don't have all 10 lags (balanced panel)
	drop if mpga_aw_lag10==.
	
	eststo clear
	local treat mpga_aw

	foreach i of num 1/5 {
	local treat `treat' mpga_aw_lag`i'
	di("`treat'")
	}
	
	quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
	est sto m5_idn
	
	foreach i of num 6/10 {
	local treat `treat' mpga_aw_lag`i'
	di("`treat'")
	}
	
	quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
	est sto m10_idn

	use `r2r_folder'/India_adm2_ready2regress_with_eq.dta, clear
	
	*drop observations that don't have all 10 lags (balanced panel)
	drop if mpga_aw_lag10==.
	
	eststo clear
	local treat mpga_aw

	foreach i of num 1/5 {
	local treat `treat' mpga_aw_lag`i'
	di("`treat'")
	}
	
	quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
	est sto m5_ind
	
	foreach i of num 6/10 {
	local treat `treat' mpga_aw_lag`i'
	di("`treat'")
	}
	
	quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
	est sto m10_ind
	
	use `r2r_folder'/Colombia_adm2_ready2regress_with_eq.dta, clear
	
	*drop observations that don't have all 10 lags (balanced panel)
	drop if mpga_aw_lag10==.
	
	eststo clear
	local treat mpga_aw

	foreach i of num 1/5 {
	local treat `treat' mpga_aw_lag`i'
	di("`treat'")
	}
	
	quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
	est sto m5_col
	
	foreach i of num 6/10 {
	local treat `treat' mpga_aw_lag`i'
	di("`treat'")
	}
	
	quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
	est sto m10_col
	
	use `r2r_folder'/Colombia_adm1_ready2regress_with_eq.dta, clear
	
	*drop observations that don't have all 10 lags (balanced panel)
	drop if mpga_aw_lag10==.
	
	eststo clear
	local treat mpga_aw

	foreach i of num 1/5 {
	local treat `treat' mpga_aw_lag`i'
	di("`treat'")
	}
	
	quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
	est sto m5_col1
	
	foreach i of num 6/10 {
	local treat `treat' mpga_aw_lag`i'
	di("`treat'")
	}
	
	quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
	est sto m10_col1


	local results_country "./output/regressions_tex/simultaneous_regs"
	local results m5_idn m10_idn m5_ind m10_ind m5_col m10_col m5_col1 m10_col1

	esttab `results' using `results_country'/`dep'_5_and_10.tex, se noconstant nomtitles keep(`treat') replace booktabs label compress title("Dependent variable: `: var label `dep''. Indonesia: (1)-(2), India: (3)-(4), Colombia ADM2: (5)-(6), Colombia ADM1: (7)-(8).") addnotes("Year and plant fixed effects are included in each specification.")
	
	clear all

}

foreach dep in dom_sales {

	use `r2r_folder'/India_adm2_ready2regress_with_eq.dta, clear
	
	*drop observations that don't have all 10 lags (balanced panel)
	drop if mpga_aw_lag10==.	
	
	eststo clear
	local treat mpga_aw

	foreach i of num 1/5 {
	local treat `treat' mpga_aw_lag`i'
	di("`treat'")
	}
	
	quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
	est sto m5_ind
	
	foreach i of num 6/10 {
	local treat `treat' mpga_aw_lag`i'
	di("`treat'")
	}
	
	quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
	est sto m10_ind
	
	use `r2r_folder'/Colombia_adm2_ready2regress_with_eq.dta, clear

	*drop observations that don't have all 10 lags (balanced panel)
	drop if mpga_aw_lag10==.
	
	eststo clear
	local treat mpga_aw

	foreach i of num 1/5 {
	local treat `treat' mpga_aw_lag`i'
	di("`treat'")
	}
	
	quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
	est sto m5_col
	
	foreach i of num 6/10 {
	local treat `treat' mpga_aw_lag`i'
	di("`treat'")
	}
	
	quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
	est sto m10_col
	
	use `r2r_folder'/Colombia_adm1_ready2regress_with_eq.dta, clear

	*drop observations that don't have all 10 lags (balanced panel)
	drop if mpga_aw_lag10==.
	
	eststo clear
	local treat mpga_aw

	foreach i of num 1/5 {
	local treat `treat' mpga_aw_lag`i'
	di("`treat'")
	}
	
	quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
	est sto m5_col1
	
	foreach i of num 6/10 {
	local treat `treat' mpga_aw_lag`i'
	di("`treat'")
	}
	
	quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
	est sto m10_col1


	local results_country "./output/regressions_tex/simultaneous_regs"
	local results m5_ind m10_ind m5_col m10_col m5_col1 m10_col1

	esttab `results' using `results_country'/`dep'_5_and_10.tex, se noconstant nomtitles keep(`treat') replace booktabs label compress title("Dependent variable: `: var label `dep''. India: (1)-(2), Colombia ADM2: (3)-(4), Colombia ADM1: (5)-(6).") addnotes("Year and plant fixed effects are included in each specification.")
	
	clear all

}  

foreach dep in bldings_val tot_invest {

	use `r2r_folder'/Indonesia_adm2_ready2regress_with_eq.dta, clear
	
	*drop observations that don't have all 10 lags (balanced panel)
	drop if mpga_aw_lag10==.
	
	eststo clear
	local treat mpga_aw

	foreach i of num 1/5 {
	local treat `treat' mpga_aw_lag`i'
	di("`treat'")
	}
	
	quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
	est sto m5_idn
	
	foreach i of num 6/10 {
	local treat `treat' mpga_aw_lag`i'
	di("`treat'")
	}
	
	quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
	est sto m10_idn
	
	use `r2r_folder'/Colombia_adm2_ready2regress_with_eq.dta, clear
	
	*drop observations that don't have all 10 lags (balanced panel)
	drop if mpga_aw_lag10==.
	
	eststo clear
	local treat mpga_aw

	foreach i of num 1/5 {
	local treat `treat' mpga_aw_lag`i'
	di("`treat'")
	}
	
	quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
	est sto m5_col
	
	foreach i of num 6/10 {
	local treat `treat' mpga_aw_lag`i'
	di("`treat'")
	}
	
	quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
	est sto m10_col
	
	use `r2r_folder'/Colombia_adm1_ready2regress_with_eq.dta, clear
	
	*drop observations that don't have all 10 lags (balanced panel)
	drop if mpga_aw_lag10==.
	
	eststo clear
	local treat mpga_aw

	foreach i of num 1/5 {
	local treat `treat' mpga_aw_lag`i'
	di("`treat'")
	}
	
	quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
	est sto m5_col1
	
	foreach i of num 6/10 {
	local treat `treat' mpga_aw_lag`i'
	di("`treat'")
	}
	
	quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
	est sto m10_col1


	local results_country "./output/regressions_tex/simultaneous_regs"
	local results m5_idn m10_idn m5_col m10_col m5_col1 m10_col1

	esttab `results' using `results_country'/`dep'_5_and_10.tex, se noconstant nomtitles keep(`treat') replace booktabs label compress title("Dependent variable: `: var label `dep''. Indonesia: (1)-(2), Colombia ADM2: (3)-(4), Colombia ADM1: (5)-(6).") addnotes("Year and plant fixed effects are included in each specification.")
	
	clear all

}

/*#############################################################################*/
*3. 5 and 10 lags: different indep vars
*#############################################################################

foreach var in popmpga_aw num_qs_aw {
	foreach dep in labor wages tot_invent_eoy capital output exports {
		use `r2r_folder'/Indonesia_adm2_ready2regress_with_eq.dta, clear

		*drop observations that don't have all 10 lags (balanced panel)
		drop if mpga_aw_lag10==.
		
		eststo clear
		local treat `var'

		foreach i of num 1/5 {
		local treat `treat' `var'_lag`i'
		di("`treat'")
		}
		
		quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m5_idn
		
		foreach i of num 6/10 {
		local treat `treat' `var'_lag`i'
		di("`treat'")
		}
		
		quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m10_idn

		use `r2r_folder'/India_adm2_ready2regress_with_eq.dta, clear
		
		*drop observations that don't have all 10 lags (balanced panel)
		drop if mpga_aw_lag10==.
		
		eststo clear
		local treat `var'

		foreach i of num 1/5 {
		local treat `treat' `var'_lag`i'
		di("`treat'")
		}
		
		quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m5_ind
		
		foreach i of num 6/10 {
		local treat `treat' `var'_lag`i'
		di("`treat'")
		}
		
		quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m10_ind
		
		use `r2r_folder'/Colombia_adm2_ready2regress_with_eq.dta, clear
		
		*drop observations that don't have all 10 lags (balanced panel)
		drop if mpga_aw_lag10==.
		
		eststo clear
		local treat `var'

		foreach i of num 1/5 {
		local treat `treat' `var'_lag`i'
		di("`treat'")
		}
		
		quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m5_col
		
		foreach i of num 6/10 {
		local treat `treat' `var'_lag`i'
		di("`treat'")
		}
		
		quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m10_col
		
		use `r2r_folder'/Colombia_adm1_ready2regress_with_eq.dta, clear
		
		*drop observations that don't have all 10 lags (balanced panel)
		drop if mpga_aw_lag10==.
		
		eststo clear
		local treat `var'

		foreach i of num 1/5 {
		local treat `treat' `var'_lag`i'
		di("`treat'")
		}
		
		quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m5_col1
		
		foreach i of num 6/10 {
		local treat `treat' `var'_lag`i'
		di("`treat'")
		}
		
		quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m10_col1


		local results_country "./output/regressions_tex/simultaneous_regs"
		local results m5_idn m10_idn m5_ind m10_ind m5_col m10_col m5_col1 m10_col1

		esttab `results' using `results_country'/`dep'_5_and_10_`var'.tex, se noconstant nomtitles keep(`treat') replace booktabs label compress title("Dependent variable: `: var label `dep''. Indonesia: (1)-(2), India: (3)-(4), Colombia ADM2: (5)-(6), Colombia ADM1: (7)-(8).") addnotes("Year and plant fixed effects are included in each specification.")
		
		clear all

	}

	foreach dep in dom_sales {

		use `r2r_folder'/India_adm2_ready2regress_with_eq.dta, clear
		
		*drop observations that don't have all 10 lags (balanced panel)
		drop if mpga_aw_lag10==.
		
		eststo clear
		local treat `var'

		foreach i of num 1/5 {
		local treat `treat' `var'_lag`i'
		di("`treat'")
		}
		
		quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m5_ind
		
		foreach i of num 6/10 {
		local treat `treat' `var'_lag`i'
		di("`treat'")
		}
		
		quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m10_ind
		
		use `r2r_folder'/Colombia_adm2_ready2regress_with_eq.dta, clear
		
		*drop observations that don't have all 10 lags (balanced panel)
		drop if mpga_aw_lag10==.
		
		eststo clear
		local treat `var'

		foreach i of num 1/5 {
		local treat `treat' `var'_lag`i'
		di("`treat'")
		}
		
		quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m5_col
		
		foreach i of num 6/10 {
		local treat `treat' `var'_lag`i'
		di("`treat'")
		}
		
		quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m10_col
		
		use `r2r_folder'/Colombia_adm1_ready2regress_with_eq.dta, clear
		
		*drop observations that don't have all 10 lags (balanced panel)
		drop if mpga_aw_lag10==.
		
		eststo clear
		local treat `var'

		foreach i of num 1/5 {
		local treat `treat' `var'_lag`i'
		di("`treat'")
		}
		
		quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m5_col1
		
		foreach i of num 6/10 {
		local treat `treat' `var'_lag`i'
		di("`treat'")
		}
		
		quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m10_col1


		local results_country "./output/regressions_tex/simultaneous_regs"
		local results m5_ind m10_ind m5_col m10_col m5_col1 m10_col1

		esttab `results' using `results_country'/`dep'_5_and_10_`var'.tex, se noconstant nomtitles keep(`treat') replace booktabs label compress title("Dependent variable: `: var label `dep''. India: (1)-(2), Colombia ADM2: (3)-(4), Colombia ADM1: (5)-(6).") addnotes("Year and plant fixed effects are included in each specification.")
		
		clear all

	}  

	foreach dep in bldings_val tot_invest {

		use `r2r_folder'/Indonesia_adm2_ready2regress_with_eq.dta, clear
		
		*drop observations that don't have all 10 lags (balanced panel)
		drop if mpga_aw_lag10==.
		
		eststo clear
		local treat `var'

		foreach i of num 1/5 {
		local treat `treat' `var'_lag`i'
		di("`treat'")
		}
		
		quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m5_idn
		
		foreach i of num 6/10 {
		local treat `treat' `var'_lag`i'
		di("`treat'")
		}
		
		quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m10_idn
		
		use `r2r_folder'/Colombia_adm2_ready2regress_with_eq.dta, clear
		
		*drop observations that don't have all 10 lags (balanced panel)
		drop if mpga_aw_lag10==.
		
		eststo clear
		local treat `var'

		foreach i of num 1/5 {
		local treat `treat' `var'_lag`i'
		di("`treat'")
		}
		
		quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m5_col
		
		foreach i of num 6/10 {
		local treat `treat' `var'_lag`i'
		di("`treat'")
		}
		
		quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m10_col
		
		use `r2r_folder'/Colombia_adm1_ready2regress_with_eq.dta, clear
		*drop observations that don't have all 10 lags (balanced panel)
		drop if mpga_aw_lag10==.
		
		eststo clear
		local treat `var'

		foreach i of num 1/5 {
		local treat `treat' `var'_lag`i'
		di("`treat'")
		}
		
		quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m5_col1
		
		foreach i of num 6/10 {
		local treat `treat' `var'_lag`i'
		di("`treat'")
		}
		
		quietly: areg log_`dep'_diff `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m10_col1


		local results_country "./output/regressions_tex/simultaneous_regs"
		local results m5_idn m10_idn m5_col m10_col m5_col1 m10_col1

		esttab `results' using `results_country'/`dep'_5_and_10_`var'.tex, se noconstant nomtitles keep(`treat') replace booktabs label compress title("Dependent variable: `: var label `dep''. Indonesia: (1)-(2), Colombia ADM2: (3)-(4), Colombia ADM1: (5)-(6).") addnotes("Year and plant fixed effects are included in each specification.")
		
		clear all

	}

} */

/*#############################################################################*/
*3. 5 and 10 lags: different indep vars; linear specification
*#############################################################################

foreach var in mpga_aw popmpga_aw num_qs_aw {
	foreach dep in labor wages tot_invent_eoy capital output exports {
		use `r2r_folder'/Indonesia_adm2_ready2regress_with_eq.dta, clear
		
		*drop observations that don't have all 10 lags (balanced panel)
		drop if mpga_aw_lag10==.
		
		eststo clear
		local treat `var'

		foreach i of num 1/5 {
		local treat `treat' `var'_lag`i'
		di("`treat'")
		}
		
		quietly: areg `dep' `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m5_idn
		
		foreach i of num 6/10 {
		local treat `treat' `var'_lag`i'
		di("`treat'")
		}
		
		quietly: areg `dep' `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m10_idn

		use `r2r_folder'/India_adm2_ready2regress_with_eq.dta, clear
		
		*drop observations that don't have all 10 lags (balanced panel)
		drop if mpga_aw_lag10==.
		
		eststo clear
		local treat `var'

		foreach i of num 1/5 {
		local treat `treat' `var'_lag`i'
		di("`treat'")
		}
		
		quietly: areg `dep' `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m5_ind
		
		foreach i of num 6/10 {
		local treat `treat' `var'_lag`i'
		di("`treat'")
		}
		
		quietly: areg `dep' `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m10_ind
		
		use `r2r_folder'/Colombia_adm2_ready2regress_with_eq.dta, clear
		
		*drop observations that don't have all 10 lags (balanced panel)
		drop if mpga_aw_lag10==.
		
		eststo clear
		local treat `var'

		foreach i of num 1/5 {
		local treat `treat' `var'_lag`i'
		di("`treat'")
		}
		
		quietly: areg `dep' `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m5_col
		
		foreach i of num 6/10 {
		local treat `treat' `var'_lag`i'
		di("`treat'")
		}
		
		quietly: areg `dep' `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m10_col
		
		use `r2r_folder'/Colombia_adm1_ready2regress_with_eq.dta, clear
		
		*drop observations that don't have all 10 lags (balanced panel)
		drop if mpga_aw_lag10==.
		
		eststo clear
		local treat `var'

		foreach i of num 1/5 {
		local treat `treat' `var'_lag`i'
		di("`treat'")
		}
		
		quietly: areg `dep' `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m5_col1
		
		foreach i of num 6/10 {
		local treat `treat' `var'_lag`i'
		di("`treat'")
		}
		
		quietly: areg `dep' `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m10_col1


		local results_country "./output/regressions_tex/simultaneous_regs"
		local results m5_idn m10_idn m5_ind m10_ind m5_col m10_col m5_col1 m10_col1

		esttab `results' using `results_country'/`dep'_5_and_10_`var'_linear.tex, se noconstant nomtitles keep(`treat') replace booktabs label compress title("Dependent variable: `: var label `dep''. Indonesia: (1)-(2), India: (3)-(4), Colombia ADM2: (5)-(6), Colombia ADM1: (7)-(8). Linear Specification. ") addnotes("Year and plant fixed effects are included in each specification.")
		
		clear all

	}

	foreach dep in dom_sales {

		use `r2r_folder'/India_adm2_ready2regress_with_eq.dta, clear
		
		*drop observations that don't have all 10 lags (balanced panel)
		drop if mpga_aw_lag10==.
		
		eststo clear
		local treat `var'

		foreach i of num 1/5 {
		local treat `treat' `var'_lag`i'
		di("`treat'")
		}
		
		quietly: areg `dep' `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m5_ind
		
		foreach i of num 6/10 {
		local treat `treat' `var'_lag`i'
		di("`treat'")
		}
		
		quietly: areg `dep' `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m10_ind
		
		use `r2r_folder'/Colombia_adm2_ready2regress_with_eq.dta, clear
		
		*drop observations that don't have all 10 lags (balanced panel)
		drop if mpga_aw_lag10==.
		
		eststo clear
		local treat `var'

		foreach i of num 1/5 {
		local treat `treat' `var'_lag`i'
		di("`treat'")
		}
		
		quietly: areg `dep' `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m5_col
		
		foreach i of num 6/10 {
		local treat `treat' `var'_lag`i'
		di("`treat'")
		}
		
		quietly: areg `dep' `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m10_col
		
		use `r2r_folder'/Colombia_adm1_ready2regress_with_eq.dta, clear
		
		*drop observations that don't have all 10 lags (balanced panel)
		drop if mpga_aw_lag10==.
		
		eststo clear
		local treat `var'

		foreach i of num 1/5 {
		local treat `treat' `var'_lag`i'
		di("`treat'")
		}
		
		quietly: areg `dep' `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m5_col1
		
		foreach i of num 6/10 {
		local treat `treat' `var'_lag`i'
		di("`treat'")
		}
		
		quietly: areg `dep' `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m10_col1


		local results_country "./output/regressions_tex/simultaneous_regs"
		local results m5_ind m10_ind m5_col m10_col m5_col1 m10_col1

		esttab `results' using `results_country'/`dep'_5_and_10_`var'_linear.tex, se noconstant nomtitles keep(`treat') replace booktabs label compress title("Dependent variable: `: var label `dep''. India: (1)-(2), Colombia ADM2: (3)-(4), Colombia ADM1: (5)-(6). Linear Specification.") addnotes("Year and plant fixed effects are included in each specification.")
		
		clear all

	}  

	foreach dep in bldings_val tot_invest {

		use `r2r_folder'/Indonesia_adm2_ready2regress_with_eq.dta, clear
		
		*drop observations that don't have all 10 lags (balanced panel)
		drop if mpga_aw_lag10==.
		
		eststo clear
		local treat `var'

		foreach i of num 1/5 {
		local treat `treat' `var'_lag`i'
		di("`treat'")
		}
		
		quietly: areg `dep' `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m5_idn
		
		foreach i of num 6/10 {
		local treat `treat' `var'_lag`i'
		di("`treat'")
		}
		
		quietly: areg `dep' `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m10_idn
		
		use `r2r_folder'/Colombia_adm2_ready2regress_with_eq.dta, clear
		
		*drop observations that don't have all 10 lags (balanced panel)
		drop if mpga_aw_lag10==.
		
		eststo clear
		local treat `var'

		foreach i of num 1/5 {
		local treat `treat' `var'_lag`i'
		di("`treat'")
		}
		
		quietly: areg `dep' `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m5_col
		
		foreach i of num 6/10 {
		local treat `treat' `var'_lag`i'
		di("`treat'")
		}
		
		quietly: areg `dep' `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m10_col
		
		use `r2r_folder'/Colombia_adm1_ready2regress_with_eq.dta, clear
		
		*drop observations that don't have all 10 lags (balanced panel)
		drop if mpga_aw_lag10==.
		
		eststo clear
		local treat `var'

		foreach i of num 1/5 {
		local treat `treat' `var'_lag`i'
		di("`treat'")
		}
		
		quietly: areg `dep' `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m5_col1
		
		foreach i of num 6/10 {
		local treat `treat' `var'_lag`i'
		di("`treat'")
		}
		
		quietly: areg `dep' `treat'  i.year, absorb(plant) vce(cluster plant)
		est sto m10_col1


		local results_country "./output/regressions_tex/simultaneous_regs"
		local results m5_idn m10_idn m5_col m10_col m5_col1 m10_col1

		esttab `results' using `results_country'/`dep'_5_and_10_`var'_linear.tex, se noconstant nomtitles keep(`treat') replace booktabs label compress title("Dependent variable: `: var label `dep''. Indonesia: (1)-(2), Colombia ADM2: (3)-(4), Colombia ADM1: (5)-(6). Linear Specification.") addnotes("Year and plant fixed effects are included in each specification.")
		
		clear all

	}

}



















