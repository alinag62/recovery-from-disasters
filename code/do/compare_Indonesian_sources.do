*compare 2 sources of Indonesian data (Ishan and Arti)

local path "/Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters"

*1. Worldbank data (Arti)
use "`path'/data/firm-data/Indonesia_worldbank/maindata_v1.dta", clear

*Number of variables (incl. derivative vars, like logs and shares): 657

*sum year

*    Variable |        Obs        Mean    Std. Dev.       Min        Max
*-------------+---------------------------------------------------------
*        year |    523,404    2003.344    8.294042       1988       2017

*tab year

/*       Year |      Freq.     Percent        Cum.
------------+-----------------------------------
       1988 |     11,231        2.15        2.15
       1989 |     11,491        2.20        4.34
       1990 |     12,861        2.46        6.80
       1991 |     13,556        2.59        9.39
       1992 |     14,699        2.81       12.20
       1993 |     15,235        2.91       15.11
       1994 |     16,030        3.06       18.17
       1995 |     17,740        3.39       21.56
       1996 |     18,669        3.57       25.13
       1997 |     18,752        3.58       28.71
       1998 |     18,198        3.48       32.19
       1999 |     18,494        3.53       35.72
       2000 |     18,751        3.58       39.30
       2001 |     18,148        3.47       42.77
       2002 |     17,922        3.42       46.19
       2003 |     17,336        3.31       49.51
       2004 |     17,347        3.31       52.82
       2005 |     17,166        3.28       56.10
       2006 |     21,945        4.19       60.29
       2007 |     21,463        4.10       64.39
       2008 |     20,755        3.97       68.36
       2009 |     20,030        3.83       72.18
       2010 |     19,215        3.67       75.86
       2011 |     19,092        3.65       79.50
       2012 |     18,725        3.58       83.08
       2013 |     18,148        3.47       86.55
       2014 |     18,226        3.48       90.03
       2015 |     18,602        3.55       93.58
       2017 |     33,577        6.42      100.00
------------+-----------------------------------
      Total |    523,404      100.00 */
	  
**********************************************************************	  
*merge with geographical units from Ishan data to obtain unique geo IDs
*rename prov province_id
*rename DKABUP district_id
*gen id = province_id + "-" +district_id

*merge m:1 province_id district_id using "`path'/data/firm-data/Indonesia/Final-Dataset/Indonesia_unique_IDs.dta"

*duplicates drop  province_name province_id id_used district_name district_id  provn province_name DPROVI _m, force
*keep province_name province_id id_used district_name district_id  provn province_name DPROVI _m
**********************************************************************	

**********************************************************************	
*merge with geographical units from Arti
rename prov province_id_wb
rename DKABUP district_id_wb
gen id = province_id + "-" +district_id

/*check if plants change its IDs
duplicates drop PSID id, force
keep PSID id
sort PSID id
drop if id=="-"
bys PSID: gen n = _n
tab n*/

/*record when IDs change
preserve 
drop if id=="-"
drop if district_id==""
drop if district_id=="00"
drop if district_id=="."
gen year2 = year
collapse (min) year (max) year2 , by(PSID id)
rename year year_min
rename year2 year_max
bys PSID: gen N = _N
*keep if N!=1
tempfile ID_change
save "`ID_change'"
restore  */

/*district names
merge m:1 province_id district_id using "`path'/data/firm-data/Indonesia_worldbank/mfd_kabu_16_cleaned.dta"
keep if _m==3
drop _m */

/*preserve
keep if _m==1
drop if id=="-"
drop if district_id==""
drop if district_id=="00"
drop if district_id=="."
keep PSID year id
merge m:1 PSID id using "`ID_change'"
drop if _m==2
restore*/

**********************************************************************	

*length of records for each firm
bys PSID: gen num_periods = _N

*Are plants with different IDs from year to year the same as 
* the ones that cannot be matched?

tempfile WB
save "`WB'"
	  
*2. Original data (Ishan)
local path "/Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters"
use "`path'/data/firm-data/Indonesia/Final-Dataset/Indonesia_survey_readytoregress2.dta", clear

