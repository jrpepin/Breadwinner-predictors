*-------------------------------------------------------------------------------
* BREADWINNER PROJECT
* predicting_consequences.do
* Kim McErlean
*-------------------------------------------------------------------------------
di "$S_DATE"

********************************************************************************
* DESCRIPTION
********************************************************************************
* This file....

use "$tempdir/combined_bw_equation.dta", clear


********************************************************************************
* CREATE SAMPLE AND VARIABLES
********************************************************************************

* Create dependent variable: income change
gen inc_pov = thearn_adj / threshold
sort SSUID PNUM year
by SSUID PNUM (year), sort: gen inc_pov_change = ((inc_pov-inc_pov[_n-1])/inc_pov[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==year[_n-1]+1
by SSUID PNUM (year), sort: gen inc_pov_change_raw = (inc_pov-inc_pov[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==year[_n-1]+1

gen inc_pov_summary2=.
replace inc_pov_summary2=1 if inc_pov_change_raw > 0 & inc_pov_change_raw!=. & inc_pov >=1.5
replace inc_pov_summary2=2 if inc_pov_change_raw > 0 & inc_pov_change_raw!=. & inc_pov <1.5
replace inc_pov_summary2=3 if inc_pov_change_raw < 0 & inc_pov_change_raw!=. & inc_pov >=1.5
replace inc_pov_summary2=4 if inc_pov_change_raw < 0 & inc_pov_change_raw!=. & inc_pov <1.5
replace inc_pov_summary2=5 if inc_pov_change_raw==0

label define summary2 1 "Up, Above Pov" 2 "Up, Below Pov" 3 "Down, Above Pov" 4 "Down, Below Pov" 5 "No Change"
label values inc_pov_summary2 summary2

gen mechanism=.
replace mechanism=1 if inc_pov_summary2==4
replace mechanism=2 if inc_pov_summary2==2 | inc_pov_summary2==3
replace mechanism=3 if inc_pov_summary2==1

label define mechanism 1 "Default" 2 "Reserve" 3 "Empowerment"
label values mechanism mechanism

* Creating necessary independent variables
 // one variable for all pathways
egen validate = rowtotal(mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes) // make sure moms only have 1 event
browse SSUID PNUM validate mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes trans_bw60_alt2 bw60_mom

gen pathway=0
replace pathway=1 if mt_mom==1
replace pathway=2 if ft_partner_down_mom==1
replace pathway=3 if ft_partner_down_only==1
replace pathway=4 if ft_partner_leave==1
replace pathway=5 if lt_other_changes==1

label define pathway 0 "None" 1 "Mom Up" 2 "Mom Up Partner Down" 3 "Partner Down" 4 "Partner Left" 5 "Other HH Change"
label values pathway pathway

** Should I restrict sample to just mothers who transitioned into breadwinning for this step? Probably. or just subpop?
keep if trans_bw60_alt2==1 & bw60lag==0
keep if survey == 2014

********************************************************************************
* ANALYSIS
********************************************************************************

/// To use for now
log using "$logdir/regression_consequences.log", replace

mlogit mechanism, baseoutcome(1) rrr // here prove that reserve is most likely outcome for full sample
mlogit mechanism i.educ_gp, baseoutcome(1) rrr nocons
margins i.educ_gp
tabulate mechanism educ_gp, chi2 col // this matches margins - because FULLY SATURATED (according to help article)
listcoef i.educ_gp // gives me what i need for educ 2

mlogit mechanism ib3.educ_gp, baseoutcome(1) rrr nocons
listcoef i.educ_gp // gives me educ 1

mlogit mechanism i.educ_gp i.educ_gp#i.pathway, baseoutcome(2) rrr nocons // okay using reserve as the category makes things make more sense. think there are more differences between reserve and empower than there are default and anything else
margins educ_gp#pathway  // why won't mom up estimate?
listcoef i.educ_gp // oh wait maybe this is helpful?!

mlogit mechanism i.race, baseoutcome(1) rrr
margins race

mlogit mechanism i.race i.race#i.pathway, baseoutcome(2) rrr nocons 
margins race#pathway
listcoef i.race

log close

/// testing things

mlogit mechanism, baseoutcome(1) rrr // here prove that reserve is most likely outcome for full sample
mlogit mechanism i.educ_gp, baseoutcome(1) rrr nocons
// do I interpret some college reserve coefficient as some college likelihood of being in reserve relative to default OR some college likelihood of being in reserve relative to HS or less being in reserve? OR some college reserve relative to default high school or less?!
// from UCLA: This is the multinomial logit estimate for a one unit increase in video score (so going from no HS to some college) for chocolate relative to vanilla (for reserve to default), given the other variables in the model are held constant. so going up in education increases likelihood of going to next outcome?
// think WITHOUT no cons, it's relative to default HS. does that mean constant is HS or less relative to HS or less default?? I *think* so gah
// WITH no cons, it's relative to that education in default?? so like college empower to college default, same with reserve
// how do I get it to be relative to less than HS in same category?? probably need to change reference groups?! and reference outcomes? listcoef
// from ND: Hence, you can easily see whether, say, yr89 significantly affects the likelihood of your being in the SD versus the SA category; but you can't easily tell whether yr89 significantly affects the likelihood of your being in, say, SD versus D, when neither is the base.
// from German: Thus, the relative probability of working rather than being in school is 37% higher for blacks than for non-blacks with the same education and work experience. (Relative probabilities are also called relative odds.) A common mistake is to interpret this coefficient as meaning that the probability of working is higher for blacks. It is only the relative probability of work over school that is higher. Says use MARGINS to interpret

margins i.educ_gp
tabulate mechanism educ_gp, chi2 col // this matches margins - because FULLY SATURATED (according to help article)

listcoef i.educ_gp // gives me what i need for educ 2

mlogit mechanism ib3.educ_gp, baseoutcome(1) rrr nocons
listcoef i.educ_gp // gives me educ 1

mlogit mechanism ib2.educ_gp, baseoutcome(1) rrr nocons
listcoef i.educ_gp // why can't I get educ 3??

mlogit mechanism i.race, baseoutcome(1) rrr
margins race

mlogit mechanism i.pathway, baseoutcome(1) rrr
margins pathway

mlogit mechanism i.educ_gp i.educ_gp#i.pathway, baseoutcome(1) rrr nocons // very few things are significant, think because reference groups are weird?
margins educ_gp#pathway  // why won't mom up estimate?

mlogit mechanism i.educ_gp i.educ_gp#i.pathway, baseoutcome(2) rrr nocons // okay using reserve as the category makes things make more sense. think there are more differences between reserve and empower than there are default and anything else
margins educ_gp#pathway  // why won't mom up estimate?
listcoef i.educ_gp // oh wait maybe this is helpful?!

// instead of interacting, do a model either for each educ and use pathway as IV?
// OR do pathway as stratifyer and education as iV?

mlogit mechanism i.pathway if educ_gp==1, baseoutcome(1) rrr // think the problem is like one outcome is most common - and there isn't noticeable variation by pathway on what leads to that outcome? so it's like ALL pathways leads to that outcome?
margins pathway // okay this literally matches above, just does estimate mom up - very low. okay because basically ONLY leads to default

mlogit mechanism i.educ_gp if pathway==2, baseoutcome(1) rrr // okay this doesn't work bc mom up can't lead to default?
margins educ_gp // okay this also matches above interaction

tab pathway mechanism if educ_gp==1
