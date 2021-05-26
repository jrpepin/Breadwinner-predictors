*-------------------------------------------------------------------------------
* BREADWINNER PROJECT
* annualize.do
* Kelly Raley and Joanna Pepin
*-------------------------------------------------------------------------------
di "$S_DATE"


********************************************************************************
* DESCRIPTION
********************************************************************************
* Create annual measures of breadwinning.

* The data file used in this script was produced by merging_hh_characteristics.do
* It is restricted to mothers living with minor children.


********************************************************************************
* Create descriptive statistics to prep for annualized variables
********************************************************************************
use "$SIPP14keep/sipp14tpearn_rel", clear

// Create variables with the first and last month of observation by year
   egen startmonth=min(monthcode), by(SSUID PNUM year)
   egen lastmonth =max(monthcode), by(SSUID PNUM year)
   
// Creating partner status variables needed for reshape

	egen statuses = nvals(marital_status),	by(SSUID ERESIDENCEID PNUM year) // first examining how many people have more than 2 statuses in a year (aka changed status more than 1 time)
	// browse SSUID PNUM panelmonth marital_status statuses // if statuses>2
	tab statuses // okay very small percent - will use last status change OR if I do as separate columns, she can get both captured?
	
	replace spouse	=1 	if spouse 	> 1 // one case has 2 spouses
	replace partner	=1 	if partner 	> 1 // 36 cases of 2-3 partners

	// Create a combined spouse & partner indicator
	gen 	spartner=1 	if spouse==1 | partner==1
	replace spartner=0 	if spouse==0 & partner==0
	
	// Create indicators of partner presence at the first and last month of observation by year
	gen 	start_spartner=spartner if monthcode==startmonth
	gen 	last_spartner=spartner 	if monthcode==lastmonth
	gen 	start_spouse=spouse if monthcode==startmonth
	gen 	last_spouse=spouse 	if monthcode==lastmonth
	gen 	start_partner=partner if monthcode==startmonth
	gen 	last_partner=partner 	if monthcode==lastmonth
	
	// get partner specific variables
	gen spousenum=.
	forvalues n=1/22{
	replace spousenum=`n' if relationship`n'==1
	}

	gen partnernum=.
	forvalues n=1/22{
	replace partnernum=`n' if relationship`n'==2
	}

	gen spart_num=spousenum
	replace spart_num=partnernum if spart_num==.

	gen ft_pt_sp=.
	gen educ_sp=.

	forvalues n=1/22{
	replace ft_pt_sp=to_ft_pt`n' if spart_num==`n'
	replace educ_sp=to_educ`n' if spart_num==`n'
	}

	
// getting ready to create indicators of various status changes THROUGHOUT the year
drop _merge
local reshape_vars marital_status hhsize other_earner earnings spartner ft_pt educ renroll ft_pt_sp educ_sp

