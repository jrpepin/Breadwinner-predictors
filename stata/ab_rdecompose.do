*-------------------------------------------------------------------------------
* BREADWINNER PROJECT
* rdecompose.do
* Kimberly McErlean
*-------------------------------------------------------------------------------
********************************************************************************
* DESCRIPTION
********************************************************************************
* This file creates a program to calculate the rate and composition components
* of the decomposition equation then inserts them into rdecompose to get the 
* contribution of each element. it then runs through 100 bootstrap iterations to 
* create standard errors of the decomposition estimates

********************************************************************************
* FORMULA COMPARISON
********************************************************************************
*1. "Original" estimates

use "$tempdir/combined_for_decomp.dta", clear // created in ab

	gen pathway=0
	replace pathway=1 if mt_mom==1
	replace pathway=2 if ft_partner_down_mom==1
	replace pathway=3 if ft_partner_down_only==1
	replace pathway=4 if ft_partner_leave==1
	replace pathway=5 if lt_other_changes==1
	label define pathway 0 "None" 1 "Mom up" 2 "Mom up Partner Down" 3 "Partner Down" 4 "Partner Exit" 5 "Other HH"
	label values pathway pathway
	
	gen no=0
	replace no=1 if pathway==0
	
	gen transitioned=0
	replace transitioned=1 if trans_bw60_alt2==1 & bw60lag==0
	
	gen sample=0
	replace sample=1 if bw60lag==0
	
// pathway rate / composition breakdowns

foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes no{
	gen `var'_rate=. // have to do this for round 1 to get boostrap to work? Think was throwing errors every time I had to start the file over
	gen `var'_comp=. 
	gen `var'_total=.
}

	
	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes no{
		drop `var'_comp `var'_rate `var'_total
		svy: mean `var' if bw60lag==0 & survey==1996
		matrix `var'_comp = e(b)
		gen `var'_comp = e(b)[1,1] if survey==1996
		svy: mean trans_bw60_alt2 if bw60lag==0 & survey==1996 & `var'==1
		matrix `var'_rate = e(b)
		gen `var'_rate = e(b)[1,1] if survey==1996
	}

	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes no{
		svy: mean `var' if bw60lag==0 & survey==2014
		matrix `var'_comp = e(b)
		replace `var'_comp = e(b)[1,1] if survey==2014
		svy: mean trans_bw60_alt2 if bw60lag==0 & survey==2014 & `var'==1
		matrix `var'_rate = e(b)
		replace `var'_rate = e(b)[1,1] if survey==2014
	}
	
	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes no{
		gen `var'_total = `var'_rate * `var'_comp // to get aggregate pathway level
	}

	preserve
	collapse (mean) mt_mom_rate mt_mom_comp ft_partner_down_mom_rate ft_partner_down_mom_comp ft_partner_down_only_rate ft_partner_down_only_comp ft_partner_leave_rate ft_partner_leave_comp lt_other_changes_rate lt_other_changes_comp, by(survey)

	rdecompose mt_mom_rate mt_mom_comp ft_partner_down_mom_rate ft_partner_down_mom_comp ft_partner_down_only_rate ft_partner_down_only_comp ft_partner_leave_rate ft_partner_leave_comp lt_other_changes_rate lt_other_changes_comp, ///
	group(survey) func((mt_mom_rate*mt_mom_comp) + (ft_partner_down_mom_rate*ft_partner_down_mom_comp) + (ft_partner_down_only_rate*ft_partner_down_only_comp) + (ft_partner_leave_rate*ft_partner_leave_comp) + (lt_other_changes_rate*lt_other_changes_comp)) 
	
	restore
	
// pathway totals
	preserve

	collapse (mean) mt_mom_total ft_partner_down_mom_total ft_partner_down_only_total ft_partner_leave_total lt_other_changes_total no_total, by(survey)
	
	rdecompose mt_mom_total ft_partner_down_mom_total ft_partner_down_only_total ft_partner_leave_total lt_other_changes_total no_total, group(survey) ///
	func(mt_mom_total + ft_partner_down_mom_total + ft_partner_down_only_total + ft_partner_leave_total + lt_other_changes_total + no_total)
	
	restore

// rate / composition totals - including "no pathway" as a line item
	preserve

	collapse (sum) sample transitioned if bw60lag==0, by(survey pathway)
	
	gen rate = transitioned / sample
	
	rdecompose sample rate, group(survey) transform(sample) sum(pathway)
	
	restore

// excluding "no pathway"
	preserve

	collapse (sum) sample transitioned if bw60lag==0 & pathway!=0, by(survey pathway)
	
	gen rate = transitioned / sample

	rdecompose sample rate, group(survey) transform(sample) sum(pathway)
	
	restore
	
*2. "Updated" estimates

use "$tempdir/combined_for_decomp.dta", clear // created in ab

	gen pathway=0
	replace pathway=1 if mt_mom==1
	replace pathway=2 if ft_partner_down_mom==1
	replace pathway=3 if ft_partner_down_only==1
	replace pathway=4 if ft_partner_leave==1
	replace pathway=5 if lt_other_changes==1
	label define pathway 0 "None" 1 "Mom up" 2 "Mom up Partner Down" 3 "Partner Down" 4 "Partner Exit" 5 "Other HH"
	label values pathway pathway
	
	/*
	tab pathway survey if bw60lag==0, col
	tab pathway survey if bw60lag==0 & pathway!=0, col
	tab pathway survey if bw60lag==0 [aweight=wpfinwgt], col
	
	tab pathway trans_bw60_alt2 if bw60lag==0, row
	tab pathway trans_bw60_alt2 if bw60lag==0 & pathway!=0, row
	*/

	gen no=0
	replace no=1 if pathway==0
	
	gen any_event=0
	replace any_event=1 if inrange(pathway,1,5)
	
	tab survey any_event, row
	tab survey any_event if bw60lag==0, row /// this should match kelly's calculations
	
	tab survey trans_bw60_alt2 if bw60lag==0 & any_event==1, row // this should also match kelly's calculations
// but this isn't total rate, need to take the multiplication of both - so try rdecompose with just "any_event"? I am still confused to get the total pathways to add up - but is that because of the no event composition?
	
// pathway rate / composition breakdowns
	
foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes no any_event{
	gen `var'_rate_a=. // have to do this for round 1 to get boostrap to work? Think was throwing errors every time I had to start the file over
	gen `var'_comp_all=.
	gen `var'_comp_path=.
}

	
	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes no any_event{
		drop `var'_comp_all `var'_comp_path `var'_rate_a
		svy: mean `var' if bw60lag==0 & survey==1996
		matrix `var'_comp_all = e(b)
		gen `var'_comp_all = e(b)[1,1] if survey==1996
		svy: mean `var' if bw60lag==0 & survey==1996 & pathway!=0
		matrix `var'_comp_path = e(b)
		gen `var'_comp_path = e(b)[1,1] if survey==1996
		svy: mean trans_bw60_alt2 if bw60lag==0 & survey==1996 & `var'==1
		matrix `var'_rate_a = e(b)
		gen `var'_rate_a = e(b)[1,1] if survey==1996
	}

	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes no any_event{
		svy: mean `var' if bw60lag==0 & survey==2014
		matrix `var'_comp_all = e(b)
		replace `var'_comp_all = e(b)[1,1] if survey==2014
		svy: mean `var' if bw60lag==0 & survey==2014 & pathway!=0
		matrix `var'_comp_path = e(b)
		replace `var'_comp_path = e(b)[1,1] if survey==2014
		svy: mean trans_bw60_alt2 if bw60lag==0 & survey==2014 & `var'==1
		matrix `var'_rate_a = e(b)
		replace `var'_rate_a = e(b)[1,1] if survey==2014
	}

	preserve
	collapse (mean) mt_mom_rate_a mt_mom_comp_all mt_mom_comp_path ft_partner_down_mom_rate_a ft_partner_down_mom_comp_all ft_partner_down_mom_comp_path ft_partner_down_only_rate_a ft_partner_down_only_comp_all ft_partner_down_only_comp_path ft_partner_leave_rate_a ft_partner_leave_comp_all ft_partner_leave_comp_path lt_other_changes_rate_a lt_other_changes_comp_all lt_other_changes_comp_path, by(survey)
	
foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
	gen `var'_rate = `var'_comp_path * `var'_rate_a
}
	
	rdecompose mt_mom_rate mt_mom_comp_all ft_partner_down_mom_rate ft_partner_down_mom_comp_all ft_partner_down_only_rate ft_partner_down_only_comp_all ft_partner_leave_rate ft_partner_leave_comp_all lt_other_changes_rate lt_other_changes_comp_all, ///
	group(survey) func((mt_mom_rate + ft_partner_down_mom_rate + ft_partner_down_only_rate + ft_partner_leave_rate + lt_other_changes_rate) * (mt_mom_comp_all + ft_partner_down_mom_comp_all + ft_partner_down_only_comp_all + ft_partner_leave_comp_all + lt_other_changes_comp_all))
	
	restore
	
// pathway totals
	* not sure if this can just be same as above

// rate / composition totals
	preserve
	
	collapse (mean) any_event_rate_a any_event_comp_all, by(survey)
	
	rdecompose any_event_rate_a any_event_comp_all, group(survey)
	
	restore

********************************************************************************
**# CREATE PROGRAM ("Updated" Estimates)
********************************************************************************
* Okay I think program FIRST, then do the data?
* Okay, because I am creating variables, need to do data each time?! or craete the variables and only bootstrap the collapse? but that won't accomplish anything?

// bootstrap THIS:
// rate = mean var if bwlag==0 & survey_yr=1996
// comp = mean trans_bw60_alt2 if bw60lag==0 & survey_yr==`y' & `var'==1

** Pathway specific rate/ compositions
capture: program drop mydecompose

program mydecompose, eclass

	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes no any_event{
		drop `var'_comp_all `var'_comp_path `var'_rate_a
		svy: mean `var' if bw60lag==0 & survey==1996
		matrix `var'_comp_all = e(b)
		gen `var'_comp_all = e(b)[1,1] if survey==1996
		svy: mean `var' if bw60lag==0 & survey==1996 & pathway!=0
		matrix `var'_comp_path = e(b)
		gen `var'_comp_path = e(b)[1,1] if survey==1996
		svy: mean trans_bw60_alt2 if bw60lag==0 & survey==1996 & `var'==1
		matrix `var'_rate_a = e(b)
		gen `var'_rate_a = e(b)[1,1] if survey==1996
	}

	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes no any_event{
		svy: mean `var' if bw60lag==0 & survey==2014
		matrix `var'_comp_all = e(b)
		replace `var'_comp_all = e(b)[1,1] if survey==2014
		svy: mean `var' if bw60lag==0 & survey==2014 & pathway!=0
		matrix `var'_comp_path = e(b)
		replace `var'_comp_path = e(b)[1,1] if survey==2014
		svy: mean trans_bw60_alt2 if bw60lag==0 & survey==2014 & `var'==1
		matrix `var'_rate_a = e(b)
		replace `var'_rate_a = e(b)[1,1] if survey==2014
	}

// pathway-specific rate / composition elements
preserve

	collapse (mean) mt_mom_rate_a mt_mom_comp_all mt_mom_comp_path ft_partner_down_mom_rate_a ft_partner_down_mom_comp_all ft_partner_down_mom_comp_path ft_partner_down_only_rate_a ft_partner_down_only_comp_all ft_partner_down_only_comp_path ft_partner_leave_rate_a ft_partner_leave_comp_all ft_partner_leave_comp_path lt_other_changes_rate_a lt_other_changes_comp_all lt_other_changes_comp_path, by(survey)
	
foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
	gen `var'_rate = `var'_comp_path * `var'_rate_a
}
	
	rdecompose ft_partner_leave_comp_all mt_mom_comp_all ft_partner_down_only_comp_all ft_partner_down_mom_comp_all lt_other_changes_comp_all ft_partner_leave_rate mt_mom_rate  ft_partner_down_only_rate   ft_partner_down_mom_rate lt_other_changes_rate, ///
	group(survey) func((mt_mom_rate + ft_partner_down_mom_rate + ft_partner_down_only_rate + ft_partner_leave_rate + lt_other_changes_rate) * (mt_mom_comp_all + ft_partner_down_mom_comp_all + ft_partner_down_only_comp_all + ft_partner_leave_comp_all + lt_other_changes_comp_all))

	matrix a = e(b) * 100
