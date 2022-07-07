/*
###########################################################################
 0)                     Intro
########################################################################### */

* Housekeeping
clear
clear matrix
set more off

local pathbuilt $path2save_shake
local percentage_thresholds $perc_thr

*automatically read number of regions from .shp (add path, name and unique id column name)
local path2shp $path2shp
local country $country
local country_abbr $country_abbr
local adm_level $adm_level
local ID $ID

*************************************************
* Manual check
*************************************************
*cd /Users/alina/Box/recovery-from-disasters/
*local country Indonesia
*local country_abbr IDN
*local pathbuilt "./data/earthquakes/intermediate/`country'"
*local percentage_thresholds 10 
*local path2shp "./data/firm-data/`country'/Shapefile/`country_abbr'_adm_shp/`country_abbr'_adm2.shp"

*##############################################################################

* DEFINE PROGRAM FOR CREATING A VARIABLE THAT IDENTIFIES THE GRIDCELLS IN THE PERCENTAGE AREAS  
* Create extra obs to fix the not exact percentage thresholds
* Splitting up observations
* Define for each gridcell to what percentage of the region they belong
* ----------
* first input is percentage area of region considered
* second input is the shaking measure considered 
* third input is sorting addition for number of earthquakes ("-mpga")
* fourth input is potential urban/rural/unpop distinction
* fifth input is reference area
* sixth input is a plus if urban_level in 4th input is used
* important output is: perc`2'_`1'_`4'area

