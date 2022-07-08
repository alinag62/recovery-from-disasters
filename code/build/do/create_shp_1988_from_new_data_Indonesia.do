* Working with masterfile to create a crosswalk

local path "/Users/alinagafanova/Library/CloudStorage/Box-Box/recovery-from-disasters"
cd `path'

********************************************************************************
*I.Load the 1985 file (it's not really 1985, just the name)
* and check if it intersects with any year
********************************************************************************

import excel "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_no_timor_1988.xlsx", sheet("Sheet1") firstrow clear

gen name_year1990 = upper(ADMIN_NAME)
replace name_year1990 = subinstr(name_year1990, "KODYA.", "KOTA", 1)
replace name_year1990 = subinstr(name_year1990, "KODYA", "KOTA", 1)
replace name_year1990 = subinstr(name_year1990, "KOTA JAKARTA", "KODYA JAKARTA", 1)

replace name_year1990 = "BANTAENG" if name_year1990=="BANTAENG/BONTHAIN"
replace name_year1990 = "BATANG HARI" if name_year1990=="BATANGHARI"
replace name_year1990 = "BOLAANG MENGONDOW" if name_year1990=="BOLAANG MONGONDOW"
replace name_year1990 = "BOYOLALI" if name_year1990=="BOYOLAI"
replace name_year1990 = "BUOL TOLI-TOLI" if name_year1990=="BUAL--TOLI-TOLI"
replace name_year1990 = "GOWA" if name_year1990=="GOWA/GOA"
replace name_year1990 = "HULU SUNGAI SELATAN" if name_year1990=="HULU SEI SELATAN"
replace name_year1990 = "HULU SUNGAI TENGAH" if name_year1990=="HULU SEI TENGAH"
replace name_year1990 = "HULU SUNGAI UTARA" if name_year1990=="HULU SEI UTARA"
replace name_year1990 = "INDRAGIRI HILIR" if name_year1990=="INDRAGIRI ILIR"
replace name_year1990 = "INDRAGIRI HULU" if name_year1990=="INDRAGIRI ULU"
replace name_year1990 = "KARANG ASEM" if name_year1990=="KARANGASEM"
replace name_year1990 = "KOTA MANADO" if name_year1990=="KOTA MENADO"
replace name_year1990 = "KOTA PEKALONGAN" if name_year1990=="KOTA PEKALONGANG"
replace name_year1990 = "KOTA PEMATANG SIANTAR" if name_year1990=="KOTA PEMATANGSIANTAR"
replace name_year1990 = "KOTA TEBING TINGGI" if name_year1990=="KOTA TEBINGTINGGI"
replace name_year1990 = "KOTAWARINGIN BARAT" if name_year1990=="KOTA WARINGIN BARAT"
replace name_year1990 = "KOTAWARINGIN TIMUR" if name_year1990=="KOTA WARINGIN TIMUR"
replace name_year1990 = "LIMA PULUH KOTO" if name_year1990=="LIMAPULUH KOTA"
replace name_year1990 = "MUARA ENIM" if name_year1990=="MUARA ENIM/L.I.O.T." 
replace name_year1990 = "PANGKAJENE KEPULAUAN" if name_year1990=="PAKAJENE KEPULAUAN"
replace name_year1990 = "MUSI BANYU ASIN" if name_year1990=="MUSI BANYUASIN"
replace name_year1990 = "JAYAWIJAYA" if name_year1990=="PEG. JAYAWIJAYA"
replace name_year1990 = "SITUBONDO" if name_year1990=="PANARUKAN (1980 SITUBONDO)" 
replace name_year1990 = "GRESIK" if name_year1990=="SURABAYA (1980 GRESIK)"
replace name_year1990 = "BANGGAI" if name_year1990=="LUWUK/BANGGAI"
replace name_year1990 = "KOTA UJUNG PANDANG" if name_year1990=="KOTA MAKASSAR (1980 UJUNG PADANG)"
replace name_year1990 = "PURBALINGGA" if name_year1990=="PURBOLINGGO"  
replace name_year1990 = "REJANG LEBONG" if name_year1990=="REJANGLEBONG" 
replace name_year1990 = "SAWAHLUNTO/SIJUNJUNG" if name_year1990=="SAWAH LUNTO (SIJUNJUNG)"
replace name_year1990 = "TANGERANG" if name_year1990=="TANGGERANG"
replace name_year1990 = "TAPIN" if name_year1990=="TAPIN/TAPIAN"
replace name_year1990 = "WAJO" if name_year1990=="WAJO/FAJO"  
replace name_year1990 = "PANIAI" if name_year1990=="PANIAI/NABIRE"
replace name_year1990 = "KOTA PEKAN BARU" if name_year1990=="KOTA PAKAN BARU"  
replace name_year1990 = "KOTA BUKITTINGGI" if name_year1990=="KOTA BUKIT TINGGI" 
replace name_year1990 = "KARAWANG" if name_year1990=="KRAWANG"
replace name_year1990 = "SIDENRENG RAPPANG" if name_year1990=="SID. RAPPANG"
replace name_year1990 = "BIAK NUMFOR" if name_year1990=="TELUK CENDRAWASIH (BIAK NUMFOR)"
replace name_year1990 = "BUNGO TEBO" if name_year1990=="MUARA BUNGO TEBO"
replace name_year1990 = "SAROLANGUN BANGKO" if name_year1990=="BANGKO SAROLANGUN"
replace name_year1990 = "KOTA BATAM" if name_year1990=="BATAM"
replace name_year1990 = "KOTA BANDAR LAMPUNG" if name_year1990=="KOTA TANJUNG KARANG"

tempfile shp90
save "`shp90'"

use "./data/firm-data/Indonesia/regions_codes/crosswalk_1988_2015.dta", clear
keep i_harmonize_to_1988 id_year1990 name_year1990
duplicates drop

merge m:1 name_year1990 using `shp90'

sort i_harmonize_to_1988
keep i_harmonize_to_1988 REGY1990
rename REGY1990 ADM2_id_in_shp_88

save "./data/firm-data/Indonesia/regions_codes/crosswalk_1988_2015_to_shp.dta", replace












