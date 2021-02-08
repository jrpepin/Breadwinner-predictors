*-------------------------------------------------------------------------------
* BREADWINNER PROJECT
* measures and sample.do
* Kelly Raley and Joanna Pepin
*-------------------------------------------------------------------------------
di "$S_DATE"

********************************************************************************
* DESCRIPTION
********************************************************************************
* Extracts key variables from all SIPP 2014 waves and creates the analytic sample.

* The data files used in this script are the compressed data files that we
* created from the Census data files. 

********************************************************************************
* Read in each original, compressed, data set and extract the key variables
********************************************************************************
clear
* set maxvar 5500 //set the maxvar if not starting from a master project file.

   forvalues w=1/4{
      use "$SIPP2014/pu2014w`w'_compressed.dta"
   	keep	swave monthcode wpfinwgt ssuid pnum eresidenceid shhadid einttype thhldstatus						/// /* TECHNICAL */
			tpearn apearn tjb?_msum ajb?_msum tftotinc thtotinc rhpov rhpovt2 thincpov thincpovt2				/// /* FINANCIAL   */
			erace eorigin esex tage tage_fb eeduc tceb tcbyr* tyear_fb ems ems_ehc								/// /* DEMOGRAPHIC */
			tyrcurrmarr tyrfirstmarr exmar eehc_why														  		///
			tjb*_occ tjb*_ind tmwkhrs enjflag rmesr rmnumjobs ejb*_bmonth ejb*_emonth ejb*_ptresn*				/// /* EMPLOYMENT */
			ejb*_rsend ejb*_wsmnr enj_nowrk* ejb*_payhr* ejb*_wsjob ajb*_rsend									///
			tjb*_annsal* tjb*_hourly* tjb*_wkly* tjb*_bwkly* tjb*_mthly* tjb*_smthly* tjb*_other* 				/// /* EARNINGS */
			tjb*_gamt* tjb*_msum tpearn
			
	  gen year = 2012+`w'
      save "$tempdir/sipp14tpearn`w'", replace
   }

 
clear

********************************************************************************
* Stack all the extracts into a single file 
********************************************************************************

// Import first wave. 
   use "$tempdir/sipp14tpearn1", clear

// Append the remaining waves
   forvalues w=2/4{
      append using "$tempdir/sipp14tpearn`w'"
   }

********************************************************************************
* Create and format variables
********************************************************************************
// Create a panel month variable ranging from 1(01/2013) to 48 (12/2016)
	gen panelmonth = (swave-1)*12+monthcode
	
// Capitalize variables to be compatible with household composition indicators
	rename ssuid SSUID
	rename eresidenceid ERESIDENCEID
	rename pnum PNUM

// Create a measure of total household earnings per month (with allocated data)
	* Note that this approach omits the earnings of type 2 people.
    egen thearn = total(tpearn), 	by(SSUID ERESIDENCEID swave monthcode)

// Count number of earners in hh per month
    egen numearner = count(tpearn),	by(SSUID ERESIDENCEID swave monthcode)

// Create an indicator of first wave of observation for this individual

    egen first_wave = min(swave), by(SSUID PNUM)	
	
// Create an indictor of the birth year of the first child 
    gen yrfirstbirth = tcbyr_1 

	* If a birth of the second child or later is earlier than the year of the first child's birth,
	* replace the yrfirstbirth with the date of the firstborn.
	forvalues birth = 2/12 {
		replace yrfirstbirth = tcbyr_`birth' if tcbyr_`birth' < yrfirstbirth
	}
	

	// browse tyear_fb yrfirstbirth tcbyr_1
	// browse tcbyr_1 tcbyr_2 tcbyr_3 if tcbyr_1 > tcbyr_2
	
	gen bcheck=.
	replace bcheck=1 if yrfirstbirth==tyear_fb
	replace bcheck=0 if yrfirstbirth!=tyear_fb
	
// create an indicator of birth year of the last child
	egen yrlastbirth = rowmax(tcbyr_1-tcbyr_7)

// Create an indicator of how many years have elapsed since individual's last birth
   gen durmom=year-yrlastbirth if !missing(yrlastbirth)

// Create an indicator of how many years have elapsed since individual's first birth
* Note: I want to be able to capture negatives in this case, because we want the year prior to women bcoming a mother if she did in the panel. However, if she had her first baby in 2014, all her tcbyr's will be blank in the 2013 survey (since they only ask that question to parents) -- I need to copy the value of her yr of first birth to all nulls before then to get the appropriate calculation. example browse SSUID PNUM yrfirstbirth year tcbyr_1 if SSUID == "000114552134"
bysort SSUID PNUM (yrfirstbirth): replace yrfirstbirth = yrfirstbirth[1] 

gen durmom_1st=year-yrfirstbirth if !missing(yrfirstbirth) // to get the duration 1 year prior to respondent becoming a mom
   
