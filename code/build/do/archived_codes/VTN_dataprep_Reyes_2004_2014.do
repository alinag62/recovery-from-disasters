clear all
set more off
capture log close

cd "k:\Vietnam\WBproject" 

g yr_start=nam       		
	la var yr_start "year of startup -numeric"

g unit = 1000000
replace unit = $units_cnst_used if $units_constant==1


* total sales	
g sales = revenue*unit
	la var sales "sales (000 LCU)"
   	
* % of output exported 
g export_tot= amt_export*unit
la var export_tot "total exports (000 LCU)"    

g exports =  100*export_tot/sales if sales~=. 	  // note: if export is reported as a % of sales write this variable instead	
   	la var exports "% of output exported"

* material inputs  (cost incurred this year if possible, otherwise expenses regardless of whether goods were used or inventories)
g input=cost_gd_sold
g nm =input*unit 
	la var nm "materials(000 LCU)"

gen va=revenue-input
g nv = va*unit //revenue-inputs
   	la var nv "value added (000 LCU)"

* total capital stocks (replacement values) -it does not include new purchases
egen qqq=rsum(assets_b assets_e)
egen www=rownonmiss(assets_b assets_e)
g nk = qqq/www   // the average of the beginning and end period
	
replace nk=nk*unit
	la var nk "total capital -replacement values(000 LCU)"
	
g nk_nlb = nk // "net value fixed assets after depreciation and monetary correction"
replace nk_nlb=nk_nlb*unit
	la var nk_nlb  "capital excluding land and buildings(000 LCU)"        

*******EMPLOYMENT INFORMATION   	
* total wages 
g pay=wage
replace pay=pay*unit 
 	la var pay "total wages this year(000 LCU)"

*** !! THIS IS ONLY PAID EMPLOYMENT ***   
* total employment 
g L=size_e // total permanent labor
replace L=size_b if L==.
	la var L "total employment"
drop if L==0|L==.

g fememp =size_fe
	la var fememp "total permanent female employment"
   
g maleemp = L-fememp
	la var maleemp "total permanent male employment"
	
* total wages of female workers
gen fempay=wage_f 
   	la var fempay "total wages to female workers this year"
* total wages of male workers   	 
gen malepay=.
   	la var malepay "total wages to male workers this year"
***
	
*LPQ
	g LPQ =rS/L
	g lnLPQ = lnrS - lnL 
	replace lnLPQ=. if lnrS==.
		}
if $doprod1==0 & $doprod2==1 {
	g LPQ =rY/L
	g lnLPQ = lnrY - lnL 
	replace lnLPQ=. if lnrY==.
		}
if ($doprod1==1 |$doprod2==1 ) {
	g outl_lnLPQ=.
	sum id if rY~=.&L~=.
	local N = r(N)
	if `N' > 0 {
		tempvar n geuk0 neuk0 
		egen `n'=tag(id)  if rY~=.&L~=.
		bysort euk0: egen `neuk0'=sum(`n') 
		egen `geuk0'=group(euk0) if `neuk0'>=20 & `neuk0'~=.
		sum `geuk0'
		local xf = r(max)			
		forvalues i=1(1)`xf' {
					sum lnLPQ if `geuk0'==`i', de
					replace outl_lnLPQ=1 if (lnLPQ<=r(p1)|(lnLPQ>=r(p99) & lnLPQ~=.)) & `geuk0'==`i' 
							}
		sum lnLPQ, de
		replace outl_lnLPQ=1 if (lnLPQ<=r(p1)|(lnLPQ>=r(p99) & lnLPQ~=.)) & `neuk0'<20  
			}
	*drop very large ratios
	g LPQorig=LPQ 
	g lnLPQorig=lnLPQ 
	replace lnLPQ=. if outl_lnLPQ==1|lnLPQ>16|lnLPQ<-16
	replace LPQ=. if lnLPQ==.
	if $doprod1==1 {
		la var LPQ "Sales per worker"
		la var lnLPQ "Sales per worker -log"
			}
	if $doprod1==0 & $doprod2==1 {
		la var lnLPQ "Output per worker"
		la var lnLPQ "Output per worker -log"
			}
		}
	foreach i in LPQ lnLPQ outl_lnLPQ LPQorig lnLPQorig {
		capture g `i' = .
				}

