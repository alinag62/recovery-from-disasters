* Working with masterfile to create a crosswalk

local path "/Users/alinagafanova/Library/CloudStorage/Box-Box/recovery-from-disasters"
cd `path'

********************************************************************************
*I.Crosswalk between 1988 and 1993 (we don't have ID information here)
********************************************************************************

import excel "./data/firm-data/Indonesia/regions_codes/mfkab_88_93.xlsx", sheet("Sheet1") firstrow clear
gen id_year1988 = id_year1994
replace id_year1988 = 1803 if name_year1994=="LAMPUNG BARAT"
replace id_year1988 = 3219 if name_year1994=="KOTA TANGERANG"
replace id_year1988 = 5103 if name_year1994=="KOTA DENPASAR"
replace id_year1988 = 5201 if name_year1994=="KOTA MATARAM"
replace id_year1988 = 8103 if name_year1994=="HALMAHERA TENGAH"
replace id_year1988 = 8203 if name_year1994=="KOTA JAYAPURA"
replace id_year1988 = 7103 if name_year1994=="KOTA BITUNG"

gen kota = "KOTA"

tostring id_year1988, replace
gen last_1dig_88 = substr(id_year1988,3,1)
replace name_year1988 = kota + " " + name_year1988 if (last_1dig_88=="7")&(regexm(name_year1988,"KOTA")!=1)&(regexm(name_year1988,"JAKARTA")!=1)
replace name_year1988 = "KODYA JAKARTA UTARA" if name_year1988=="JAKARTA UTARA"
drop kota
drop last_1dig_88

bys E: gen n = _n
replace n = . if n==2
replace n = sum(n)
drop E
rename n i_harmonize_to_1988
drop id_year1994 name_year1994

gen name_year1989 = name_year1988
gen id_year1989 = id_year1988
gen name_year1990 = name_year1988
gen id_year1990 = id_year1988
gen name_year1991 = name_year1988
gen id_year1991 = id_year1988
gen name_year1992 = name_year1988
gen id_year1992 = id_year1988
gen name_year1993 = name_year1988
gen id_year1993 = id_year1988

order i i_harmonize_to_1988

tempfile years_88_93
save "`years_88_93'"

********************************************************************************
*II. Combine data for 1993-2015
********************************************************************************
import excel "./data/firm-data/Indonesia/regions_codes/mfkab_93_09.xlsx", sheet("Sheet1") firstrow clear

rename KAB290Des1993 name_year1994
rename ID290 id_year1994
rename KAB291Des1994 name_year1995
rename ID291 id_year1995
rename KAB292Des1995 name_year1996
rename ID292 id_year1996
rename KAB294Des1996 name_year1997
rename ID294 id_year1997
rename KAB301Des1997 name_year1998
rename ID301 id_year1998
rename KAB341Des1999 name_year2000
rename ID341 id_year2000
rename KAB354Des2001 name_year2001
rename ID354 id_year2001
rename KAB391Des2002 name_year2003
rename ID391 id_year2003
rename KAB440Des2003 name_year2004
rename ID440 id_year2004
rename KAB465Des2007 name_year2008
rename ID465 id_year2008
rename KAB483Des2008 name_year2009
rename ID483 id_year2009
rename KAB497Agt2009 name_year2010
rename ID497 id_year2010

drop KAB456Juli2007 ID456 KAB471Juli2008 ID471 KAB493April2009 ID493 KAB495Juni2009 ID495