gen mom_panel=.
replace mom_panel=1 if inrange(yrfirstbirth, 2013, 2016) // flag if became a mom during panel to use later

* Note that durmom=0 when child was born in this year, but some of the children born in the previous calendar
* year are still < 1. So if we want the percentage of mothers breadwinning in the year of the child's birth
* we should check to see if breadwinning is much different between durmom=0 or durmom=1. We could use durmom=1
* because many of those with durmom=0 will have spent much of the year not a mother. 

* also, some women gave birth to their first child after the reference year. In this case durmom < 0, but
* we don't have income information for this year in that wave of data. So, durmom < 0 is dropped below
 
// Create a flag if year of first birth is > respondents year of birth+9
   gen 		mybirthyear		= year-tage
   gen 		birthyear_error	= 1 			if mybirthyear+9  > yrfirstbirth & !missing(yrfirstbirth)  // too young
   replace 	birthyear_error	= 1 			if mybirthyear+50 < yrfirstbirth & !missing(yrfirstbirth)  // too old

// create an indicator of age at first birth to be able to compare to NLSY analysis
   gen ageb1=yrfirstbirth-mybirthyear
   
   gen check=.
   replace check=1 if ageb1==tage_fb & tage_fb!=.
   replace check=0 if ageb1!=tage_fb
   
//   browse tage_fb ageb1 check if check==0 // comparing calculated v. recoded age at first birth. if anything tage_fb is one year younger, probably because based on specific date not just year-  use that?
   

********************************************************************************
* Variable recodes
********************************************************************************

* age of youngest child: needs to vary with time across the household, will compute once relationships updated. for any given month, identify all children in household, use TAGE and get min TAGE (file 04)

* # of preschool age children: will update this in future code with other HH compositon calculations (file 04)

* race/ ethnicity: combo of ERACE and EORIGIN
gen race=.
replace race=1 if erace==1 & eorigin==2
replace race=2 if erace==2 & eorigin==2
replace race=3 if erace==3 & eorigin==2
replace race=4 if eorigin==1
replace race=5 if erace==4 & eorigin==2

label define race 1 "NH White" 2 "NH Black" 3 "NH Asian" 4 "Hispanic" 5 "Other"
label values race race

drop erace eorigin

* age at 1st birth: this exists as TAGE_FB

* marital status at 1st birth: not 100% sure. TYEAR_FB is year of first birth. we also have first and current marriage year. HOWEVER, if divorced, do not have that information. Would need to merge with SSA supplement

* educational attainment: use EEDUC
recode eeduc (31/38=1)(39=2)(40/42=3)(43=4)(44/46=5), gen(educ)
label define educ 1 "Less than HS" 2 "HS Diploma" 3 "Some College" 4 "College Degree" 5 "Advanced Degree"
label values educ educ

drop eeduc

* subsequent birth: can use TCBYR* to get year of each birth, so will get a flag if that occurs during survey waves.

* partner status: can use ems for marriage. for cohabiting unions, need to use relationship codes. will recode this in a later step (may already happen in step 4)
	* need to code as like year status, did they lose a partner at all, add one, in that year - need to think about this more

* employment change: use rmesr? but this is the question around like # of jobs - RMESR is OVERALL employment status, but then could have went from 2 jobs to 1 job and still be "employed" - do we care about that?! also put with hours to get FT / PT?
	* also use ENJFLAG - says if no-job or not

recode rmesr (1=1) (2/5=2) (6/7=3) (8=4), gen(employ)
label define employ 1 "Full Time" 2 "Part Time" 3 "Not Working - Looking" 4 "Not Working - Not Looking" // this is probably oversimplified at the moment
label values employ employ

drop rmesr

label define jobchange 0 "No" 1 "Yes"
forvalues job=1/7{
	recode ajb`job'_rsend (0=0) (1/10=1), gen(jobchange_`job')
	label values jobchange_`job' jobchange
	drop ajb`job'_rsend
}

* earnings change: tpearn seems to cover all jobs in month. need to decide if we want OVERALL change in earnings, or PER JOB (<5% of sample has 2+ jobs) - less hard than i thought...
// browse TAGE RMNUMJOBS EJB1_PAYHR1 TJB1_ANNSAL1 TJB1_HOURLY1 TJB1_WKLY1 TJB1_BWKLY1 TJB1_MTHLY1 TJB1_SMTHLY1 TJB1_OTHER1 TJB1_GAMT1 TJB1_MSUM TJB2_MSUM TJB3_MSUM TPEARN

egen earnings=rowtotal(tjb1_msum tjb2_msum tjb3_msum tjb4_msum tjb5_msum tjb6_msum tjb7_msum)
browse earnings tpearn
gen check_e=.
replace check_e=0 if earnings!=tpearn & tpearn!=.
replace check_e=1 if earnings==tpearn

tab check_e // 8.4% don't match
// browse TAGE TJB1_MSUM TJB2_MSUM TJB3_MSUM TPEARN earnings if check==0 // think difference is the profit / loss piece of TPEARN. decide to use that or earnings