/* DEFLATORS
gen go_p= 213.07 if year==2009
replace go_p = 238.79 if year==2010
replace go_p = 289.56 if year==2011
replace go_p = 321.20 if year==2012
replace go_p=200.63 if year==2008
replace go_p=163.51 if year==2007
replace go_p=149.19 if year==2006
replace go_p=137.377 if year==2005
replace go_p=125.832 if year==2004
replace go_p=336.46 if year==2013
replace go_p=348.87 if year==2014
replace go_p=go_p/100
prefix "r" real values"
***/
	g LPQ =rS/L
	g LPV = rV/L
	sum id if rV~=.&L~=.
	local N = r(N)
	if `N' > 0 {
		tempvar n geuk0 neuk0 // sector 2 digits
		egen `n'=tag(id)  if rV~=.&L~=.
		bysort euk0: egen `neuk0'=sum(`n') 
		egen `geuk0'=group(euk0) if `neuk0'>=20 & `neuk0'~=.
		sum `geuk0'
		local xf = r(max)			/*last sector*/
		forvalues i=1(1)`xf' {
					sum lnLPV if `geuk0'==`i', de
					replace outl_lnLPV=1 if (lnLPV<=r(p1)|(lnLPV>=r(p99) & lnLPV~=.)) & `geuk0'==`i'  
						}
		sum lnLPV, de
		replace outl_lnLPV=1 if (lnLPV<=r(p1)|(lnLPV>=r(p99) & lnLPV~=.)) & `neuk0'<20
			}
*drop very large ratios
	g LPVorig=LPV
	g lnLPVorig=log(LPV) 
	replace lnLPV=. if outl_lnLPV==1|lnLPV>16|lnLPV<-16
	replace LPV=. if lnLPV==.
	la var lnLPV "Value Added per worker -log"

*TFPR, TFPRT
xtset id year

***********************Outlier program begins************************************
capture program drop outlier
program define outlier

	syntax, lhs(varname numeric) rhs(varlist numeric) ctl(varname numeric) regr(string) res(string) error(string) outl(string) [outldum(string)]

	local pct=1
	local endpct = 100 - `pct'

	tempvar nmiss
	g `nmiss'=.

	foreach var of local rhs{
	replace `nmiss'=1 if `var'==.
		}

	if "`outldum'" ~= ""{
	local dummies ""
	foreach dummy of local outldum{
	 	 local dummies "`dummies' i.`dummy'"
				}
			}

	if `"`dummies'"' ~= ""{ 
		local prefix "xi:" 
			}

	g outl_`outl' =. 

	tempvar tails n geuk0 neuk0 
	g `tails'=.
	egen `n'=tag(id)  if `lhs'~=.&`nmiss'~=1
	bysort euk0: egen `neuk0'=sum(`n') 
	egen `geuk0'=group(euk0) if `neuk0'>=20 & `neuk0'~=.
	sum `ctl',de
	replace `tails'=1 if ((`ctl'>r(p`endpct')&`ctl'~=.)|`ctl'<r(p`pct'))&`neuk0'<20

	sum `geuk0'
	local xf = r(max)			
	di `xf'
	forvalues i = 1(1)`xf' {	   //the estimates are made at the sectoral level
		di `i'
		sum `ctl' if `geuk0'==`i', de
		replace `tails'=1 if ((`ctl'>r(p`endpct')&`ctl'~=.)|`ctl'<r(p`pct'))& `geuk0'==`i'

		`prefix' `regr' `lhs' `rhs' `dummies' if `geuk0'==`i' & `tails'~=1, `error'
		tempvar res`i' 

		predict `res`i'', `res'
		sum `res`i''  if `geuk0'==`i', de
		replace outl_`outl' = 1 if (`res`i'' <= r(p`pct')|(`res`i'' >= r(p`endpct')&`res`i'' ~=.))  & `geuk0'==`i'
		drop `res`i'' 
			} 

	*sectors with small number of firms
	`prefix' `regr' `lhs' `rhs' `dummies' if  `tails'~=1, `error'
	tempvar resm

	predict `resm', `res'
	sum `resm', de
	replace outl_`outl' = 1 if  (`resm' <= r(p`pct')|(`resm' >= r(p`endpct')&`resm' ~=.)) &`neuk0'<20
	drop `resm'  `neuk0' `geuk0' `nmiss'
 
	capture drop _I*

	la var outl_`outl' "outlier - reg w/o 1% tails but allow tails back"

end

******************************Outlier program ends**********************************

******************************Productivity var program begins**********************************	
capture program drop pvartfp
program def pvartfp
	syntax, varn(string) regr(string) lvar(string) res(string)   [dum(string) prefix(string)]

	tempvar n n1 geuk0 neuk0
	g `n1'=1 if  lnrV~=.& lnrK~=.& lnL~=.
	egen `n'=tag(id)  if  `n1'==1
	bysort euk0: egen `neuk0'=sum(`n') 
	egen `geuk0'=group(euk0) if `neuk0'>=20
	sum `geuk0'
	local xf = r(max)		
	g `varn'=.

	forvalues i = 1(1)`xf' {	   // the estimates are made at the sectoral level
		`prefix' `regr' lnrV lnrK `lvar' `dum' if outl_`varn'~=1 & `geuk0'==`i' , `res'
		local lb_k=_b[lnrK]
		local lb_l=_b[`lvar'] 
		replace `varn' = lnrV- `lb_k'*lnrK - `lb_l'*`lvar' if `n1'==1 &`geuk0'==`i' & outl_`varn'~=1
		capture drop _I* 
			}

	`prefix' `regr' lnrV lnrK `lvar' `dum'  if outl_`varn'~=1, `res'
	local lb_k=_b[lnrK]
	local lb_l=_b[`lvar'] 

	replace `varn' = lnrV- `lb_k'*lnrK - `lb_l'*`lvar' if `n1'==1 &`neuk0'<20 & outl_`varn'~=1
	capture drop _I* 
end
******************************Productivity var program ends***********************************
	outlier, lhs(lnrV) rhs(lnL lnrK) ctl(lnLPVorig) regr(reg) res(residuals) error(r) outl(TFPR) outldum(year) 
	outlier, lhs(lnrV) rhs(lnL lnrK) ctl(lnLPVorig) regr(xtreg) res(ue) error(fe) outl(TFPRT) 
	pvartfp, varn(TFPR) regr(reg) lvar(lnL) res(r) dum(i.year) prefix(xi:)
	pvartfp, varn(TFPRT) regr(xtreg) lvar(lnL) res(fe)   
