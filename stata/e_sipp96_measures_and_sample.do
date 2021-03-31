*-------------------------------------------------------------------------------
* BREADWINNER PROJECT
* measures and sample.do
* Kelly Raley and Joanna Pepin
*-------------------------------------------------------------------------------
di "$S_DATE"

********************************************************************************
* DESCRIPTION
********************************************************************************
* Creates the analytic sample and relevant measures

* The data files used in this script are the compressed data files that we
* created from the Census data files. 

use "$SIPP14keep/sipp96_data.dta", clear

********************************************************************************
* Create and format variables
********************************************************************************

// Capitalize variables to be compatible with 2014 and household composition indicators
	rename ssuid SSUID
	rename eentaid ERESIDENCEID
	rename rhcalmn monthcode
	rename rhcalyr year
	
// exploring HH roster
browse SSUID PNUM panelmonth ehrefper errp erelat* eprlpn*

// Create a measure of total household earnings per month (with allocated data)
	* Note that this approach omits the earnings of type 2 people.
    egen thearn = total(tpearn), 	by(SSUID ERESIDENCEID swave monthcode)
	
// Creating a measure of earnings solely based on wages and not profits and losses
	egen earnings=rowtotal(tpmsum1 tpmsum2), missing

	// browse earnings tpearn
	gen check_e=.
	replace check_e=0 if earnings!=tpearn & tpearn!=.
	replace check_e=1 if earnings==tpearn

	tab check_e 
	
	egen thearn_alt = total(earnings), 	by(SSUID ERESIDENCEID swave monthcode) // how different is a HH measure based on earnings v. tpearn?
	// browse SSUID thearn thearn_alt

// Count number of earners in hh per month
    egen numearner = count(earnings) if earnings>0,	by(SSUID ERESIDENCEID swave monthcode)

// Create an indicator of first wave of observation for this individual

    egen first_wave = min(swave), by(SSUID PNUM)	
	
// Create an indictor of the birth year of the first child - using the variables that already exist, but leaving names to be consistent with 2014, just in case we ever merge
    gen yrfirstbirth = tfbrthyr 

// create an indicator of birth year of the last child
	gen yrlastbirth = tlbirtyr
	replace yrlastbirth = tfbrthyr if tlbirtyr==-1 // tfbrthyr records first or ONLY birth, so for some, this is blank if only 1 child
	
	browse yrfirstbirth tfbrthyr yrlastbirth tlbirtyr
	replace yrfirstbirth=. if yrfirstbirth == -1
	replace yrlastbirth=. if yrlastbirth == -1

// Create an indicator of how many years have elapsed since individual's last birth
   gen durmom=year-yrlastbirth if !missing(yrlastbirth)
   
   //browse SSUID PNUM year panelmonth yrlastbirth yrfirstbirth tfbrthyr tlbirtyr durmom

// Create an indicator of how many years have elapsed since individual's first birth
gen durmom_1st=year-yrfirstbirth if !missing(yrfirstbirth) // to get the duration 1 year prior to respondent becoming a mom
   
gen mom_panel=.
replace mom_panel=1 if inrange(yrfirstbirth, 1995, 2000) // flag if became a mom during panel to use later - note, since the topical module was in 1996, anyone with a birth during the panel not captured - unless I am missing something

* Note that durmom=0 when child was born in this year, but some of the children born in the previous calendar
* year are still < 1. So if we want the percentage of mothers breadwinning in the year of the child's birth
* we should check to see if breadwinning is much different between durmom=0 or durmom=1. We could use durmom=1
* because many of those with durmom=0 will have spent much of the year not a mother. 
 
// Create a flag if year of first birth is > respondents year of birth+9
   gen 		mybirthyear		= year-tage
   gen 		birthyear_error	= 1 			if mybirthyear+9  > yrfirstbirth & !missing(yrfirstbirth)  // too young
   replace 	birthyear_error	= 1 			if mybirthyear+50 < yrfirstbirth & !missing(yrfirstbirth)  // too old

// create an indicator of age at first birth to be able to compare to NLSY analysis
   gen ageb1=yrfirstbirth-mybirthyear
   replace ragfbrth=. if ragfbrth==-1
   gen ageb1_mon=(ragfbrth/12) // ragfbrth is given in months not years

   gen check=.
   replace check=1 if ageb1==round(ageb1_mon) & ageb1_mon!=.
   replace check=0 if ageb1!=round(ageb1_mon) 
   browse mybirthyear yrfirstbirth ageb1 ageb1_mon
   