//	local a = e(b) * 100
//	di `a'
	ereturn post a //[1,10]

restore

/* when I try to bootstrap, not working to have in same program
// rate / composition totals
preserve

	collapse (mean) any_event_rate_a any_event_comp_all, by(survey)
	
	rdecompose any_event_rate_a any_event_comp_all, group(survey)

	matrix b = e(b) * 100
	ereturn post b //[1,10]
	
restore
*/

end

** Total rate / composition
capture: program drop mydecompose_total

program mydecompose_total, eclass

	drop any_event_comp any_event_rate
	svy: mean any_event if bw60lag==0 & survey==1996
	matrix any_event_comp = e(b)
	gen any_event_comp = e(b)[1,1] if survey==1996
	svy: mean trans_bw60_alt2 if bw60lag==0 & survey==1996 & any_event==1
	matrix any_event_rate = e(b)
	gen any_event_rate = e(b)[1,1] if survey==1996
	
	svy: mean any_event if bw60lag==0 & survey==2014
	matrix any_event_comp = e(b)
	replace any_event_comp = e(b)[1,1] if survey==2014
	svy: mean trans_bw60_alt2 if bw60lag==0 & survey==2014 & any_event==1
	matrix any_event_rate = e(b)
	replace any_event_rate = e(b)[1,1] if survey==2014
	
// rate / composition totals
preserve

	collapse (mean) any_event_rate any_event_comp, by(survey)
	
	rdecompose any_event_rate any_event_comp, group(survey)

	matrix b = e(b) * 100
	ereturn post b //[1,10]
	
restore

end


********************************************************************************
**# EXECUTE PROGRAMS
********************************************************************************
use "$tempdir/combined_for_decomp.dta", clear // created in ab

gen pathway=0
replace pathway=1 if mt_mom==1
replace pathway=2 if ft_partner_down_mom==1
replace pathway=3 if ft_partner_down_only==1
replace pathway=4 if ft_partner_leave==1
replace pathway=5 if lt_other_changes==1
label define pathway 0 "None" 1 "Mom up" 2 "Mom up Partner Down" 3 "Partner Down" 4 "Partner Exit" 5 "Other HH"
label values pathway pathway

gen no=0
replace no=1 if pathway==0
	
gen any_event=0
replace any_event=1 if inrange(pathway,1,5)

foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes no any_event{
	gen `var'_rate_a=. // have to do this for round 1 to get boostrap to work? Think was throwing errors every time I had to start the file over
	gen `var'_comp_all=.
	gen `var'_comp_path=.
}

gen any_event_comp=.
gen any_event_rate=.

** Pathway specific rate/ composition
// log using "$logdir/bw_decomposition.log", replace

mydecompose // test it
bootstrap, reps(2) nodrop: mydecompose // just to figure it out
bootstrap, reps(100) nodrop: mydecompose // to actually use
// bootstrap, reps(10) nodrop: mydecompose
// bootstrap, reps(1000) nodrop: mydecompose

// by education group
preserve
keep if educ==1 | educ==2 // HS or less
bootstrap, reps(100) nodrop: mydecompose
restore

preserve
keep if educ==3 // Some College
bootstrap, reps(100) nodrop: mydecompose
restore

preserve
keep if educ==4 // College
bootstrap, reps(100) nodrop: mydecompose
restore

// by race/ ethnicity
preserve
keep if race==1 // White
bootstrap, reps(100) nodrop: mydecompose
restore

preserve
keep if race==2 // Black
bootstrap, reps(100) nodrop: mydecompose
restore

preserve
keep if race==3 // NH Asian
bootstrap, reps(100) nodrop: mydecompose
restore

preserve
keep if race==4 // Hispanic
bootstrap, reps(100) nodrop: mydecompose
restore

// log close

** Total rate / composition
// log using "$logdir/bw_decomposition.log", append

mydecompose_total
bootstrap, reps(2) nodrop: mydecompose_total // just to figure it out
bootstrap, reps(100) nodrop: mydecompose_total

// by education group
preserve
keep if educ==1 | educ==2 // HS or less
bootstrap, reps(100) nodrop: mydecompose_total
restore

preserve
keep if educ==3 // Some College
bootstrap, reps(100) nodrop: mydecompose_total
restore

preserve
keep if educ==4 // College
bootstrap, reps(100) nodrop: mydecompose_total
restore

// by race/ ethnicity
preserve
keep if race==1 // White
bootstrap, reps(100) nodrop: mydecompose_total
restore

preserve
keep if race==2 // Black
bootstrap, reps(100) nodrop: mydecompose_total
restore

preserve
keep if race==3 // NH Asian
bootstrap, reps(100) nodrop: mydecompose_total
restore

preserve
keep if race==4 // Hispanic
bootstrap, reps(100) nodrop: mydecompose_total
restore

// log close

********************************************************************************
**# PATHWAY AGGREGATE VIEWS - still need to figure this out
********************************************************************************

program mydecompose_temp, eclass

	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		drop `var'_comp `var'_rate `var'_total
		svy: mean `var' if bw60lag==0 & survey==1996
		matrix `var'_comp = e(b)
		gen `var'_comp = e(b)[1,1] if survey==1996
		svy: mean trans_bw60_alt2 if bw60lag==0 & survey==1996 & `var'==1
		matrix `var'_rate = e(b)
		gen `var'_rate = e(b)[1,1] if survey==1996
	}

	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		svy: mean `var' if bw60lag==0 & survey==2014
		matrix `var'_comp = e(b)
		replace `var'_comp = e(b)[1,1] if survey==2014
		svy: mean trans_bw60_alt2 if bw60lag==0 & survey==2014 & `var'==1
		matrix `var'_rate = e(b)
		replace `var'_rate = e(b)[1,1] if survey==2014
	}
	
	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		gen `var'_total = `var'_rate * `var'_comp // to get aggregate pathway level
	}
	/*
	gen pathway=0
	replace pathway=1 if mt_mom==1
	replace pathway=2 if ft_partner_down_mom==1
	replace pathway=3 if ft_partner_down_only==1
	replace pathway=4 if ft_partner_leave==1
	replace pathway=5 if lt_other_changes==1
	label define pathway 0 "None" 1 "Mom up" 2 "Mom up Partner Down" 3 "Partner Down" 4 "Partner Exit" 5 "Other HH"
	label values pathway pathway
	
	gen pathway_trans=0
	replace pathway_trans=1 if mt_mom==1 & bw60lag==0
	replace pathway_trans=2 if ft_partner_down_mom==1 & bw60lag==0
	replace pathway_trans=3 if ft_partner_down_only==1 & bw60lag==0
	replace pathway_trans=4 if ft_partner_leave==1 & bw60lag==0
	replace pathway_trans=5 if lt_other_changes==1 & bw60lag==0
	label values pathway_trans pathway
	
	tab pathway trans_bw60_alt2 if bw60lag==0, row
	gen transitioned=0
	replace transitioned=1 if trans_bw60_alt2==1 & bw60lag==0
	// replace transitioned=. if trans_bw60_alt2==. // not eligible to transition
	
	gen sample=0
	replace sample=1 if bw60lag==0
	// replace sample=. if trans_bw60_alt2==. // not eligible to transition
	tab pathway transitioned if sample==1
	preserve
	collapse (sum) sample transitioned if bw60lag==0, by(survey pathway)
	// drop if pathway==0 - okay I think I need the none to get composition right
	gen rate = transitioned / sample
	
	rdecompose sample rate, group(survey) transform(sample) sum(pathway) // func(sample*rate) it just keeps being too high of rates and it feels like composition is too high. is it because summing across years?
	
	restore
	
	preserve
	collapse (sum) sample transitioned, by(survey)
	gen rate = transitioned / sample
	rdecompose sample rate, group(survey) transform(sample)
*/

	preserve
	collapse (mean) mt_mom_total ft_partner_down_mom_total ft_partner_down_only_total ft_partner_leave_total lt_other_changes_total, by(survey) // to get aggregate pathway level
	
	rdecompose mt_mom_total ft_partner_down_mom_total ft_partner_down_only_total ft_partner_leave_total lt_other_changes_total, group(survey) ///
	func(mt_mom_total + ft_partner_down_mom_total + ft_partner_down_only_total + ft_partner_leave_total + lt_other_changes_total)
	
	matrix b = e(b) * 100
	ereturn post b //[1,10]

//	rdecompose sample rate, group(survey) func(sample*rate)
	restore
end

use "$tempdir/combined_for_decomp.dta", clear // created in ab

foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
	gen `var'_rate=. // have to do this for round 1 to get boostrap to work? Think was throwing errors every time I had to start the file over
	gen `var'_comp=. 
	gen `var'_total=.
}

