
/*
###########################################################################
 0)                     Intro
########################################################################### */

cd /Users/alina/Box/recovery-from-disasters


* Housekeeping
clear
clear matrix
set more off

*###########################################################################

shp2dta using "./data/firm-data/Colombia/Shapefile/COL_adm_shp/COL_adm1.shp", database("./data/firm-data/Colombia/Shapefile/COL_adm_shp/COL_adm1.dta") coordinates("./data/firm-data/Colombia/Shapefile/COL_adm_shp/COL_adm1_coordinates.dta") replace
use ./data/firm-data/Colombia/Shapefile/COL_adm_shp/COL_adm1.dta, clear

replace NAME_1= "Boyaca" if NAME_1=="Boyacá"
replace NAME_1= "Atlantico" if NAME_1=="Atlántico"
replace NAME_1= "Bolivar" if NAME_1=="Bolívar"
replace NAME_1= "Caqueta" if NAME_1=="Caquetá"
replace NAME_1= "Choco" if NAME_1=="Chocó"
replace NAME_1= "Cordoba" if NAME_1=="Córdoba"
replace NAME_1= "Guainia" if NAME_1=="Guainía"
replace NAME_1= "Narino" if NAME_1=="Nariño"
replace NAME_1= "Quindio" if NAME_1=="Quindío"
replace NAME_1= "San Andres" if NAME_1=="San Andrés y Providencia"
replace NAME_1= "Vaupes" if NAME_1=="Vaupés"

merge 1:1 NAME_1 using ./data/firm-data/Colombia/Shapefile/COL_adm_shp/adm1_transferring.dta
keep if _m==3
drop _m
keep ID_1 country_sect

merge 1:m country_sect using ./data/firm-data/Colombia/Final-Dataset/Colombia_survey_readytoregress_no_adm1_id_Ishan_version.dta
drop if _m==1
drop _m
rename ID_1 id_used_adm1
order id_used_adm1 id_used plant year

replace id_used_adm1=2 if id_used==76
replace id_used_adm1=4 if id_used==141
replace id_used_adm1=5 if id_used==169
replace id_used_adm1=7 if id_used==330
replace id_used_adm1=14 if id_used==568
replace id_used_adm1=25 if id_used==847
replace id_used_adm1=27 if id_used==863
replace id_used_adm1=30 if id_used==1043

save "./data/firm-data/Colombia/Final-Dataset/Colombia_survey_readytoregress.dta", replace




