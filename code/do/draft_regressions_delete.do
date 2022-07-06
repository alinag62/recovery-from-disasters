/**********
* Year and plant fixed effects; t=0 included
**********

eststo clear
local treat mpga_aw
foreach i of num 1/10 {
	local treat `treat ' mpga_aw_lag`i'
	di("`treat'")
	quietly: areg tot_emp `treat'  i.year, absorb(plant) vce(cluster plant)
	est sto m`i'
}

local results 
foreach i of num 1/10 {
	local results `results' m`i'
	di("`results'")
}

esttab `results' using example.tex, se noconstant replace booktabs compress keep(`treat') addnotes("Year and plant fixed effects are included in each specification.")


**********
* Year and plant fixed effects; t=0 excluded
**********

eststo clear
local treat
foreach i of num 1/10 {
	local treat `treat ' mpga_aw_lag`i'
	di("`treat'")
	quietly: areg tot_emp `treat'  i.year, absorb(plant) vce(cluster plant)
	est sto m`i'
}

local results 
foreach i of num 1/10 {
	local results `results' m`i'
	di("`results'")
}

esttab `results' using example3.tex, se noconstant replace booktabs compress keep(`treat') addnotes("Year and plant fixed effects are included in each specification.")

**********
* Year, district and plant fixed effects; t=0 included
**********


eststo clear 
local treat mpga_aw
foreach i of num 1/10 {
	local treat `treat ' mpga_aw_lag`i'
	di("`treat'")
	quietly: areg tot_emp `treat'  i.year c.region, absorb(plant) vce(cluster plant)
	est sto m`i'
}

local results 
foreach i of num 1/10 {
	local results `results' m`i'
	di("`results'")
}

esttab `results' using example5.tex, se noconstant replace booktabs compress keep(`treat') addnotes("Year, district and plant fixed effects are included in each specification.")

**********
* Year and plant fixed effects; t=0 included; region-specific time trend
**********

eststo clear
local treat mpga_aw
foreach i of num 1/10 {
	local treat `treat ' mpga_aw_lag`i'
	di("`treat'")
	quietly: areg tot_emp `treat' i.year c.year##i.region, absorb(plant) vce(cluster plant)
	est sto m`i'
}

local results 
foreach i of num 1/10 {
	local results `results' m`i'
	di("`results'")
}

esttab `results' using example7.tex, se noconstant replace booktabs compress keep(`treat') addnotes("Year, and plant fixed effects are included in each specification. District-year linear trends are included.")