********************************************************************************
* Variable recodes
********************************************************************************

* race/ ethnicity: combo of ERACE and EORIGIN
gen race=.
replace race=1 if erace==1 & !inrange(eorigin, 20,28)
replace race=2 if erace==2
replace race=3 if erace==4 & !inrange(eorigin, 20,28)
replace race=4 if inrange(eorigin, 20,28) & erace!=2
replace race=5 if erace==3 & !inrange(eorigin, 20,28)

label define race 1 "NH White" 2 "Black" 3 "NH Asian" 4 "Hispanic" 5 "Other"
label values race race

// drop erace eorigin


* educational attainment: use EEDUC
recode eeducate (31/38=1)(39=2)(40/43=3)(44/47=4)(-1=.), gen(educ)
label define educ 1 "Less than HS" 2 "HS Diploma" 3 "Some College" 4 "College Plus"
label values educ educ

drop eeducate



* employment changes: use rmesr? but this is the question around like # of jobs - RMESR is OVERALL employment status, but then could have went from 2 jobs to 1 job and still be "employed" - do we care about that?! also put with hours to get FT / PT?
	* also use ENJFLAG - says if no-job or not

recode rmesr (1=1) (2/5=2) (6/7=3) (8=4) (-1=.), gen(employ)
label define employ 1 "Full Time" 2 "Part Time" 3 "Not Working - Looking" 4 "Not Working - Not Looking" // this is probably oversimplified at the moment
label values employ employ

label define jobchange 0 "No" 1 "Yes"

recode ersend1 (-1=0) (1/15=1), gen(jobchange_1)
recode ersend2 (-1=0) (1/15=1), gen(jobchange_2)
label values jobchange_1 jobchange_2 jobchange

gen better_job = .
replace better_job = 1 if (inlist(ersend1,12,14) | inlist(ersend2,12,14))
replace better_job = 0 if (jobchange_1==1 | jobchange_2==1) & better_job==.


* wages change: revisit this - confused bc only seem to track hourly pay rates
browse SSUID PNUM epayhr1 tpyrate1 ejbhrs1 tpmsum1
// should I either create an hourly metric for all? need the column w weeks in month...or create annual or monthly wages for those not paid hourly? - this might also be in a topical module, haven't gotten this far 
gen hourly_est1 = .
replace hourly_est1 = tpyrate1 if epayhr1==1
replace hourly_est1 = (tpmsum1 / rwksperm / ejbhrs1) if epayhr1==2
	// browse SSUID PNUM epayhr1 tpyrate1 ejbhrs1 tpmsum1 hourly_est1
	
gen hourly_est2 = .
replace hourly_est2 = tpyrate2 if epayhr2==1
replace hourly_est2 = (tpmsum2 / rwksperm / ejbhrs2) if epayhr2==2
	
egen avg_wk_rate=rowmean(hourly_est1 hourly_est2)

// browse SSUID PNUM epayhr1 tpyrate1 ejbhrs1 tpmsum1 hourly_est1 hourly_est2 avg_wk_rate
	

* hours change: need to create a view of average hours across both job options // browse SSUID ejbhrs1 ejbhrs2 rmhrswk
replace ejbhrs1=. if ejbhrs1==-1
replace ejbhrs2=. if ejbhrs2==-1

egen avg_mo_hrs=rowmean(ejbhrs1 ejbhrs2)

* also do a recode for reference of FT / PT
replace eptwrk=. if eptwrk==-1
	
/* this is from a topical module I did not pull in
	* type of schedule - Each person can have up to 7 jobs, so recoding all 7
	label define jobtype 1 "Regular Day" 2 "Regular Night" 3 "Irregular" 4 "Other"
	forvalues job=1/7{
		recode ejb`job'_wsjob (1=1) (2/3=2) (4/6=3) (7=4), gen(jobtype_`job')
		label values jobtype_`job' jobtype
		drop ejb`job'_wsjob
	}
*/

* Welfare use
foreach var in rcutyp20 rcutyp21 rcutyp24 rcutyp25 rcutyp27 rhnbrf rhcbrf rhmtrf{
replace `var' =0 if `var'==2
}

