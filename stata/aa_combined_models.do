*-------------------------------------------------------------------------------
* BREADWINNER PROJECT
* combined_models.do
* Kelly Raley and Joanna Pepin
*-------------------------------------------------------------------------------
di "$S_DATE"

********************************************************************************
* DESCRIPTION
********************************************************************************
* This file estimates initial models testing simpler v. more complicated
* measures of household changes

* Files used were created in sipp14_bw_descriptives and sipp96_bw_descriptives

********************************************************************************
* First need to append the 2014 and 1996 files
********************************************************************************

local keep_vars "SSUID year PNUM spart_num ageb1 educ race avg_earn avg_mo_hrs betterjob betterjob_sp birth bw50 bw50L bw60 bw60L coh_diss coh_mar durmom earn_change earn_change_hh earn_change_oth earn_change_raw earn_change_raw_hh earn_change_raw_oth earn_change_raw_sp earn_change_sp earn_gain earn_lose earn_non earndown8 earndown8_all earndown8_hh earndown8_hh_all earndown8_oth earndown8_oth_all earndown8_sp earndown8_sp_all earnings earnings_a_sp earnings_mis earnings_ratio earnings_sp earnup8 earnup8_all earnup8_hh earnup8_hh_all earnup8_oth earnup8_oth_all earnup8_sp earnup8_sp_all firstbirth full_no full_no_sp full_part full_part_sp gain_partner hh_earn hh_gain hh_gain_earn hh_lose hh_lose_earn hhsize hours_change hours_change_sp avg_mo_hrs_sp hours_up5 hours_up5_all hours_up5_sp hours_up5_sp_all hoursdown5 hoursdown5_all hoursdown5_sp hoursdown5_sp_all jobchange jobchange_sp lost_partner marr_coh marr_diss marr_wid mom_gain_earn mom_lose_earn momdown_othdown momdown_partdown momno_hhdown momno_othdown momno_othleft momno_partdown momno_relend momup_only momup_othdown momup_othleft momup_othup momup_partdown momup_partup momup_relend monthsobserved nmos_bw50 nmos_bw60 no_full no_full_sp no_job_chg no_job_chg_sp no_part no_part_sp no_status_chg non_earn numearner oth_gain_earn oth_lose_earn other_earn other_earner part_full part_full_sp part_gain_earn part_lose_earn part_no part_no_sp resp_earn resp_non sing_coh sing_mar tage ageb1_mon thearn tpearn tpearn_mis trans_bw50 trans_bw60 wage_chg wage_chg_sp wagesdown8 wagesdown8_all wagesdown8_sp wagesdown8_sp_all wagesup8 wagesup8_all wagesup8_sp wagesup8_sp_all wpfinwgt momup_anydown momup_anyup momno_anydown momdown_anydown"

// 1996 file
use "$SIPP14keep/96_bw_descriptives.dta", clear

keep `keep_vars'

save "$tempdir/sipp96_to_append.dta", replace

// 2014 file
use "$SIPP14keep/bw_descriptives.dta", clear

rename avg_hrs 		avg_mo_hrs
rename hours_sp		avg_mo_hrs_sp
rename tage_fb 		ageb1_mon

keep `keep_vars'

append using "$SIPP14keep/96_bw_descriptives.dta"

save "$SIPP14keep/combined_annual_bw_status.dta", replace


********************************************************************************
* now specify models
********************************************************************************
//use "$SIPP14keep/combined_annual_bw_status.dta", clear

gen survey=.
replace survey=1996 if inrange(year,1995,2000)
replace survey=2014 if inrange(year,2013,2016)

gen dv=trans_bw60==1
replace dv=. if trans_bw60==. // recoding so only can be 0 or 1 - currently has missing values because we have been counting first year as "ineligible" since we don't know history. decide if that should stay?

local simple "earnup8_all earndown8_hh_all earn_lose"
local overlap "momup_only momup_anydown momup_othleft momup_anyup momno_hhdown momno_othleft momdown_anydown"
// should I add any control variables like educ and race here?!

// base models
logistic dv i.year `simple'
est store m1
outreg2 using "$results/regression.xls", sideway stats(coef se pval) label ctitle(Model 1) dec(2) alpha(0.001, 0.01, 0.05) replace 
outreg2 using "$results/regression.xls", sideway stats(coef) label ctitle(Model 1) dec(2) eform alpha(0.001, 0.01, 0.05) append 

logistic dv i.year `overlap'
est store m2
outreg2 using "$results/regression.xls", sideway stats(coef se pval) label ctitle(Model 2) dec(2) alpha(0.001, 0.01, 0.05) append 
outreg2 using "$results/regression.xls", sideway stats(coef) label ctitle(Model 2) dec(2) eform alpha(0.001, 0.01, 0.05) append 

