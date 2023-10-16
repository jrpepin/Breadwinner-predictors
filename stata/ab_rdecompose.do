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
