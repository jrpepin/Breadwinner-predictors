*-------------------------------------------------------------------------------
* BREADWINNER PROJECT
* combine_waves.do
* Kelly Raley and Joanna Pepin
*-------------------------------------------------------------------------------
di "$S_DATE"


********************************************************************************
* DESCRIPTION
********************************************************************************
* This file combines our 1996 and 2014 panels to use in our decomposition.
* Files used were created in sipp14_bw_descriptives and sipp96_bw_descriptives

********************************************************************************
* First need to append the 2014 and 1996 files
********************************************************************************

local keep_vars "SSUID year PNUM firstyr spart_num ageb1 educ race avg_earn avg_mo_hrs birth bw50 bw50L bw60 bw60L trans_bw50 trans_bw60 trans_bw60_alt trans_bw60_alt2 coh_diss coh_mar durmom durmom_1st earn_change earn_change_hh earn_change_oth earn_change_raw earn_change_raw_hh earn_change_raw_oth earn_change_raw_sp earn_change_sp earn_gain earn_lose earn_non earndown8 earndown8_all earndown8_hh earndown8_hh_all earndown8_oth earndown8_oth_all earndown8_sp earndown8_sp_all earnings earnings_a_sp earnings_mis earnings_ratio earnings_sp earnup8 earnup8_all earnup8_hh earnup8_hh_all earnup8_oth earnup8_oth_all earnup8_sp earnup8_sp_all firstbirth yrfirstbirth full_no full_no_sp full_part full_part_sp gain_partner hh_earn hh_gain hh_gain_earn hh_lose hh_lose_earn avg_hhsize st_hhsize end_hhsize st_minorchildren end_minorchildren hours_change hours_change_sp avg_mo_hrs_sp hours_up5 hours_up5_all hours_up5_sp hours_up5_sp_all hoursdown5 hoursdown5_all hoursdown5_sp hoursdown5_sp_all lost_partner marr_coh marr_diss marr_wid mom_gain_earn mom_lose_earn momdown_othdown momdown_partdown momno_hhdown momno_othdown momno_othleft momno_partdown momno_relend momup_only momup_othdown momup_othleft momup_othup momup_partdown momup_partup momup_relend monthsobserved monthsobservedL nmos_bw50 nmos_bw60 no_full no_full_sp no_job_chg no_job_chg_sp no_part no_part_sp no_status_chg non_earn numearner oth_gain_earn oth_lose_earn other_earn other_earner part_full part_full_sp part_gain_earn part_lose_earn part_no part_no_sp resp_earn resp_non sing_coh sing_mar tage ageb1_mon thearn thearn_alt tpearn tpearn_mis wage_chg wage_chg_sp wagesdown8 wagesdown8_all wagesdown8_sp wagesdown8_sp_all wagesup8 wagesup8_all wagesup8_sp wagesup8_sp_all wpfinwgt correction momup_anydown momup_anyup momno_anydown momdown_anydown ageb1_gp status_b1 minors_fy mom_panel partner_gain partner_lose st_marital_status end_marital_status start_marital_status last_marital_status scaled_weight rmwkwjb educ_sp race_sp weeks_employed_sp minorchildren minorbiochildren preschoolchildren prebiochildren age3children age3biochildren oldest_age all_ages youngest_age"

// 1996 file
use "$SIPP96keep/96_bw_descriptives.dta", clear
gen correction=1

keep `keep_vars'

save "$tempdir/sipp96_to_append.dta", replace

// 2014 file
use "$SIPP14keep/bw_descriptives.dta", clear

rename avg_hrs 		avg_mo_hrs
rename hours_sp		avg_mo_hrs_sp
rename tage_fb 		ageb1_mon

gen yrfirstbirth_ch=year if firstbirth==1
bysort SSUID PNUM (yrfirstbirth_ch): replace yrfirstbirth_ch=yrfirstbirth_ch[1]
// browse SSUID PNUM year mom_panel firstbirth yrfirstbirth yrfirstbirth_ch

keep `keep_vars' st_occ_* end_occ_* st_tjb*_occ end_tjb*_occ program_income tanf_amount rtanfyn rtanfcov eeitc st_partner_earn end_partner_earn sex_sp

append using "$tempdir/sipp96_to_append.dta"

gen survey=.
replace survey=1996 if inrange(year,1995,2000)
replace survey=2014 if inrange(year,2013,2016)

// Missing value check - key IVs (DV handled elsewhere / meant to have missing because not always eligible, etc.)
tab race, m
tab educ, m // .02%
drop if educ==.
tab last_marital_status, m // .02%
drop if last_marital_status==.

// adding in lookups for poverty thresholds
browse year SSUID end_hhsize end_minorchildren

merge m:1 year end_hhsize end_minorchildren using "$projcode/stata/poverty_thresholds.dta"

browse year SSUID end_hhsize end_minorchildren threshold

drop if _merge==2
drop _merge

save "$combined_data/combined_annual_bw_status.dta", replace


