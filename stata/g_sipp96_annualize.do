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
use "$SIPP14keep/sipp96tpearn_rel.dta", clear

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
	tab statuses
	
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
	by SSUID PNUM (panelmonth), sort: gen resp_earn = (earnings!=. & (earnings[_n-1]==.|earnings[_n-1]==0)) & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	* Respondent became non-earner
	by SSUID PNUM (panelmonth), sort: gen resp_non = ((earnings==. | earnings==0) & earnings[_n-1]!=.) & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	* Gained children under 5
	by SSUID PNUM (panelmonth), sort: gen prekid_gain = (preschoolchildren > preschoolchildren[_n-1]) & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] // check for missing and ensure not messed up, also do I want to specifically track like from 0 to more? as that might be different than say, 1 to 2?
	* Lost children under 5
	by SSUID PNUM (panelmonth), sort: gen prekid_lose = (preschoolchildren < preschoolchildren[_n-1]) & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	* Parents entered (bio and in-law)
	by SSUID PNUM (panelmonth), sort: gen parents_gain = (parents > parents[_n-1]) & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	* Parents left (bio and in-law)
	by SSUID PNUM (panelmonth), sort: gen parents_lose = (parents < parents[_n-1]) & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]	

// browse SSUID PNUM tpearn panelmonth hhsize numearner other_earner hh_lose earn_lose earn_non hh_gain earn_gain non_earn resp_earn resp_non	
	
// Create indicator of birth during the year  -- because fertility module is only in wave 2, aka 1996, we can't really get a robust measure of this. we also only get first and last month of birth, nothing in between.
	gen birth=1 if (yrfirstbirth==year | yrlastbirth==year)
	gen first_birth=1 if (yrfirstbirth==year)
	
// create indicators of job changes
**Respondent
	// Employment Status
	* Full-Time to Part-Time
	by SSUID PNUM (panelmonth), sort: gen full_part = (eptwrk==1 & eptwrk[_n-1]==2)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	* Full-Time to No Job
	by SSUID PNUM (panelmonth), sort: gen full_no = (eptwrk==. & eptwrk[_n-1]==2)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	* Part-Time to No Job
	by SSUID PNUM (panelmonth), sort: gen part_no = (eptwrk==. & eptwrk[_n-1]==1)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	* Part-Time to Full-Time
	by SSUID PNUM (panelmonth), sort: gen part_full = (eptwrk==2 & eptwrk[_n-1]==1)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	* No Job to Part-Time
	by SSUID PNUM (panelmonth), sort: gen no_part = (eptwrk==1 & eptwrk[_n-1]==.)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	* No Job to Full-Time
	by SSUID PNUM (panelmonth), sort: gen no_full = (eptwrk==2 & eptwrk[_n-1]==.)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	
	* Employer Change (currently using ANY out of a possible 7 jobs - can update to be first job or top job if needed)
	* Recoded in file 07 - variable is jobchange
	gen jobchange=0
	replace jobchange =1 if jobchange_1==1 | jobchange_2==1
	
	* "Better Job" (see recode in file 06 - based on reasons left job)
	by SSUID PNUM (panelmonth), sort: gen betterjob = (better_job==1 & better_job[_n-1]==0)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	
	* Left job for pregnancy / childbirth. Don't 100% know which it was, but will code it for now anyway
	by SSUID PNUM (panelmonth), sort: gen left_preg = (ersnowrk==5 & ersnowrk[_n-1]!=5)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & ersnowrk != -1 & ersnowrk[_n-1] != -1

	// Number of Jobs // also going to test on an annual average, did # of job changes, this is monthly
	* 1 to More than 1 (as I feel like this is a bigger deal than going from 2 to 3, say)
	by SSUID PNUM (panelmonth), sort: gen many_jobs = (inrange(ejobcntr,2,7) & ejobcntr[_n-1]==1)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	* More than 1 to 1
	by SSUID PNUM (panelmonth), sort: gen one_job = (ejobcntr==1 & inrange(ejobcntr[_n-1],2,7))  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	* Any # job change up
	by SSUID PNUM (panelmonth), sort: gen num_jobs_up = (ejobcntr > ejobcntr[_n-1])  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & ejobcntr != -1 & ejobcntr[_n-1] != -1
	* Any # job change down
	by SSUID PNUM (panelmonth), sort: gen num_jobs_down = (ejobcntr < ejobcntr[_n-1])  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & ejobcntr != -1 & ejobcntr[_n-1] != -1

	// Welfare Use
	by SSUID PNUM (panelmonth), sort: gen welfare_in = (programs>0 & programs[_n-1]==0)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	by SSUID PNUM (panelmonth), sort: gen welfare_out = (programs==0 & programs[_n-1]>0)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	by SSUID PNUM (panelmonth), sort: gen benefits_in = (benefits>0 & benefits[_n-1]==0)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	by SSUID PNUM (panelmonth), sort: gen benefits_out = (benefits==0 & benefits[_n-1]>0)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	
