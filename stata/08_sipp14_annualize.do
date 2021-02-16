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
	by SSUID PNUM (panelmonth), sort: gen resp_earn = (tpearn!=. & tpearn[_n-1]==.) & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	* Respondent became non-earner
	by SSUID PNUM (panelmonth), sort: gen resp_non = (tpearn==. & tpearn[_n-1]!=.) & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	* Gained children under 5
	by SSUID PNUM (panelmonth), sort: gen prekid_gain = (preschoolchildren > preschoolchildren[_n-1]) & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] // check for missing and ensure not messed up, also do I want to specifically track like from 0 to more? as that might be different than say, 1 to 2?
	* Lost children under 5
	by SSUID PNUM (panelmonth), sort: gen prekid_lose = (preschoolchildren < preschoolchildren[_n-1]) & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	* Parents entered (bio and in-law)
	by SSUID PNUM (panelmonth), sort: gen prekid_gain = (parents > parents[_n-1]) & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	* Parents left (bio and in-law)
	by SSUID PNUM (panelmonth), sort: gen prekid_lose = (parents < parents[_n-1]) & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]	


// browse SSUID PNUM tpearn panelmonth hhsize numearner other_earner hh_lose earn_lose earn_non hh_gain earn_gain non_earn resp_earn resp_non	
	
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
	
	* Employer Change (currently using ANY out of a possible 7 jobs - can update to be first job or top job if needed)
	* Recoded in file 07 - variable is jobchange
	
	* "Better Job" (see recode in file 06 - based on reasons left job)
	by SSUID PNUM (panelmonth), sort: gen betterjob = (better_job==1 & better_job[_n-1]==0)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 

	* Left job for pregnancy / childbirth. Don't 100% know which it was, but will code it for now anyway
	by SSUID PNUM (panelmonth), sort: gen left_preg = (enj_nowrk5==1 & enj_nowrk5[_n-1]==0)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 

	// Number of Jobs // also going to test on an annual average, did # of job changes, this is monthly
	* 1 to More than 1 (as I feel like this is a bigger deal than going from 2 to 3, say)
	by SSUID PNUM (panelmonth), sort: gen many_jobs = ((inrange,rmnumjobs,2,7) & rmnumjobs[_n-1]==1)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	* More than 1 to 1
	by SSUID PNUM (panelmonth), sort: gen one_job = (rmnumjobs==1 & (inrange,rmnumjobs[_n-1],2,7))  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	* Any # job change up
	by SSUID PNUM (panelmonth), sort: gen num_jobs_up = (rmnumjobs > rmnumjobs[_n-1])  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]  // confirm if any missing here, this doesn't mess up the greater / less than
	* Any # job change down
	by SSUID PNUM (panelmonth), sort: gen num_jobs_down = (rmnumjobs < rmnumjobs[_n-1])  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]

// Disability status - testing all three specifications for now; will pick one. efindjob and esdisabl more about work, while dis_alt is broader disability
	by SSUID PNUM (panelmonth), sort: gen efindjob_in= (efindjob==1 & efindjob[_n-1]==0)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	by SSUID PNUM (panelmonth), sort: gen efindjob_out = (efindjob==0 & efindjob[_n-1]==1)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	by SSUID PNUM (panelmonth), sort: gen edisabl_in = (edisabl==1 & edisabl[_n-1]==0)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	by SSUID PNUM (panelmonth), sort: gen edisabl_out = (edisabl==0 & edisabl[_n-1]==1)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	by SSUID PNUM (panelmonth), sort: gen rdis_alt_in = (rdis_alt==1 & rdis_alt[_n-1]==0)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	by SSUID PNUM (panelmonth), sort: gen rdis_alt_out = (rdis_alt==0 & rdis_alt[_n-1]==1)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 

// Welfare Use
	by SSUID PNUM (panelmonth), sort: gen welfare_in = (programs>0 & programs[_n-1]==0)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]  // confirm that missing won't mess up the greater than
	by SSUID PNUM (panelmonth), sort: gen welfare_out = (programs==0 & programs[_n-1]>0)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 