egen programs = rowtotal ( rcutyp20 rcutyp21 rcutyp24 rcutyp25 rcutyp27 )
egen benefits = rowtotal ( rhnbrf rhcbrf rhmtrf )

drop rcutyp20 rcutyp21 rcutyp24 rcutyp25 rcutyp27 rhnbrf rhcbrf rhmtrf

/* revisit this coding - trying to prioritize basic estimates

* occupation change (https://www.census.gov/topics/employment/industry-occupation/guidance/code-lists.html)...do we care about industry change? (industry codes: https://www.naics.com/search/)
label define occupation 1 "Management" 2 "STEM" 3 "Education / Legal / Media" 4 "Healthcare" 5 "Service" 6 "Sales" 7 "Office / Admin" 8 "Farming" 9 "Construction" 10 "Maintenance" 11 "Production" 12 "Transportation" 13 "Military" 

forvalues job=1/7{ 
destring tjb`job'_occ, replace
recode tjb`job'_occ (0010/0960=1)(1005/1980=2)(2000/2970=3)(3000/3550=4)(3600/4655=5)(4700/4965=6)(5000/5940=7)(6005/6130=8)(6200/6950=9)(7000/7640=10)(7700/8990=11)(9000/9760=12)(9800/9840=13), gen(occ_`job')
label values occ_`job' occupation
drop tjb`job'_occ
}

* employer change: do we want any employer characteristics? could / would industry go here?


//misc variables
* Disability status
// EFINDJOB (seems more restrictive than EDISABL, which is about limits, find job is about difficult finding ANY job) EDISABL RDIS_ALT (alt includes job rrlated disability measures whereas RDIS doesn't, but theeir differences are very neglible so relying on the more comprehensive one)
// relabeling so the Nos are 0 not 2
foreach var in efindjob edisabl rdis_alt{
replace `var' =0 if `var'==2
}


* Child care ease of use
foreach var in echld_mnyn elist eworkmore{
replace `var'=0 if `var'==2
}


* reasons for moving

recode eehc_why (1/3=1) (4/7=2) (8/12=3) (13=4) (14=5) (15=7) (16=6), gen(moves)
label define moves 1 "Family reason" 2 "Job reason" 3 "House/Neighborhood" 4 "Disaster" 5 "Evicted" 6 "Other" 7 "Did not Move"
label values moves moves

recode eehc_why (1=1) (2=2) (3/14=3) (15=4) (16=3), gen(hh_move)
label define hh_move 1 "Relationship Change" 2 "Independence" 3 "Other" 4 "Did not Move"
label values hh_move hh_move


* Reasons for leaving employer
label define leave_job 1 "Fired" 2 "Other Involuntary Reason" 3 "Quit Voluntarily" 4 "Retired" 5 "Childcare-related" 6 "Other personal reason" 7 "Illness" 8 "In School"

forvalues job=1/7{ 
recode ejb`job'_rsend (5=1)(1/4=2)(6=2)(7/9=3)(10=4)(11=5)(12=6)(16=6)(13/14=7)(15=8), gen(leave_job`job')
label values leave_job`job' leave_job
drop ejb`job'_rsend
}

* Reasons for work schedule
label define schedule 1 "Involuntary" 2 "Pay" 3 "Childcare" 4 "Other Voluntary"

forvalues job=1/7{
recode ejb`job'_wsmnr (1/3=1) (4=2) (5=3) (6/8=4), gen(why_schedule`job') 
label values why_schedule`job' schedule
drop ejb`job'_wsmnr
}

* Why not working - this is a series of variables not one variable, so first checking for how many people gave more than one reason, then recoding
forvalues n=1/12{
replace enj_nowrk`n'=0 if enj_nowrk`n'==2
} // recoding nos to 0 instead of 2

egen count_nowork = rowtotal(enj_nowrk1-enj_nowrk12)
//browse count_nowork ENJ_NO*
tab count_nowork

gen why_nowork=.
forvalues n=1/12{
replace why_nowork = `n' if enj_nowrk`n'==1 & count_nowork==1
}

replace why_nowork=13 if count_nowork>=2 & !missing(count_nowork)

recode why_nowork (1/3=1) (4=2) (5/6=3) (7=4) (8/9=5) (10=6) (11/12=7) (13=8), gen(whynowork)
label define whynowork 1 "Illness" 2 "Retired" 3 "Child related" 4 "In School" 5 "Involuntary" 6 "Voluntary" 7 "Other" 8 "Multiple reasons"
label values whynowork whynowork

*poverty - think I did this too early // revisit
recode thincpov (0/0.499=1) (.500/1.249=2) (1.250/1.499=3) (1.500/1.849=4) (1.850/1.999=5) (2.000/3.999=6) (4.000/1000=7), gen(pov_level)
label define pov_level 1 "< 50%" 2 "50-125%" 3 "125-150%" 4 "150-185%" 5 "185-200%" 6 "200-400%" 7 "400%+" // http://neocando.case.edu/cando/pdf/CensusPovertyandIncomeIndicators.pdf - to determine thresholds
label values pov_level pov_level
// drop thincpov
*/