// log using "$logdir/bw_decomposition.log", append

mydecompose_temp // test it
bootstrap, reps(100) nodrop: mydecompose_temp

// by education group
preserve
keep if educ==1 | educ==2 // HS or less
bootstrap, reps(100) nodrop: mydecompose_temp
restore

preserve
keep if educ==3 // Some College
bootstrap, reps(100) nodrop: mydecompose_temp
restore

preserve
keep if educ==4 // College
bootstrap, reps(100) nodrop: mydecompose_temp
restore

// by race/ ethnicity
preserve
keep if race==1 // White
bootstrap, reps(100) nodrop: mydecompose_temp
restore

preserve
keep if race==2 // Black
bootstrap, reps(100) nodrop: mydecompose_temp
restore

preserve
keep if race==3 // NH Asian
bootstrap, reps(100) nodrop: mydecompose_temp
restore

preserve
keep if race==4 // Hispanic
bootstrap, reps(100) nodrop: mydecompose_temp
restore

// log close


use "$tempdir/combined_for_decomp.dta", clear // created in ab

	gen pathway=0
	replace pathway=1 if mt_mom==1
	replace pathway=2 if ft_partner_down_mom==1
	replace pathway=3 if ft_partner_down_only==1
	replace pathway=4 if ft_partner_leave==1
	replace pathway=5 if lt_other_changes==1
	label define pathway 0 "None" 1 "Mom up" 2 "Mom up Partner Down" 3 "Partner Down" 4 "Partner Exit" 5 "Other HH"
	label values pathway pathway
	
/*
	gen pathway_trans=0
	replace pathway_trans=1 if mt_mom==1 & bw60lag==0
	replace pathway_trans=2 if ft_partner_down_mom==1 & bw60lag==0
	replace pathway_trans=3 if ft_partner_down_only==1 & bw60lag==0
	replace pathway_trans=4 if ft_partner_leave==1 & bw60lag==0
	replace pathway_trans=5 if lt_other_changes==1 & bw60lag==0
	label values pathway_trans pathway
*/
	
	gen transitioned=0
	replace transitioned=1 if trans_bw60_alt2==1 & bw60lag==0
	// replace transitioned=. if trans_bw60_alt2==. // not eligible to transition
	
	gen sample=0
	replace sample=1 if bw60lag==0
	// replace sample=. if trans_bw60_alt2==. // not eligible to transition
	// tab pathway transitioned if sample==1
	
svyset [pweight = wpfinwgt]
svy: tab pathway if sample==1 & survey==2014 
svy: logit transitioned i.pathway if sample==1 & survey==2014, or nocons // is this rate contribution?, then composition is above? some estimates are too high
svy: logit transitioned i.pathway if sample==1 & survey==2014 & pathway!=0, or nocons 

svy: tab pathway if sample==1 & survey==1996
svy: logit transitioned i.pathway if sample==1 & survey==1996, or nocons // is this rate contribution?, then composition is above?

gen none=0
replace none=1 if pathway==0

/*
You can also use oaxaca, for example, with binary outcome variables and employ a
command such as logit to estimate the models. You have to understand, however,
that oaxaca will always apply the decomposition to the linear predictions from the
models (based on the first equation if a model contains multiple equations). With
logit models, for example, the decomposition computed by oaxaca is expressed in
terms of log odds and not in terms of probabilities or proportions

oaxaca transitioned pathway if sample==1, by(survey) logit
oaxaca transitioned mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes if sample==1, by(survey) logit noisily
oaxaca transitioned normalize(none mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes) if sample==1, by(survey) logit svy relax // see Stata Journal article, the logit estimates don't nicely calculate the proportion


oaxaca transitioned mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes if sample==1, by(survey) svy // this matches generally. the interaction is main thing
oaxaca transitioned mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes if sample==1, by(survey) svy pooled // yes this gets rid of interaction

oaxaca transitioned mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes if sample==1 & educ==4, by(survey) svy pooled // test for a subgroup
*/	

