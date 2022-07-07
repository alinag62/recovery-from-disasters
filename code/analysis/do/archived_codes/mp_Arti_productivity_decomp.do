	local bar ""
	local k = 1
	foreach i in ebblue olive khaki dknavy {
		local bar "`bar' bar(`k', color(`i'))"
		global mc`k' "mc(`i')"
		local k = `k' + 1
				}
	global bar "`bar'"
	global legmp "legend(row(1) lab(1 "Within") lab(2 "Between") lab(3 "Entry") lab(4 "Exit") size(vsmall))" 	
	
cap program drop mp
program def mp
syntax varlist, weight(str) [sector(str) lag(integer 1) interval(integer 1)]
	cap g wgt = 1
	preserve
		drop if `varlist'==. | `weight' ==. | `sector'==. 
		keep PSID year `varlist' `weight' age entry exit `sector' wgt
		cap drop yr_start
		g yr_start=year-age
		su year
		global startyr = r(min)
		global endyr = r(max)
		
		cap drop fyear
		cap drop lyear
		egen fyear = min(year), by(PSID)
		egen lyear = max(year), by(PSID)	
		drop if `varlist' == . | `weight' == . | (fyear==lyear) | `sector' == .
		
		cap g w=`weight'
		g exyr = year if exit == 1
		g entryyear = yr_start
		egen exityear = min(exyr), by(PSID) 
		drop exyr
		g phi = `varlist' 
		g weight = `weight' if year >= entryyear & year <= exityear
		replace weight = . if w < 0 
		replace phi = . 	if weight == .

		winsor2 phi, cuts(1 99) replace
		g wphi = weight*phi
		
		cap g all = 1
		g se = (exityear == 0) if year >= entryyear & year <= exityear
		g sx = (entryyear == 0|entryyear==.) if year >= entryyear & year <= exityear
		g e = (entryyear==1) if year >= entryyear & year <= exityear
		g x = (exityear==1) if year >= entryyear & year <= exityear
		global groups "all se sx e x"
		foreach i in $groups {	
			g phi_`i' = phi if `i' == 1
			la var phi_`i' "yvar for group `i'"
			g wphi_`i' =  wphi if `i' == 1
			la var wphi_`i' "weighted yvar for group `i'"
			g weight_`i' = weight if `i' == 1
			la var weight_`i' "weight for group `i'"
			}

		collapse (mean) phi* $groups (sum) *wphi* weight* [pw=wgt], by(`sector' year)
		foreach i in $groups {
			replace wphi_`i' = wphi_`i' /weight_`i'
			g wshare_`i' = weight_`i'/weight_all
			}

			
		bys `sector' (year): gen within 	= (phi_sx - phi_se[_n-`lag'])/`interval' 
		bys `sector' (year): gen between 	= ((wphi_sx - phi_sx) - (wphi_se[_n-`lag'] - phi_se[_n-`lag']))/`interval' 
		bys `sector' (year): gen entry 		= (wshare_e*(wphi_e - wphi_sx))/`interval'
		bys `sector' (year): gen exit 		= (wshare_x[_n-`lag']*(wphi_se[_n-`lag'] - wphi_x[_n-`lag']))/`interval'
		bys `sector' (year): gen wP 	= (wphi_all - wphi_all[_n-`lag'])/`interval'
		egen RHS  = rsum(within between entry exit)
		drop if year == $startyr
		sort year 
		save "mp_`varlist'_`weight'_lag`lag'_${CCC}.dta", replace
		foreach i in within between entry exit {
			g sh_`i' = 100*`i'/RHS
			la var sh_`i' "`i' share"
		}
		graph bar (mean) sh_within sh_between sh_entry sh_exit if year~=1992, /// 
		over(`sector',  label(angle(vertical) labsize(vsmall))) stack ///
		title("${country} ($startyr-$endyr)", size(medium)) ///
		subtit("change in ${`varlist't}", size(medium)) /// 
		ylabel(,format(%9.2f) labsize(vsmall)) /// 
		ytitle("%", size(small)) $bar $legmp   /// 
		note("weight: ${`weight't}" "Melitz & Polanec (2012)", size(vsmall))
		graph export "mp_`varlist'_`weight'_lag`lag'_${CCC}.png", as(png) replace wPSIDth(3500)
		graph save "mp_`varlist'_`weight'_lag`lag'_${CCC}.gph", replace
	restore
end

cd "K:\Climate change\data\Indonesia"
use "data\_dta\maindata_v1.dta", clear
global CCC IDN
global country Indonesia
su year

global startyr = r(min)
global endyr =r(max)

destring kblir4_2d, replace
rename LPDNOU L // paPSID workers
rename LTLNOU  Ltot // paPSID + unpaPSID
rename LTL avL_t0

bys PSID: egen firstyr = min(year)
bys PSID: egen lastyr= max(year)

bys PSID: egen minage = min(age)
bys PSID: replace age = 0 if _n == 1 & minage == . & avL_t0 == 0 & year ~= $startyr 
sort PSID year
tsset PSID year
g lag = year - l.year 
replace age = age + lag if age == . & minage == . & avL_t0 == 0 & year ~= $startyr

* entry: first time entering to the data
g entry = (age == 0)  if age ~= .

*VTLVCU // value added
*OUTPUT // output
*ETLQUU // fuel and lubricants
*EELKHU // electricity
*vEnergy // Energy expenses (total)
*rvadTR // real value added trimmig 1% tails
*routTR // real output trimmig 1% tails

g deflator = VTLVCU/rvad
winsor2 vEnergy, cuts(1 99) 
g renergy = vEnergy/deflator
replace renergy = . if PSID==13191 & year==1995
g sh_energy_y = renergy/routTR
la var sh_energy_y "share of energy over output"
g sh_energy_va = renergy/rvadTR
la var sh_energy_va "share of energy over value added"
g lnrout = log(rout)
g lnrenergy= log(renergy)
g lnsh_energy_y = log(sh_energy_y)

mp sh_energy_y, weight(renergy) sector(kblir4_2d) lag(1) interval(1)

/*
preserve
	collapse (mean) lnrout lnrenergy sh_energy_y, by(year)
	twoway line lnrout year, yaxis(1) || line lnrenergy year, yaxis(1) || line sh_energy_y year, yaxis(2) legend(lab(1 "output (log)") lab(2 "energy (log)") lab(3 "E/Y"))
	graph export "trends_log.png", as(png) 

restore