*-------------------------------------------------------------------------------
* BREADWINNER PROJECT
* sensitivity_checks.do
* Kim McErlean
*-------------------------------------------------------------------------------
di "$S_DATE"

********************************************************************************
* DESCRIPTION
********************************************************************************
* The Socius paper used duration since 1st born child, the Demography paper used
* duration for last, so that is what current JFEI analyses are based on. Here, I 
* see what happens if I use the duration since 1st born, but I need to go to our
* sample restrictions (file 6 in 2014 folder)

use "$tempdir/sipp14tpearn_fullsamp", clear

********************************************************************************
********************************************************************************
********************************************************************************
**# Bookmark #7
* Create the analytic sample
********************************************************************************
********************************************************************************
********************************************************************************
* Keep observations of women in first 18 years since first birth. 
* Durmom is wave specific. So a mother who was durmom=19 in wave 3 is still in the sample 
* in waves 1 and 2.

* First, create an id variable per person
	sort SSUID PNUM
	egen id = concat (SSUID PNUM)
	destring id, gen(idnum)
	format idnum %20.0f
	drop id

// Create a macro with the total number of respondents in the dataset.
	egen all = nvals(idnum)
	global allindividuals14 = all
	di "$allindividuals14"
	
	egen all_py = count(idnum)
	global allpersonyears14 = all_py
	di "$allpersonyears14"

* Next, keep only the respondents that meet sample criteria

// Keep only women
	tab 	esex				// Shows all cases
	unique idnum, 	by(esex)	// Number of individuals
	
	// Creates a macro with the total number of women in the dataset.
	egen	allwomen 	= nvals(idnum) if esex == 2
	global 	allwomen_n14 	= allwomen
	di "$allwomen_n14"
	
	egen	allwomen_py 	= count(idnum) if esex == 2
	global 	allwomen_py14 	= allwomen_py
	di "$allwomen_py14"

	egen everman = min(esex) , by(idnum) // Identify if ever reported as a man (inconsistency).
	unique idnum, by(everman)

	keep if everman !=1 		// Keep women consistently identified
	
	// Creates a macro with the ADJUSTED total number of women in the dataset.
	egen	women 	= nvals(idnum)
	global 	women_n14 = women
	di "$women_n14"
	
	egen	women_py14	= count(idnum)
	global 	women_py14 = women_py14
	di "$women_py14"
	
// Only keep mothers
	tab 	durmom_1st, m
	unique 	idnum 	if durmom_1st ==.  // Not mothers
	keep 		 	if durmom_1st !=.  // Keep only mothers
	
	// Creates a macro with the total number of mothers in the dataset.
	egen	mothers = nvals(idnum)
	global mothers_n14 = mothers
	di "$mothers_n14"
	
	egen	mothers_py = count(idnum)
	global mothers_py14 = mothers_py
	di "$mothers_py14"

* Keep mothers that meet our criteria: 18 years or less since last birth OR became a mother during panel (we want data starting 1 year prior to motherhood)
*** Here is the change
	keep if (durmom_1st>=0 & durmom_1st < 19) | (mom_panel==1 & durmom_1st>=-1)
	
	// Creates a macro with the total number of mothers left in the dataset.
	egen	mothers_sample = nvals(idnum)
	global mothers_sample_n14 = mothers_sample
	di "$mothers_sample_n14"
	
	egen	mothers_sample_py = count(idnum)
	global mothers_sample_py14 = mothers_sample_py
	di "$mothers_sample_py14"
	
	
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

// browse SSUID PNUM year panelmonth durmom minorbiochildren if inlist(SSUID, "000418500162", "000418209903", "000418334944") - okay yes so no minor children, so they're getting dropped. is this concerning?

// Fix household composition variables for unmatched individuals who live alone (_merge==1)
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
	di "$mothers_sample_n14"
	di "$newsamplesize"

	if ("$newsamplesize" == "$mothers_sample_n14") {
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
	
// identify mothers who resided with their biological children for a full year
	gen minors_m1=.
	replace minors_m1=1 if minorbiochildren>=1 & monthcode==1
	bysort SSUID PNUM year (minors_m1): replace minors_m1 = minors_m1[1]
	gen minors_m12=.
	replace minors_m12=1 if minorbiochildren>=1 & monthcode==12
	bysort SSUID PNUM year (minors_m12): replace minors_m12 = minors_m12[1]
	gen minors_fy=0
	replace minors_fy=1 if minors_m12==1 & minors_m1==1

	browse SSUID PNUM year monthcode minors_m1 minors_m12 minors_fy minorbiochildren
	
	unique 	idnum 	if minors_fy >= 1  

// identify mothers who resided with their children at some point in the panel
	bysort SSUID PNUM: egen maxchildren=max(minorbiochildren)
	unique idnum if maxchildren >=1
	
	gen children_yn=minorbiochildren
	replace children_yn=1 if inrange(minorbiochildren,1,10)
	
	gen children_ever=maxchildren
	replace children_ever=1 if inrange(maxchildren,1,10)
	
	keep if maxchildren >= 1 | mom_panel==1	// Keep only moms with kids in household. for those who became a mom in the panel, I think sometimes child not recorded in 1st year of birth
	
// Final sample size
	egen		hhmom	= nvals(idnum)
	global 		hhmom_n14 = hhmom
	di "$hhmom_n14"
	
	egen		hhmom_py	= count(idnum)
	global 		hhmom_py14 = hhmom_py
	di "$hhmom_py14"

// Creates a macro with the total number of mothers in the dataset.
preserve
	keep			if minorbiochildren >=1
	cap drop 	hhmom
	egen		hhmom	= nvals(idnum)
	global 		hhmom_n = hhmom
	di "$hhmom_n"
	drop idnum hhmom
restore
	
save "$SIPP14keep/sipp14_altsample", replace

********************************************************************************
********************************************************************************
********************************************************************************
**# Bookmark #6
* Add on hh characteristics (step 7)
********************************************************************************
********************************************************************************
********************************************************************************

* Final sample file:
use "$SIPP14keep/sipp14_altsample", clear

// Make the six digit identifier for residence addresses numeric to match the merge file
replace ERESIDENCEID=subinstr(ERESIDENCEID,"A","1",.)
replace ERESIDENCEID=subinstr(ERESIDENCEID,"B","2",.)
replace ERESIDENCEID=subinstr(ERESIDENCEID,"C","3",.)
replace ERESIDENCEID=subinstr(ERESIDENCEID,"D","4",.)
replace ERESIDENCEID=subinstr(ERESIDENCEID,"E","5",.)
replace ERESIDENCEID=subinstr(ERESIDENCEID,"F","6",.)
        
destring ERESIDENCEID, replace
	
merge 1:1 SSUID ERESIDENCEID panelmonth PNUM using "$tempdir/relationship_details_wide.dta"

drop if _merge==2

tab hhsize if _merge==1 // confirming that the unmatched in master are all people who live alone, so that is fine.

drop from_* // just want to use the "to" attributes aka others in HH. Will use original file for respondent's characteristics. This will help simplify

save "$SIPP14keep/sipp14_altsample_rel.dta", replace

// union status recodes - compare these to using simplistic gain or lose partner / gain or lose spouse later on

label define ems 1 "Married, spouse present" 2 "Married, spouse absent" 3 "Widowed" 4 "Divorced" 5 "Separated" 6 "Never Married"
label values ems_ehc ems
label values ems ems

tab ems_ehc spouse // some people are "married - spouse absent" - currently not in "spouse" tally, (but they are also not SEPARATED according to them), we are considering them married. Worth noting that some of these women also have unmarried partner living there
tab ems_ehc partner
// browse SSUID PNUM panelmonth ems_ehc ems spouse partner relationship* if ems_ehc==2

gen marital_status=.
replace marital_status=1 if inlist(ems_ehc,1,2) // for now - considered all married as married
replace marital_status=2 if inlist(ems_ehc,3,4,5,6) & partner>=1 // for now, if married spouse absent and having a partner - considering you married and not counting here. Cohabiting will override if divorced / separated in given month
replace marital_status=3 if ems_ehc==3 & partner==0
replace marital_status=4 if inlist(ems_ehc,4,5) & partner==0
replace marital_status=5 if ems_ehc==6 & partner==0

label define marital_status 1 "Married" 2 "Cohabiting" 3 "Widowed" 4 "Dissolved-Unpartnered" 5 "Never Married- Not partnered"
label values marital_status marital_status

// earner status recodes
gen other_earner=numearner if tpearn==.
replace other_earner=(numearner-1) if tpearn!=.

// browse panelmonth numearner other_earner tpearn to_TPEARN*

// job changes
egen jobchange = rowtotal(jobchange_1-jobchange_7)
replace jobchange=1 if jobchange>=1 & jobchange!=.
replace jobchange=. if tmwkhrs==.

forvalues n=1/22{
	egen to_jobchange`n' = rowtotal(to_jobchange_1`n'-to_jobchange_7`n')
	replace to_jobchange`n'=1 if to_jobchange`n'>=1 & to_jobchange`n'!=.
	replace to_jobchange`n'=. if to_TMWKHRS`n'==.
}