********************************************************************************
**# CREATE PROGRAMS ("Original" Estimates)
********************************************************************************
* Okay I think program FIRST, then do the data?
* Okay, because I am creating variables, need to do data each time?! or craete the variables and only bootstrap the collapse? but that won't accomplish anything?

// bootstrap THIS:
// rate = mean var if bwlag==0 & survey_yr=1996
// comp = mean trans_bw60_alt2 if bw60lag==0 & survey_yr==`y' & `var'==1
capture: program drop mydecompose_orig

program mydecompose_orig, eclass
// browse mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes


	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		drop `var'_comp `var'_rate
		svy: mean `var' if bw60lag==0 & survey==1996
		matrix `var'_comp = e(b)
		gen `var'_comp = e(b)[1,1] if survey==1996
		svy: mean trans_bw60_alt2 if bw60lag==0 & survey==1996 & `var'==1
		matrix `var'_rate = e(b)
		gen `var'_rate = e(b)[1,1] if survey==1996
	}

	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		svy: mean `var' if bw60lag==0 & survey==2014
		matrix `var'_comp = e(b)
		replace `var'_comp = e(b)[1,1] if survey==2014
		svy: mean trans_bw60_alt2 if bw60lag==0 & survey==2014 & `var'==1
		matrix `var'_rate = e(b)
		replace `var'_rate = e(b)[1,1] if survey==2014
	}

	preserve
	collapse (mean) mt_mom_rate mt_mom_comp ft_partner_down_mom_rate ft_partner_down_mom_comp ft_partner_down_only_rate ft_partner_down_only_comp ft_partner_leave_rate ft_partner_leave_comp lt_other_changes_rate lt_other_changes_comp, by(survey)

	rdecompose mt_mom_rate mt_mom_comp ft_partner_down_mom_rate ft_partner_down_mom_comp ft_partner_down_only_rate ft_partner_down_only_comp ft_partner_leave_rate ft_partner_leave_comp lt_other_changes_rate lt_other_changes_comp, ///
	group(survey) func((mt_mom_rate*mt_mom_comp) + (ft_partner_down_mom_rate*ft_partner_down_mom_comp) + (ft_partner_down_only_rate*ft_partner_down_only_comp) + (ft_partner_leave_rate*ft_partner_leave_comp) + (lt_other_changes_rate*lt_other_changes_comp))

	matrix b = e(b) * 100
	ereturn post b //[1,10]

	restore
end

program mydecompose_total, eclass

	preserve
	collapse (sum) sample transitioned if bw60lag==0, by(survey pathway)
	// drop if pathway==0 - okay I think I need the none to get composition right
	gen rate = transitioned / sample
	
	rdecompose sample rate, group(survey) transform(sample) sum(pathway) // func(sample*rate) it just keeps being too high of rates and it feels like composition is too high. is it because summing across years?
	
	matrix b = e(b) * 100
	ereturn post b //[1,10]

//	rdecompose sample rate, group(survey) func(sample*rate)
	restore

end

********************************************************************************
**# MISC. CHECKS
********************************************************************************
// bootstrap, nowarn nodots reps(1000): mydecompose
// bootstrap, reps(1000): mydecompose //  Error occurred when bootstrap executed mydecompose. insufficient observations to compute bootstrap standard errors. no results will be saved
// https://www.statalist.org/forums/forum/general-stata-discussion/general/1342804-bootstrap-command-insufficient-observations-to-compute-bootstrap-standard-errors-no-results-will-be-save
// https://stackoverflow.com/questions/17623678/block-bootstrap-with-indicator-variable-for-each-block


// to match
import excel "T:\Research Projects\Breadwinner-predictors\data\equation.xlsx", sheet("Sheet1") firstrow clear

rdecompose exit_rate	momup_rate	partnerdown_rate	momup_partnerdown_rate	other_rate	///
exit_comp	momup_comp	partnerdown_comp	momup_partnerdown_comp	other_comp,	///
group(year) func((exit_rate*exit_comp) + (momup_rate*momup_comp) + (partnerdown_rate*partnerdown_comp) + ///
(momup_partnerdown_rate*momup_partnerdown_comp) + (other_rate*other_comp)) detail