*Number of variables (incl. temperatures): 378

*sum year

*    Variable |        Obs        Mean    Std. Dev.       Min        Max
*-------------+---------------------------------------------------------
*        year |    254,406    1987.168    5.910088       1975       1995


*tab year

/*       year |      Freq.     Percent        Cum.
------------+-----------------------------------
       1975 |      7,469        2.94        2.94
       1976 |      7,257        2.85        5.79
       1977 |      7,655        3.01        8.80
       1978 |      7,831        3.08       11.88
       1979 |      7,958        3.13       15.00
       1980 |      8,086        3.18       18.18
       1981 |      7,941        3.12       21.30
       1982 |      8,019        3.15       24.46
       1983 |      7,918        3.11       27.57
       1984 |      8,002        3.15       30.71
       1985 |     12,900        5.07       35.78
       1986 |     12,208        4.80       40.58
       1987 |     12,768        5.02       45.60
       1988 |     14,645        5.76       51.36
       1989 |     14,659        5.76       57.12
       1990 |     16,341        6.42       63.54
       1991 |     16,478        6.48       70.02
       1992 |     17,620        6.93       76.95
       1993 |     18,135        7.13       84.07
       1994 |     18,992        7.47       91.54
       1995 |     21,524        8.46      100.00
------------+-----------------------------------
      Total |    254,406      100.00 */

* A) Data intersects in 1988-1995. Ishan's data has more observations per year 
* (like 10-20% diff)! What is the missing data? Let's find out
* Let's merge and only keep 1988-1995 first

keep if year>=1988&year<=1995

merge 1:1 PSID year using "`WB'", force
keep if year>=1988&year<=1995

*tab _m

/*
                 _merge |      Freq.     Percent        Cum.
------------------------+-----------------------------------
        master only (1) |     25,787       18.60       18.60
         using only (2) |        236        0.17       18.77
            matched (3) |    112,607       81.23      100.00
------------------------+-----------------------------------
                  Total |    138,630      100.00

*/

*Comparing firms with _m==1 and _m==3
*Doesn't depend on:
*industry; employers' cutoff; year of establishment; output; assets; provinces/districts; wages
* No clear pattern for why we lack this data

*B) No data in WB for 2016. Is it a year of the census?

*C) Why the count of data is so high in 2017? Is it a census?

*D) Districts' IDs are not unique in WB data (DKABUP). 
*We need to create unique IDs to merge with the shapefile
*Are these district+province IDs the same as official codes?
*they change through time! Are these the most updated ones?
*the one i found doesn't match ishan data 
*https://www.nomor.net/_kodepos.php?_i=kota-kodepos&daerah=&jobs=&perhal=514&sby=010000&_en=ENGLISH&asc=00001110&urut=10

*E) WB has a better coverage in terms of districts: 281 ADM2 regions in Ishan's data 
*and 476 in WB data (out of >500)

*F)We check if plants change their IDs from year to year 


/*preserve
duplicates drop PSID id_used, force
keep PSID id_used
sort PSID id_used
bys PSID: gen n = _n
tab n
restore*/

/*This is the distribution of how many times plants change the IDs in Ishan's data:          
          n |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     39,846       97.91       97.91
          2 |        841        2.07       99.98
          3 |         10        0.02      100.00
------------+-----------------------------------
      Total |     40,697      100.00

	  

And this is in Arti's data: 

          n |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 |     44,617       82.15       82.15
          2 |      8,052       14.83       96.97
          3 |      1,554        2.86       99.83
          4 |         86        0.16       99.99
          5 |          4        0.01      100.00
------------+-----------------------------------
      Total |     54,313      100.00	  
	  */

*Those are definitely not reallocations, since plants follow the same pattern
*of changes in IDs. Very important to change this!
*There can be both merges and divisions

*H) There are non-existant IDs in the dataset (they are not in current shapefile,
*nor in historic one)


*I) Unclear if there are no firms in new provinces OR they are still coded with old names