/*
// Disability status - testing all three specifications for now; will pick one. efindjob and esdisabl more about work, while dis_alt is broader disability
	by SSUID PNUM (panelmonth), sort: gen efindjob_in= (efindjob==1 & efindjob[_n-1]==0)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	by SSUID PNUM (panelmonth), sort: gen efindjob_out = (efindjob==0 & efindjob[_n-1]==1)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	by SSUID PNUM (panelmonth), sort: gen edisabl_in = (edisabl==1 & edisabl[_n-1]==0)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	by SSUID PNUM (panelmonth), sort: gen edisabl_out = (edisabl==0 & edisabl[_n-1]==1)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	by SSUID PNUM (panelmonth), sort: gen rdis_alt_in = (rdis_alt==1 & rdis_alt[_n-1]==0)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	by SSUID PNUM (panelmonth), sort: gen rdis_alt_out = (rdis_alt==0 & rdis_alt[_n-1]==1)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 

// East of finding child-care. Not 100% sure these capture our sentiment, but testing for now
	by SSUID PNUM (panelmonth), sort: gen ch_workmore_yes = (eworkmore==1 & eworkmore[_n-1]==0)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	by SSUID PNUM (panelmonth), sort: gen ch_workmore_no = (eworkmore==0 & eworkmore[_n-1]==1)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	by SSUID PNUM (panelmonth), sort: gen childasst_yes = (echld_mnyn==1 & echld_mnyn[_n-1]==0)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	by SSUID PNUM (panelmonth), sort: gen childasst_no = (echld_mnyn==0 & echld_mnyn[_n-1]==1)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	by SSUID PNUM (panelmonth), sort: gen ch_waitlist_yes = (elist==1 & elist[_n-1]==0)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	by SSUID PNUM (panelmonth), sort: gen ch_waitlist_no = (elist==0 & elist[_n-1]==1)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 

// Respondent moved
	// can I see if eresidence ID changed? play around with this more browse SSUID PNUM panelmonth ERESIDENCEID hh_move move_relat move_indep
	by SSUID PNUM (panelmonth), sort: gen move_relat = (hh_move==1 & inrange(hh_move[_n-1],2,4)) & ERESIDENCEID != ERESIDENCEID[_n-1]  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	by SSUID PNUM (panelmonth), sort: gen move_indep = (hh_move==2 & inlist(hh_move[_n-1],1,3,4)) & ERESIDENCEID != ERESIDENCEID[_n-1]  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 

// Education - how often can education change?
	// highest educational attainment only measured yearly, so will test yearly educational changes, as well as school enrollment. testing monthly, but will also add to annualize file
	by SSUID PNUM (panelmonth), sort: gen educ_change = (educ>educ[_n-12])  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] // make sure this creates the 0s I want, for people who didn't get more education
	by SSUID PNUM (panelmonth), sort: gen enrolled_yes = (renroll==1 & renroll[_n-1]==2)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	by SSUID PNUM (panelmonth), sort: gen enrolled_no = (renroll==2 & renroll[_n-1]==1)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 

*/

