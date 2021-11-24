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
use "$SIPP96keep/sipp96tpearn_rel.dta", clear

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
	gen 	start_marital_status=marital_status if monthcode==startmonth
	gen 	last_marital_status=marital_status 	if monthcode==lastmonth
	
	// get partner specific variables
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
	gen educ_sp=.

	forvalues n=1/17{
	replace eptwrk_sp=to_eptwrk`n' if spart_num==`n'
	replace educ_sp=to_educ`n' if spart_num==`n'
	}

	
// getting ready to create indicators of various status changes THROUGHOUT the year
drop _merge
local reshape_vars marital_status hhsize other_earner earnings spartner eptwrk educ renroll eptwrk_sp educ_sp

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

	forvalues m=2/51{
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

	forvalues m=2/51{
		local l				=`m'-1
		
		gen hh_lose`m'		=  (hhsize`m' < hhsize`l') & hhsize`l'!=.
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
		
	forvalues m=2/51{
		local l				=`m'-1
		
		gen full_part`m'	=  eptwrk`m'==1 & eptwrk`l'==2
		gen full_no`m'		=  eptwrk`m'==. & eptwrk`l'==2
		gen part_no`m'		=  eptwrk`m'==. & eptwrk`l'==1
		gen part_full`m'	=  eptwrk`m'==2 & eptwrk`l'==1
		gen no_part`m'		=  eptwrk`m'==1 & eptwrk`l'==.
		gen no_full`m'		=  eptwrk`m'==2 & eptwrk`l'==.
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
		
	forvalues m=2/51{
		local l				=`m'-1
		
		gen full_part_sp`m'		=  eptwrk_sp`m'==1 & eptwrk_sp`l'==2
		gen full_no_sp`m'		=  eptwrk_sp`m'==. & eptwrk_sp`l'==2
		gen part_no_sp`m'		=  eptwrk_sp`m'==. & eptwrk_sp`l'==1
		gen part_full_sp`m'		=  eptwrk_sp`m'==2 & eptwrk_sp`l'==1
		gen no_part_sp`m'		=  eptwrk_sp`m'==1 & eptwrk_sp`l'==.
		gen no_full_sp`m'		=  eptwrk_sp`m'==2 & eptwrk_sp`l'==.
		gen educ_change_sp`m'	=  educ_sp`m'>educ_sp`l'
	}
	
		
// Reshape data back to long format
reshape long `reshape_vars' sing_coh sing_mar coh_mar coh_diss marr_diss marr_wid marr_coh ///
hh_lose earn_lose earn_non hh_gain earn_gain non_earn resp_earn resp_non partner_gain partner_lose ///
full_part full_no part_no part_full no_part no_full educ_change enrolled_yes enrolled_no ///
full_part_sp full_no_sp part_no_sp part_full_sp no_part_sp no_full_sp educ_change_sp, i(SSUID PNUM) j(panelmonth)

save "$tempdir/reshape_transitions_96.dta", replace

// exporting table to get 2014 correction

use "$SIPP96keep/sipp96tpearn_rel.dta", clear

drop _merge
merge 1:1 SSUID PNUM panelmonth using "$tempdir/reshape_transitions_96.dta"
drop if _merge==2

// preserve
collapse 	(sum) partner_lose, by(monthcode)
egen total_N=total(partner_lose)
gen distro=partner_lose/total_N
save "$tempdir/96_partner_distro.dta", replace

//*Back to original and testing match

use "$SIPP96keep/sipp96tpearn_rel.dta", clear

drop _merge
merge 1:1 SSUID PNUM panelmonth using "$tempdir/reshape_transitions_96.dta"

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

// Create indicator of birth during the year  -- because fertility module is only in wave 2, aka 1996, we can't really get a robust measure of this. we also only get first and last month of birth, nothing in between.
	gen birth=1 if (yrfirstbirth==year | yrlastbirth==year)
	gen first_birth=1 if (yrfirstbirth==year)
	
// Readding partner status variables

	egen statuses = nvals(marital_status),	by(SSUID ERESIDENCEID PNUM year) // first examining how many people have more than 2 statuses in a year (aka changed status more than 1 time)
	// browse SSUID PNUM panelmonth marital_status statuses // if statuses>2
	tab statuses // okay very small percent - will use last status change OR if I do as separate columns, she can get both captured?
	
	replace spouse	=1 	if spouse 	> 1 // one case has 2 spouses
	replace partner	=1 	if partner 	> 1 // 36 cases of 2-3 partners
	
// creating indicator of year partner left to count person-months to troubleshoot
bysort SSUID PNUM (year): egen year_left = min(year) if partner_lose==1
bysort SSUID PNUM year (year_left): replace year_left = year_left[1]

tab monthcode if year == year_left
	
/* exploration
browse SSUID PNUM year monthcode partner_lose spartner
tab monthcode partner_lose, column

bysort SSUID PNUM year (monthcode): egen month_left = min(monthcode) if partner_lose==1
bysort SSUID PNUM year (month_left): replace month_left = month_left[1]
sort SSUID PNUM year monthcode
browse SSUID PNUM year monthcode panelmonth partner_lose month_left

gen timing_left=.
replace timing_left=0 if monthcode <= month_left & month_left!=.
replace timing_left=1 if monthcode > month_left & month_left!=.
browse SSUID PNUM year monthcode panelmonth partner_lose month_left timing_left

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

	gen earnings_sp=.
	gen earnings_a_sp=.

	forvalues n=1/17{
	replace earnings_sp=to_tpearn`n' if spart_num==`n'
	replace earnings_a_sp=to_earnings`n' if spart_num==`n' // use this one
	}
	
browse SSUID PNUM year monthcode spartner partner_lose earnings earnings_a_sp thearn_alt mbw60 //  ems ems_ehc

// change in earnings within year
gen earnings_z = earnings
replace earnings_z = 0 if earnings==.

by SSUID PNUM (panelmonth), sort: gen earn_change = ((earnings_z -earnings_z[_n-1])/earnings_z [_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & panelmonth==panelmonth[_n-1]+1
by SSUID PNUM (panelmonth), sort: gen earn_change_raw = (earnings_z -earnings_z[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & panelmonth==panelmonth[_n-1]+1

browse SSUID PNUM year monthcode earnings earn_change earn_change_raw

gen earnings_z_sp = earnings_a_sp
replace earnings_z_sp = 0 if earnings_a_sp==.

by SSUID PNUM (panelmonth), sort: gen earn_change_sp = ((earnings_z_sp -earnings_z_sp[_n-1])/earnings_z_sp[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & panelmonth==panelmonth[_n-1]+1
by SSUID PNUM (panelmonth), sort: gen earn_change_raw_sp = (earnings_z_sp -earnings_z_sp[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & panelmonth==panelmonth[_n-1]+1

browse SSUID PNUM year monthcode earnings_z_sp earn_change_sp earn_change_raw_sp

bysort SSUID PNUM year (monthcode): egen month_lost10 = min(monthcode) if earn_change_sp<=-.10000000000000000000
bysort SSUID PNUM year (month_lost10): replace month_lost10 = month_lost10[1]
gen month_lost10_flag = 1 if month_lost10 == monthcode
sort SSUID PNUM year monthcode
browse SSUID PNUM year monthcode panelmonth earnings_z_sp earn_change_sp month_lost10 month_lost10_flag

bysort SSUID PNUM year (monthcode): egen month_lost50 = min(monthcode) if earn_change_sp<=-.5000000000000000000
bysort SSUID PNUM year (month_lost50): replace month_lost50 = month_lost50[1]
gen month_lost50_flag = 1 if month_lost50 == monthcode

bysort SSUID PNUM year (monthcode): egen month_lost100 = min(monthcode) if earn_change_sp<=-1
bysort SSUID PNUM year (month_lost100): replace month_lost100 = month_lost100[1]
gen month_lost100_flag = 1 if month_lost100 == monthcode

sort SSUID PNUM year monthcode
browse SSUID PNUM year monthcode panelmonth earnings_z_sp earn_change_sp month_lost10 month_lost10_flag month_lost50 month_lost50_flag month_lost100 month_lost100_flag

tab monthcode month_lost10_flag, column
tab monthcode month_lost50_flag, column
tab monthcode month_lost100_flag, column

sum earnings_z, detail
sum earn_change, detail
sum earn_change_raw, detail
sum earnings_z_sp, detail
sum earn_change_sp, detail
sum earn_change_raw_sp, detail

preserve

collapse 	(sum) earnings earnings_a_sp thearn_alt to_earnings* /// 
			(mean) partner_lose partner_gain 					///
			(max) relationship*, ///
			by(SSUID PNUM year timing_left)

egen hh_earn_max = rowmax (to_earnings1-to_earnings17)
// browse SSUID PNUM year hh_earn_max earnings to_earnings* 

gen who_max_earn=.
forvalues n=1/17{
replace who_max_earn=relationship`n' if to_earnings`n'==hh_earn_max
}

// browse SSUID PNUM year who_max_earn hh_earn_max earnings to_earnings* relationship*

gen total_max_earner=.
replace total_max_earner=who_max_earn if (earnings==. & hh_earn_max>0 & hh_earn_max!=.) | (hh_earn_max > earnings & earnings!=. & hh_earn_max!=.)
replace total_max_earner=99 if (earnings>0 & earnings!=. & hh_earn_max==.) | (hh_earn_max < earnings & earnings!=. & hh_earn_max!=.)

gen total_max_earner2=total_max_earner
replace total_max_earner2=100 if total_max_earner==99 & (hh_earn_max==0 | hh_earn_max==.) // splitting out the "self" view to delineate between hh where mother is primary earner because she is the only earner

browse SSUID PNUM year who_max_earn hh_earn_max earnings total_max_earner total_max_earner2 to_earnings*


#delimit ;
label define rel2 1 "Spouse"
                  2 "Unmarried partner"
                  10 "Biological parent"
				  11 "Stepparent"
				  12 "Step / adoptive parent"
				  13 "Adoptive parent"
				  14 "Foster parent"
				  15 "Other parent"
                  20 "Biological child"
				  21 "Step child"
                  22 "Step / adopted child"
                  23 "Adoptive child"
                  24 "Foster child"
				  25 "Other child"
				  30 "Bio sib"
				  31 "Half sib"
				  32 "Step sib"
				  33 "Adopted siblings"
				  34 "Other sib"
				  40 "Grandparent"
				  41 "Grandchild"
                  42 "Uncle/ aunt"
				  43 "Nephew / niece"
				  50 "Parent in law"
				  51 "Daughter / son in law"
				  52 "Sibling in law"
				  55 "Other relative"
				  61 "Roommate / housemate"
				  62 "Roomer / boarder"
				  63 "Paid employee"
				  65 "Other non-relative"
                  99 "self" 
				  100 "self - no other earners" ;

#delimit cr

label values who_max_earn total_max_earner* relationship* rel2

gen parent=0
forvalues r=1/17{
    replace parent=parent+1 if inrange(relationship`r',10,15)
}

gen other_rel=0
forvalues r=1/17{
    replace other_rel=other_rel+1 if inrange(relationship`r',30,55)
}

gen other_non_rel=0
forvalues r=1/17{
    replace other_non_rel=other_non_rel+1 if inrange(relationship`r',61,65)
}

browse SSUID PNUM year timing_left parent other_rel other_non_rel

sum parent if timing_left==0
sum parent if timing_left==1
sum other_rel if timing_left==0
sum other_rel if timing_left==1
sum other_non_rel if timing_left==0
sum other_non_rel if timing_left==1

gen parent_enter=0
replace parent_enter=1 if timing_left==1 & timing_left[_n-1]==0 & parent > parent[_n-1]
replace parent_enter=. if timing_left==.

gen rel_enter=0
replace rel_enter=1 if timing_left==1 & timing_left[_n-1]==0 & other_rel > other_rel[_n-1]
replace rel_enter=. if timing_left==.

gen non_rel_enter=0
replace non_rel_enter=1 if timing_left==1 & timing_left[_n-1]==0 & other_non_rel > other_non_rel[_n-1]
replace non_rel_enter=. if timing_left==.

browse SSUID PNUM year timing_left parent other_rel other_non_rel parent_enter rel_enter non_rel_enter

tab parent_enter if timing_left==1
tab rel_enter if timing_left==1
tab non_rel_enter if timing_left==1

gen bw60 = (earnings > .6*thearn_alt) 
gen earnings_ratio = earnings / thearn_alt

sum earnings_ratio if timing_left==1, detail

tab who_max_earn if bw60==1
replace who_max_earn=99 if who_max_earn==. & bw60==1

tab who_max_earn if timing_left==1

bysort SSUID PNUM year: egen total_earnings = total(earnings)
bysort SSUID PNUM year: egen total_hh_earn = total(thearn_alt)
gen total_ratio = total_earnings / total_hh_earn
gen total_bw = (total_ratio>.6)

tab bw60 total_bw if timing_left==1, row

browse SSUID PNUM year timing_left who_max_earn hh_earn_max earnings thearn_alt earnings_a_sp earnings_ratio total_ratio partner_lose partner_gain bw60 if timing_left!=.

restore
			
*/
	
	// Create indicators of partner presence at the first and last month of observation by year
	gen 	start_spartner=spartner if monthcode==startmonth
	gen 	last_spartner=spartner 	if monthcode==lastmonth
	gen 	start_spouse=spouse if monthcode==startmonth
	gen 	last_spouse=spouse 	if monthcode==lastmonth
	gen 	start_partner=partner if monthcode==startmonth
	gen 	last_partner=partner 	if monthcode==lastmonth
	gen 	start_marital_status=marital_status if monthcode==startmonth
	gen 	last_marital_status=marital_status 	if monthcode==lastmonth

	**Partner - want their hours for next step
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

	gen ejbhrs1_sp=.
	gen ejbhrs2_sp=.

	forvalues n=1/17{
	replace ejbhrs1_sp=to_ejbhrs1`n' if spart_num==`n'
	replace ejbhrs2_sp=to_ejbhrs2`n' if spart_num==`n'
	}
	
	* Average hours recode
	replace ejbhrs1_sp=. if ejbhrs1_sp==-1
	replace ejbhrs2_sp=. if ejbhrs2_sp==-1
	egen avg_mo_hrs_sp=rowmean(ejbhrs1_sp ejbhrs2_sp)
	
// Create basic indictor to identify months observed when data is collapsed
gen one=1
	
********************************************************************************
* Create annual measures
********************************************************************************
// Creating variables to facilate the below since a lot of variables share a suffix

foreach var of varlist employ eptwrk ems marital_status{ 
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
					hh_lose earn_lose earn_non hh_gain earn_gain non_earn resp_earn 					///
					resp_non first_birth partner_gain partner_lose										///
					full_part full_no part_no part_full no_part no_full									///
					full_part_sp full_no_sp part_no_sp part_full_sp no_part_sp no_full_sp				///
			(mean) 	spouse partner wpfinwgt birth mom_panel hhsize start_marital_status last_marital_status		///
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
	
	gen earnings_ratio=earnings/thearn_alt if hh_noearnings !=1

	// 50% breadwinning threshold
	* Note that this measure was missing for no (or negative) earnings households, but that is now changed
	gen 	bw50= (earnings > .5*thearn_alt) 	if hh_noearnings !=1 // if earnings missing, techincally larger than this ratio so was getting a 1 here when I removed the missing restriction above, so need to add below
	replace bw50= 0 					if hh_noearnings==1 | earnings==.	

	// 60% breadwinning threshold
	gen 	bw60= (earnings > .6*thearn_alt) 	if hh_noearnings !=1
	replace bw60= 0 					if hh_noearnings==1 | earnings==.
	
	/*
	// 60% breadwinning threshold - old, uses potential negative earnings for tpearn. more different for 1996 than 2014
	gen 	bw60_alt= (tpearn > .6*thearn) 	if hh_noearnings !=1 & !missing(tpearn)
	replace bw60_alt= 0 					if hh_noearnings==1
	*/
	
save "$SIPP96keep/sipp96_annual_bw_status.dta", replace