save "$tempdir/sipp96tpearn_fullsamp", replace


********************************************************************************
* Create the analytic sample
********************************************************************************
* Keep observations of women in first 18 years since first birth. 
* Durmom is wave specific. So a mother who was durmom=19 in wave 3 is still in the sample 
* in waves 1 and 2.

* Before dropping, get a count of children from here.
egen ssuid_month = group (SSUID panelmonth)
// qui unique epnmom if epnmom!=9999, by(ssuid_month) generate(count_mom)

// bysort SSUID panelmonth (person): gen num_children= (count)
qui unique PNUM if person==3 & epnmom!=., by(ssuid_month) generate(num_children)
bysort SSUID panelmonth (num_children): replace num_children = num_children[1] if (PNUM==hhmom1 | PNUM==hhmom2) // this is more accurate ffor children, but NOT biological children
qui unique PNUM if person==3 & tage < 18 & epnmom!=., by(ssuid_month) generate(num_minors)
bysort SSUID panelmonth (num_minors): replace num_minors = num_minors[1] if (PNUM==hhmom1 | PNUM==hhmom2)

browse SSUID PNUM panelmonth person hhmom1 hhmom2 epnmom tage num_children num_minors errp ehrefper if inlist(SSUID, "019156667000", "019228369159" , "019359986255", "019344451235") // okay some issues with multigenerational households

// ids to look at PRE drop: 019156667000, 019228369159, 019359986255 - potentially not related?
// is 1 or 2 right for 019228369159 - does it switch? confused bc think 106 is a child, but 105 is unclear
// 019359986255: grandkids: 2 (105,106) not: 1 (104), eventually 104 becomes "mom", now 2 chldren in home GAH, between month 10 and 11. mom 104 had 2 kids, mom 102 had 2 kids (104,101), then becomes grandparent via 104

* First, create an id variable per person
	sort SSUID PNUM
	egen id = concat (SSUID PNUM)
	destring id, gen(idnum)
	format idnum %20.0f
	drop id

// Create a macro with the total number of respondents in the dataset.
	egen all = nvals(idnum)
	global allindividuals = all
	di "$allindividuals"

* Next, keep only the respondents that meet sample criteria

// Keep only women
	tab 	esex				// Shows all cases
	unique idnum, 	by(esex)	// Number of individuals
	
	// Creates a macro with the total number of women in the dataset.
	egen	allwomen 	= nvals(idnum) if esex == 2
	egen allwomen_n = min(allwomen)
	global 	allwomen_n	=  allwomen_n
	di "$allwomen_n"

	egen everman = min(esex) , by(idnum) // Identify if ever reported as a man (inconsistency).
	unique idnum, by(everman)

	keep if everman !=1 		// Keep women consistently identified
	
	// Creates a macro with the ADJUSTED total number of women in the dataset.
	egen	women 	= nvals(idnum)
	global 	women_n = women
	di "$women_n"

// Only keep mothers
	tab 	durmom_1st, m
	unique 	idnum 	if durmom_1st ==.  // Not mothers
	keep 		 	if durmom_1st !=.  // Keep only mothers
	
	// Creates a macro with the total number of mothers in the dataset.
	egen	mothers = nvals(idnum)
	global mothers_n = mothers
	di "$mothers_n"

* Keep mothers that meet our criteria: 18 years or less since last birth OR became a mother during panel (we want data starting 1 year prior to motherhood)
	keep if (durmom>=0 & durmom < 19) | (mom_panel==1 & durmom_1st>=-1)
	
	// Creates a macro with the total number of mothers left in the dataset.
	egen	mothers_sample = nvals(idnum)
	global mothers_sample = mothers_sample
	di "$mothers_sample"
	
