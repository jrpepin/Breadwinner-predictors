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

//browse SSUID PNUM year panelmonth if inlist(SSUID, "000418500162", "000418209903", "000418334944")

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
   
// Create indicators of transitions into marriage/cohabitation or out of marriage/cohabitation

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
	
	// getting ready to create indicators of various status changes THROUGHOUT the year
	* Single -> Cohabit 
	by SSUID PNUM (panelmonth), sort: gen sing_coh = (marital_status==2 & inlist(marital_status[_n-1],3,4,5)) & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] // including divorced / widowed plus unpartnered here as single, does that make sense? with this method, any changes from december to janary will be captured in the january year. to avoid that, add year to by.
	// browse SSUID PNUM panelmonth marital_status statuses sing_coh if statuses==2 - validate this first one
	* Single -> Married
	by SSUID PNUM (panelmonth), sort: gen sing_mar = (marital_status==1 & inlist(marital_status[_n-1],3,4,5)) & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] // including divorced / widowed plus unpartnered here as single, does that make sense?
	* Cohab -> Married
	by SSUID PNUM (panelmonth), sort: gen coh_mar = (marital_status==1 & marital_status[_n-1]==2) & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	* Cohab -> Single
	by SSUID PNUM (panelmonth), sort: gen coh_diss = (inlist(marital_status,3,4,5) & marital_status[_n-1]==2) & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	* Marry -> Dissolve
	by SSUID PNUM (panelmonth), sort: gen marr_diss = (marital_status==4 & marital_status[_n-1]==1)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	* Marry -> Widow
	by SSUID PNUM (panelmonth), sort: gen marr_wid = (marital_status==3 & marital_status[_n-1]==1)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	* Marry -> Cohabit
	by SSUID PNUM (panelmonth), sort: gen marr_coh = (marital_status==2 & marital_status[_n-1]==1)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	
// indicators of someone leaving household DURING the year -- revisit this. am I capturing mother at all, or ALL OTHERS?
	// browse SSUID PNUM panelmonth hhsize numearner other_earner
	
	* Anyone left - hhsize change
	by SSUID PNUM (panelmonth), sort: gen hh_lose = (hhsize < hhsize[_n-1]) & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	* Earner left - other earner left AND hh size change
	by SSUID PNUM (panelmonth), sort: gen earn_lose = (other_earner < other_earner[_n-1]) & (hhsize < hhsize[_n-1]) & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	* Earner became non-earner - other earner down AND hh size stayed the same
	by SSUID PNUM (panelmonth), sort: gen earn_non = (other_earner < other_earner[_n-1]) & (hhsize==hhsize[_n-1]) & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	* Anyone came - hhsize change
	by SSUID PNUM (panelmonth), sort: gen hh_gain = (hhsize > hhsize[_n-1]) & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	* Earner came - other earner came AND hh size change
	by SSUID PNUM (panelmonth), sort: gen earn_gain = (other_earner > other_earner[_n-1]) & (hhsize > hhsize[_n-1]) & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	* Non-earner became earner - other earner up AND hh size stayed the same
	by SSUID PNUM (panelmonth), sort: gen non_earn = (other_earner > other_earner[_n-1]) & (hhsize==hhsize[_n-1]) & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	* Respondent became earner
	by SSUID PNUM (panelmonth), sort: gen resp_earn = (earnings!=. & (earnings[_n-1]==. | earnings[_n-1]==0)) & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	* Respondent became non-earner
	by SSUID PNUM (panelmonth), sort: gen resp_non = ((earnings==. | earnings==0) & earnings[_n-1]!=.) & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	* Gained partner // validate with above status measures
	by SSUID PNUM (panelmonth), sort: gen partner_gain = (spartner > spartner[_n-1]) & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	* Lost partner // validate with above status measures
	by SSUID PNUM (panelmonth), sort: gen partner_lose = (spartner < spartner[_n-1]) & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]	
		
// Create indicator of birth during the year
	drop tcbyr_8-tcbyr_20 // suppressed variables, no observations
	gen birth=1 if (tcbyr_1==year | tcbyr_2==year | tcbyr_3==year | tcbyr_4==year | tcbyr_5==year | tcbyr_6==year | tcbyr_7==year)
	gen first_birth=1 if (yrfirstbirth==year)
	// browse birth year tcbyr*
	
// create indicators of job changes
**Respondent
	// Employment Status
	* Full-Time to Part-Time
	by SSUID PNUM (panelmonth), sort: gen full_part = (ft_pt==2 & ft_pt[_n-1]==1)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] // this is based on a recode of number of hours worked per week. I am not sure if there is a better way to get this. that is what the sipp uses to ask why a respondent works less than 35 hours
	* Full-Time to No Job
	by SSUID PNUM (panelmonth), sort: gen full_no = (ft_pt==. & ft_pt[_n-1]==1)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	* Part-Time to No Job
	by SSUID PNUM (panelmonth), sort: gen part_no = (ft_pt==. & ft_pt[_n-1]==2)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	* Part-Time to Full-Time
	by SSUID PNUM (panelmonth), sort: gen part_full = (ft_pt==1 & ft_pt[_n-1]==2)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	* No Job to Part-Time
	by SSUID PNUM (panelmonth), sort: gen no_part = (ft_pt==2 & ft_pt[_n-1]==.)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	* No Job to Full-Time
	by SSUID PNUM (panelmonth), sort: gen no_full = (ft_pt==1 & ft_pt[_n-1]==.)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	
// Education
	// highest educational attainment only measured yearly, so will test yearly educational changes, as well as school enrollment. testing monthly, but will also add to annualize file
	by SSUID PNUM (panelmonth), sort: gen educ_change = (educ>educ[_n-12])  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] // make sure this creates the 0s I want, for people who didn't get more education
	by SSUID PNUM (panelmonth), sort: gen enrolled_yes = (renroll==1 & renroll[_n-1]==2)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	by SSUID PNUM (panelmonth), sort: gen enrolled_no = (renroll==2 & renroll[_n-1]==1)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 

**Partner
	* first get partner specific variables
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

	* Full-Time to Part-Time
	by SSUID PNUM (panelmonth), sort: gen full_part_sp = (ft_pt_sp==2 & ft_pt_sp[_n-1]==1)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] // this is based on a recode of number of hours worked per week. I am not sure if there is a better way to get this. that is what the sipp uses to ask why a respondent works less than 35 hours
	* Full-Time to No Job
	by SSUID PNUM (panelmonth), sort: gen full_no_sp = (ft_pt_sp==. & ft_pt_sp[_n-1]==1)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	* Part-Time to No Job
	by SSUID PNUM (panelmonth), sort: gen part_no_sp = (ft_pt_sp==. & ft_pt_sp[_n-1]==2)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	* Part-Time to Full-Time
	by SSUID PNUM (panelmonth), sort: gen part_full_sp = (ft_pt_sp==1 & ft_pt_sp[_n-1]==2)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	* No Job to Part-Time
	by SSUID PNUM (panelmonth), sort: gen no_part_sp = (ft_pt_sp==2 & ft_pt_sp[_n-1]==.)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	* No Job to Full-Time
	by SSUID PNUM (panelmonth), sort: gen no_full_sp = (ft_pt_sp==1 & ft_pt_sp[_n-1]==.)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	
// Education
	// highest educational attainment only measured yearly, so will test yearly educational changes, as well as school enrollment. testing monthly, but will also add to annualize file
	by SSUID PNUM (panelmonth), sort: gen educ_change_sp = (educ_sp > educ_sp[_n-12])  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] // make sure this creates the 0s I want, for people who didn't get more education

	
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