keep `reshape_vars' SSUID PNUM panelmonth
 
// Reshape the data wide (1 person per row)
reshape wide `reshape_vars', i(SSUID PNUM) j(panelmonth)

	// marital status variables
	gen sing_coh1=0
	gen sing_mar1=0
	gen coh_mar1=0
	gen coh_diss1=0
	gen marr_diss1=0
	gen marr_wid1=0
	gen marr_coh1=0

	forvalues m=2/48{
		local l				=`m'-1
		
		gen sing_coh`m'	=  marital_status`m'==2 & inlist(marital_status`l',3,4,5)
		gen sing_mar`m'	=  marital_status`m'==1 & inlist(marital_status`l',3,4,5)
		gen coh_mar`m'	=  marital_status`m'==1 & marital_status`l'==2
		gen coh_diss`m'	=  inlist(marital_status`m',3,4,5) & marital_status`l'==2
		gen marr_diss`m'=  marital_status`m'==4 & marital_status`l'==1
		gen marr_wid`m'	=  marital_status`m'==3 & marital_status`l'==1
		gen marr_coh`m'	=  marital_status`m'==2 & marital_status`l'==1
	}

	// browse marital_status2 marital_status3 sing_coh3 sing_mar3 coh_mar3 coh_diss3 marr_diss3 marr_wid3 marr_coh3
	
	// indicators of someone leaving household DURING the year
		gen hh_lose1=0
		gen earn_lose1=0
		gen earn_non1=0
		gen hh_gain1=0
		gen earn_gain1=0
		gen non_earn1=0
		gen resp_earn1=0
		gen resp_non1=0
		gen partner_gain1=0
		gen partner_lose1=0

	forvalues m=2/48{
		local l				=`m'-1
		
		gen hh_lose`m'		=  hhsize`m' < hhsize`l'
		gen earn_lose`m'	=  other_earner`m' < other_earner`l' & hhsize`m' < hhsize`l'
		gen earn_non`m'		=  other_earner`m' < other_earner`l' & hhsize`m' == hhsize`l'
		gen hh_gain`m'		=  hhsize`m' > hhsize`l'
		gen earn_gain`m'	=  other_earner`m' > other_earner`l' & hhsize`m' > hhsize`l'
		gen non_earn`m'		=  other_earner`m' > other_earner`l' & hhsize`m' == hhsize`l'
		gen resp_earn`m'	= earnings`m'!=. & (earnings`l'==. | earnings`l'==0)
		gen resp_non`m'		=  (earnings`m'==. | earnings`m'==0) & earnings`l'!=.
		gen partner_gain`m'	=  spartner`m' > spartner`l'
		gen partner_lose`m'	=  spartner`m' < spartner`l'
	}
	
	// create indicators of job / education changes: respondent
		gen full_part1=0
		gen full_no1=0
		gen part_no1=0
		gen part_full1=0
		gen no_part1=0
		gen no_full1=0
		gen educ_change1=0
		gen enrolled_yes1=0
		gen enrolled_no1=0
		
	forvalues m=2/48{
		local l				=`m'-1
		
		gen full_part`m'	=  ft_pt`m'==2 & ft_pt`l'==1
		gen full_no`m'		=  ft_pt`m'==. & ft_pt`l'==1
		gen part_no`m'		=  ft_pt`m'==. & ft_pt`l'==2
		gen part_full`m'	=  ft_pt`m'==1 & ft_pt`l'==2
		gen no_part`m'		=  ft_pt`m'==2 & ft_pt`l'==.
		gen no_full`m'		=  ft_pt`m'==1 & ft_pt`l'==.
		gen educ_change`m'	=  educ`m'>educ`l' // education only measured annually but I think this will capture if it changes in the first month of the year? which is fine?
		gen enrolled_yes`m'	=  renroll`m'==1 & renroll`l'==2
		gen enrolled_no`m'	=  renroll`m'==2 & renroll`l'==1
	}
	
	// create indicators of job / education changes: partner
		gen full_part_sp1=0
		gen full_no_sp1=0
		gen part_no_sp1=0
		gen part_full_sp1=0
		gen no_part_sp1=0
		gen no_full_sp1=0
		gen educ_change_sp1=0
		
	forvalues m=2/48{
		local l				=`m'-1
		
		gen full_part_sp`m'		=  ft_pt_sp`m'==2 & ft_pt_sp`l'==1
		gen full_no_sp`m'		=  ft_pt_sp`m'==. & ft_pt_sp`l'==1
		gen part_no_sp`m'		=  ft_pt_sp`m'==. & ft_pt_sp`l'==2
		gen part_full_sp`m'		=  ft_pt_sp`m'==1 & ft_pt_sp`l'==2
		gen no_part_sp`m'		=  ft_pt_sp`m'==2 & ft_pt_sp`l'==.
		gen no_full_sp`m'		=  ft_pt_sp`m'==1 & ft_pt_sp`l'==.
		gen educ_change_sp`m'	=  educ_sp`m'>educ_sp`l'
	}
		
// Reshape data back to long format
reshape long `reshape_vars' sing_coh sing_mar coh_mar coh_diss marr_diss marr_wid marr_coh ///
hh_lose earn_lose earn_non hh_gain earn_gain non_earn resp_earn resp_non partner_gain partner_lose ///
full_part full_no part_no part_full no_part no_full educ_change enrolled_yes enrolled_no ///
full_part_sp full_no_sp part_no_sp part_full_sp no_part_sp no_full_sp educ_change_sp, i(SSUID PNUM) j(panelmonth)

save "$tempdir/reshape_transitions.dta", replace


//*Back to original and testing match

use "$SIPP14keep/sipp14tpearn_rel", clear

drop _merge
merge 1:1 SSUID PNUM panelmonth using "$tempdir/reshape_transitions.dta"

tab marital_status _merge, m // all missing
tab educ _merge, m
drop if _merge==2
	
// Create variables with the first and last month of observation by year
   egen startmonth=min(monthcode), by(SSUID PNUM year)
   egen lastmonth =max(monthcode), by(SSUID PNUM year)
   
   * All months have the same number of observations (12) within year
   * so this wasn't necessary.
   order 	SSUID PNUM year startmonth lastmonth
   list 	SSUID PNUM year startmonth lastmonth in 1/5, clean
   sort 	SSUID PNUM year panelmonth

* Prep for counting the total number of months breadwinning for the year. 
* NOTE: This isn't our primary measure.
   gen mbw50=1 if earnings > .5*thearn_alt & !missing(earnings) & !missing(thearn_alt)	// 50% threshold
   gen mbw60=1 if earnings > .6*thearn_alt & !missing(earnings) & !missing(thearn_alt)	// 60% threshold
   
// Create indicator of birth during the year
	drop tcbyr_8-tcbyr_20 // suppressed variables, no observations
	gen birth=1 if (tcbyr_1==year | tcbyr_2==year | tcbyr_3==year | tcbyr_4==year | tcbyr_5==year | tcbyr_6==year | tcbyr_7==year)
	gen first_birth=1 if (yrfirstbirth==year)
	// browse birth year tcbyr*

// Readding partner status variables

	egen statuses = nvals(marital_status),	by(SSUID ERESIDENCEID PNUM year) // first examining how many people have more than 2 statuses in a year (aka changed status more than 1 time)
	// browse SSUID PNUM panelmonth marital_status statuses // if statuses>2
	tab statuses // okay very small percent - will use last status change OR if I do as separate columns, she can get both captured?
	
	replace spouse	=1 	if spouse 	> 1 // one case has 2 spouses
	replace partner	=1 	if partner 	> 1 // 36 cases of 2-3 partners

	// Create a combined spouse & partner indicator
	gen 	spartner=1 	if spouse==1 | partner==1
	replace spartner=0 	if spouse==0 & partner==0
	
	// Create indicators of partner presence at the first and last month of observation by year
	gen 	start_spartner=spartner if monthcode==startmonth
	gen 	last_spartner=spartner 	if monthcode==lastmonth
	gen 	start_spouse=spouse if monthcode==startmonth
	gen 	last_spouse=spouse 	if monthcode==lastmonth
	gen 	start_partner=partner if monthcode==startmonth
	gen 	last_partner=partner 	if monthcode==lastmonth
	
// Create basic indictor to identify months observed when data is collapsed
	gen one=1
	
********************************************************************************
* Create annual measures
********************************************************************************
// Creating variables to facilate the below since a lot of variables share a suffix

foreach var of varlist employ ft_pt ems_ehc rmnumjobs marital_status{ 
    gen st_`var'=`var'
    gen end_`var'=`var'
}

