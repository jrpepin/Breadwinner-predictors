*-------------------------------------------------------------------------------
* BREADWINNER PROJECT
* variable recodes.do
* Kelly Raley and Joanna Pepin
*-------------------------------------------------------------------------------
di "$S_DATE"

********************************************************************************
* DESCRIPTION
********************************************************************************
* This script recodes variables to simplify data for use in identifying
* Respondent, Partner's, and other in HH'S characteristics

********************************************************************************
* Create variables for Type 1 people
********************************************************************************
// Load the data
use "$SIPP14keep/allmonths14.dta", clear


// variables needed. Dropping extra variables as I go to keep things tidy

* age of youngest child: needs to vary with time across the household, will compute once relationships updated. for any given month, identify all children in household, use TAGE and get min TAGE (file 04)

* # of preschool age children: will update this in future code with other HH compositon calculations (file 04)

* race/ ethnicity: combo of ERACE and EORIGIN
gen race=.
replace race=1 if ERACE==1 & EORIGIN==2
replace race=2 if ERACE==2 & EORIGIN==2
replace race=3 if ERACE==3 & EORIGIN==2
replace race=4 if EORIGIN==1
replace race=5 if ERACE==4 & EORIGIN==2

label define race 1 "NH White" 2 "NH Black" 3 "NH Asian" 4 "Hispanic" 5 "Other"
label values race race

drop ERACE EORIGIN

* age at 1st birth: this exists as TAGE_FB

* marital status at 1st birth: not 100% sure. TYEAR_FB is year of first birth. we also have first and current marriage year. HOWEVER, if divorced, do not have that information. Would need to merge with SSA supplement

* educational attainment: use EEDUC
recode EEDUC (31/38=1)(39=2)(40/42=3)(43=4)(44/46=5), gen(educ)
label define educ 1 "Less than HS" 2 "HS Diploma" 3 "Some College" 4 "College Degree" 5 "Advanced Degree"
label values educ educ

drop EEDUC

* subsequent birth: can use TCBYR* to get year of each birth, so will get a flag if that occurs during survey waves.

* partner status: can use ems for marriage. for cohabiting unions, need to use relationship codes. will recode this in a later step (may already happen in step 4)
	* need to code as like year status, did they lose a partner at all, add one, in that year - need to think about this more

* employment change: use rmesr? but this is the question around like # of jobs - RMESR is OVERALL employment status, but then could have went from 2 jobs to 1 job and still be "employed" - do we care about that?! also put with hours to get FT / PT?
	* also use ENJFLAG - says if no-job or not

recode RMESR (1=1) (2/5=2) (6/7=3) (8=4), gen(employ)
label define employ 1 "Full Time" 2 "Part Time" 3 "Not Working - Looking" 4 "Not Working - Not Looking" // this is probably oversimplified at the moment
label values employ employ

drop RMESR

label define jobchange 0 "No" 1 "Yes"
forvalues job=1/7{
	recode AJB`job'_RSEND (0=0) (1/10=1), gen(jobchange_`job')
	label values jobchange_`job' jobchange
	drop AJB`job'_RSEND
}

// check how AJB_RSEND and missings for that work - is that sufficient to get job change?

* earnings change: tpearn seems to cover all jobs in month. need to decide if we want OVERALL change in earnings, or PER JOB (<5% of sample has 2+ jobs) - less hard than i thought...
// browse TAGE RMNUMJOBS EJB1_PAYHR1 TJB1_ANNSAL1 TJB1_HOURLY1 TJB1_WKLY1 TJB1_BWKLY1 TJB1_MTHLY1 TJB1_SMTHLY1 TJB1_OTHER1 TJB1_GAMT1 TJB1_MSUM TJB2_MSUM TJB3_MSUM TPEARN

egen earnings=rowtotal(TJB1_MSUM TJB2_MSUM TJB3_MSUM TJB4_MSUM TJB5_MSUM TJB6_MSUM TJB7_MSUM)
browse earnings TPEARN
gen check=.
replace check=0 if earnings!=TPEARN & TPEARN!=.
replace check=1 if earnings==TPEARN

tab check // 8.4% don't match
// browse TAGE TJB1_MSUM TJB2_MSUM TJB3_MSUM TPEARN earnings if check==0 // think difference is the profit / loss piece of TPEARN. decide to use that or earnings