********************************************************************************
* Merge on SSA to get marital history
********************************************************************************
rename SSUID ssuid // ssa currently in lowercare
rename PNUM pnum

drop _merge

merge m:1 ssuid pnum using "$SIPP2014/pu2014ssa.dta", keepusing(ems_s exmar_s tmar?_yr twid?_yr tdiv?_yr tsep?_yr ewidiv*)

drop if _merge==2 // don't want people JUST in SSA, bc likely means they are not in our sample

rename ssuid SSUID
rename pnum PNUM

tab ems_ehc _merge // not a function of marital status
tab first_wave _merge // SSA after wave 1, but still a lot of people in wave 1 unmatched

/// creating indicator of marital status at first birth
browse SSUID PNUM exmar exmar_s ems tyrcurrmarr tyrfirstmarr tmar1_yr tdiv1_yr tmar2_yr tmar3_yr yrfirstbirth _merge

//
gen status_b1=.
replace status_b1 = 1 if inlist(ems,1,2) & exmar==1 & yrfirstbirth >= tyrfirstmarr // assuming if birth happened IN year, they were married, especially bc it's birth NOT conception
replace status_b1 = 1 if yrfirstbirth >= tyrcurrmarr 
replace status_b1 = 1 if ems!=6 & yrfirstbirth >= tyrfirstmarr & tyrfirstmarr!=. & ((yrfirstbirth < tdiv1_yr & tdiv1_yr!=.) | (yrfirstbirth < twid1_yr & twid1_yr!=.) | (yrfirstbirth < tsep1_yr & tsep1_yr!=.)) // trying to use the actual data v. SSA whenever possible
replace status_b1 = 1 if exmar>1 & yrfirstbirth >= tmar2_yr & tmar2_yr!=. & ((yrfirstbirth < tdiv2_yr & tdiv2_yr!=.) | (yrfirstbirth < twid2_yr & twid2_yr!=.) | (yrfirstbirth < tsep2_yr & tsep2_yr!=.))
replace status_b1 = 1 if exmar>2 & yrfirstbirth >= tmar3_yr & tmar3_yr!=. & ((yrfirstbirth < tdiv3_yr & tdiv3_yr!=.) | (yrfirstbirth < twid3_yr & twid3_yr!=.) | (yrfirstbirth < tsep3_yr & tsep3_yr!=.))
replace status_b1 = 2 if ems==6
replace status_b1 = 2 if yrfirstbirth < tyrfirstmarr
replace status_b1 = 2 if inlist(ems,1,2) & exmar==1 & yrfirstbirth < tyrfirstmarr
replace status_b1 = 3 if ems!=6 & yrfirstbirth > twid1_yr & yrfirstbirth < tmar2_yr & twid1_yr!=. & tmar2_yr!=.
replace status_b1 = 3 if ems!=6 & yrfirstbirth > twid2_yr & yrfirstbirth < tmar3_yr & twid2_yr!=. & tmar3_yr!=.
replace status_b1 = 3 if exmar==1 & ems==3 &  (yrfirstbirth > twid1_yr & twid1_yr!=.)
replace status_b1 = 4 if ems!=6 & yrfirstbirth > tdiv1_yr & yrfirstbirth < tmar2_yr & tdiv1_yr!=. & tmar2_yr!=.
replace status_b1 = 4 if ems!=6 & yrfirstbirth > tsep1_yr & yrfirstbirth < tmar2_yr & tsep1_yr!=. & tmar2_yr!=.
replace status_b1 = 4 if ems!=6 & yrfirstbirth > tdiv2_yr & yrfirstbirth < tmar3_yr & tdiv2_yr!=. & tmar3_yr!=.
replace status_b1 = 4 if ems!=6 & yrfirstbirth > tsep2_yr & yrfirstbirth < tmar3_yr & tsep2_yr!=. & tmar3_yr!=.
replace status_b1 = 4 if exmar==1 & inlist(ems,4,5) &  ((yrfirstbirth > tdiv1_yr & tdiv1_yr!=.) | (yrfirstbirth > tsep1_yr & tsep1_yr!=.))

// filling in ones I have to guesstimate
replace status_b1 = 1 if (yrfirstbirth-tyrfirstmarr) <=3 & status_b1==. // assuming if birth within 3 years of married date, you were married
// my concern with using a longer timeline is, for those who it was a while and are divorced, it COULD be with a partner, but we don't have that info, so feel less sure

label define birth_status 1 "Married" 2 "Never Married" 3  "Widowed" 4 "Divorced or Separated"
label values status_b1 birth_status

browse SSUID PNUM exmar ems tyrcurrmarr tyrfirstmarr tmar1_yr tdiv1_yr tmar2_yr tmar3_yr yrfirstbirth status_b1 _merge

save "$SIPP14keep/sipp14_altsample_rel.dta", replace

********************************************************************************
********************************************************************************
********************************************************************************
**# Bookmark #5
* Annualize (step 8)
********************************************************************************
********************************************************************************
********************************************************************************
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
	gen 	start_spartner=spartner 			if monthcode==startmonth
	gen 	last_spartner=spartner 				if monthcode==lastmonth
	gen 	start_spouse=spouse 				if monthcode==startmonth
	gen 	last_spouse=spouse 					if monthcode==lastmonth
	gen 	start_partner=partner 				if monthcode==startmonth
	gen 	last_partner=partner 				if monthcode==lastmonth
	gen 	start_marital_status=marital_status if monthcode==startmonth
	gen 	last_marital_status=marital_status 	if monthcode==lastmonth
	
	// browse SSUID PNUM year monthcode startmonth lastmonth start_marital_status last_marital_status marital_status
	
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
	gen race_sp=.
	gen weeks_employed_sp=.
	gen sex_sp =.
	
	forvalues n=1/22{
	replace ft_pt_sp=to_ft_pt`n' if spart_num==`n'
	replace educ_sp=to_educ`n' if spart_num==`n'
	replace race_sp=to_race`n' if spart_num==`n'
	replace weeks_employed_sp=to_RMWKWJB`n' if spart_num==`n'
	replace sex_sp=to_sex`n' if spart_num==`n'	
	}

	
// getting ready to create indicators of various status changes THROUGHOUT the year
drop _merge
local reshape_vars marital_status hhsize other_earner earnings spartner ft_pt educ renroll ft_pt_sp educ_sp race_sp weeks_employed_sp

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
	
	// indicators of someone leaving or entering household DURING the year
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
		gen partner_gain`m'	=  spartner`m' ==1 & (spartner`l'==. | spartner`l'==0)
		gen partner_lose`m'	=  (spartner`m'==. | spartner`m'==0) & spartner`l' == 1
	}
	
	* egen partner_lose_sum = rowtotal(partner_lose*)
	* browse partner_lose* spartner* if partner_lose_sum > 0
	
	
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

save "$tempdir/reshape_transitions_alt.dta", replace

//*Back to original and testing match

use "$SIPP14keep/sipp14_altsample_rel", clear

drop _merge
merge 1:1 SSUID PNUM panelmonth using "$tempdir/reshape_transitions_alt.dta"

tab marital_status _merge, m // all missing
tab educ _merge, m
drop if _merge==2

drop _merge

	
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
	
	
/* adding column for weight adjustment for partner_lose
bysort SSUID PNUM (year): egen year_left = min(year) if partner_lose==1
bysort SSUID PNUM year (year_left): replace year_left = year_left[1]

browse SSUID PNUM year monthcode partner_lose year_left

gen correction=1
replace correction = ratio if year == year_left

browse SSUID PNUM year monthcode partner_lose year_left ratio correction

sum correction
*/

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

gen earnings_sp=.
gen sex_sp=.
// gen earnings_a_sp=.

forvalues n=1/22{
	// replace earnings_sp=to_TPEARN`n' if spart_num==`n'
	replace earnings_sp=to_earnings`n' if spart_num==`n' // use this one
	replace sex_sp=to_sex`n' if spart_num==`n'	
}

	// Create a combined spouse & partner indicator
*	gen 	spartner=1 	if spouse==1 | partner==1
*	replace spartner=0 	if spouse==0 & partner==0
	
	// Create indicators of partner presence and earnings at the first and last month of observation by year
	gen 	start_spartner=spartner if monthcode==startmonth
	gen 	last_spartner=spartner 	if monthcode==lastmonth
	gen 	start_spouse=spouse if monthcode==startmonth
	gen 	last_spouse=spouse 	if monthcode==lastmonth
	gen 	start_partner=partner if monthcode==startmonth
	gen 	last_partner=partner 	if monthcode==lastmonth
	gen 	start_marital_status=marital_status if monthcode==startmonth
	gen 	last_marital_status=marital_status 	if monthcode==lastmonth
	gen 	st_partner_earn=earnings_sp if monthcode==startmonth
	gen 	end_partner_earn=earnings_sp 	if monthcode==lastmonth
	