// Consider dropping respondents who have an error in birthyear
	* (year of first birth is > respondents year of birth+9)
	*  drop if birthyear_error == 1
tab birthyear_error	

// Clean up dataset
	drop idnum all allwomen women mothers mothers_sample 
	
// now that sample is restricted, see how any missings there are for HH members (was around 6%)
tab person, m

********************************************************************************
* Merge  measures of earning, demographic characteristics and household composition
********************************************************************************
// Merge this data with household composition data - created in step c. hhcomp.dta has one record for
	* every SSUID PNUM panelmonth combination except for PNUMs living alone (_merge==1). 
	* those not in the target sample are _merge==2
	drop _merge
	
	merge 1:1 SSUID PNUM panelmonth using "$tempdir/s96_hhcomp.dta"

	drop if _merge==2
	
	browse SSUID PNUM person ehhnumpp num_minors minorchildren num_children // validate if this at all matches 
	gen check_c=0
	replace check_c=1 if num_minors==minorchildren
	replace check_c=1 if num_minors==0 & minorchildren==.
	
	browse SSUID PNUM person ehhnumpp num_minors minorchildren minorbiochildren preschoolchildren prebiochildren spouse partner hhsize parents grandparents grandchildren siblings if check_c==0
	browse SSUID PNUM person panelmonth ehhnumpp num_children num_minors minorchildren minorbiochildren preschoolchildren prebiochildren spouse partner hhsize parents grandparents grandchildren siblings  if SSUID=="019228369159"
	// ids to look at PRE drop: 019156667000, 019228369159, 019359986255, 019344451235
	
	/* okay, based investigating, these new measures of children seem SLIGHTLY more accurate than previous. I think this is due to when the people are all "non-relatives" of the reference person; I wasn't accurately capturing parent / child dynamics using mom & dad ids*/

// Fix household compposition variables for unmatched individuals who live alone (_merge==1)
	* Relationship_pairs_bymonth has one record per person living with PNUM. 
	* We deleted records where "from_num==to_num." (compute_relationships.do)
	* So, individuals living alone are not in the data.

	// Make relationship variables equal to zero
	local hhcompvars "minorchildren minorbiochildren preschoolchildren prebiochildren spouse partner parents grandparents grandchildren siblings"

	foreach var of local hhcompvars{
		replace `var'=0 if _merge==1 & missing(`var') 
	}
	
	// Make household size = 1 for those living alone
	replace hhsize = 1 if _merge==1

// 	Create a tempory unique person id variable
	sort SSUID PNUM
	egen id = concat (SSUID PNUM)
	destring id, gen(idnum)
	format idnum %20.0f
	drop id
	
	unique 	idnum 

* Now, let's make sure we have the same number of mothers as before merge.
	egen newsample = nvals(idnum) 
	global newsamplesize = newsample
	di "$newsamplesize"

// Make sure starting sample size is consistent.
	di "$mothers_sample"
	di "$newsamplesize"

	if ("$newsamplesize" == "$mothers_sample") {
		display "Success! Sample sizes consistent."
		}
		else {
		display as error "The sample size is different than extract_earnings."
		exit
		}
		
	drop 	_merge

********************************************************************************
* Restrict sample to women who live with their own minor children
********************************************************************************
// Revisit this for those living with bio children at start AND end of panel

// Identify mothers who reside with their biological children
	replace num_minors=0 if num_minors==.
	fre num_minors
	unique 	idnum 	if num_minors >= 1  	// 1 or more minor children in household

	gen children_yn=num_minors
	replace children_yn=1 if inrange(num_minors,1,11)

	keep if num_minors >= 1 | mom_panel==1	// Keep only moms with kids in household. for those who became a mom in the panel, I think sometimes child not recorded in 1st year of birth

// Creates a macro with the total number of mothers in the dataset.
preserve
	keep			if num_minors >=1
	cap drop 	hhmom
	egen		hhmom	= nvals(idnum)
	global 		hhmom_n = hhmom
	di "$hhmom_n"
	drop idnum hhmom
restore

*/

save "$SIPP14keep/sipp96tpearn_all", replace
