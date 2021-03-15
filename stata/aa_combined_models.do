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
logistic dv i.year `overlap'
logistic dv i.survey `simple' i.survey#i.(`simple')
logistic dv i.survey `overlap' i.survey#i.(`overlap')

**************************************************8
**Rest of below is me trying to figure out the collinearity problem

// base models with fit statistics
logistic dv i.year `simple'
est store m1
fitstat
outreg2 using "$results/regression.xls", sideway stats(coef se pval) label ctitle(Model 1) dec(2) alpha(0.001, 0.01, 0.05) replace 
outreg2 using "$results/regression.xls", sideway stats(coef) label ctitle(Model 1) dec(2) eform alpha(0.001, 0.01, 0.05) append 

/*estat gof

Logistic model for dv, goodness-of-fit test

       number of observations =     38677
 number of covariate patterns =        54
             Pearson chi2(44) =       219.56
                  Prob > chi2 =         0.0000

fitstat

Measures of Fit for logistic of dv

Log-Lik Intercept Only:     -10903.255   Log-Lik Full Model:          -9709.591
D(38666):                    19419.183   LR(9):                        2387.328
                                         Prob > LR:                       0.000
McFadden's R2:                   0.109   McFadden's Adj R2:               0.108
ML (Cox-Snell) R2:               0.060   Cragg-Uhler(Nagelkerke) R2:      0.139
McKelvey & Zavoina's R2:         0.186   Efron's R2:                      0.075
Variance of y*:                  4.044   Variance of error:               3.290
Count R2:                        0.919   Adj Count R2:                    0.003
AIC:                             0.503   AIC*n:                       19441.183
BIC:                       -389009.790   BIC':                        -2292.261
BIC used by Stata:           19524.813   AIC used by Stata:           19439.183

*/

logistic dv i.year `overlap'
est store m2
fitstat
outreg2 using "$results/regression.xls", sideway stats(coef se pval) label ctitle(Model 2) dec(2) alpha(0.001, 0.01, 0.05) append 
outreg2 using "$results/regression.xls", sideway stats(coef) label ctitle(Model 2) dec(2) eform alpha(0.001, 0.01, 0.05) append 

/*estat gof

Logistic model for dv, goodness-of-fit test

       number of observations =     38677
 number of covariate patterns =       104
             Pearson chi2(90) =       945.97
                  Prob > chi2 =         0.0000


fitstat

Measures of Fit for logistic of dv

Log-Lik Intercept Only:     -10903.255   Log-Lik Full Model:          -9452.086
D(38662):                    18904.172   LR(13):                       2902.339
                                         Prob > LR:                       0.000
McFadden's R2:                   0.133   McFadden's Adj R2:               0.132
ML (Cox-Snell) R2:               0.072   Cragg-Uhler(Nagelkerke) R2:      0.168
McKelvey & Zavoina's R2:         0.228   Efron's R2:                      0.094
Variance of y*:                  4.260   Variance of error:               3.290
Count R2:                        0.919   Adj Count R2:                    0.003
AIC:                             0.490   AIC*n:                       18934.172
BIC:                       -389482.549   BIC':                        -2765.020
BIC used by Stata:           19052.054   AIC used by Stata:           18932.172
*/

lrtest m1 m2, stats
fitstat, using(m1)

/*

Likelihood-ratio test                                 LR chi2(4)  =    515.01 // this is LR from m2 (2902.34) - LR from m1 (2387.33)
(Assumption: m1 nested in m2)                         Prob > chi2 =    0.0000

Akaike's information criterion and Bayesian information criterion

-----------------------------------------------------------------------------
       Model |          N   ll(null)  ll(model)      df        AIC        BIC
-------------+---------------------------------------------------------------
          m1 |     38,677  -10903.26  -9709.591      10   19439.18   19524.81
          m2 |     38,677  -10903.26  -9452.086      14   18932.17   19052.05
-----------------------------------------------------------------------------

helpful ref for calculations: https://stats.idre.ucla.edu/stata/webbooks/logistic/chapter3/lesson-3-logistic-regression-diagnostics/
pseudo R2 = (null-model) / null

*/

