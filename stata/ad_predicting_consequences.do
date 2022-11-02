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
keep if survey == 2014

********************************************************************************
* CREATE SAMPLE AND VARIABLES
********************************************************************************

* Create dependent variable: income change
gen inc_pov = thearn_adj / threshold
sort SSUID PNUM year
by SSUID PNUM (year), sort: gen inc_pov_change = ((inc_pov-inc_pov[_n-1])/inc_pov[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==year[_n-1]+1
by SSUID PNUM (year), sort: gen inc_pov_change_raw = (inc_pov-inc_pov[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==year[_n-1]+1

gen inc_pov_lag = inc_pov[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)
gen pov_lag=.
replace pov_lag=0 if inc_pov_lag <1.5
replace pov_lag=1 if inc_pov_lag>=1.5 & inc_pov_lag!=. // okay 1 is NOT in poverty

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

// program variables
gen tanf=0
replace tanf=1 if tanf_amount > 0

// need to get tanf in year prior and then eitc in year after - but this is not really going to work for 2016, so need to think about that
sort SSUID PNUM year
browse SSUID PNUM year rtanfcov tanf tanf_amount program_income eeitc
gen tanf_lag = tanf[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)
gen tanf_amount_lag = tanf_amount[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)
gen program_income_lag = program_income[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)
gen eitc_after = eeitc[_n+1] if SSUID==SSUID[_n+1] & PNUM==PNUM[_n+1] & year==(year[_n+1]-1)
gen earnings_lag = earnings[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)
gen thearn_lag = thearn_adj[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)

gen zero_earnings=0
replace zero_earnings=1 if earnings_lag==0

// last_status
recode last_marital_status (1=1) (2=2) (3/5=3), gen(marital_status_t1)
label define marr 1 "Married" 2 "Cohabiting" 3 "Single"
label values marital_status_t1 marr
recode marital_status_t1 (1/2=1)(3=0), gen(partnered_t1)

// first_status
recode start_marital_status (1=1) (2=2) (3/5=3), gen(marital_status_t)
label values marital_status_t marr
recode marital_status_t (1/2=1)(3=0), gen(partnered_t)

// household income change
by SSUID PNUM (year), sort: gen hh_income_chg = ((thearn_adj-thearn_adj[_n-1])/thearn_adj[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1) & trans_bw60_alt2==1
by SSUID PNUM (year), sort: gen hh_income_raw = ((thearn_adj-thearn_adj[_n-1])) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1) & trans_bw60_alt2==1
browse SSUID PNUM year thearn_adj bw60 trans_bw60_alt2 hh_income_chg hh_income_raw
	
by SSUID PNUM (year), sort: gen hh_income_raw_all = ((thearn_adj-thearn_adj[_n-1])) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1) & bw60lag==0
	
inspect hh_income_raw // almost split 50/50 negative v. positive
sum hh_income_raw, detail // i am now wondering - is this the better way to do it?
gen hh_chg_value=.
replace hh_chg_value = 0 if hh_income_raw <0
replace hh_chg_value = 1 if hh_income_raw >0 & hh_income_raw!=.
tab hh_chg_value
sum hh_income_raw if hh_chg_value==0, detail
sum hh_income_raw if hh_chg_value==1, detail

** Should I restrict sample to just mothers who transitioned into breadwinning for this step? Probably. or just subpop?
keep if trans_bw60_alt2==1 & bw60lag==0

gen start_from_0 = 0
replace start_from_0=1 if earnings_lag==0

gen end_as_sole=0
replace end_as_sole=1 if earnings_ratio==1

** use the single / partnered I created before: single needs to be ALL YEAR
gen single_all=0
replace single_all=1 if partnered_t==0 & no_status_chg==1

gen partnered_all=0
replace partnered_all=1 if partnered_t==1 | single_all==0

gen relationship=.
replace relationship=1 if start_marital_status==1 & partnered_all==1 // married
replace relationship=2 if start_marital_status==2 & partnered_all==1 // cohab
label values relationship marr

* gah
gen rel_status=.
replace rel_status=1 if single_all==1
replace rel_status=2 if partnered_all==1

********************************************************************************
* Descriptive things
********************************************************************************
tab single_all start_from_0, row
tab single_all end_as_sole, row

// both more likely to start from 0 AND end up as 100% contributor

tabstat earnings_ratio if trans_bw60_alt2==1 & bw60lag==0, stats(mean p50)
tabstat earnings_ratio if trans_bw60_alt2==1 & bw60lag==0 & single_all==1, stats(mean p50)
tabstat earnings_ratio if trans_bw60_alt2==1 & bw60lag==0 & partnered_all==1, stats(mean p50)

// Sample descriptives for impact paper
putexcel set "$results/Breadwinner_Impact_Tables", sheet(sample) modify
putexcel A1 = "Descriptive Statistics", border(bottom) hcenter bold
putexcel B1 = "Total Sample"
putexcel C1 = "Single Mothers"
putexcel D1 = "Partnered Mothers"
putexcel A2 = "Median HH income at time t-1 (inflation-adjusted)"
putexcel A3 = "Mothers' median income at time t-1 (inflation-adjusted)"
putexcel A4 = "Race/ethnicity (time-invariant)"
putexcel A5 = "Non-Hispanic White", txtindent(4)
putexcel A6 = "Black", txtindent(4)
putexcel A7 = "Non-Hispanic Asian", txtindent(4)
putexcel A8 = "Hispanic", txtindent(4)
putexcel A9 = "Education (time-varying)"
putexcel A10 = "HS Degree or Less", txtindent(4)
putexcel A11 = "Some College", txtindent(4)
putexcel A12 = "College Plus", txtindent(4)
putexcel A13 = "Relationship Status (time-varying)"
putexcel A14 = "Married", txtindent(4)
putexcel A15 = "Cohabitating", txtindent(4)
putexcel A16 = "Single", txtindent(4)
putexcel A17 = "Pathway into primary earning (time-varying)"
putexcel A18 = "Partner separation", txtindent(4)
putexcel A19 = "Mothers increase in earnings", txtindent(4)
putexcel A20 = "Partner lost earnings", txtindent(4)
putexcel A21 = "Mothers increase in earnings & partner lost earnings", txtindent(4)
putexcel A22 = "Other member exit | lost earnings", txtindent(4)
putexcel A23 = "Poverty and welfare"
putexcel A24 = "Mom had Zero Earnings in Year Prior", txtindent(4)
putexcel A25 = "TANF in Year Prior", txtindent(4)
putexcel A26 = "EITC in Year Prior", txtindent(4)
putexcel A27 = "EITC in Year Became Primary Earner (reduced sample)", txtindent(4)

*Income 
* HH
sum thearn_lag, detail
putexcel B2=`r(p50)', nformat(###,###)
sum thearn_lag if rel_status==1, detail
putexcel C2=`r(p50)', nformat(###,###)
sum thearn_lag if rel_status==2, detail
putexcel D2=`r(p50)', nformat(###,###)

*Mother
/*
sum earnings_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & trans_bw60_alt2[_n+1]==1 & bw60lag[_n+1]==0, detail  // okay yes this is right, but before I had the below - which is wrong, because need the earnings to lag the bw
sum earnings_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & trans_bw60_alt2==1 & bw60lag==0, detail
*/
sum earnings_lag, detail 
putexcel B3=`r(p50)', nformat(###,###)
sum earnings_lag if rel_status==1, detail 
putexcel C3=`r(p50)', nformat(###,###)
sum earnings_lag if rel_status==2, detail 
putexcel D3=`r(p50)', nformat(###,###)

* Race
tab race, gen(race)

local i=1

foreach var in race1 race2 race3 race4{
	local row = `i'+4
	mean `var' if survey_yr==2 & trans_bw60_alt2==1 & bw60lag==0
	matrix `var'_bw14 = e(b)
	putexcel B`row' = matrix(`var'_bw14), nformat(#.##%)
	local ++i
}
		

* Education
tab educ_gp, gen(educ_gp)

local i=1

foreach var in educ_gp1 educ_gp2 educ_gp3{
	local row = `i'+9
	mean `var' if survey_yr==2 & trans_bw60_alt2==1 & bw60lag==0
	matrix `var'_bw14 = e(b)
	putexcel B`row' = matrix(`var'_bw14), nformat(#.##%)
	local ++i
}
		
	
* Marital Status - December of prior year
tab marital_status_t1, gen(marst)

local i=1

foreach var in marst1 marst2 marst3{
	local row = `i'+13
	mean `var' if survey_yr==2 & trans_bw60_alt2==1 & bw60lag==0
	matrix `var'_bw14 = e(b)
	putexcel B`row' = matrix(`var'_bw14), nformat(#.##%)
	local ++i
}

* Pathway into breadwinning

local i=1

foreach var in ft_partner_leave mt_mom ft_partner_down_only ft_partner_down_mom lt_other_changes{
	local row = `i'+17
	mean `var' if survey_yr==2 & trans_bw60_alt2==1 // & bw60lag==0 // remove svy to see if matches paper 1
	matrix `var'_bw14 = e(b)
	putexcel B`row' = matrix(`var'_bw14), nformat(#.##%)
	local ++i
}

local i=1

* Poverty and welfare
foreach var in start_from_0 tanf_lag eeitc eitc_after{
	local row = `i'+23
	mean `var' if survey_yr==2 & trans_bw60_alt2==1 & bw60lag==0
	matrix `var'_bw14 = e(b)
	putexcel B`row' = matrix(`var'_bw14), nformat(#.##%)
	local ++i
}


//// by partnership status

* Race
local i=1
local colu "C D"

foreach var in race1 race2 race3 race4{
	forvalues p=1/2{
		local row = `i'+4
		local col: word `p' of `colu'
		mean `var' if rel_status==`p'
		matrix `var'_`p' = e(b)
		putexcel `col'`row' = matrix(`var'_`p'), nformat(#.##%)
	}
	local ++i
}


* Education
local i=1
local colu "C D"

foreach var in educ_gp1 educ_gp2 educ_gp3{
	forvalues p=1/2{
		local row = `i'+9
		local col: word `p' of `colu'
		mean `var' if rel_status==`p'
		matrix `var'_`p' = e(b)
		putexcel `col'`row' = matrix(`var'_`p'), nformat(#.##%)
	}
	local ++i
}
		
	
* Marital Status - December of prior year
local i=1
local colu "C D"

foreach var in marst1 marst2 marst3{
	forvalues p=1/2{
		local row = `i'+13
		local col: word `p' of `colu'
		mean `var' if rel_status==`p'
		matrix `var'_`p' = e(b)
		putexcel `col'`row' = matrix(`var'_`p'), nformat(#.##%)
	}
	local ++i
}

* Pathway into breadwinning
local i=1
local colu "C D"

foreach var in ft_partner_leave mt_mom ft_partner_down_only ft_partner_down_mom lt_other_changes{
	forvalues p=1/2{
		local row = `i'+17
		local col: word `p' of `colu'
		mean `var' if rel_status==`p'
		matrix `var'_`p' = e(b)
		putexcel `col'`row' = matrix(`var'_`p'), nformat(#.##%)
	}
	local ++i
}

* Poverty and welfare
local i=1
local colu "C D"

foreach var in start_from_0 tanf_lag eeitc eitc_after{
	forvalues p=1/2{
		local row = `i'+23
		local col: word `p' of `colu'
		mean `var' if rel_status==`p'
		matrix `var'_`p' = e(b)
		putexcel `col'`row' = matrix(`var'_`p'), nformat(#.##%)
	}
	local ++i
}


********************************************************************************
* ANALYSIS
********************************************************************************
tab pov_lag inc_pov_summary2, row

tab pathway inc_pov_summary2 if pov_lag==0, row nofreq
tab pathway inc_pov_summary2 if pov_lag==1, row nofreq

tab race inc_pov_summary2 if pov_lag==0, row nofreq
tab race inc_pov_summary2 if pov_lag==1, row nofreq

tab educ_gp inc_pov_summary2 if pov_lag==0, row nofreq
tab educ_gp inc_pov_summary2 if pov_lag==1, row nofreq

tabstat inc_pov, by(pov_lag)
tabstat inc_pov_lag, by(pov_lag)
tab educ_gp pov_lag, row

tab single_all inc_pov_summary2, row nofreq
tab single_all inc_pov_summary2 if start_from_0==1, row nofreq
tab single_all inc_pov_summary2 if start_from_0==0, row nofreq

tab relationship inc_pov_summary2, row nofreq

sum thearn_lag, detail  // pre 2014 -- matches paper
sum thearn_adj, detail // post 2014 -- matches paper

sum thearn_lag if single_all==1, detail
sum thearn_adj if single_all==1, detail

sum thearn_lag if partnered_all==1, detail
sum thearn_adj if partnered_all==1, detail

sum thearn_lag if relationship==1, detail
sum thearn_adj if relationship==1, detail

sum thearn_lag if relationship==2, detail
sum thearn_adj if relationship==2, detail

// trying NEW classification
gen outcome=.
replace outcome=1 if pov_lag==0 & inc_pov_summary2==1 // improve
replace outcome=2 if (pov_lag==0 & inlist(inc_pov_summary2,2,4)) | (pov_lag==1 & inlist(inc_pov_summary2,1,3)) // maintain
replace outcome=3 if pov_lag==1 & inc_pov_summary2==4 // decline

label define outcome 1 "Improve" 2 "Maintain" 3 "Decline"
label values outcome outcome

tab inc_pov_summary2 outcome

tab race outcome, row nofreq
tab educ_gp outcome, row nofreq

tab pathway outcome, row nofreq // okay I honestly do not hate this.

browse SSUID PNUM year earnings_adj thearn_adj tanf_amount_lag  tanf_amount program_income program_income_lag

********************************************************************************
* Demographics by outcome and pathway
********************************************************************************

tab inc_pov_summary2 tanf, row
tab inc_pov_summary2 tanf_lag, row
tab inc_pov_summary2 eeitc, row
tab inc_pov_summary2 eitc_after, row

tab pathway tanf, row
tab pathway tanf_lag, row
tab pathway eeitc, row
tab pathway eitc_after, row
tab pathway inc_pov_summary2, row
tab pathway inc_pov_summary2 if partnered==0, row
tab pathway inc_pov_summary2 if partnered==1, row

tab inc_pov_summary2 educ_gp, row nofreq
tab inc_pov_summary2 race, row nofreq
tab inc_pov_summary2 partnered, row nofreq
tab inc_pov_summary2 tanf_lag, row nofreq
tab inc_pov_summary2 eeitc, row nofreq
tab inc_pov_summary2 eitc_after, row nofreq
tab inc_pov_summary2 zero_earnings, row nofreq

tab inc_pov_summary2 tanf_lag if partnered==0, row

tab pathway inc_pov_summary2 if educ_gp==1, row
tab pathway inc_pov_summary2 if partnered==1, row

	
histogram hh_income_raw if hh_income_raw > -50000 & hh_income_raw <50000, kdensity width(5000) addlabel addlabopts(yvarformat(%4.1f)) percent xlabel(-50000(10000)50000) title("Household income change upon transition to BW") xtitle("HH income change")
histogram inc_pov_change_raw if inc_pov_change_raw < 5 & inc_pov_change_raw >-5, width(.5) xlabel(-5(0.5)5) addlabel addlabopts(yvarformat(%4.1f)) percent

browse SSUID PNUM year earnings_adj earnings_lag thearn_adj thearn_lag hh_income_raw inc_pov inc_pov_lag inc_pov_change_raw

histogram hh_income_raw if hh_income_raw > -50000 & hh_income_raw <50000 & single_all==1, kdensity width(5000) addlabel addlabopts(yvarformat(%4.1f)) percent xlabel(-50000(10000)50000) title("Household income change upon transition to BW") xtitle("HH income change") // single moms

histogram hh_income_raw if hh_income_raw > -50000 & hh_income_raw <50000 & partnered_all==1, kdensity width(5000) addlabel addlabopts(yvarformat(%4.1f)) percent xlabel(-50000(10000)50000) title("Household income change upon transition to BW") xtitle("HH income change") // partnered

********************************************************************************
* MODELS
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

save "$tempdir/bw_consequences.dta", replace

browse SSUID PNUM educ_gp pathway mechanism inc_pov

preserve

collapse (p50) inc_pov, by(educ_gp pathway)
export excel using "$results\class_pathway_poverty.xls", firstrow(variables) replace

restore
preserve

collapse (p50) inc_pov, by(race pathway)
export excel using "$results\race_pathway_poverty.xls", firstrow(variables) replace

restore