* hours change: do average tmwkhrs? this is average hours by month, so to aggregate to year, use average?
	
	* also do a recode for reference of FT / PT
	recode TMWKHRS (0/34.99=2)(35.0/99=1), gen(ft_pt)
	label define hours 1 "Full-Time" 2 "Part-Time"
	label values ft_pt hours
	
	* type of schedule - Each person can have up to 7 jobs, so recoding all 7
	label define jobtype 1 "Regular Day" 2 "Regular Night" 3 "Irregular" 4 "Other"
	forvalues job=1/7{
		recode EJB`job'_WSJOB (1=1) (2/3=2) (4/6=3) (7=4), gen(jobtype_`job')
		label values jobtype_`job' jobtype
		drop EJB`job'_WSJOB
	}
	
* occupation change (https://www.census.gov/topics/employment/industry-occupation/guidance/code-lists.html)...do we care about industry change? (industry codes: https://www.naics.com/search/)
label define occupation 1 "Management" 2 "STEM" 3 "Education / Legal / Media" 4 "Healthcare" 5 "Service" 6 "Sales" 7 "Office / Admin" 8 "Farming" 9 "Construction" 10 "Maintenance" 11 "Production" 12 "Transportation" 13 "Military" 

forvalues job=1/7{ 
destring TJB`job'_OCC, replace
recode TJB`job'_OCC (0010/0960=1)(1005/1980=2)(2000/2970=3)(3000/3550=4)(3600/4655=5)(4700/4965=6)(5000/5940=7)(6005/6130=8)(6200/6950=9)(7000/7640=10)(7700/8990=11)(9000/9760=12)(9800/9840=13), gen(occ_`job')
label values occ_`job' occupation
drop TJB`job'_OCC
}

* employer change: do we want any employer characteristics? could / would industry go here?

//misc variables
* reasons for moving

recode EEHC_WHY (1/3=1) (4/7=2) (8/12=3) (13=4) (14=5) (15=7) (16=6), gen(moves)
label define moves 1 "Family reason" 2 "Job reason" 3 "House/Neighborhood" 4 "Disaster" 5 "Evicted" 6 "Other" 7 "Did not Move"
label values moves moves

* Reasons for leaving employer
label define leave_job 1 "Fired" 2 "Other Involuntary Reason" 3 "Quit Voluntarily" 4 "Retired" 5 "Childcare-related" 6 "Other personal reason" 7 "Illness" 8 "In School"

forvalues job=1/7{ 
recode EJB`job'_RSEND (5=1)(1/4=2)(6=2)(7/9=3)(10=4)(11=5)(12=6)(16=6)(13/14=7)(15=8), gen(leave_job`job')
label values leave_job`job' leave_job
drop EJB`job'_RSEND
}

* Reasons for work schedule
label define schedule 1 "Involuntary" 2 "Pay" 3 "Childcare" 4 "Other Voluntary"

forvalues job=1/7{
recode EJB`job'_WSMNR (1/3=1) (4=2) (5=3) (6/8=4), gen(why_schedule`job') 
label values why_schedule`job' schedule
drop EJB`job'_WSMNR
}

* Why not working - this is a series of variables not one variable, so first checking for how many people gave more than one reason, then recoding
forvalues n=1/12{
replace ENJ_NOWRK`n'=0 if ENJ_NOWRK`n'==2
} // recoding nos to 0 instead of 2

egen count_nowork = rowtotal(ENJ_NOWRK1-ENJ_NOWRK12)
//browse count_nowork ENJ_NO*
tab count_nowork

gen why_nowork=.
forvalues n=1/12{
replace why_nowork = `n' if ENJ_NOWRK`n'==1 & count_nowork==1
}

replace why_nowork=13 if count_nowork>=2 & !missing(count_nowork)

recode why_nowork (1/3=1) (4=2) (5/6=3) (7=4) (8/9=5) (10=6) (11/12=7) (13=8), gen(whynowork)
label define whynowork 1 "Illness" 2 "Retired" 3 "Child related" 4 "In School" 5 "Involuntary" 6 "Voluntary" 7 "Other" 8 "Multiple reasons"
label values whynowork whynowork

*poverty
recode THINCPOV (0/0.499=1) (.500/1.249=2) (1.250/1.499=3) (1.500/1.849=4) (1.850/1.999=5) (2.000/3.999=6) (4.000/1000=7), gen(pov_level)
label define pov_level 1 "< 50%" 2 "50-125%" 3 "125-150%" 4 "150-185%" 5 "185-200%" 6 "200-400%" 7 "400%+" // http://neocando.case.edu/cando/pdf/CensusPovertyandIncomeIndicators.pdf - to determine thresholds
label values pov_level pov_level
drop THINCPOV


save "$SIPP14keep/allmonths14_rec.dta", replace