corr earnup8_all earndown8_hh_all  earn_lose if dv==1
corr dv earnup8_all earndown8_hh_all earn_lose
corr dv earnup8_all earndown8_hh_all earn_lose if dv==1
corr dv_nom earnup8_all earndown8_hh_all earn_lose if dv_nom==1
gen dv_nom = dv
replace dv_nom=0 if dv_nom==. // okay def don't use this because the variables can't have 1 values in the first year (and that is where the missing come from)
collin earnup8_all earndown8_hh_all earn_lose

gen survey_test = 1 // wondering if getting messed up with use of 1996 and 2014
replace survey_test = 2 if survey == 2014

** testing making own interactions to test collinearity
gen earnup_sur= earnup8_all * survey_test
gen earndown_sur = earndown8_hh_all * survey_test
gen earnlose_sur = earn_lose * survey_test

collin earnup_sur earndown_sur earnlose_sur dv

logistic dv i.survey_test earnup8_all earndown8_hh_all earn_lose i.earnup_sur i.earndown_sur i.earnlose_sur

logistic dv i.survey_test i.earnup_sur i.earndown_sur i.earnlose_sur // works with just interactions but this seems flawed...

/* https://www.statalist.org/forums/forum/general-stata-discussion/general/1297011-omitted-because-of-collinearity - see response number 6

"I guess I know what is going on. You are logging your dependent variable, which means that observations where the dependent variable is equal to zero are dropped. Therefore, dummy variables that are equal to 1 only when the dependent variable is zero will be identically zero in the sample used in the estimation. These will, of course, be dropped because of collinearity. I have discussed a similar problem in this paper. As an aside, it is a bad idea to estimate the model taking logs of a dependent variable that ca be zero; have a look here and here."
*/

// adding interactions - testing many things
local simple "earnup8_all earndown8_hh_all earn_lose"
logistic dv i.survey_test `simple' i.survey_test#i.(`simple')
logistic dv i.survey `simple' i.survey#i.(`simple')
logistic dv_nom i.survey `simple' i.survey#i.(`simple')
logistic dv i.year `simple' i.year#i.(`simple')
logistic dv_nom i.year `simple' i.year#i.(`simple')

// outreg2 using "$results/regression.xls", sideway stats(coef se pval) label ctitle(Model 3) dec(2) alpha(0.001, 0.01, 0.05) append 
// outreg2 using "$results/regression.xls", sideway stats(coef) label ctitle(Model 3) dec(2) eform alpha(0.001, 0.01, 0.05) append 

logistic dv i.survey `overlap' i.survey#i.(`overlap')
outreg2 using "$results/regression.xls", sideway stats(coef se pval) label ctitle(Model 4) dec(2) alpha(0.001, 0.01, 0.05) append 
outreg2 using "$results/regression.xls", sideway stats(coef) label ctitle(Model 4) dec(2) eform alpha(0.001, 0.01, 0.05) append

// by year, because so much collinearity in 2014 - this works, but changes interpretation bc base of 2014 is so different
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


// seeing if estimating by group helps - it doesn't.
local simple "earnup8_all earndown8_hh_all earn_lose"
logistic dv i.survey `simple' i.survey#i.(`simple') if educ==2

local overlap "momup_only momup_anydown momup_othleft momup_anyup momno_hhdown momno_othleft momdown_anydown"
logistic dv i.survey `overlap' i.survey#i.(`overlap') if educ==2

// testing dur mom instead of year as discrete time for interactions
drop if durmom<0

logistic dv i.durmom `simple' i.survey#i.(`simple')
outreg2 using "$results/regression.xls", sideway stats(coef se pval) label ctitle(Model 3a) dec(2) alpha(0.001, 0.01, 0.05) append 
outreg2 using "$results/regression.xls", sideway stats(coef) label ctitle(Model 3a) dec(2) eform alpha(0.001, 0.01, 0.05) append 

local overlap "momup_only momup_anydown momup_othleft momup_anyup momno_hhdown momno_othleft momdown_anydown"
logistic dv i.durmom `overlap' i.survey#i.(`overlap')
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