* hours change: do average tmwkhrs? this is average hours by month, so to aggregate to year, use average?
	
	* also do a recode for reference of FT / PT
	recode tmwkhrs (0/34.99=2)(35.0/99=1), gen(ft_pt)
	label define hours 1 "Full-Time" 2 "Part-Time"
	label values ft_pt hours
	
	* type of schedule - Each person can have up to 7 jobs, so recoding all 7
	label define jobtype 1 "Regular Day" 2 "Regular Night" 3 "Irregular" 4 "Other"
	forvalues job=1/7{
		recode ejb`job'_wsjob (1=1) (2/3=2) (4/6=3) (7=4), gen(jobtype_`job')
		label values jobtype_`job' jobtype
		drop ejb`job'_wsjob
	}
	
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
* reasons for moving

recode eehc_why (1/3=1) (4/7=2) (8/12=3) (13=4) (14=5) (15=7) (16=6), gen(moves)
label define moves 1 "Family reason" 2 "Job reason" 3 "House/Neighborhood" 4 "Disaster" 5 "Evicted" 6 "Other" 7 "Did not Move"
label values moves moves

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

*poverty
recode thincpov (0/0.499=1) (.500/1.249=2) (1.250/1.499=3) (1.500/1.849=4) (1.850/1.999=5) (2.000/3.999=6) (4.000/1000=7), gen(pov_level)
label define pov_level 1 "< 50%" 2 "50-125%" 3 "125-150%" 4 "150-185%" 5 "185-200%" 6 "200-400%" 7 "400%+" // http://neocando.case.edu/cando/pdf/CensusPovertyandIncomeIndicators.pdf - to determine thresholds
label values pov_level pov_level
drop thincpov

********************************************************************************
* Create the analytic sample
********************************************************************************
* Keep observations of women in first 18 years since first birth. 
* Durmom is wave specific. So a mother who was durmom=19 in wave 3 is still in the sample 
* in waves 1 and 2.

* Note that we don't restrict the sample to mothers coresident with minor 
* children (below) anymore. At least not for now, to allow robustness checks.

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
	global 	allwomen_n 	= allwomen
	di "$allwomen_n"

	egen everman = min(esex) , by(idnum) // Identify if ever reported as a man (inconsistency).
	unique idnum, by(everman)

	keep if everman !=1 		// Keep women consistently identified
	
	// Creates a macro with the ADJUSTED total number of women in the dataset.
	egen	women 	= nvals(idnum)
	global 	women_n = women
	di "$women_n"

	// browse durmom_1st year yrfirstbirth tcbyr* if durmom_1st<=0
	// browse durmom_1st year yrfirstbirth tcbyr* if yrfirstbirth >=2013 &!missing(yrfirstbirth)
	// tab durmom_1st durmom   if durmom_1st==0 | durmom_1st==-1 | durmom_1st==1, m
	
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
	
********************************************************************************
* Merge  measures of earning, demographic characteristics and household composition
********************************************************************************
// Merge this data with household composition data. hhcomp.dta has one record for
	* every SSUID PNUM panelmonth combination except for PNUMs living alone (_merge==1). 
	* those not in the target sample are _merge==2
	merge 1:1 SSUID PNUM panelmonth using "$tempdir/hhcomp.dta"

drop if _merge==2

// Fix household compposition variables for unmatched individuals who live alone (_merge==1)
	* Relationship_pairs_bymonth has one record per person living with PNUM. 
	* We deleted records where "from_num==to_num." (compute_relationships.do)
	* So, individuals living alone are not in the data.

	// Make relationship variables equal to zero
	local hhcompvars "minorchildren minorbiochildren preschoolchildren prebiochildren spouse partner numtype2 parents grandparents grandchildren siblings"

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

// Identify mothers who reside with their biological children
	fre minorbiochildren
	unique 	idnum 	if minorbiochildren >= 1  	// 1 or more minor children in household
*NOTE: Keeping all mothers, even those not living with bio children for this part of the analysis.
*Create macro just to get the n for later purposes (see msltprep.do).
*	keep if minorbiochildren >= 1	// Keep only moms with kids in household

/* It's something worth thinking about more. Generally, we assume that minor children live with their mothers and generally that is right. In the earlier analysis, I put women not living with minor children as a separate category to be able to see how wrong the assumption is. The results pretty clearly support the idea that most (but not all mothers, all the time) live with their minor children. So, the decision to include all mothers is really about minimizing the number of complications we introduce to the analysis.
*/	

// Creates a macro with the total number of mothers in the dataset.
preserve
	keep			if minorbiochildren >=1
	cap drop 	hhmom
	egen		hhmom	= nvals(idnum)
	global 		hhmom_n = hhmom
	di "$hhmom_n"
	drop idnum hhmom
restore
	
save "$SIPP14keep/sipp14tpearn_all", replace
