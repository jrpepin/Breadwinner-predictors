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

use "$SIPP96keep/sipp96_data.dta", clear

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
browse tpearn earnings tpmsum1 tpmsum2 tbmsum1 tbmsum2 tprftb1 tprftb2 ejobcntr ebuscntr 
	egen profits=rowtotal(tbmsum1 tbmsum2), missing
	egen tpearn_calculated = rowtotal(earnings profits), missing
	
	browse tpearn earnings profits tpearn_calculated tpmsum1 tpmsum2 tbmsum1 tbmsum2 eclwrk1 eclwrk2 // not sure any of these are self-employed. Maybe 6?
	tabstat profits, by(eclwrk1)

	// browse earnings tpearn
	gen check_e=.
	replace check_e=0 if earnings!=tpearn & tpearn!=.
	replace check_e=1 if earnings==tpearn
	tab check_e, m
	
	gen check_e2=0
	replace check_e2=0 if tpearn_calculated!=tpearn & tpearn!=.
	replace check_e2=1 if tpearn_calculated==tpearn
	tab check_e2, m // okay, so with profits added, essentially 100% match (99.5%)
	
	egen thearn_alt = total(earnings), 	by(SSUID ERESIDENCEID swave monthcode) // how different is a HH measure based on earnings v. tpearn?
	// browse SSUID thearn thearn_alt

// Count number of earners in hh per month
    egen numearner = count(earnings) if earnings>0,	by(SSUID ERESIDENCEID swave monthcode)

// Create an indicator of first wave of observation for this individual

    egen first_wave = min(swave), by(SSUID PNUM)	
	
// Create an indictor of the birth year of the first child - using the variables that already exist, but leaving names to be consistent with 2014, for when we merge
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
replace mom_panel=1 if inrange(yrfirstbirth, 1995, 2000) // flag if became a mom during panel to use later - note, since the topical module was in 1996, anyone with a birth during the panel not captured here - I handle this below with the counts of children

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


* employment changes: 

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


* Welfare use
foreach var in rcutyp20 rcutyp21 rcutyp24 rcutyp25 rcutyp27 rhnbrf rhcbrf rhmtrf{
replace `var' =0 if `var'==2
}

* scalings weights to use before I combine with 2014
summarize wpfinwgt
local rescalefactor `r(N)'/`r(sum)'
display `rescalefactor'
gen scaled_weight = .
replace scaled_weight = wpfinwgt*`rescalefactor'
summarize scaled_weight

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
qui unique PNUM if person==3 & tage <=1 & epnmom!=., by(ssuid_month) generate(num_babies)
bysort SSUID panelmonth (num_babies): replace num_babies = num_babies[1] if (PNUM==hhmom1 | PNUM==hhmom2)

// Merge in number of children saved in step d
drop _merge

/*
** using household roster to identify births
merge 1:1 SSUID shhadid panelmonth PNUM using "$tempdir/mom_children_lookup96.dta", keepusing(mom_children mom_bio_children)
drop if _merge==2 // not in my sample
drop _merge

replace mom_children=0 if mom_children==.
replace mom_bio_children=0 if mom_bio_children==.

browse SSUID PNUM panelmonth num_babies mom_children mom_bio_children rfownkid rfoklt18 num_children

sort SSUID PNUM panelmonth
gen any_child_inpanel=0
replace any_child_inpanel=(mom_bio_children-mom_bio_children[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] // & panelmonth==panelmonth[_n-1]+1
gen year_birth=year if any_child_inpanel>=1 & any_child_inpanel!=.
bysort SSUID PNUM (year_birth): replace year_birth=year_birth[1]
replace any_child_inpanel=0 if any_child_inpanel<0
replace any_child_inpanel=1 if any_child_inpanel>0 & any_child_inpanel!=.

sort SSUID PNUM panelmonth
gen first_child_inpanel=0
replace first_child_inpanel=1 if (mom_bio_children>0 & mom_bio_children[_n-1]==0) & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] // & panelmonth==panelmonth[_n-1]+1
gen year_first_birth=year if first_child_inpanel>=1 & first_child_inpanel!=.
bysort SSUID PNUM (year_first_birth): replace year_first_birth=year_first_birth[1]
replace first_child_inpanel=0 if first_child_inpanel<0
replace first_child_inpanel=1 if first_child_inpanel>0 & first_child_inpanel!=.

browse SSUID PNUM panelmonth num_babies mom_bio_children any_child_inpanel first_child_inpanel mom_panel year_birth year_first_birth yrfirstbirth

gen yrfirstbirth2=yrfirstbirth
replace yrfirstbirth2=year_first_birth if yrfirstbirth2==. & year_first_birth!=.

gen mom_panel2=mom_panel
replace mom_panel2=1 if first_child_inpanel==1 & yrfirstbirth==. & yrfirstbirth2!=. 
bysort SSUID PNUM (mom_panel2): replace mom_panel2=mom_panel2[1]

browse SSUID PNUM year panelmonth num_babies mom_bio_children any_child_inpanel first_child_inpanel mom_panel year_birth year_first_birth yrfirstbirth mom_panel2 yrfirstbirth2 durmom_1st
browse SSUID PNUM year panelmonth num_babies mom_bio_children any_child_inpanel first_child_inpanel mom_panel year_birth year_first_birth yrfirstbirth mom_panel2 yrfirstbirth2 durmom_1st if yrfirstbirth==. & yrfirstbirth2!=. // I think I want THESE moms right?
unique SSUID PNUM if mom_panel==1
unique SSUID PNUM if mom_panel2==1 & yrfirstbirth==. & yrfirstbirth2!=.  /// so these are just the EXTRA moms, for full picutre, I need all.
*/