**Partner
	* first get partner specific variables
	gen spousenum=.
	forvalues n=1/17{
	replace spousenum=`n' if relationship`n'==1
	}

	gen partnernum=.
	forvalues n=1/17{
	replace partnernum=`n' if relationship`n'==2
	}

	gen spart_num=spousenum
	replace spart_num=partnernum if spart_num==.

	gen eptwrk_sp=.
	gen jobchange1_sp=.
	gen jobchange2_sp=.
	gen better_job_sp=.
	gen ejobcntr_sp=.
	gen ejbhrs1_sp=.
	gen ejbhrs2_sp=.

	forvalues n=1/17{
	replace eptwrk_sp=to_eptwrk`n' if spart_num==`n'
	replace jobchange1_sp=to_jobchange_1`n' if spart_num==`n'
	replace jobchange1_sp=to_jobchange_2`n' if spart_num==`n'
	replace better_job_sp=to_better_job`n' if spart_num==`n'
	replace ejobcntr_sp=to_ejobcntr`n' if spart_num==`n'
	replace ejbhrs1_sp=to_ejbhrs1`n' if spart_num==`n'
	replace ejbhrs2_sp=to_ejbhrs2`n' if spart_num==`n'
	}

	* Full-Time to Part-Time
	by SSUID PNUM (panelmonth), sort: gen full_part_sp = (eptwrk_sp==1 & eptwrk_sp[_n-1]==2) & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	* Full-Time to No Job
	by SSUID PNUM (panelmonth), sort: gen full_no_sp = (eptwrk_sp==. & eptwrk_sp[_n-1]==2) & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	* Part-Time to No Job
	by SSUID PNUM (panelmonth), sort: gen part_no_sp = (eptwrk_sp==. & eptwrk_sp[_n-1]==1)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	* Part-Time to Full-Time
	by SSUID PNUM (panelmonth), sort: gen part_full_sp = (eptwrk_sp==2 & eptwrk_sp[_n-1]==1)   & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	* No Job to Part-Time
	by SSUID PNUM (panelmonth), sort: gen no_part_sp = (eptwrk_sp==1 & eptwrk_sp[_n-1]==.) & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	* No Job to Full-Time
	by SSUID PNUM (panelmonth), sort: gen no_full_sp = (eptwrk_sp==2 & eptwrk_sp[_n-1]==.)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	
	* Average hours recode
	replace ejbhrs1_sp=. if ejbhrs1_sp==-1
	replace ejbhrs2_sp=. if ejbhrs2_sp==-1
	egen avg_mo_hrs_sp=rowmean(ejbhrs1_sp ejbhrs2_sp)
	
	* Employer Change (currently using ANY out of a possible 7 jobs - can update to be first job or top job if needed)
	gen jobchange_sp=0
	replace jobchange_sp =1 if jobchange1_sp==1 | jobchange2_sp==1
	
	
	* "Better Job" (see recode in file 06 - based on reasons left job)
	by SSUID PNUM (panelmonth), sort: gen betterjob_sp = (better_job_sp==1 & better_job_sp[_n-1]==0)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 

	// Number of Jobs // also going to test on an annual average, did # of job changes, this is monthly
	* 1 to More than 1 (as I feel like this is a bigger deal than going from 2 to 3, say)
	by SSUID PNUM (panelmonth), sort: gen many_jobs_sp = (inrange(ejobcntr_sp,2,7) & ejobcntr_sp[_n-1]==1)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	* More than 1 to 1
	by SSUID PNUM (panelmonth), sort: gen one_job_sp = (ejobcntr_sp==1 & inrange(ejobcntr_sp[_n-1],2,7))  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	* Any # job change up 
	by SSUID PNUM (panelmonth), sort: gen num_jobs_up_sp = (ejobcntr_sp > ejobcntr_sp[_n-1])  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & ejobcntr_sp != -1 & ejobcntr_sp[_n-1] != -1
	* Any # job change down
	by SSUID PNUM (panelmonth), sort: gen num_jobs_down_sp = (ejobcntr_sp < ejobcntr_sp[_n-1])   & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & ejobcntr_sp != -1 & ejobcntr_sp[_n-1] != -1

/*	
// Disability status - testing all three specifications for now; will pick one. efindjob and esdisabl more about work, while dis_alt is broader disability
	by SSUID PNUM (panelmonth), sort: gen efindjob_in_sp= (efindjob_sp==1 & efindjob_sp[_n-1]==0)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	by SSUID PNUM (panelmonth), sort: gen efindjob_out_sp = (efindjob_sp==0 & efindjob_sp[_n-1]==1)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	by SSUID PNUM (panelmonth), sort: gen edisabl_in_sp = (edisabl_sp==1 & edisabl_sp[_n-1]==0)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	by SSUID PNUM (panelmonth), sort: gen edisabl_out_sp = (edisabl_sp==0 & edisabl_sp[_n-1]==1)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	by SSUID PNUM (panelmonth), sort: gen rdis_alt_in_sp = (rdis_alt_sp==1 & rdis_alt_sp[_n-1]==0)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	by SSUID PNUM (panelmonth), sort: gen rdis_alt_out_sp = (rdis_alt_sp==0 & rdis_alt_sp[_n-1]==1)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 

// Education
	// highest educational attainment only measured yearly, so will test yearly educational changes, as well as school enrollment. testing monthly, but will also add to annualize file
	by SSUID PNUM (panelmonth), sort: gen educ_change_sp = (educ_sp > educ_sp[_n-12])  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] // make sure this creates the 0s I want, for people who didn't get more education
	by SSUID PNUM (panelmonth), sort: gen enrolled_yes_sp = (renroll_sp==1 & renroll_sp[_n-1]==2)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	by SSUID PNUM (panelmonth), sort: gen enrolled_no_sp = (renroll_sp==2 & renroll_sp[_n-1]==1)  & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
*/
	
// Create basic indictor to identify months observed when data is collapsed
	gen one=1
	
********************************************************************************
* Create annual measures
********************************************************************************
// Creating variables to facilate the below since a lot of variables share a suffix

foreach var of varlist employ eptwrk ems ejobcntr marital_status{ 
    gen st_`var'=`var'
    gen end_`var'=`var'
}

