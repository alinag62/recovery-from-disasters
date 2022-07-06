local path "/Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters"
import delimited "/Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters/data/tropical-cyclones/raw/ibtracs.ALL.list.v04r00.csv", rowrange(3) clear 

* Based on the papers: we keep only main observations to avoid spurs
keep if track_type=="main"

*Dropping disturbances 
drop if nature=="DS"
drop if usa_status=="DB"
drop if reunion_type=="01"
drop if bom_type=="10"
drop if td9636_stage=="0"

*Dropping extratropical
drop if nature=="ET"
drop if usa_status=="EX"
drop if tokyo_grade=="6"
drop if cma_cat=="9"
drop if reunion_type=="05"
drop if bom_type=="50"|bom_type=="51"|bom_type=="52"
drop if td9636_stage=="5"
drop if neumann_class=="EX"
drop if mlc_class=="EX"

/*Dropping low storms 
drop if usa_status=="LO"
drop if usa_sshs=="-3"
drop if hko_cat=="LW"
drop if newdelhi_grade=="L"
drop if bom_type=="20"
drop if mlc_class=="LO"

*Dropping depressions (tropical/subtropical/monsoonal) 
drop if usa_status=="TD"| usa_status=="SD"| usa_status=="MD"
drop if usa_sshs=="-1"
drop if reunion_type=="02"
drop if tokyo_grade=="2"
drop if cma_cat=="0"|cma_cat=="1"
drop if hko_cat=="TD"
drop if newdelhi_grade=="D"|newdelhi_grade=="DD"
drop if td9636_stage=="1"
drop if mlc_class=="SD"|mlc_class=="TD"

*Dropping subtropical cyclones
drop if nature=="SS"
drop if usa_sshs=="-2"
drop if reunion_type=="07"
drop if bom_type=="70"|bom_type=="71"|bom_type=="72"
drop if mlc_class=="SS" */