forvalues r=1/22{
gen avg_to_tpearn`r'=to_TPEARN`r' // using the same variable in sum and avg and can't use wildcards in below, so renaming first to use renamed variable for avg
gen avg_to_hrs`r'=to_TMWKHRS`r'
gen avg_to_earn`r'=to_earnings`r'
gen to_mis_TPEARN`r'=to_TPEARN`r'
gen to_mis_earnings`r'=to_earnings`r'
gen to_mis_TMWKHRS`r'=to_TMWKHRS`r'
	foreach var of varlist to_employ`r' to_ft_pt`r' to_EMS`r'{
		gen st_`var'=`var'
		gen end_`var'=`var'
	}
}

// need to retain missings for earnings when annualizing (sum treats missing as 0)

bysort SSUID PNUM year (tpearn): egen tpearn_mis = min(tpearn)
// browse SSUID PNUM year panelmonth tpearn tpearn_mis // can I just do this with min in collapse? if all missing, missing will be min?
bysort SSUID PNUM year (earnings): egen earnings_mis = min(earnings)
bysort SSUID PNUM year (tmwkhrs): egen tmwkhrs_mis = min(tmwkhrs)

// Collapse the data by year to create annual measures
collapse 	(count) monthsobserved=one  nmos_bw50=mbw50 nmos_bw60=mbw60 				/// mother char.
			(sum) 	tpearn thearn thearn_alt tmwkhrs earnings enjflag					///
					sing_coh sing_mar coh_mar coh_diss marr_diss marr_wid marr_coh 		///
					hh_lose earn_lose earn_non hh_gain earn_gain non_earn resp_earn		///
					resp_non partner_gain partner_lose first_birth						///
					full_part full_no part_no part_full no_part no_full educ_change		///
					full_part_sp full_no_sp part_no_sp part_full_sp no_part_sp			///
					no_full_sp educ_change_sp  											///
			(mean) 	spouse partner numtype2 wpfinwgt birth mom_panel hhsize				/// 
					avg_hrs=tmwkhrs avg_earn=earnings  numearner other_earner			///
					thincpovt2 pov_level											///
					tjb*_annsal1 tjb*_hourly1 tjb*_wkly1 tjb*_bwkly1					///
					tjb*_mthly1 tjb*_smthly1 tjb*_other1 tjb*_gamt1						///
			(max) 	minorchildren minorbiochildren preschoolchildren minors_fy			///
					prebiochildren race educ tceb oldest_age ejb*_payhr1 				///
					start_spartner last_spartner start_spouse last_spouse				///
					start_partner last_partner tage ageb1 status_b1 tcbyr_1-tcbyr_7		///
			(min) 	tage_fb durmom youngest_age first_wave								///
					tpearn_mis tmwkhrs_mis earnings_mis									///
					to_mis_TPEARN* to_mis_TMWKHRS* to_mis_earnings*						///
			(max) 	relationship* to_num* to_sex* to_age* to_race* to_educ*				/// other hh members char.
			(sum) 	to_TPEARN* to_TMWKHRS* to_earnings*			 						///
			(mean) 	avg_to_tpearn* avg_to_hrs* avg_to_earn*								///
					to_EJB*_PAYHR1* to_TJB*_ANNSAL1* to_TJB*_HOURLY1* to_TJB*_WKLY1* 	///
					to_TJB*_BWKLY1* to_TJB*_MTHLY1* to_TJB*_SMTHLY1* to_TJB*_OTHER1*	///
					to_TJB*_GAMT1* to_RMNUMJOBS*										///
			(firstnm) st_*																/// will cover all (mother + hh per recodes) 
			(lastnm) end_*,																///
			by(SSUID PNUM year)
			


