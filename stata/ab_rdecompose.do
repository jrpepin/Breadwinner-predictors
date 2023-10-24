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
* CREATE PROGRAM
********************************************************************************
* Okay I think program FIRST, then do the data?
* Okay, because I am creating variables, need to do data each time?! or craete the variables and only bootstrap the collapse? but that won't accomplish anything?

// bootstrap THIS:
// rate = mean var if bwlag==0 & survey_yr=1996
// comp = mean trans_bw60_alt2 if bw60lag==0 & survey_yr==`y' & `var'==1

program mydecompose, eclass
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

********************************************************************************
* EXECUTE PROGRAM
********************************************************************************
use "$tempdir/combined_for_decomp.dta", clear // created in ab

foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
	gen `var'_rate=. // have to do this for round 1 to get boostrap to work? Think was throwing errors every time I had to start the file over
	gen `var'_comp=. 
}

log using "$logdir/bw_decomposition.log", replace

mydecompose // test it
bootstrap, reps(10) nodrop: mydecompose
bootstrap, reps(100) nodrop: mydecompose
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

log close

********************************************************************************
* AGGREGATE VIEWS
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

log using "$logdir/bw_decomposition.log", append

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

log close


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

oaxaca transitioned pathway if sample==1, by(survey) logit
oaxaca transitioned mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes if sample==1, by(survey) logit noisily
oaxaca transitioned normalize(none mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes) if sample==1, by(survey) logit svy relax // see Stata Journal article, the logit estimates don't nicely calculate the proportion
/*
You can also use oaxaca, for example, with binary outcome variables and employ a
command such as logit to estimate the models. You have to understand, however,
that oaxaca will always apply the decomposition to the linear predictions from the
models (based on the first equation if a model contains multiple equations). With
logit models, for example, the decomposition computed by oaxaca is expressed in
terms of log odds and not in terms of probabilities or proportions
*/
oaxaca transitioned mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes if sample==1, by(survey) svy // this matches generally. the interaction is main thing
oaxaca transitioned mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes if sample==1, by(survey) svy pooled // yes this gets rid of interaction

oaxaca transitioned mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes if sample==1 & educ==4, by(survey) svy pooled // test for a subgroup
	
log using "$logdir/bw_decomposition.log", append

mydecompose_total
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

log close


********************************************************************************
* MISC. CHECKS
********************************************************************************
// bootstrap, nowarn nodots reps(1000): mydecompose
// bootstrap, reps(1000): mydecompose //  Error occurred when bootstrap executed mydecompose. insufficient observations to compute bootstrap standard errors. no results will be saved
// https://www.statalist.org/forums/forum/general-stata-discussion/general/1342804-bootstrap-command-insufficient-observations-to-compute-bootstrap-standard-errors-no-results-will-be-save
// https://stackoverflow.com/questions/17623678/block-bootstrap-with-indicator-variable-for-each-block


// to match
import excel "T:\Research Projects\Breadwinner-predictors\data\equation.xlsx", sheet("Sheet1") firstrow

rdecompose exit_rate	momup_rate	partnerdown_rate	momup_partnerdown_rate	other_rate	///
exit_comp	momup_comp	partnerdown_comp	momup_partnerdown_comp	other_comp,	///
group(year) func((exit_rate*exit_comp) + (momup_rate*momup_comp) + (partnerdown_rate*partnerdown_comp) + ///
(momup_partnerdown_rate*momup_partnerdown_comp) + (other_rate*other_comp)) detail