lrtest m1 m2	

// adding interactions
logistic dv i.year i.survey#i.(`simple')
outreg2 using "$results/regression.xls", sideway stats(coef se pval) label ctitle(Model 3) dec(2) alpha(0.001, 0.01, 0.05) append 
outreg2 using "$results/regression.xls", sideway stats(coef) label ctitle(Model 3) dec(2) eform alpha(0.001, 0.01, 0.05) append 

logistic dv i.year i.survey#i.(`overlap')
outreg2 using "$results/regression.xls", sideway stats(coef se pval) label ctitle(Model 4) dec(2) alpha(0.001, 0.01, 0.05) append 
outreg2 using "$results/regression.xls", sideway stats(coef) label ctitle(Model 4) dec(2) eform alpha(0.001, 0.01, 0.05) append

// by year, because so much collinearity in 2014
logistic dv i.year `simple' if survey==1996
outreg2 using "$results/regression_by_year.xls", sideway stats(coef se pval) label ctitle(1996 1) dec(2) alpha(0.001, 0.01, 0.05) replace 
outreg2 using "$results/regression_by_year.xls", sideway stats(coef) label ctitle(1996 1) dec(2) eform alpha(0.001, 0.01, 0.05) append 

logistic dv i.year `overlap' if survey==1996
outreg2 using "$results/regression_by_year.xls", sideway stats(coef se pval) label ctitle(1996 2) dec(2) alpha(0.001, 0.01, 0.05) append 
outreg2 using "$results/regression_by_year.xls", sideway stats(coef) label ctitle(1996 2) dec(2) eform alpha(0.001, 0.01, 0.05) append  

logistic dv i.year `simple' if survey==2014
outreg2 using "$results/regression_by_year.xls", sideway stats(coef se pval) label ctitle(2014 1) dec(2) alpha(0.001, 0.01, 0.05) append 
outreg2 using "$results/regression_by_year.xls", sideway stats(coef) label ctitle(2014 1) dec(2) eform alpha(0.001, 0.01, 0.05) append 

logistic dv i.year `overlap' if survey==2014
outreg2 using "$results/regression_by_year.xls", sideway stats(coef se pval) label ctitle(2014 2) dec(2) alpha(0.001, 0.01, 0.05) append 
outreg2 using "$results/regression_by_year.xls", sideway stats(coef) label ctitle(2014 2) dec(2) eform alpha(0.001, 0.01, 0.05) append  


// testing dur mom instead of year as discrete time for interactions
drop if durmom<0

logistic dv i.durmom i.survey#i.(`simple')
outreg2 using "$results/regression.xls", sideway stats(coef se pval) label ctitle(Model 3a) dec(2) alpha(0.001, 0.01, 0.05) append 
outreg2 using "$results/regression.xls", sideway stats(coef) label ctitle(Model 3a) dec(2) eform alpha(0.001, 0.01, 0.05) append 

logistic dv i.durmom i.survey#i.(`overlap')
outreg2 using "$results/regression.xls", sideway stats(coef se pval) label ctitle(Model 4a) dec(2) alpha(0.001, 0.01, 0.05) append 
outreg2 using "$results/regression.xls", sideway stats(coef) label ctitle(Model 4a) dec(2) eform alpha(0.001, 0.01, 0.05) append 

/*
Likelihood-ratio test                                 LR chi2(4)  =    143.63
(Assumption: m1 nested in m2)                         Prob > chi2 =    0.0000
*/

/* okay didn't work because survey encompasses year - leaving for reference
logistic dv i.year i.survey `simple'
est store m3
outreg2 using "$results/regression.xls", sideway stats(coef se pval) label ctitle(Model 3) dec(2) alpha(0.001, 0.01, 0.05) append 
outreg2 using "$results/regression.xls", sideway stats(coef) label ctitle(Model 3) dec(2) eform alpha(0.001, 0.01, 0.05) append 

logistic dv i.year i.survey  `overlap'
est store m4
outreg2 using "$results/regression.xls", sideway stats(coef se pval) label ctitle(Model 4) dec(2) alpha(0.001, 0.01, 0.05) append 
outreg2 using "$results/regression.xls", sideway stats(coef) label ctitle(Model 4) dec(2) eform alpha(0.001, 0.01, 0.05) append 

lrtest m3 m4

Likelihood-ratio test                                 LR chi2(4)  =    143.63
(Assumption: m3 nested in m4)                         Prob > chi2 =    0.0000

drop if durmom < 0
logistic dv i.durmom `simple' // testing durmom - okay also very similar results/regression
*/

// need to recode race and education, per meeting, different categories