// Create basic indictor to identify months observed when data is collapsed
	gen one=1
	
********************************************************************************
* Create annual measures
********************************************************************************
// Creating variables to prep for annualizing

foreach var of varlist employ ft_pt ems_ehc rmnumjobs marital_status occ_code* tjb*_occ{ 
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

foreach var of varlist hhsize minorchildren{
	gen st_`var' = `var'
	gen end_`var' = `var'
}

recode eeitc (.=0)
recode rtanfyn (.=0)
recode rtanfcov (.=0)

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
					no_full_sp educ_change_sp rmwkwjb weeks_employed_sp					///
					program_income tanf_amount rtanfyn									///
			(mean) 	spouse partner numtype2 wpfinwgt   birth 							///  correction scaled_weight
					mom_panel avg_hhsize = hhsize avg_hrs=tmwkhrs avg_earn=earnings  	///
					numearner other_earner thincpovt2 pov_level start_marital_status 	///
					last_marital_status tjb*_annsal1 tjb*_hourly1 tjb*_wkly1  			///
					tjb*_bwkly1 tjb*_mthly1 tjb*_smthly1 tjb*_other1 tjb*_gamt1			///
					eeitc rtanfcov 														///
			(max) 	minorchildren minorbiochildren preschoolchildren minors_fy			///
					prebiochildren race educ race_sp educ_sp sex_sp tceb oldest_age 	///
					ejb*_payhr1 start_spartner last_spartner start_spouse last_spouse	///
					start_partner last_partner tage ageb1 status_b1 tcbyr_1-tcbyr_7		///
					yrfirstbirth														///
			(min) 	tage_fb durmom durmom_1st youngest_age first_wave					///
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

// label define occupation 1 "Management" 2 "STEM" 3 "Education / Legal / Media" 4 "Healthcare" 5 "Service" 6 "Sales" 7 "Office / Admin" 8 "Farming" 9 "Construction" 10 "Maintenance" 11 "Production" 12 "Transportation" 13 "Military" 
label values st_occ_* end_occ_* occupation
label values st_tjb*_occ end_tjb*_occ occ

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
	
save "$SIPP14keep/annual_bw_altsample.dta", replace

********************************************************************************
********************************************************************************
********************************************************************************
**# Bookmark #4
* Getting parts of step 9 I need
********************************************************************************
********************************************************************************
********************************************************************************

sort SSUID PNUM year


********************************************************************************
* Create breadwinning measures
********************************************************************************
// Create a lagged measure of breadwinning

gen bw50L=.
replace bw50L=bw50[_n-1] if PNUM==PNUM[_n-1] & SSUID==SSUID[_n-1] & year==(year[_n-1]+1) in 2/-1 
replace bw50L=. if year==2013 // in wave 1 we have no measure of breadwinning in previous wave
//browse SSUID PNUM year bw50 bw50L

gen bw60L=.
replace bw60L=bw60[_n-1] if PNUM==PNUM[_n-1] & SSUID==SSUID[_n-1] & year==(year[_n-1]+1) in 2/-1 
replace bw60L=. if year==2013 // in wave 1 we have no measure of breadwinning in previous wave

gen monthsobservedL=.
replace monthsobservedL=monthsobserved[_n-1] if PNUM==PNUM[_n-1] & SSUID==SSUID[_n-1] & year==(year[_n-1]+1) in 2/-1 

gen minorbiochildrenL=.
replace minorbiochildrenL=minorbiochildren[_n-1] if PNUM==PNUM[_n-1] & SSUID==SSUID[_n-1] & year==(year[_n-1]+1) in 2/-1 


// Create an indicators for whether individual transitioned into breadwinning for the first time (1) 
*  or has been observed breadwinning in the past (2). There is no measure for wave 1 because
* we cant know whether those breadwinning at wave 1 transitioned or were continuing
* in that status...except for women who became mothers in 2013, but there isn't a good
* reason to adjust code just for duration 0.

gen nprevbw50=0
replace nprevbw50=nprevbw50[_n-1] if PNUM==PNUM[_n-1] & SSUID==SSUID[_n-1] & year==(year[_n-1]+1) in 2/-1 
replace nprevbw50=nprevbw50+1 if bw50[_n-1]==1 & PNUM==PNUM[_n-1] & SSUID==SSUID[_n-1] & year==(year[_n-1]+1)

gen nprevbw60=0
replace nprevbw60=nprevbw60[_n-1] if PNUM==PNUM[_n-1] & SSUID==SSUID[_n-1] & year==(year[_n-1]+1) in 2/-1 
replace nprevbw60=nprevbw60+1 if bw60[_n-1]==1 & PNUM==PNUM[_n-1] & SSUID==SSUID[_n-1] & year==(year[_n-1]+1)

// for some mothers, year of first wave is not the year they appear in our sample. trying an alternate code
bysort SSUID PNUM (year): egen firstyr = min(year)

// browse SSUID PNUM year firstyr

gen trans_bw50=.
replace trans_bw50=0 if bw50==0 & nprevbw50==0
replace trans_bw50=1 if bw50==1 & nprevbw50==0
replace trans_bw50=2 if nprevbw50 > 0
replace trans_bw50=. if year==2013

gen trans_bw60=.
replace trans_bw60=0 if bw60==0 & nprevbw60==0
replace trans_bw60=1 if bw60==1 & nprevbw60==0
replace trans_bw60=2 if nprevbw60 > 0
replace trans_bw60=. if year==2013

gen trans_bw60_alt = trans_bw60
replace trans_bw60_alt=. if year==firstyr // if 2013 isn't the first year in our sample (often bc of not living with biological children)

// this is breadwinner variable to use - eventually need to adust to main one, but want to ensure I don't break any later code)
gen trans_bw60_alt2=.
replace trans_bw60_alt2=0 if bw60==0 & nprevbw60==0 & year==(year[_n-1]+1) // ensuring if mothers drop out of our sample, we account for non-consecutive years
replace trans_bw60_alt2=1 if bw60==1 & nprevbw60==0 & year==(year[_n-1]+1)
replace trans_bw60_alt2=2 if nprevbw60 > 0 & year==(year[_n-1]+1)
replace trans_bw60_alt2=. if year==firstyr

drop nprevbw50 nprevbw60*	

********************************************************************************
* Address missing data & some value labels that dropped off
********************************************************************************
// 	Create a tempory unique person id variable
	sort SSUID PNUM
	
	egen id = concat (SSUID PNUM)
	destring id, gen(idnum)
	format idnum %20.0f
	drop id
	
	unique 	idnum 
	
//
label define educ 1 "Less than HS" 2 "HS Diploma" 3 "Some College" 4 "College Plus"
label values educ educ

label define race 1 "NH White" 2 "Black" 3 "NH Asian" 4 "Hispanic" 5 "Other"
label values race race

label define employ 1 "Full Time" 2 "Part Time" 3 "Not Working - Looking" 4 "Not Working - Not Looking" // this is probably oversimplified at the moment
label values st_employ end_employ employ

replace birth=0 if birth==.
replace firstbirth=0 if firstbirth==.


#delimit ;
label define arel 1 "Spouse"
                  2 "Unmarried partner"
                  3 "Biological parent"
                  4 "Biological child"
                  5 "Step parent"
                  6 "Step child"
                  7 "Adoptive parent"
                  8 "Adoptive child"
                  9 "Grandparent"
                 10 "Grandchild"
                 11 "Biological siblings"
                 12 "Half siblings"
                 13 "Step siblings"
                 14 "Adopted siblings"
                 15 "Other siblings"
                 16 "In-law"
                 17 "Aunt, Uncle, Niece, Nephew"
                 18 "Other relationship"   
                 19 "Foster parent/Child"
                 20 "Other non-relative"
                 99 "self" ;

#delimit cr

label values relationship* arel

// Look at how many respondents first appeared in each wave
tab first_wave wave 

// Look at percent breadwinning (60%) by wave and years of motherhood
// table durmom wave, contents(mean bw60) format(%3.2g)


********************************************************************************
* Variables
********************************************************************************
// Marital status changes
	*First need to calculate those with no status change
	tab no_status_chg
	tab no_status_chg if trans_bw60_alt2==1 & year==2014
	tab no_status_chg if trans_bw60_alt2[_n+1]==1 & year[_n+1]==2014 // samples match when I do like this but with different distributions, and the sample for both matches those who became breadwinners in 2014 (578 at the moment) - which is what I want. However, now concerned that they are not necessarily the same people - hence below
	tab no_status_chg if trans_bw60_alt2[_n+1]==1 & year[_n+1]==2014 & SSUID==SSUID[_n+1] & PNUM==PNUM[_n+1] // we might not always have the year prior, so this makes sure we are still getting data for the same person? - sample drops, which is to be expected

	* quick recode so 1 signals any transition not number of transitions
	foreach var in sing_coh sing_mar coh_mar coh_diss marr_diss marr_wid marr_coh no_status_chg{
	replace `var' = 1 if `var' > 1
	}

// Household changes

	* quick recode so 1 signals any transition not number of transitions
	foreach var in hh_lose earn_lose earn_non hh_gain earn_gain non_earn resp_earn resp_non{
	replace `var' = 1 if `var' > 1
	}

// Job changes - respondent and spouse
	
	* quick recode so 1 signals any transition not number of transitions
	foreach var in full_part full_no part_no part_full no_part no_full no_job_chg full_part_sp full_no_sp part_no_sp part_full_sp no_part_sp no_full_sp no_job_chg_sp educ_change educ_change_sp{
	replace `var' = 1 if `var' > 1
	}
	
// Earnings changes

* Using earnings not tpearn which is the sum of all earnings and won't be negative
* First create a variable that indicates percent change YoY

by SSUID PNUM (year), sort: gen earn_change = ((earnings-earnings[_n-1])/earnings[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
by SSUID PNUM (year), sort: gen earn_change_raw = (earnings-earnings[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]

* then doing for partner specifically
* first get partner specific earnings
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

	gen earnings_sp=.
	gen earnings_a_sp=.

	forvalues n=1/22{
	replace earnings_sp=to_TPEARN`n' if spart_num==`n'
	replace earnings_a_sp=to_earnings`n' if spart_num==`n'
	}

	//check: browse spart_num earnings_sp to_TPEARN* 

replace earnings=0 if earnings==. // this is messing up the hh_earn calculations because not considering as 0
replace earnings_a_sp=0 if earnings_a_sp==. // this is messing up the hh_earn calculations because not considering as 0

* then create variables
by SSUID PNUM (year), sort: gen earn_change_sp = ((earnings_a_sp-earnings_a_sp[_n-1])/earnings_a_sp[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
by SSUID PNUM (year), sort: gen earn_change_raw_sp = (earnings_a_sp-earnings_a_sp[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]

* Variable for all earnings in HH besides R
gen hh_earn=thearn_alt-earnings
by SSUID PNUM (year), sort: gen earn_change_hh = ((hh_earn-hh_earn[_n-1])/hh_earn[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
by SSUID PNUM (year), sort: gen earn_change_raw_hh = (hh_earn-hh_earn[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]

* Variable for all earnings in HH besides R + partner - eventually break this down to WHO? (like child, parent, etc)
gen other_earn=thearn_alt-earnings-earnings_a_sp
by SSUID PNUM (year), sort: gen earn_change_oth = ((other_earn-other_earn[_n-1])/other_earn[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
by SSUID PNUM (year), sort: gen earn_change_raw_oth = (other_earn-other_earn[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]

// coding changes up and down
* Mother
gen earnup8=0
replace earnup8 = 1 if earn_change >=.08000000
replace earnup8=. if earn_change==.
gen earndown8=0
replace earndown8 = 1 if earn_change <=-.08000000
replace earndown8=. if earn_change==.

// browse SSUID PNUM year tpearn earn_change earnup8 earndown8

* partner
gen earnup8_sp=0
replace earnup8_sp = 1 if earn_change_sp >=.08000000
replace earnup8_sp=. if earn_change_sp==.
gen earndown8_sp=0
replace earndown8_sp = 1 if earn_change_sp <=-.08000000
replace earndown8_sp=. if earn_change_sp==.
	

* HH excl mother
gen earnup8_hh=0
replace earnup8_hh = 1 if earn_change_hh >=.08000000
replace earnup8_hh=. if earn_change_hh==.
gen earndown8_hh=0
replace earndown8_hh = 1 if earn_change_hh <=-.08000000
replace earndown8_hh=. if earn_change_hh==.
	
* HH excl mother and partner
gen earnup8_oth=0
replace earnup8_oth = 1 if earn_change_oth >=.08000000
replace earnup8_oth=. if earn_change_oth==.
gen earndown8_oth=0
replace earndown8_oth = 1 if earn_change_oth <=-.08000000
replace earndown8_oth=. if earn_change_oth==.
	
/* Looking at other HH member changes

* First calculate a change measure for all earnings
forvalues n=1/22{
	by SSUID PNUM (year), sort: gen to_earn_change`n' = ((to_earnings`n'-to_earnings`n'[_n-1])/to_earnings`n'[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
}
*/

// Raw hours changes

* First create a variable that indicates percent change YoY
by SSUID PNUM (year), sort: gen hours_change = ((avg_hrs-avg_hrs[_n-1])/avg_hrs[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
browse SSUID PNUM year avg_hrs hours_change

* then doing for partner specifically
* first get partner specific hours

	gen hours_sp=.
	forvalues n=1/22{
	replace hours_sp=avg_to_hrs`n' if spart_num==`n'
	}

	//check: browse spart_num hours_sp avg_to_hrs* 

* then create variables
by SSUID PNUM (year), sort: gen hours_change_sp = ((hours_sp-hours_sp[_n-1])/hours_sp[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]

// coding changes up and down
* Mother
gen hours_up5=0
replace hours_up5 = 1 if hours_change >=.0500000
replace hours_up5=. if hours_change==.
gen hoursdown5=0
replace hoursdown5 = 1 if hours_change <=-.0500000
replace hoursdown5=. if hours_change==.
// browse SSUID PNUM year avg_hrs hours_change hours_up hoursdown

* Partner
gen hours_up5_sp=0
replace hours_up5_sp = 1 if hours_change_sp >=.0500000
replace hours_up5_sp=. if hours_change_sp==.
gen hoursdown5_sp=0
replace hoursdown5_sp = 1 if hours_change_sp <=-.0500000
replace hoursdown5_sp=. if hours_change_sp==.

// Wage variables

* First create a variable that indicates percent change YoY - using just job 1 for now, as that's already a lot of variables
foreach var in ejb1_payhr1 tjb1_annsal1 tjb1_hourly1 tjb1_wkly1 tjb1_bwkly1 tjb1_mthly1 tjb1_smthly1 tjb1_other1 tjb1_gamt1{
by SSUID PNUM (year), sort: gen `var'_chg = ((`var'-`var'[_n-1])/`var'[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]  
}

browse SSUID PNUM year ejb1_payhr1 tjb1_annsal1 tjb1_hourly1 tjb1_wkly1 tjb1_bwkly1 tjb1_mthly1 tjb1_smthly1 tjb1_other1 tjb1_gamt1

egen wage_chg = rowmin (tjb1_annsal1_chg tjb1_hourly1_chg tjb1_wkly1_chg tjb1_bwkly1_chg tjb1_mthly1_chg tjb1_smthly1_chg tjb1_other1_chg tjb1_gamt1_chg)
browse SSUID PNUM year wage_chg tjb1_annsal1_chg tjb1_hourly1_chg tjb1_wkly1_chg tjb1_bwkly1_chg tjb1_mthly1_chg tjb1_smthly1_chg tjb1_other1_chg tjb1_gamt1_chg // need to go back to annual file and fix ejb1_payhr1 to not be a mean

* then doing for partner specifically
* first get partner specific hours

foreach var in EJB1_PAYHR1 TJB1_ANNSAL1 TJB1_HOURLY1 TJB1_WKLY1 TJB1_BWKLY1 TJB1_MTHLY1 TJB1_SMTHLY1 TJB1_OTHER1 TJB1_GAMT1{
gen `var'_sp=.
	forvalues n=1/22{
	replace `var'_sp=to_`var'`n' if spart_num==`n'
	}
}

foreach var in EJB1_PAYHR1_sp TJB1_ANNSAL1_sp TJB1_HOURLY1_sp TJB1_WKLY1_sp TJB1_BWKLY1_sp TJB1_MTHLY1_sp TJB1_SMTHLY1_sp TJB1_OTHER1_sp TJB1_GAMT1_sp{
by SSUID PNUM (year), sort: gen `var'_chg = ((`var'-`var'[_n-1])/`var'[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]  
}

egen wage_chg_sp = rowmin (EJB1_PAYHR1_sp_chg TJB1_ANNSAL1_sp_chg TJB1_HOURLY1_sp_chg TJB1_WKLY1_sp_chg TJB1_BWKLY1_sp_chg TJB1_MTHLY1_sp_chg TJB1_SMTHLY1_sp_chg TJB1_OTHER1_sp_chg TJB1_GAMT1_sp_chg)

// coding changes up and down
* Mother
gen wagesup8=0
replace wagesup8 = 1 if wage_chg >=.0800000
replace wagesup8=. if wage_chg==.
gen wagesdown8=0
replace wagesdown8 = 1 if wage_chg <=-.0800000
replace wagesdown8=. if wage_chg==.
// browse SSUID PNUM year avg_hrs hours_change hours_up hoursdown

* Partner 
gen wagesup8_sp=0
replace wagesup8_sp = 1 if wage_chg_sp >=.0800000
replace wagesup8_sp=. if wage_chg_sp==.
gen wagesdown8_sp=0
replace wagesdown8_sp = 1 if wage_chg_sp <=-.0800000
replace wagesdown8_sp=. if wage_chg_sp==.

local chg_vars "earn_change earn_change_sp earn_change_hh earn_change_oth earn_change_raw earn_change_raw_oth earn_change_raw_hh earn_change_raw_sp hours_change hours_change_sp wage_chg wage_chg_sp earnup8 earndown8 earnup8_sp earndown8_sp earnup8_hh earndown8_hh earnup8_oth earndown8_oth hours_up5 hoursdown5 hours_up5_sp hoursdown5_sp wagesup8 wagesdown8 wagesup8_sp wagesdown8_sp"

foreach var in `chg_vars'{
	gen `var'_m=`var'
	replace `var'=0 if `var'==. // updating so base is full sample, even if not applicable, but retaining a version of the variables with missing just in case
}

// Testing changes from no earnings to earnings for all (Mother, Partner, Others)

by SSUID PNUM (year), sort: gen mom_gain_earn = ((earnings!=. & earnings!=0) & (earnings[_n-1]==. | earnings[_n-1]==0)) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
by SSUID PNUM (year), sort: gen mom_lose_earn = ((earnings==. | earnings==0) & (earnings[_n-1]!=. & earnings[_n-1]!=0)) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
by SSUID PNUM (year), sort: gen part_gain_earn = ((earnings_a_sp!=. & earnings_a_sp!=0) & (earnings_a_sp[_n-1]==. | earnings_a_sp[_n-1]==0)) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
by SSUID PNUM (year), sort: gen part_lose_earn = ((earnings_a_sp==. | earnings_a_sp==0) & (earnings_a_sp[_n-1]!=. & earnings_a_sp[_n-1]!=0)) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
by SSUID PNUM (year), sort: gen hh_gain_earn = ((hh_earn!=. & hh_earn!=0) & (hh_earn[_n-1]==. | hh_earn[_n-1]==0)) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
by SSUID PNUM (year), sort: gen hh_lose_earn = ((hh_earn==. | hh_earn==0) & (hh_earn[_n-1]!=. & hh_earn[_n-1]!=0)) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
by SSUID PNUM (year), sort: gen oth_gain_earn = ((other_earn!=. & other_earn!=0) & (other_earn[_n-1]==. | other_earn[_n-1]==0)) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
by SSUID PNUM (year), sort: gen oth_lose_earn = ((other_earn==. | other_earn==0) & (other_earn[_n-1]!=. & other_earn[_n-1]!=0)) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]

// recoding change variables to account for both changes in earnings for those already earning as well as adding those who became earners

foreach var in earnup8 hours_up5 wagesup8{
	gen `var'_all = `var'
	replace `var'_all=1 if mom_gain_earn==1
}

foreach var in earndown8 hoursdown5 wagesdown8{
	gen `var'_all = `var'
	replace `var'_all=1 if mom_lose_earn==1
}

foreach var in earnup8_sp hours_up5_sp wagesup8_sp{
	gen `var'_all = `var'
	replace `var'_all=1 if part_gain_earn==1
}

foreach var in earndown8_sp hoursdown5_sp wagesdown8_sp{
	gen `var'_all = `var'
	replace `var'_all=1 if part_lose_earn==1
}

foreach var in earnup8_hh{
	gen `var'_all = `var'
	replace `var'_all=1 if hh_gain_earn==1
}

foreach var in earndown8_hh{
	gen `var'_all = `var'
	replace `var'_all=1 if hh_lose_earn==1
}

foreach var in earnup8_oth{
	gen `var'_all = `var'
	replace `var'_all=1 if oth_gain_earn==1
}

foreach var in earndown8_oth{
	gen `var'_all = `var'
	replace `var'_all=1 if oth_lose_earn==1
}


local earn_status_vars "mom_gain_earn mom_lose_earn part_gain_earn part_lose_earn hh_gain_earn hh_lose_earn oth_gain_earn oth_lose_earn"

foreach var in `earn_status_vars'{
	gen `var'_m=`var'
	replace `var'=0 if `var'==.
}

// adding some core overlap views = currently base is total sample, per meeting 3/4, want a consistent view. so, even if woman doesn't have a partner, for now that is 0 not missing

* Mother earnings up, anyone else down
gen momup_anydown=0
replace momup_anydown=1 if earnup8_all==1 & earndown8_hh_all==1
* Mother earnings up, partner earnings down
gen momup_partdown=0
replace momup_partdown=1 if earnup8_all==1 & earndown8_sp_all==1
* Mother earnings up, someone else's earnings down
gen momup_othdown=0
replace momup_othdown=1 if earnup8_all==1 & earndown8_oth_all==1 // this "oth" view is all hh earnings except mom and partner so accounts for other hh earning changes
* Mother earnings up, no one else's earnings changed
gen momup_only=0
replace momup_only=1 if earnup8_all==1 & earndown8_hh_all==0 & earnup8_hh_all==0 // this hh view is all hh earnings eXCEPT MOM so if 0, means no one else changed
* Mother's earnings did not change, HH's earnings down
gen momno_hhdown=0
replace momno_hhdown=1 if earnup8_all==0 & earndown8_all==0 & earndown8_hh_all==1
* Mother earnings did not change, anyone else down
gen momno_anydown=0
replace momno_anydown=1 if earnup8_all==0 & earndown8_all==0 & earndown8_hh_all==1
* Mother's earnings did not change, partner's earnings down
gen momno_partdown=0
replace momno_partdown=1 if earnup8_all==0 & earndown8_all==0 & earndown8_sp_all==1
* Mothers earnings did not change, someone else's earnings went down
gen momno_othdown=0
replace momno_othdown=1 if earnup8_all==0 & earndown8_all==0 & earndown8_oth_all==1
* Mother earnings up, earner left household
gen momup_othleft=0
replace momup_othleft=1 if earnup8_all==1 & earn_lose==1
* Mother earnings did not change, earner left household
gen momno_othleft=0
replace momno_othleft=1 if earnup8_all==0 & earndown8_all==0 & earn_lose==1
* Mother earnings up, relationship ended
gen momup_relend=0
replace momup_relend=1 if earnup8_all==1 & (coh_diss==1 | marr_diss==1)
* Mother earnings did not change, relationship ended
gen momno_relend=0
replace momno_relend=1 if earnup8_all==0 & earndown8_all==0 & (coh_diss==1 | marr_diss==1)
* Mother earnings up, anyone else's earnings up
gen momup_anyup=0
replace momup_anyup=1 if earnup8_all==1 & earnup8_hh_all==1
* Mother earnings up, partner earnings up
gen momup_partup=0
replace momup_partup=1 if earnup8_all==1 & earnup8_sp_all==1
* Mother earnings up, someone else's earnings up
gen momup_othup=0
replace momup_othup=1 if earnup8_all==1 & earnup8_oth_all==1
* Mother earnings down, anyone else's earnings down
gen momdown_anydown=0
replace momdown_anydown=1 if earndown8_all==1 & earndown8_hh_all==1
* Mother earnings down, partner earnings down
gen momdown_partdown=0
replace momdown_partdown=1 if earndown8_all==1 & earndown8_sp_all==1
* Mother earnings down, someone else's earnings down
gen momdown_othdown=0

// adding in sample sizes

egen total_samp = nvals(idnum)
egen bw_samp = nvals(idnum) if trans_bw60_alt2==1
local total_samp = total_samp
local bw_samp = bw_samp
replace momdown_othdown=1 if earndown8_all==1 & earndown8_oth_all==1

// age at first birth categorical variable

recode ageb1 (1/18=1) (19/21=2) (22/25=3) (26/29=4) (30/50=5), gen(ageb1_gp)
label define ageb1_gp 1 "Under 18" 2 "A19-21" 3 "A22-25" 4 "A26-29" 5 "Over 30"
label values ageb1_gp ageb1_gp

save "$SIPP14keep/bw_descriptives_alt.dta", replace

// small things from file aa / ab

rename avg_hrs 		avg_mo_hrs
rename hours_sp		avg_mo_hrs_sp
rename tage_fb 		ageb1_mon

gen yrfirstbirth_ch=year if firstbirth==1
bysort SSUID PNUM (yrfirstbirth_ch): replace yrfirstbirth_ch=yrfirstbirth_ch[1]

gen survey=.
replace survey=1996 if inrange(year,1995,2000)
replace survey=2014 if inrange(year,2013,2016)

// Missing value check - key IVs (DV handled elsewhere / meant to have missing because not always eligible, etc.)
tab race, m
tab educ, m // .02%
drop if educ==.
tab last_marital_status, m // .02%
drop if last_marital_status==.

// adding in lookups for poverty thresholds
browse year SSUID end_hhsize end_minorchildren

merge m:1 year end_hhsize end_minorchildren using "$projcode/stata/poverty_thresholds.dta"

browse year SSUID end_hhsize end_minorchildren threshold

drop if _merge==2
drop _merge

sort SSUID PNUM year

browse SSUID PNUM year bw60 trans_bw60 earnup8_all momup_only earn_lose earndown8_hh_all

// ensure those who became mothers IN panel removed from sample in years they hadn't yet had a baby
browse SSUID PNUM year bw60 trans_bw60 firstbirth yrfirstbirth if mom_panel==1
browse SSUID PNUM year bw60 trans_bw60 firstbirth yrfirstbirth mom_panel
gen bw60_mom=bw60  // need to retain this for future calculations for women who became mom in panel
replace bw60=. if year < yrfirstbirth & mom_panel==1
replace trans_bw60=. if year < yrfirstbirth & mom_panel==1
replace trans_bw60_alt=. if year < yrfirstbirth & mom_panel==1
replace trans_bw60_alt2=. if year < yrfirstbirth & mom_panel==1

svyset [pweight = wpfinwgt]

recode partner_lose (2/6=1)

sort SSUID PNUM year
gen bw60lag = 0 if bw60[_n-1]==0 & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)
replace bw60lag =1 if  bw60[_n-1]==1 & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)

// creating earnings variables adjusted for inflation
gen earnings_adj = earnings
replace earnings_adj = (earnings*$inflate_adj) if survey==1996
	// browse survey earnings earnings_adj
	// tabstat earnings, by(survey)
	// tabstat earnings_adj, by(survey)
gen thearn_adj = thearn_alt
replace thearn_adj = (thearn_alt*$inflate_adj) if survey==1996
gen earnings_sp_adj = earnings_a_sp
replace earnings_sp_adj = (earnings_a_sp*$inflate_adj) if survey==1996

********************************************************************************
* BW event variables
********************************************************************************
*Mt = The proportion of mothers who experienced an increase in earnings. This is equal to the number of mothers who experienced an increase in earnings divided by Dt-1. Mothers only included if no one else in the HH experienced a change.

gen mt_mom = 0
replace mt_mom = 1 if earnup8_all==1 & earn_lose==0 & earndown8_hh_all==0
replace mt_mom = 1 if earn_change > 0 & earn_lose==0 & earn_change_hh==0 & mt_mom==0 // to capture those outside the 8% threshold (v. small amount) - and ONLY if no other household changes happened

*Ft = the proportion of mothers who had their partner lose earnings OR leave. If mothers earnings also went up, they are captured here, not above.
gen ft_partner_down = 0
replace ft_partner_down = 1 if earndown8_sp_all==1 & mt_mom==0 & partner_lose==0 // if partner left, want them there, not here
replace ft_partner_down = 1 if earn_change_sp <0 & earn_change_sp >-.08 & mt_mom==0 & ft_partner_down==0 & partner_lose==0

	* splitting partner down into just partner down, or also mom up - we are going to use these more detailed categories
	gen ft_partner_down_only=0
	replace ft_partner_down_only = 1 if earndown8_sp_all==1 & earnup8_all==0 & mt_mom==0 & partner_lose==0 & ft_partner_down==1
	replace ft_partner_down_only = 1 if earn_change_sp <0 & earn_change_sp >-.08 & earnup8_all==0 & mt_mom==0 & ft_partner_down==1 & partner_lose==0 // so if only changed 8% (mom), still considered partner down only
	
	gen ft_partner_down_mom=0
	replace ft_partner_down_mom = 1 if earndown8_sp_all==1 & earnup8_all==1 & mt_mom==0 & partner_lose==0 & ft_partner_down==1
	replace ft_partner_down_mom = 1 if earn_change_sp <0 & earn_change_sp >-.08 & earnup8_all==1 & mt_mom==0 & ft_partner_down==1 & partner_lose==0

gen ft_partner_leave = 0
replace ft_partner_leave = 1 if partner_lose==1 & mt_mom==0

gen ft_overlap=0
replace ft_overlap = 1 if earn_lose==0 & earnup8_all==1 & earndown8_sp_all==1

*Lt = the proportion of mothers who either stopped living with someone (besides their partner) who was an earner OR someone else in the household's earnings went down (again besides her partner). Partner is main category, so if a partner experienced changes as well as someone else in HH, they are captured above.
gen lt_other_changes = 0
replace lt_other_changes = 1 if (earn_lose==1 | earndown8_oth_all==1) & (mt_mom==0 & ft_partner_down==0 & ft_partner_leave==0)

*validate
// svy: tab survey trans_bw60_alt2, row
svy: tab trans_bw60_alt2 if bw60lag==0,
tab trans_bw60_alt2 if bw60lag==0 // unweighted
tab trans_bw60_alt2 if bw60lag==0 [aweight = wpfinwgt] // validating this is same as svy

// figuring out how to add in mothers who had their first birth in a panel
browse SSUID PNUM year firstbirth bw60 trans_bw60

svy: tab survey firstbirth, row
svy: tab survey firstbirth if bw60_mom==1 & bw60_mom[_n-1]==1 & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1) in 2/-1
tab survey firstbirth if bw60_mom==1 & bw60_mom[_n-1]==1 & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1) in 2/-1 [aweight = wpfinwgt]
unique SSUID if firstbirth==1, by(bw60_mom)

// grouped education
recode educ (1/2=1) (3=2) (4=3), gen(educ_gp)
label define educ_gp 1 "Hs or Less" 2 "Some College" 3 "College Plus"
label values educ_gp educ_gp

// grouped Age at first birth
recode ageb1 (-5/19=1) (20/24=2) (25/29=3) (30/55=4), gen(ageb1_cat)
label define ageb1_cat 1 "Under 20" 2 "A20-24" 3 "A25-29" 4 "Over 30"
label values ageb1_cat ageb1_cat

recode race (1=1) (2=2)(4=3)(3=4)(5=4), gen(race_gp)
label define race_gp 1 "White" 2 "Black" 3 "Hispanic"
label values race_gp race_gp

save "$SIPP14keep/bw_descriptives_alt.dta", replace

********************************************************************************
********************************************************************************
********************************************************************************
**# Bookmark #3
* Consequences (ac / ad)
********************************************************************************
********************************************************************************
********************************************************************************

********************************************************************************
* First create variables
********************************************************************************

* Create dependent variable: income / pov change change
gen inc_pov = thearn_adj / threshold
sort SSUID PNUM year
by SSUID PNUM (year), sort: gen inc_pov_change = ((inc_pov-inc_pov[_n-1])/inc_pov[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==year[_n-1]+1
by SSUID PNUM (year), sort: gen inc_pov_change_raw = (inc_pov-inc_pov[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==year[_n-1]+1

gen in_pov=.
replace in_pov=0 if inc_pov>=1.5 & inc_pov!=.
replace in_pov=1 if inc_pov <1.5

gen inc_pov_lag = inc_pov[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)
gen pov_lag=.
replace pov_lag=0 if inc_pov_lag>=1.5 & inc_pov_lag!=.
replace pov_lag=1 if inc_pov_lag <1.5

* poverty change outcome to use
gen pov_change=.
replace pov_change=0 if in_pov==pov_lag
replace pov_change=1 if in_pov==1 & pov_lag==0
replace pov_change=2 if in_pov==0 & pov_lag==1

label define pov_change 0 "No" 1 "Moved into" 2 "Moved out of"
label values pov_change pov_change

gen pov_change_detail=.
replace pov_change_detail=1 if in_pov==0 & pov_lag==1 // moved out of poverty
replace pov_change_detail=2 if in_pov==pov_lag & pov_lag==0 // stayed out of poverty
replace pov_change_detail=3 if in_pov==pov_lag & pov_lag==1 // stay IN poverty
replace pov_change_detail=4 if in_pov==1 & pov_lag==0 // moved into

label define pov_change_detail 1 "Moved Out" 2 "Stayed out" 3 "Stayed in" 4 "Moved in"
label values pov_change_detail pov_change_detail


// some lagged measures I need
sort SSUID PNUM year
gen earnings_lag = earnings[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)
gen thearn_lag = thearn_adj[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)

* Creating necessary independent variables
 // one variable for all pathways
egen validate = rowtotal(mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes) // make sure moms only have 1 event
browse SSUID PNUM validate mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes trans_bw60_alt2 bw60_mom

gen pathway_v1=0
replace pathway_v1=1 if mt_mom==1
replace pathway_v1=2 if ft_partner_down_mom==1
replace pathway_v1=3 if ft_partner_down_only==1
replace pathway_v1=4 if ft_partner_leave==1
replace pathway_v1=5 if lt_other_changes==1

label define pathway_v1 0 "None" 1 "Mom Up" 2 "Mom Up Partner Down" 3 "Partner Down" 4 "Partner Left" 5 "Other HH Change"
label values pathway_v1 pathway_v1

// more detailed pathway
gen start_from_0 = 0
replace start_from_0=1 if earnings_lag==0

gen pathway=0
replace pathway=1 if mt_mom==1 & start_from_0==1
replace pathway=2 if mt_mom==1 & start_from_0==0
replace pathway=3 if ft_partner_down_mom==1
replace pathway=4 if ft_partner_down_only==1
replace pathway=5 if ft_partner_leave==1
replace pathway=6 if lt_other_changes==1

label define pathway 0 "None" 1 "Mom Up, Not employed" 2 "Mom Up, employed" 3 "Mom Up Partner Down" 4 "Partner Down" 5 "Partner Left" 6 "Other HH Change"
label values pathway pathway

// program variables
gen tanf=0
replace tanf=1 if tanf_amount > 0

// need to get tanf in year prior and then eitc in year after - but this is not really going to work for 2016, so need to think about that
sort SSUID PNUM year
browse SSUID PNUM year rtanfcov tanf tanf_amount program_income eeitc
gen tanf_lag = tanf[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)
gen tanf_amount_lag = tanf_amount[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)
gen program_income_lag = program_income[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)
gen eitc_after = eeitc[_n+1] if SSUID==SSUID[_n+1] & PNUM==PNUM[_n+1] & year==(year[_n+1]-1)

replace earnings_ratio=0 if earnings_ratio==. & earnings==0 & thearn_alt > 0 // wasn't counting moms with 0 earnings -- is this an issue elsewhere?? BUT still leaving as missing if NO earnings. is that right?
gen earnings_ratio_alt=earnings_ratio
replace earnings_ratio_alt=0 if earnings_ratio_alt==. // count as 0 if no earnings (instead of missing)

gen earnings_ratio_lag = earnings_ratio[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)
gen earnings_ratio_alt_lag = earnings_ratio_alt[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)

gen zero_earnings=0
replace zero_earnings=1 if earnings_lag==0

// last_status
recode last_marital_status (1=1) (2=2) (3/5=3), gen(marital_status_t1)
label define marr 1 "Married" 2 "Cohabiting" 3 "Single"
label values marital_status_t1 marr
recode marital_status_t1 (1/2=1)(3=0), gen(partnered_t1)

// first_status
recode start_marital_status (1=1) (2=2) (3/5=3), gen(marital_status_t)
label values marital_status_t marr
recode marital_status_t (1/2=1)(3=0), gen(partnered_t)

// household income change
by SSUID PNUM (year), sort: gen hh_income_chg = ((thearn_adj-thearn_adj[_n-1])/thearn_adj[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1) & trans_bw60_alt2==1
by SSUID PNUM (year), sort: gen hh_income_raw = ((thearn_adj-thearn_adj[_n-1])) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1) & trans_bw60_alt2==1
browse SSUID PNUM year thearn_adj bw60 trans_bw60_alt2 hh_income_chg hh_income_raw
	
by SSUID PNUM (year), sort: gen hh_income_raw_all = ((thearn_adj-thearn_adj[_n-1])) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1) & bw60lag==0
	
inspect hh_income_raw // almost split 50/50 negative v. positive
sum hh_income_raw, detail // i am now wondering - is this the better way to do it?
gen hh_chg_value=.
replace hh_chg_value = 0 if hh_income_raw <0
replace hh_chg_value = 1 if hh_income_raw >0 & hh_income_raw!=.
tab hh_chg_value
sum hh_income_raw if hh_chg_value==0, detail
sum hh_income_raw if hh_chg_value==1, detail

gen end_as_sole=0
replace end_as_sole=1 if earnings_ratio==1

gen partner_zero=0
replace partner_zero=1 if end_partner_earn==0
tab pathway partner_zero, row

** use the single / partnered I created before: single needs to be ALL YEAR
gen single_all=0
replace single_all=1 if partnered_t==0 & no_status_chg==1

gen partnered_all=0
replace partnered_all=1 if partnered_t==1 | single_all==0

gen partnered_no_chg=0
replace partnered_no_chg=1 if partnered_t==1 & no_status_chg==1

gen relationship=.
replace relationship=1 if start_marital_status==1 & partnered_all==1 // married
replace relationship=2 if start_marital_status==2 & partnered_all==1 // cohab
label values relationship marr

gen rel_status=.
replace rel_status=1 if single_all==1
replace rel_status=2 if partnered_all==1
label define rel 1 "Single" 2 "Partnered"
label values rel_status rel

gen rel_status_detail=.
replace rel_status_detail=1 if single_all==1
replace rel_status_detail=2 if partnered_no_chg==1
replace rel_status_detail=3 if pathway==5 // why was this 4 at one point (which was partner down) did I change this?
replace rel_status_detail=2 if partnered_all==1 & rel_status_detail==.

label define rel_detail 1 "Single" 2 "Partnered" 3 "Dissolved"
label values rel_status_detail rel_detail

* other income measures
gen income_change=.
replace income_change=1 if inc_pov_change_raw > 0 & inc_pov_change_raw!=. // up
replace income_change=2 if inc_pov_change_raw < 0 & inc_pov_change_raw!=. // down
label define income 1 "Up" 2 "Down"
label values income_change income

// topcode income change to stabilize outliers - use 1% / 99% or 5% / 95%? should I topcode here or once I restrict sample?
sum hh_income_raw_all, detail
gen hh_income_topcode=hh_income_raw_all
replace hh_income_topcode = `r(p5)' if hh_income_raw_all<`r(p5)'
replace hh_income_topcode = `r(p95)' if hh_income_raw_all>`r(p95)'

gen income_chg_top = hh_income_topcode / thearn_lag

gen hh_income_pos = hh_income_raw_all 
replace hh_income_pos = hh_income_raw_all *-1 if hh_income_raw_all<0
gen log_income = ln(hh_income_pos) // ah does not work with negative numbers
gen log_income_change = log_income
replace log_income_change = log_income*-1 if hh_income_raw_all<0
browse hh_income_raw_all hh_income_pos log_income log_income_change

sum thearn_adj, detail
gen thearn_topcode=thearn_adj
replace thearn_topcode = `r(p99)' if thearn_adj>`r(p99)'
sum thearn_topcode, detail

sum thearn_lag, detail
gen thearn_lag_topcode=thearn_lag
replace thearn_lag_topcode = `r(p99)' if thearn_lag>`r(p99)'
sum thearn_lag_topcode, detail

gen earn_change_raw_x = earn_change_raw
replace earn_change_raw = earnings-earnings_lag

save "$SIPP14keep/bw_income_alt.dta", replace
// browse SSUID PNUM year bw60 bw60lag trans_bw60_alt2 firstbirth yrfirstbirth mom_panel

********************************************************************************
** Restrict to just those who transitioned and then calculate
********************************************************************************

keep if trans_bw60_alt2==1 & bw60lag==0 // first want to see the effect of transitioning on income AMONG eligible mothers

// Replicating Table 3
*A - average pre
tabstat thearn_lag, by(rel_status_detail)
tabstat thearn_lag_topcode, by(rel_status_detail)	
*A - average post
tabstat thearn_adj, by(rel_status_detail)
tabstat thearn_topcode, by(rel_status_detail)		

*A - Average Change
tabstat hh_income_raw, by(rel_status_detail) stats(mean p50) // mean is in paper
*A - HH that gained income
tab rel_status_detail hh_chg_value, row

*B - In hardship pre
tab rel_status_detail pov_lag, row
*B - In hardship post
tab rel_status_detail in_pov, row
*B - Change
*Subtract

*C - Mom's earnings pre
tabstat earnings_lag, by(rel_status_detail)	
*C - Mom's earnings post
tabstat earnings, by(rel_status_detail)	
*C - Change
*Subtract - this works as long as not topcoded

********************************************************************************
**# Bookmark #8
* I might not need these?
********************************************************************************
/* more variables quickly (from file ac)

*Transitions
gen eligible=(bw60lag==0)
replace eligible=. if bw60lag==.
gen transitioned=0
replace transitioned=1 if trans_bw60_alt2==1 & bw60lag==0
replace transitioned=. if trans_bw60_alt2==.

* Marital Status - December of prior year
recode last_marital_status (1=1) (2=2) (3/5=3), gen(marital_status_t1)
label define marr 1 "Married" 2 "Cohabiting" 3 "Single"
label values marital_status_t1 marr

// for JG ask 10/10/22
browse SSUID PNUM year earnings_adj thearn_adj bw60 bw50 earnings_ratio
tab marital_status_t1 bw60 if survey_yr==2, row // 15.41%
unique SSUID PNUM if survey_yr==2 & marital_status_t1==1, by(ever_bw60) // 1633 / 6288 = 25.9%

tab marital_status_t1 bw50 if survey_yr==2, row // 23.34%
unique SSUID PNUM if survey_yr==2 & marital_status_t1==1, by(ever_bw50) // 2251 / 6288 = 35.8%

// need just her percentage of partner earnings
gen wife_ratio = earnings_adj / (earnings_adj + earnings_sp_adj)
browse SSUID PNUM  earnings_adj earnings_sp_adj wife_ratio

gen wife_bw60=.
replace wife_bw60 =0 if wife_ratio <.60 & wife_ratio!=.
replace wife_bw60 =1 if wife_ratio >=.60 & wife_ratio!=.

gen wife_bw50=.
replace wife_bw50 =0 if wife_ratio <.50 & wife_ratio!=.
replace wife_bw50 =1 if wife_ratio >=.50 & wife_ratio!=.

gen wife_bw50_alt=.
replace wife_bw50_alt =0 if wife_ratio <=.50 & wife_ratio!=.
replace wife_bw50_alt =1 if wife_ratio >.50 & wife_ratio!=.


**Exploratory: who's income goes up, down, stays the same
// browse SSUID PNUM year thearn_adj bw60 bw60lag trans_bw60_alt2
sort SSUID PNUM year

by SSUID PNUM (year), sort: gen hh_income_chg = ((thearn_adj-thearn_adj[_n-1])/thearn_adj[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1) & trans_bw60_alt2==1
by SSUID PNUM (year), sort: gen hh_income_raw = ((thearn_adj-thearn_adj[_n-1])) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1) & trans_bw60_alt2==1
browse SSUID PNUM year thearn_adj bw60 trans_bw60_alt2 hh_income_chg hh_income_raw
	
by SSUID PNUM (year), sort: gen hh_income_raw_all = ((thearn_adj-thearn_adj[_n-1])) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1) & bw60lag==0
	
inspect hh_income_raw // almost split 50/50 negative v. positive
sum hh_income_raw, detail // i am now wondering - is this the better way to do it?
gen hh_chg_value=.
replace hh_chg_value = 0 if hh_income_raw <0
replace hh_chg_value = 1 if hh_income_raw >0 & hh_income_raw!=.
tab hh_chg_value
sum hh_income_raw if hh_chg_value==0, detail
sum hh_income_raw if hh_chg_value==1, detail

*Mother's earnings
by SSUID PNUM (year), sort: gen mom_income_raw = ((earnings_adj-earnings_adj[_n-1])) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1) & trans_bw60_alt2==1

*Partner
by SSUID PNUM (year), sort: gen partner_income_raw = ((earnings_sp_adj-earnings_sp_adj[_n-1])) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1) & trans_bw60_alt2==1

recode marital_status_t1 (1/2=1)(3=0), gen(partnered)
recode partnered (0=1)(1=0), gen(single)

// Income-poverty change
browse SSUID year end_hhsize end_minorchildren threshold thearn_adj
gen inc_pov = thearn_adj / threshold

by SSUID PNUM (year), sort: gen inc_pov_change = ((inc_pov-inc_pov[_n-1])/inc_pov[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==year[_n-1]+1
by SSUID PNUM (year), sort: gen inc_pov_change_raw = (inc_pov-inc_pov[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==year[_n-1]+1

replace inc_pov_change = 1 if inc_pov_change==. & inc_pov_change_raw > 0 & inc_pov_change_raw!=.
gen inc_pov_up =.
replace inc_pov_up = 1 if inc_pov_change_raw > 0 & inc_pov_change_raw!=.
replace inc_pov_up = 2 if inc_pov_change==1
replace inc_pov_up = 0 if inc_pov_change_raw < 0 & inc_pov_change_raw!=.

tab inc_pov_up if trans_bw60_alt2==1
sum inc_pov_change_raw if inc_pov_up==1 & trans_bw60_alt2==1, detail
sum inc_pov_change_raw if inc_pov_up==0 & trans_bw60_alt2==1, detail

gen inc_pov_percent=.
replace inc_pov_percent = 1 if inc_pov_change > 0 & inc_pov_change <0.5
replace inc_pov_percent = 2 if inc_pov_change > 0.5 & inc_pov_change!=.
replace inc_pov_percent = 3 if inc_pov_change < 0 & inc_pov_change > -0.5
replace inc_pov_percent = 4 if inc_pov_change < -0.5
replace inc_pov_percent = 5 if inc_pov_change == 1 & inc_pov_change_raw < 1 & inc_pov_change_raw!=.
replace inc_pov_percent = 6 if inc_pov_change == 1 & inc_pov_change_raw >= 1 & inc_pov_change_raw!=.

label define inc_pov_percent 1 "<50% Up" 2 ">50% Up" 3 "<50% Down" 4 ">50% Down" 5 "Change from 0: below 1" 6 "Change from 0: above 1"
label values inc_pov_percent inc_pov_percent

gen inc_pov_move=.
replace inc_pov_move = 1 if inc_pov_change > 0 & inc_pov_change!=.
replace inc_pov_move = 2 if inc_pov_change < 0 & inc_pov_change!=.
replace inc_pov_move = 3 if inc_pov_change == 1

label define inc_pov_move 1 "Ratio Up" 2 "Ratio Down" 3 "Change from 0"
label values inc_pov_move inc_pov_move

gen inc_pov_flag=.
replace inc_pov_flag=1 if inc_pov >=1.5 & inc_pov!=.
replace inc_pov_flag=0 if inc_pov <1.5 & inc_pov!=.

browse SSUID year end_hhsize end_minorchildren threshold thearn_adj inc_pov trans_bw60_alt2 bw60 inc_pov_change inc_pov_change_raw inc_pov_move inc_pov_flag // inc_pov_percent inc_pov_up

tab inc_pov_percent, gen(inc_pov_pct)
tab inc_pov_move, gen(inc_pov_mv)

// 3 buckets we created for FAMDEM
gen inc_pov_summary=.
replace inc_pov_summary=1 if inc_pov_change_raw > 0 & inc_pov_change_raw!=. & inc_pov >=1.5
replace inc_pov_summary=2 if inc_pov_change_raw > 0 & inc_pov_change_raw!=. & inc_pov <1.5
replace inc_pov_summary=3 if inc_pov_change_raw < 0 & inc_pov_change_raw!=.
replace inc_pov_summary=4 if inc_pov_change_raw==0

label define summary 1 "Up, Above Pov" 2 "Up, Not above pov" 3 "Down" 4 "No Change"
label values inc_pov_summary summary

// Breaking out income down to above v. below poverty
gen inc_pov_summary2=.
replace inc_pov_summary2=1 if inc_pov_change_raw > 0 & inc_pov_change_raw!=. & inc_pov >=1.5
replace inc_pov_summary2=2 if inc_pov_change_raw > 0 & inc_pov_change_raw!=. & inc_pov <1.5
replace inc_pov_summary2=3 if inc_pov_change_raw < 0 & inc_pov_change_raw!=. & inc_pov >=1.5
replace inc_pov_summary2=4 if inc_pov_change_raw < 0 & inc_pov_change_raw!=. & inc_pov <1.5
replace inc_pov_summary2=5 if inc_pov_change_raw==0

label define summary2 1 "Up, Above Pov" 2 "Up, Below Pov" 3 "Down, Above Pov" 4 "Down, Below Pov" 5 "No Change"
label values inc_pov_summary2 summary2

browse SSUID year end_hhsize end_minorchildren threshold thearn_adj inc_pov trans_bw60_alt2 bw60 inc_pov_change inc_pov_change_raw inc_pov_move inc_pov_summary // inc_pov_percent inc_pov_up

tab inc_pov_summary if trans_bw60_alt2==1

gen mom_zero_earn=0
replace mom_zero_earn=1 if earnings_adj==0
recode mom_zero_earn (0=1)(1=0), gen(mom_earn)

* Total ratio by year
gen earnings_ratio_mis=earnings_ratio
replace earnings_ratio_mis=0 if earnings_ratio==.

* Pathways
gen pathway=0
replace pathway=1 if mt_mom==1
replace pathway=2 if ft_partner_down_mom==1
replace pathway=3 if ft_partner_down_only==1
replace pathway=4 if ft_partner_leave==1
replace pathway=5 if lt_other_changes==1

label define pathway 0 "None" 1 "Mom Up" 2 "Mom Up Partner Down" 3 "Partner Down" 4 "Partner Left" 5 "Other HH Change"
label values pathway pathway
*/