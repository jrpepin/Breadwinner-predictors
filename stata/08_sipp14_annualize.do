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
* Create descrptive statistics to prep for annualized variables
********************************************************************************
use "$SIPP14keep/sipp14tpearn_rel", clear

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
   gen mbw50=1 if tpearn > .5*thearn & !missing(tpearn) & !missing(thearn)	// 50% threshold
   gen mbw60=1 if tpearn > .6*thearn & !missing(tpearn) & !missing(thearn)	// 60% threshold
   
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
	
	foreach var in sing_coh sing_mar coh_mar coh_diss marr_diss marr_wid marr_coh{
	tab `var'
	}
	
// indicators of someone leaving household DURING the year
	// browse SSUID PNUM panelmonth hhsize numearner other_earner
	
	* Anyone left - hhsize change
	by SSUID PNUM (panelmonth), sort: gen hh_lose = (hhsize<hhsize[_n-1]) & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	* Earner left - other earner left AND hh size change
	by SSUID PNUM (panelmonth), sort: gen earn_lose = (other_earner<other_earner[_n-1]) & (hhsize<hhsize[_n-1]) & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	* Earner became non-earner - other earner down AND hh size stayed the same
	by SSUID PNUM (panelmonth), sort: gen earn_non = (other_earner<other_earner[_n-1]) & (hhsize==hhsize[_n-1]) & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	* Anyone came - hhsize change
	by SSUID PNUM (panelmonth), sort: gen hh_gain = (hhsize>hhsize[_n-1]) & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	* Earner came - other earner came AND hh size change
	by SSUID PNUM (panelmonth), sort: gen earn_gain = (other_earner>other_earner[_n-1]) & (hhsize>hhsize[_n-1]) & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	* Non-earner became earner - other earner up AND hh size stayed the same
	by SSUID PNUM (panelmonth), sort: gen non_earn = (other_earner>other_earner[_n-1]) & (hhsize==hhsize[_n-1]) & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	* Respondent became earner
	by SSUID PNUM (panelmonth), sort: gen resp_earn = (tpearn!=. & tpearn[_n-1]==.) & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	* Respondent became non-earner
	by SSUID PNUM (panelmonth), sort: gen resp_non = (tpearn==. & tpearn[_n-1]!=.) & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	
	// browse SSUID PNUM tpearn panelmonth hhsize numearner other_earner hh_lose earn_lose earn_non hh_gain earn_gain non_earn resp_earn resp_non
	
	
// Create indicator of birth during the year
	drop tcbyr_8-tcbyr_20 // suppressed variables, no observations
	gen birth=1 if (tcbyr_1==year | tcbyr_2==year | tcbyr_3==year | tcbyr_4==year | tcbyr_5==year | tcbyr_6==year | tcbyr_7==year)
	gen first_birth=1 if (yrfirstbirth==year)
	// browse birth year tcbyr*

/* Do we want to record job changes within the year? - currently not, but keeping this here for code reference
	gen w_job_up=0
	replace w_job_up=1 if job < job[_n-1] & !missing(job[_n-1]) & idnum==idnum[_n-1] in 2/-1 
	replace w_job_up=. if job==.
	gen w_job_down=0 
	replace w_job_down=1 if job > job[_n-1] & !missing(job[_n-1]) & idnum==idnum[_n-1] in 2/-1 
	replace w_job_down=. if job==.
	// browse panelmonth idnum job w_job* husband_job h_job* spouse partner - validate
*/ 


// Create basic indictor to identify months observed when data is collapsed
	gen one=1
	
// cleaning up variables to prep for collapse - will remove these from original code later
drop *_bmonth *_emonth *_payhr* *_msum apearn rhpov* *_ind *_annsal* *_hourly* *_wkly* *_bwkly* *_mthly* *_smthly* *_other* *_gamt* ///
tyrcurrmarr tyrfirstmarr tyear_fb thtotinc tftotinc thincpov thincpovt2 pairtype* RREL* to_TAGE_FB*

			// https://www.statalist.org/forums/forum/general-stata-discussion/general/639137-any-collapse-tricks-for-multiple-stats-from-multiple-vars

********************************************************************************
* Create annual measures
********************************************************************************
// Creating variables to facilate the below since a lot of variables share a suffix

foreach var of varlist occ_1-occ_7 employ ft_pt ems_ehc rmnumjobs marital_status{ 
    gen st_`var'=`var'
    gen end_`var'=`var'
}

forvalues r=1/22{
gen avg_to_tpearn`r'=to_TPEARN`r'
gen avg_to_hrs`r'=to_TMWKHRS`r'
gen avg_to_earn`r'=to_earnings`r'
	foreach var of varlist to_occ_1`r'-to_occ_7`r' to_employ`r' to_ft_pt`r' to_EMS`r'{
		gen st_`var'=`var'
		gen end_`var'=`var'
	}
}


// Collapse the data by year to create annual measures
collapse 	(count) monthsobserved=one  nmos_bw50=mbw50 nmos_bw60=mbw60 		/// mother char.
			(sum) 	tpearn thearn tmwkhrs earnings enjflag						///
					sing_coh sing_mar coh_mar coh_diss marr_diss marr_wid		///
					marr_coh first_birth hh_lose earn_lose earn_non hh_gain		///
					earn_gain non_earn resp_earn resp_non						///
			(mean) 	spouse partner numtype2 wpfinwgt birth avg_hrs=tmwkhrs 		/// 
					avg_earn=earnings  numearner other_earner hhsize			///
			(max) 	minorchildren minorbiochildren preschoolchildren 			///
					prebiochildren race educ tceb oldest_age			 		///
					start_spartner last_spartner start_spouse last_spouse		///
					start_partner last_partner tage ageb1 tcbyr_1-tcbyr_7		///
			(min) 	tage_fb durmom youngest_age first_wave						///
			(max) 	relationship* to_num* to_sex* to_age* to_race* to_educ*		/// other hh members char.
			(sum) 	to_TPEARN* to_TMWKHRS* to_earnings*			 				///
			(mean) 	avg_to_tpearn* avg_to_hrs* avg_to_earn*						///
			(firstnm) st_*														/// will cover all (mother + hh per recodes) 
			(lastnm) end_*,														///
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
	
	// have these more specific variables now: sing_coh sing_mar coh_mar coh_diss marr_diss marr_wid marr_coh

// Create indicator for incomple annual observations
	gen partial_year= (monthsobserved < 12)

// Create annual breadwinning indicators

	// Create indicator for negative household earnings & no earnings. 
	gen hh_noearnings= (thearn <= 0)
	
	gen earnings_ratio=tpearn/thearn if hh_noearnings !=1 & !missing(tpearn) 

	// 50% breadwinning threshold
	* Note that this measure was missing for no (or negative) earnings households, but that is now changed
	gen 	bw50= (tpearn > .5*thearn) 	if hh_noearnings !=1 & !missing(tpearn) 
	replace bw50= 0 					if hh_noearnings==1
		/* *?*?* WE DON'T HAVE ANY MISSING TPEARN | THEARN. IS THAT EXPECTED? */
		/* yes. We are now using allocated data. The SIPP 2014 doesn't have codes */
		/* for whether the summary measure includes allocated data */


	// 60% breadwinning threshold
	gen 	bw60= (tpearn > .6*thearn) 	if hh_noearnings !=1 & !missing(tpearn)
	replace bw60= 0 					if hh_noearnings==1
	
gen wave=year-2012
	
save "$SIPP14keep/annual_bw_status.dta", replace
