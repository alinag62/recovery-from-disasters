clear
timer on 1
set more off

local path "/Users/slackner/Google Drive/Research/Projects/EarthquakeGDP/Data/"

********* temp
use "`path'Built/Country/Country_ShakingPanel/Countryshaking1temp.dta", clear
foreach val of numlist 2/241 {
	append using "`path'Built/Country/Country_ShakingPanel/Countryshaking`val'temp.dta"
}
rename country isocode
save "`path'Built/WorldPaneltemp.dta", replace
****************

insheet using "`path'Raw/countrypoints/country_points.csv", clear name
save "`path'Built/country_points.dta", replace

use "`path'Built/Country/Country_ShakingPanel/Countryshaking1.dta", clear
foreach val of numlist 2/241 {
	append using "`path'Built/Country/Country_ShakingPanel/Countryshaking`val'.dta"
}

count

ta country
codebook country

merge 1:1 country year using "`path'Raw/eqe18/worldbank_detailed.dta", nogen

rename country isocode
merge n:1 isocode using "`path'Built/country_points.dta"

rename wb_iso_num country
tsset country year
sort country year

foreach var in ny_gnp_pcap_cd sl_emp_vuln_zs sl_emp_vuln_fe_zs sl_emp_vuln_ma_zs sl_uem_1524_ne_zs sl_uem_1524_ma_ne_zs sl_uem_1524_fe_ne_zs sl_uem_totl_ne_zs sl_uem_totl_ma_ne_zs sl_uem_totl_fe_ne_zs sl_uem_tert_ma_zs sl_uem_tert_fe_zs sl_uem_tert_zs sl_uem_seco_ma_zs sl_uem_seco_fe_zs sl_uem_seco_zs sl_uem_prim_ma_zs sl_uem_prim_fe_zs sl_uem_prim_zs sh_alc_pcap_li sp_dyn_to65_fe_zs sp_dyn_to65_ma_zs sh_sta_suic_p5 ic_lgl_cred_xq sh_prv_smok_fe sh_prv_smok_ma nv_srv_tetc_zs nv_srv_tetc_kd_zg si_pov_ruhc sl_tlf_cact_fm_ne_zs se_sec_prog_fe_zs se_sec_prog_ma_zs sh_sta_wast_ma_zs sh_sta_wast_fe_zs sh_sta_wast_zs sh_sta_maln_ma_zs sh_sta_maln_fe_zs sh_sta_maln_zs sn_itk_defc_zs sh_sta_stnt_ma_zs sh_sta_stnt_fe_zs sh_sta_stnt_zs sh_svr_wast_ma_zs sh_svr_wast_fe_zs sh_svr_wast_zs sh_sta_owgh_ma_zs sh_sta_owgh_fe_zs sh_sta_owgh_zs sh_dyn_aids_zs sh_hiv_1524_ma_zs sh_hiv_1524_fe_zs sh_anm_allw_zs sh_prg_anem sh_anm_nprg_zs sh_anm_chld_zs sp_pop_grow sp_pop_0014_to_zs sh_dth_imrt sh_dth_nmrt sp_dyn_amrt_fe sp_dyn_amrt_ma sp_dyn_imrt_in sp_dyn_imrt_fe_in sh_dyn_nmrt sp_dyn_imrt_ma_in sh_dyn_mort sh_dyn_mort_fe sh_dyn_mort_ma sl_uem_ltrm_ma_zs sl_uem_ltrm_fe_zs sl_uem_ltrm_zs se_adt_1524_lt_ma_zs se_adt_1524_lt_fe_zs se_adt_1524_lt_fm_zs se_adt_litr_ma_zs se_adt_litr_fe_zs sp_dyn_le00_in sh_mmr_risk_zs sp_dyn_le00_ma_in sp_dyn_le00_fe_in it_net_user_p2 st_int_arvl vc_idp_totl_he vc_idp_totl_le vc_ihr_psrc_p5 nv_ind_totl_kd_zg nv_ind_totl_zs si_dst_10th_10 si_dst_frst_10 ny_gdp_mktp_pp_kd ny_gdp_pcap_kd sp_dyn_tfrt_in sl_agr_empl_zs sh_con_1524_ma_zs sh_con_1524_fe_zs sp_dyn_cbrt_in nv_agr_totl_zs nv_agr_totl_kd_zg {
	gen ln`var'=ln(`var')
	bysort country: gen growth`var'=ln`var'[_n]-ln`var'[_n-1]
}


sort country year
gen income=ny_gnp_pcap_cd if year==2015
forvalues i=1(1)20 {
	bysort country: replace income=ny_gnp_pcap_cd[_n-`i'] if year==2015 & income==.
}

bysort country: egen inc=max(income)
drop income
codebook inc

gen gni_cat=0
replace gni_cat=1 if inc<=1025
replace gni_cat=2 if inc>1025 & inc<4036
replace gni_cat=3 if inc>=12476 & inc<=30000
replace gni_cat=4 if inc>30000

label define income 0 "upper middle-income" 1 "low-income" 2 "lower middle-income" 3 "high-income" 4 "very-high-income"
label val gni_cat income
label var gni_cat "Country income category"

label var mpga_aw "Average PGA in entire country"
label var mpga_aw1 "Average PGA in strongest 1% of entire country"
foreach num in 1 10 100 1000 {
	label var Pop`num'mpga_aw "Average PGA in area with pop.dens.>=`num'/km^2"
	label var Pop`num'mpga_aw1 "Average PGA in strongest 1% of area with pop.dens.>=`num'/km^2"
}
label var urbanmpga_aw "Average PGA in urban part of country"
label var urbanmpga_aw1 "Average PGA in strongest 1% of urban part of country"
label var mpga_pw "Population weighted PGA"

label var number_quakes_aw "Average number of events in entire country"
label var number_quakes_aw1 "Average number of events in strongest 1% of entire country"
foreach num in 1 10 100 1000 {
	label var Pop`num'number_quakes_aw "Average number of events in area with pop.dens.>=`num'/km^2"
	label var Pop`num'number_quakes_aw1 "Average number of events in strongest 1% of area with pop.dens.>=`num'/km^2"
}
label var urbannumber_quakes_aw "Average number of events in urban part of country"
label var urbannumber_quakes_aw1 "Average number of events in strongest 1% of urban part of country"
label var number_quakes_pw "Population weighted number of events"

replace countryUrbanArea=countryUrbanArea/1000
foreach num in 1 10 100 1000 {
	replace countryPop`num'Area=countryPop`num'Area/1000
	label var countryPop`num'Area "Size of region in country with pop.dens.>=`num'/km^2 in 1000 km^2"
}
replace countryarea=countryarea/1000
label var countryUrbanArea "Size of urban region in country in 1000 km^2"
label var countryarea "Size of country in 1000 km^2"

bysort country: egen maxgdp=max(growthny_gdp_pcap_kd)
drop if maxgdp==.
drop if isocode=="TWN"

drop countrypop*

************ temp
drop _merge
merge 1:1 isocode year using "`path'Built/WorldPaneltemp.dta"
****************

save "`path'Built/WorldPanel.dta", replace

timer off 1
timer list 1