capture program drop defineareas
program define defineareas
	gen ref_ranking1=_n
	*sort by year and shaking; ref_ranking ensures that order is always the same
	gsort +year `6'`4' -`2' `3' +ref_ranking1
	gen ref_ranking2=_n
	
	*calculate cummulative area exposed in percentage of entire region
	by year `4': gen cumarea=sum(area)/`5'
	*calculate cumulative area exposed in percentage of entire region of the previous observation
	by year `4': gen cumareaminus=cumarea[_n-1]
	replace cumareaminus=0 if cumareaminus==.

	*identify observations that need to be split in two
	gen obsaftersplitting=1
	replace obsaftersplitting=2 if cumarea>`1'/100 & cumareaminus<`1'/100

	*make new observations
	expand obsaftersplitting, gen(new)
	gen newshare=(`1'/100-cumareaminus)/(cumarea-cumareaminus) if obsaftersplitting==2
	*codebook newshare if new==1
	replace pop=pop*newshare if new==1
	replace pop=pop*(1-newshare) if new==0 & obsaftersplitting==2
	replace urban_level=urban_level*newshare if new==1
	replace urban_level=urban_level*(1-newshare) if new==0 & obsaftersplitting==2
	replace area=area*newshare if new==1
	replace area=area*(1-newshare) if new==0 & obsaftersplitting==2

	drop cumarea*
	gsort +year `6'`4' -`2' `3' +ref_ranking2 -new
	by year `4': gen cumarea=sum(area)/`5'
	qui sum cumarea if new==1 
	local thresh`1'=`r(max)'
	gen perc`2'_`1'_`4'area=(cumarea<=float(`thresh`1''))
	drop cumarea* obsaftersplitting new* ref_ranking* 
end


/*
###########################################################################
For each region do spatial aggregation and save as region file
########################################################################### */

*get number of individual regions from .shp
shp2dta using `path2shp', data("./data/firm-data/`country'/Shapefile/`country_abbr'_adm_shp/`country_abbr'_`adm_level'.dta")  coor("./data/firm-data/`country'/Shapefile/`country_abbr'_adm_shp/`country_abbr'_`adm_level'_coordinates.dta") replace
use ./data/firm-data/`country'/Shapefile/`country_abbr'_adm_shp/`country_abbr'_`adm_level'.dta, clear
levelsof `ID', local(num_areas)
clear

global importfolder "`pathbuilt'/region_dtas"

foreach val of local num_areas {
	clear 
	
	*import data for all individual years of that region
	global filelist : dir "$importfolder/" files "`val'_*.dta"
	foreach file in $filelist {
		append using "$importfolder/`file'"
	}
	
	cap: sum region
	if(_rc!=111) {
		*rename number_quakes to num_qs since new created varnames are too long
		rename number_quakes num_qs
		
		*check if this region is big enough to be overlapped by at least 1 gridcell
		*if not - drop this region
		qui sum area 
		if `r(N)' > 0 {
			
			sort year 
			by year: egen pop_in_year = sum(pop)
			by year: egen regionarea=sum(area)

			bys year urban_level: egen region_type_area = sum(area)
			bys year urban_level: egen region_type_pop = sum(pop)
			gen region_urban_area = region_type_area if urban_level==2
			gen region_rural_area = region_type_area if urban_level==1
			gen region_nonpop_area = region_type_area if urban_level==0
			*****************************************************************************
			****Confirm stuff and clean up
			*****************************************************************************

			* should all be the same min==max. Yes confirmed!
			*bysort country: egen check=sd(regionarea)
			*codebook check*
			*drop check*

			* Standard deviations are always almost zero. make sure everything is consistent by setting variable equal to mean
			* Machine error differences across years makes deviations not exactly zero
			egen temp=mean(regionarea)
			replace regionarea=temp
			drop temp

			*****************************************************************************
			******** Create extra obs to fix the not exact percentage thresholds
			******** Splitting up observations
			******** Define for each gridcell to what percentage of the region they belong
			*****************************************************************************
			
			defineareas "`percentage_thresholds'" "mpga" "" "" "regionarea" ""
			defineareas "`percentage_thresholds'" "num_qs" "-mpga" "" "regionarea" ""
			defineareas "`percentage_thresholds'" "mpgv" "" "" "regionarea" ""
			defineareas "`percentage_thresholds'" "mag" "" "" "regionarea" ""
			defineareas "`percentage_thresholds'" "mpga" "" "urban_level" "region_type_area" "+"
			defineareas "`percentage_thresholds'" "mpgv" "" "urban_level" "region_type_area" "+"
			defineareas "`percentage_thresholds'" "mag" "" "urban_level" "region_type_area" "+"
			defineareas "`percentage_thresholds'" "num_qs" "" "urban_level" "region_type_area" "+"
			
			****************************************************************************
			****** Create variables for collapsing ************
			****************************************************************************
			
			foreach var in mpga mpgv mag num_qs {
				gen `var'_aw=`var'*area/regionarea
				gen `var'_pw=`var'*pop/pop_in_year
				
				gen urban`var'_aw=`var'*area/region_urban_area
				gen rural`var'_aw=`var'*area/region_rural_area 
				gen non_pop`var'_aw=`var'*area/region_nonpop_area	
				gen populated`var'_aw=`var'*area/region_type_area if urban_level>0
				
				foreach perc in `percentage_thresholds' {
					egen pop_in_`perc'_`var'=sum(pop*(perc`var'_`perc'_area==1)) 
					gen `var'_aw`perc'=`var'*area/(regionarea*`perc'/100) if perc`var'_`perc'_area==1
					gen `var'_pw`perc'=`var'*pop/pop_in_`perc'_`var' if perc`var'_`perc'_area==1
					
					gen urban`var'_aw`perc'=`var'*area/(region_urban_area*`perc'/100) if urban_level==2 & perc`var'_`perc'_urban_levelarea==1
					gen rural`var'_aw`perc'=`var'*area/(region_rural_area*`perc'/100) if urban_level==1 & perc`var'_`perc'_urban_levelarea==1
					gen non_pop`var'_aw`perc'=`var'*area/(region_nonpop_area*`perc'/100) if urban_level==0 & perc`var'_`perc'_urban_levelarea==1
					gen populated`var'_aw`perc'=`var'*area/(region_type_area*`perc'/100) if urban_level>0 & perc`var'_`perc'_urban_levelarea==1
				}
			}

			gen area_threshold10=0
			replace area_threshold10=area if mpga>=10

			foreach perc in `percentage_thresholds' {
				gen area_threshold10_inp`perc'=0
				*replace area_threshold10_inp`perc'=area if mpga>=10 & perc_`perc'area==1
				replace area_threshold10_inp`perc'=area if mpga>=10 & percmpga_`perc'_area==1
			}

			****************************************************************************
			****** Collapse *********
			****************************************************************************
			collapse (first) region (sum) *_aw* *_pw* area_threshold*  (mean) regionarea region_urban_area region_rural_area region_nonpop_area, by(year)

			foreach var in regionarea region_urban_area region_rural_area region_nonpop_area {
				replace `var'=0 if `var'==.
			}

			**************** check completeness ************
			*count
			*tsset region year
			*tsfill, full
			*count
			*************************************************

			save "`pathbuilt'/region_dtas_collapsed/`val'.dta", replace	
		}
		
		else { 
			save "`pathbuilt'/region_dtas_collapsed/`val'.dta", replace
		} 
	}	
	
} 