// East of finding child-care. Not 100% sure these capture our sentiment, but testing for now
	by SSUID PNUM (panelmonth), sort: gen ch_workmore_yes = (eworkmore==1 & eworkmore[_n-1]==0)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	by SSUID PNUM (panelmonth), sort: gen ch_workmore_no = (eworkmore==0 & eworkmore[_n-1]==1)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	by SSUID PNUM (panelmonth), sort: gen childasst_yes = (echld_mnyn==1 & echld_mnyn[_n-1]==0)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	by SSUID PNUM (panelmonth), sort: gen childasst_no = (echld_mnyn==0 & echld_mnyn[_n-1]==1)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	by SSUID PNUM (panelmonth), sort: gen ch_waitlist_yes = (elist==1 & elist[_n-1]==0)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	by SSUID PNUM (panelmonth), sort: gen ch_waitlist_no = (elist==0 & elist[_n-1]==1)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 

// Respondent moved
	// can I see if eresidence ID changed? play around with this more
	by SSUID PNUM (panelmonth), sort: gen move_relat = (hh_move==1 & hh_move[_n-1]==4)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] // see if this works the way I want. can they go from like other to 2? assuming right now, it's did not move, to moved for specific reason
	by SSUID PNUM (panelmonth), sort: gen move_indep = (hh_move==2 & hh_move[_n-1]==4)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 

// Education
	// highest educational attainment only measured yearly, so will test yearly educational changes, as well as school enrollment. testing monthly, but will also add to annualize file
	by SSUID PNUM (panelmonth), sort: gen educ_change = (educ>educ[_n-12])  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] // make sure this creates the 0s I want, for people who didn't get more education
	by SSUID PNUM (panelmonth), sort: gen enrolled_yes = (renroll==1 & renroll[_n-1]==0)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	by SSUID PNUM (panelmonth), sort: gen enrolled_no = (renroll==0 & renroll[_n-1]==1)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 

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
	gen jobchange_sp=.

	forvalues n=1/22{
	replace ft_pt_sp=to_ft_pt`n' if spart_num==`n'
	replace jobchange_sp=to_jobchange`n' if spart_num==`n'
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
	
	* Employer Change (currently using ANY out of a possible 7 jobs - can update to be first job or top job if needed)
	* Recoded above - variable is jobchange_sp
	
// Create basic indictor to identify months observed when data is collapsed
	gen one=1
	
// cleaning up variables to prep for collapse - will remove these from original code later
drop *_bmonth *_emonth *_payhr* *_msum apearn rhpov* *_ind *_annsal* *_hourly* *_wkly* *_bwkly* *_mthly* *_smthly* *_other* *_gamt* ///
tyrcurrmarr tyrfirstmarr tyear_fb thtotinc tftotinc pairtype* RREL* to_TAGE_FB*

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
gen avg_to_tpearn`r'=to_TPEARN`r' // using the same variable in sum and avg and can't use wildcards in below, so renaming first to use renamed variable for avg
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
					jobchange full_part full_no part_no part_full no_part		///
					no_full jobchange_sp full_part_sp full_no_sp				///
					part_no_sp part_full_sp no_part_sp no_full_sp				///
			(mean) 	spouse partner numtype2 wpfinwgt birth mom_panel hhsize		/// 
					avg_hrs=tmwkhrs avg_earn=earnings  numearner other_earner	///
					thincpovt2 pov_level 										///
			(max) 	minorchildren minorbiochildren preschoolchildren 			///
					prebiochildren race educ tceb oldest_age			 		///
					start_spartner last_spartner start_spouse last_spouse		///
					start_partner last_partner tage ageb1 tcbyr_1-tcbyr_7		///
			(min) 	tage_fb durmom youngest_age first_wave						///
			(max) 	relationship* to_num* to_sex* to_age* to_race* to_educ*		/// other hh members char.
			(sum) 	to_TPEARN* to_TMWKHRS* to_earnings*			 				///
			(mean) 	avg_to_tpearn* avg_to_hrs* avg_to_earn*	to_pov_level*		///
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
	
	gen no_job_chg=0
	replace no_job_chg=1 if (full_part + full_no + part_no + part_full + no_part + no_full)==0
	
	gen no_job_chg_sp=0
	replace no_job_chg_sp=1 if (full_part_sp + full_no_sp + part_no_sp + part_full_sp + no_part_sp + no_full_sp)==0
	
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