// Fix Type 2 people identifier
	gen 	anytype2 = (numtype2 > 0)
	drop 	numtype2
	gen 	firstbirth = (first_birth>0)
	drop	first_birth

// Create indicators for partner changes -- note to KM: revisit this, needs more categories (like differentiate spouse v. partner)
	gen 	gain_partner=0 				if !missing(start_spartner) & !missing(last_spartner)
	replace gain_partner=1 				if start_spartner==0 		& last_spartner==1

	gen 	lost_partner=0 				if !missing(start_spartner) & !missing(last_spartner)
	replace lost_partner=1 				if start_spartner==1 		& last_spartner==0
	
	gen		no_status_chg=0
	replace no_status_chg=1 if (sing_coh + sing_mar + coh_mar + coh_diss + marr_diss + marr_wid + marr_coh)==0
	
	gen no_job_chg=0
	replace no_job_chg=1 if (full_part + full_no + part_no + part_full + no_part + no_full)==0
	
	gen no_job_chg_sp=0
	replace no_job_chg_sp=1 if (full_part_sp + full_no_sp + part_no_sp + part_full_sp + no_part_sp + no_full_sp)==0
	
// Create indicator for incomple annual observations
	gen partial_year= (monthsobserved < 12)
	
// update earnings / hours to be missing if missing all 12 months
replace earnings=. if earnings_mis==.
replace tpearn=. if tpearn_mis==.
replace tmwkhrs=. if tmwkhrs_mis==.

forvalues r=1/22{
replace to_TPEARN`r'=. if to_mis_TPEARN`r'==.
replace to_earnings`r'=. if to_mis_earnings`r'==.
replace to_TMWKHRS`r'=. if to_mis_TMWKHRS`r'==.
}

// Create annual breadwinning indicators

	// Create indicator for negative household earnings & no earnings. 
	gen hh_noearnings= (thearn_alt <= 0)
	
	gen earnings_ratio=earnings/thearn_alt if hh_noearnings !=1 

	// 50% breadwinning threshold
	* Note that this measure was missing for no (or negative) earnings households, but that is now changed
	gen 	bw50= (earnings > .5*thearn_alt) 	if hh_noearnings !=1 // if earnings missing, techincally larger than this ratio so was getting a 1 here when I removed the missing restriction above, so need to add below
	replace bw50= 0 					if hh_noearnings==1 | earnings==.

	// 60% breadwinning threshold
	gen 	bw60= (earnings > .6*thearn_alt) 	if hh_noearnings !=1
	replace bw60= 0 					if hh_noearnings==1 | earnings==.
	
gen wave=year-2012
	
save "$SIPP14keep/annual_bw_status.dta", replace