forvalues r=1/17{
gen avg_to_tpearn`r'=to_tpearn`r' // using the same variable in sum and avg and can't use wildcards in below, so renaming first to use renamed variable for avg
gen avg_to_earn`r'=to_earnings`r'
gen to_mis_tpearn`r'=to_tpearn`r'
gen to_mis_earnings`r'=to_earnings`r'
	foreach var of varlist to_employ`r' to_eptwrk`r' to_ems`r'{
		gen st_`var'=`var'
		gen end_`var'=`var'
	}
}

// need to retain missings for earnings when annualizing (sum treats missing as 0) - currently with msum1, 0 means either none or not in universe, so will use hours to deduce if it should be missing or 0 (because for hours, 0 was just not in universe)

replace tpearn = . if avg_mo_hrs ==.
replace earnings= . if avg_mo_hrs ==.

bysort SSUID PNUM year (tpearn): egen tpearn_mis = min(tpearn)
bysort SSUID PNUM year (earnings): egen earnings_mis = min(earnings)

// Collapse the data by year to create annual measures
collapse 	(count) monthsobserved=one  nmos_bw50=mbw50 nmos_bw60=mbw60 								/// mother char.
			(sum) 	tpearn thearn thearn_alt total_hrs=avg_mo_hrs total_hrs_sp = avg_mo_hrs_sp earnings ///
					eawop sing_coh sing_mar coh_mar coh_diss marr_diss marr_wid marr_coh				///
					hh_lose earn_lose earn_non hh_gain earn_gain non_earn resp_earn resp_non 			///
					prekid_gain prekid_lose parents_gain parents_lose first_birth						///
					full_part full_no part_no part_full no_part no_full jobchange						///
					betterjob left_preg many_jobs one_job num_jobs_up num_jobs_down						///
					full_part_sp full_no_sp part_no_sp part_full_sp no_part_sp							///
					no_full_sp betterjob_sp many_jobs_sp one_job_sp num_jobs_up_sp 						///
					num_jobs_down_sp jobchange_sp 														///
			(mean) 	spouse partner wpfinwgt birth mom_panel hhsize										///
					avg_mo_hrs avg_mo_hrs_sp avg_earn=earnings numearner other_earner					///
					tpyrate1	tpyrate2 avg_wk_rate thpov												/// 		
			(max) 	minorchildren minorbiochildren preschoolchildren prebiochildren oldest_age			///
					race educ tmomchl tage ageb1 ageb1_mon yrfirstbirth yrlastbirth status_b1 minors_fy ///
					start_spartner last_spartner start_spouse last_spouse start_partner last_partner	///
			(min) 	durmom durmom_1st emomlivh youngest_age first_wave									///
					tpearn_mis earnings_mis to_mis_tpearn* to_mis_earnings*								/// put emomlivh as min, bc min=yes and if at SOME PT in year, all kids at home, want here
			(max) 	relationship* to_num* to_sex* to_age* to_race* to_educ*								/// other hh members char.
			(sum) 	to_tpearn* to_ejbhrs1* to_ejbhrs2* to_earnings*			 							///
			(mean) 	avg_to_tpearn* avg_to_earn*	to_epayhr1* to_epayhr2*									///
					to_tpyrate1* to_tpyrate2* to_ejobcntr*	to_avg_wk_rate*								///
			(firstnm) st_*																				/// will cover all (mother + hh per recodes) 
			(lastnm) end_*,																				///
			by(SSUID PNUM year)

		
			
// Fix identifiers greater than 1
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

forvalues r=1/17{
replace to_tpearn`r'=. if to_mis_tpearn`r'==.
replace to_earnings`r'=. if to_mis_earnings`r'==.
}


// Create annual breadwinning indicators

	// Create indicator for negative household earnings & no earnings. 
	gen hh_noearnings= (thearn_alt <= 0)
	
	gen earnings_ratio=earnings/thearn_alt if hh_noearnings !=1 & !missing(earnings) 

	// 50% breadwinning threshold
	* Note that this measure was missing for no (or negative) earnings households, but that is now changed
	gen 	bw50= (earnings > .5*thearn_alt) 	if hh_noearnings !=1 & !missing(earnings) 
	replace bw50= 0 					if hh_noearnings==1

	// 60% breadwinning threshold
	gen 	bw60= (earnings > .6*thearn_alt) 	if hh_noearnings !=1 & !missing(earnings)
	replace bw60= 0 					if hh_noearnings==1
	
	/*
	// 60% breadwinning threshold - old, uses potential negative earnings for tpearn. more different for 1996 than 2014
	gen 	bw60_alt= (tpearn > .6*thearn) 	if hh_noearnings !=1 & !missing(tpearn)
	replace bw60_alt= 0 					if hh_noearnings==1
	*/
	
save "$SIPP14keep/sipp96_annual_bw_status.dta", replace