gen kota = "KOTA"
foreach year in 1994 1995 1996 1997 1998 2000 2001 2003 2004 2008 2009 2010 {
	tostring id_year`year', replace
	gen last_1dig_`year' = substr(id_year`year',3,1)
	replace name_year`year' = kota + " " + name_year`year' if (last_1dig_`year'=="7")&(regexm(name_year`year',"KOTA")!=1)&(regexm(name_year`year',"JAKARTA")!=1)
	drop last_1dig_`year'
	replace name_year`year' = "KODYA JAKARTA UTARA" if name_year`year'=="JAKARTA UTARA"
}
drop kota 



gen name_year1999 = name_year1998
gen id_year1999 = id_year1998
gen name_year2002 = name_year2001
gen id_year2002 = id_year2001
gen name_year2005 = name_year2004
gen id_year2005 = id_year2004
gen name_year2006 = name_year2004
gen id_year2006 = id_year2004
gen name_year2007 = name_year2004
gen id_year2007 = id_year2004

tempfile years_93_09
save "`years_93_09'"

*merge 93_09 with 09_15 to create crosswalk file for 1993-2015
import excel "./data/firm-data/Indonesia/regions_codes/mfkab_09_15.xlsx", sheet("Sheet1") firstrow clear

*add "kota" to cities names (not to confuse with municipalities)
gen kota = "KOTA"
tostring ID_jan2015, replace
gen last_1dig_jan2015 = substr(ID_jan2015,3,1)
replace NAME_jan2015 = kota + " " + NAME_jan2015 if last_1dig_jan2015=="7"
drop last_1dig_jan2015

tostring ID_july2010, replace
gen last_1dig_july2010 = substr(ID_july2010,3,1)
replace NAME_july2010 = kota + " " + NAME_july2010 if last_1dig_july2010=="7"
drop last_1dig_july2010

tostring ID_aug2013, replace
gen last_1dig_aug2013 = substr(ID_aug2013,3,1)
replace NAME_aug2013 = kota + " " + NAME_aug2013 if last_1dig_aug2013=="7"
drop last_1dig_aug2013
drop kota

*clean the ones that are replaced redundantly
replace NAME_july2010 = "KOTA GUNUNGSITOLI" if NAME_july2010=="KOTA KOTA GUNUNGSITOLI"
replace NAME_july2010 = "KOTA SUNGAI PENUH" if NAME_july2010=="KOTA KOTA SUNGAI PENUH"
replace NAME_july2010 = "KOTA TANGERANG SELATAN" if NAME_july2010=="KOTA KOTA TANGERANG SELATAN"

merge m:1 IDharmonization using `years_93_09'
drop _m KAB497Agt2009 ID497

rename NAME_july2010 name_year2011
rename ID_july2010 id_year2011
rename NAME_aug2013 name_year2014
rename ID_aug2013 id_year2014
rename NAME_jan2015 name_year2015
rename ID_jan2015 id_year2015


gen name_year2012 = name_year2011
gen id_year2012 = id_year2011
gen name_year2013 = name_year2011
gen id_year2013 = id_year2011

order IDharmonization id_year1994 name_year1994 id_year1995 name_year1995 id_year1996 name_year1996 id_year1997 name_year1997 id_year1998 name_year1998 id_year1999 name_year1999 id_year2000 name_year2000 id_year2001 name_year2001 id_year2002 name_year2002 id_year2003 name_year2003 id_year2004 name_year2004 id_year2005 name_year2005 id_year2006 name_year2006 id_year2007 name_year2007 id_year2008 name_year2008 id_year2009 name_year2009 id_year2010 name_year2010 id_year2011 name_year2011 id_year2012 name_year2012 id_year2013 name_year2013 id_year2014 name_year2014 id_year2015 name_year2015

*unique identifier for 1994
bys id_year1994: gen n=_n
replace n = . if n>1
replace n = sum(n)
rename n i
drop IDharmonization
order i

merge m:1 i using "`years_88_93'"

order i_harmonize_to_1988 i id_year1988 name_year1988 id_year1989 name_year1989 id_year1990 name_year1990 id_year1991 name_year1991 id_year1992 name_year1992 id_year1993 name_year1993

foreach year of num 1988/2015 {
	replace name_year`year' = "KODYA JAKARTA UTARA" if name_year`year'=="JAKARTA UTARA"
}

drop _m i

tostring id_year1990, replace
gen last2dig = substr(id_year1990, 3, 4)
drop if last2dig=="00"
drop last2dig

sort i_harmonize_to_1988

bys i_harmonize_to_1988: replace i_harmonize_to_1988=_n
replace i_harmonize_to_1988 = . if i_harmonize_to_1988>1
replace i_harmonize_to_1988 = sum(i_harmonize_to_1988)

save "./data/firm-data/Indonesia/regions_codes/crosswalk_1988_2015.dta", replace