/* Create an indicator of how many years have elapsed since individual's first birth
replace durmom_1st=year-year_first_birth if durmom_1st==. & !missing(year_first_birth)
*/

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
	global allindividuals96 = all
	di "$allindividuals96"
	
	egen all_py = count(idnum)
	global allpersonyears96 = all_py
	di "$allpersonyears96"


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
	global 	women_n96 = women
	di "$women_n96"
	
	egen	women_py96	= count(idnum)
	global 	women_py96 = women_py96
	di "$women_py96"

// Only keep mothers
	tab 	durmom_1st, m
	unique 	idnum 	if durmom_1st ==.  // Not mothers
	keep 		 	if durmom_1st !=.  // Keep only mothers
	
	// Creates a macro with the total number of mothers in the dataset.
	egen	mothers = nvals(idnum)
	global mothers_n96 = mothers
	di "$mothers_n96"
	
	egen	mothers_py = count(idnum)
	global mothers_py96 = mothers_py
	di "$mothers_py96"

* Keep mothers that meet our criteria: 18 years or less since last birth OR became a mother during panel (we want data starting 1 year prior to motherhood)
	keep if (durmom>=0 & durmom < 19) | (mom_panel==1 & durmom_1st>=-1)
	
	// Creates a macro with the total number of mothers left in the dataset.
	egen	mothers_sample = nvals(idnum)
	global mothers_sample_n96 = mothers_sample
	di "$mothers_sample_n96"
	
	egen	mothers_sample_py = count(idnum)
	global mothers_sample_py96 = mothers_sample_py
	di "$mothers_sample_py96"
	
	
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
	di "$mothers_sample_n96"
	di "$newsamplesize"

	if ("$newsamplesize" == "$mothers_sample_n96") {
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
	
// identify mothers who resided with their biological children for a full year
	gen minors_m1=.
	replace minors_m1=1 if num_minors>=1 & monthcode==1
	bysort SSUID PNUM year (minors_m1): replace minors_m1 = minors_m1[1]
	gen minors_m12=.
	replace minors_m12=1 if num_minors>=1 & monthcode==12
	bysort SSUID PNUM year (minors_m12): replace minors_m12 = minors_m12[1]
	gen minors_fy=0
	replace minors_fy=1 if minors_m12==1 & minors_m1==1

	browse SSUID PNUM year monthcode minors_m1 minors_m12 minors_fy num_minors
	
	unique 	idnum 	if minors_fy >= 1  

// identify mothers who resided with their children at some point in the panel
	bysort SSUID PNUM: egen maxchildren=max(num_minors)
	unique idnum if maxchildren >=1
	
	gen children_yn=num_minors
	replace children_yn=1 if inrange(num_minors,1,11)
	
	gen children_ever=maxchildren
	replace children_ever=1 if inrange(maxchildren,1,10)
	
	keep if maxchildren >= 1 | mom_panel==1	// Keep only moms with kids in household. for those who became a mom in the panel, I think sometimes child not recorded in 1st year of birth
	
// Final sample size
	egen		hhmom	= nvals(idnum)
	global 		hhmom_n96 = hhmom
	di "$hhmom_n96"
	
	egen		hhmom_py	= count(idnum)
	global 		hhmom_py96 = hhmom_py
	di "$hhmom_py96"


// Creates a macro with the total number of mothers in the dataset.
preserve
	keep			if num_minors >=1
	cap drop 	hhmom
	egen		hhmom	= nvals(idnum)
	global 		hhmom_n = hhmom
	di "$hhmom_n"
	drop idnum hhmom
restore


// create output of sample size with restrictions
dyndoc "$SIPP1996_code/sample_size_1996.md", saving($results/sample_size_1996.html) replace

// drop mom_panel
// rename mom_panel2 mom_panel

// drop yrfirstbirth
// rename yrfirstbirth2 yrfirstbirth

compress
save "$SIPP96keep/sipp96tpearn_all", replace
