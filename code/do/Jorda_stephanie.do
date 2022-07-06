*Regression with countryspecific quadratic time-trend
clear
set matsize 5000

local path "/Users/slackner/Google Drive/Research/Projects/EarthquakeGDP/"
use "`path'Data/Built/WorldPanel.dta", clear
drop _merge
drop if year<1973 | year==2016 | country==.

sysdir set PERSONAL "/Applications/Stata/ado/personal/"

tsset country year
gen yvar=growthny_gdp_pcap_kd

xi i.country
ds _I*
foreach var in `r(varlist)' {
	gen year`var'=year*`var'
}


	* Define Variables from Input
	preserve
	local leadn=3
	*`4'
	local lagn=8
	*`3'
	local zeropos=`leadn'+1
	cap drop *shaking*
	*gen shaking=`1'
	gen shaking=Pop1number_quakes_aw1
	*Missing values in shaking data are due to gdp data being "longer" in time (for leads and lags)


	*Define Plot title
	sum shaking if shaking>0, detail
	local meannum=round(`r(mean)',0.01)
	local percnum=round(`r(p90)',0.01)
	local meannum: di %3.2f `meannum'
	local percnum: di %3.2f `percnum'
	local titleplot2 "(mean non-zero exposure: `meannum'; 90th percentile: `percnum')"
	local titleplot1 "Exposure: 2B"
	*`2'"

	*Calculate lags end leads
	if `lagn'>0 {
		foreach val of numlist 1/`lagn' {
			gen L`val'shaking=L`val'.shaking
		}
	}
	if `leadn'>0 {
		foreach val of numlist 1/`leadn' {
			gen F`val'shaking=F`val'.shaking
		}
	}

	quietly reg2hdfespatial yvar shaking year_I*, lat(point_y) lon(point_x) t(year) p(country) dist(1000) lagcutoff(10)
	estimates store Y0

	quietly lincom shaking
	cap drop coef lower upper time
	gen coef=r(estimate) in `zeropos'
	gen lower=r(estimate)+invnorm(0.025)*r(se) in `zeropos'
	gen upper=r(estimate)+invnorm(0.975)*r(se) in `zeropos'
	gen time=0 in `zeropos'
	if `leadn'>0 {
		foreach val of numlist 1/`leadn' {
			local pos=`zeropos'-`val'
			*Run Regression
			quietly reg2hdfespatial yvar F`val'shaking year_I*, lat(point_y) lon(point_x) t(year) p(country) dist(1000) lagcutoff(10)
			estimates store Fm`val'

			quietly lincom F`val'shaking
			replace coef=r(estimate) in `pos'
			replace lower=r(estimate)+invnorm(0.025)*r(se) in `pos'
			replace upper=r(estimate)+invnorm(0.975)*r(se) in `pos'
			replace time=-`val' in `pos'
		}
	}

	if `lagn'>0 {
		foreach val of numlist 1/`lagn' {
			local pos=`zeropos'+`val'
			*Run Regression
			quietly reg2hdfespatial yvar L`val'shaking year_I*, lat(point_y) lon(point_x) t(year) p(country) dist(1000) lagcutoff(10)
			estimates store Lp`val'

			quietly lincom L`val'shaking
			replace coef=r(estimate) in `pos'
			replace lower=r(estimate)+invnorm(0.025)*r(se) in `pos'
			replace upper=r(estimate)+invnorm(0.975)*r(se) in `pos'
			replace time=`val' in `pos'
		}
	}
	*Define plot variable labels
	label var time "Years since earthquake exposure"
	label var coef "Estimate"
	label var lower "95% Confidence Intervall"
	label var upper "95% Confidence Intervall"

	*Adjust to Percentage values by multiplying with 100
	replace lower=lower*100
	replace upper=upper*100
	replace coef=coef*100

	local ticks ""
	foreach val of numlist -`leadn'/`lagn' {
		local ticks "`ticks' `val'"
	}


	coefplot (Fm3, offset(0)) (Fm2) (Fm1,) (Y0) (Lp1) (Lp2) (Lp3) (Lp4) (Lp5) (Lp6) (Lp7) (Lp8),  drop(year_I*) levels(99 95 90 75) ciopts(lwidth(3 ..) lcolor(ebblue*.2 ebblue*.4 ebblue*.8 ebblue*1.6)) msymbol(d) mcolor(white) legend(pos(6) order(1  2  3  4) label(1 "99% CI") lab(2 "95% CI") lab(3 "90% CI") lab(4 "75% CI") row(1)) coeflabels(shaking = "0" F1shaking = "-1" F2shaking = "-2" F3shaking = "-3" L1shaking = "1" L2shaking = "2" L3shaking = "3" L4shaking = "4" L5shaking = "5" L6shaking = "6" L7shaking = "7" L8shaking = "8") vertical yline(0,lc(gs3) lw(medthick)) xline(4,lc(gs3) lw(medthick)) xtitle("Years since earthquake exposure",size(medlarge)) ytitle("Marginal response of GDP p.c. growth",size(medlarge)) ytick(-0.01 -0.0075 -0.005 -0.0025 0 0.0025 0.005) ylabel(-0.01 "-1" -0.0075 "-0.75" -0.005 "-0.5" -0.0025 "-0.25" 0 "0" 0.0025 "0.25" 0.005 "0.5")

	graph export "/Users/slackner/Google Drive/Research/Projects/EarthquakeGDP/Output/Figures/Jorda_beta.png", replace width(350)

	/* PLOT & SAVE
	twoway (rarea upper lower time, color(ltemerald%75) ytitle("Percentage change in GDP per capita") xline(0, lc(gs3) lw(medthick)) yline(0, lc(gs3) lw(medthick)) xscale(range(-`leadn' `lagn')) xtick(`ticks') xlabel(`ticks')) ///
			 (line coef time, color("green") xlabel(,labsize(medlarge)) ylabel(,labsize(medlarge)) xtitle(,size(medlarge)) ytitle(,size(medlarge)) title("`titleplot1' `6'" "`titleplot2' ", size(large)) legend(off))
			 *legend(pos(6) region(lstyle(foreground)))
	*/

	keep lower upper coef shaking time
	*drop if shaking==0 & time==.
	replace shaking=. if shaking==0
	gen id=_n


	gen future=1 if time>=0 & time~=.
	bysort future (time): gen coefOMEGA=sum(coef) if future==1
	gen past=1 if time<=0
	gen timem=-time
	bysort past (timem): replace coefOMEGA=sum(coef) if time<0
	drop timem
	sort time

	*generate mean and percentile observation
	local num=_N+1
	set obs `num'
	sum shaking if shaking>0, detail
	replace shaking=`r(mean)' in `num'
	replace id=-1 if id==.

	local num=_N+1
	set obs `num'
	sum shaking if shaking>0 & id>0, detail
	replace shaking=`r(p90)' in `num'
	replace id=-2 if id==.

	local num=_N+1
	set obs `num'
	sum shaking if shaking>0 & id>0, detail
	replace shaking=`r(p99)' in `num'
	replace id=-3 if id==.

	if `leadn'>0 {
		foreach val of numlist `leadn'/1 {
			local num=`zeropos'-`val'
			local valcoef=coefOMEGA[`num']
			gen coefshake`num'=`valcoef'*shaking
		}
	}
	local valcoef=coefOMEGA[`zeropos']
	gen coefshake`zeropos'=`valcoef'*shaking
	if `lagn'>0 {
		foreach val of numlist 1/`lagn' {
			local num=`zeropos'+`val'
			local valcoef=coefOMEGA[`num']
			gen coefshake`num'=`valcoef'*shaking
		}
	}
	keep coefshake* id
	drop if coefshake1==.
	local total=_N
	reshape long coefshake, i(id) j(time)
	replace time=time-1-`leadn'
	*reshape wide coefshake, i(time) j(id)

	local ticks2 ""
	foreach val of numlist -0/`lagn' {
		local ticks2 "`ticks2' `val'"
	}

	*br coefshake id time if time==`lagn' & id<0
	ta coefshake id if time==`lagn' & id<0

	sort id time
	label var time "Years since earthquake exposure"
  twoway (line coefshake time if id>0 & time>=0, connect(L) lc(ebblue%20) ytitle("Estimated percentage change in GDP per capita")  xline(0, lc(gs3) lw(medthick)) yline(0, lc(gs3) lw(medthick)) ylabel(-20 -15 -10 -5 0) yscale(range(-23 2)) ytick(-20 -15 -10 -5 0) xscale(range(0 `lagn')) xtick(`ticks2') xlabel(`ticks2') title("`titleplot1'", size(large))) ///
	(line coefshake time if id==-1 & time>=0, lc(yellow) lp(longdash_dot)) ///
	(line coefshake time if id==-2 & time>=0, lc(orange) lp(dash)) ///
	(line coefshake time if id==-3 & time>=0, lc(red) lp(longdash) xlabel(,labsize(medlarge)) ylabel(,labsize(medlarge)) xtitle(,size(medlarge)) ytitle(,size(medlarge)) legend(off))
	graph export "/Users/slackner/Google Drive/Research/Projects/EarthquakeGDP/Output/Figures/Jorda_Omega.png", replace width(350)



*modelwithplot "mpga_pw1" "1B - population weighted" 8 3 "PW"
*modelwithplot "number_quakes_pw" "2A - population weighted" 8 3 "PW"
*modelwithplot "number_quakes_pw1" "2B - population weighted" 8 3 "PW"
*modelwithplot "mpga_pw" "1A - population weighted" 8 3 "PW"
