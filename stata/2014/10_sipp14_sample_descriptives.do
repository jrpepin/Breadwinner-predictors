*-------------------------------------------------------------------------------
* BREADWINNER PROJECT
* sample_descriptives.do
* Kelly Raley and Joanna Pepin
*-------------------------------------------------------------------------------
di "$S_DATE"
version 16
********************************************************************************
* DESCRIPTION
********************************************************************************
* Create basic descriptive statistics of sample as well as others in the HH

* The data file used in this script was produced by bw_descriptives.do

********************************************************************************
* Import data
********************************************************************************
use "$SIPP14keep/bw_descriptives.dta", clear

********************************************************************************
* Calculating who is primary earner in each HH
********************************************************************************
egen hh_earn_max = rowmax (to_earnings1-to_earnings22)
// browse SSUID PNUM year hh_earn_max earnings to_earnings* 

gen who_max_earn=.
forvalues n=1/22{
replace who_max_earn=relationship`n' if to_earnings`n'==hh_earn_max
}

// browse SSUID PNUM year who_max_earn hh_earn_max earnings to_earnings* relationship*

gen total_max_earner=.
replace total_max_earner=who_max_earn if (earnings==. & hh_earn_max>0 & hh_earn_max!=.) | (hh_earn_max >= earnings & earnings!=. & hh_earn_max!=. & (earnings+hh_earn_max>0))
replace total_max_earner=99 if (earnings>0 & earnings!=. & hh_earn_max==.) | (hh_earn_max < earnings & earnings!=. & hh_earn_max!=.)

gen total_max_earner2=total_max_earner
replace total_max_earner2=100 if total_max_earner==99 & (hh_earn_max==0 | hh_earn_max==.) // splitting out the "self" view to delineate between hh where mother is primary earner because she is the only earner

sort SSUID PNUM year
browse SSUID PNUM year who_max_earn hh_earn_max earnings total_max_earner total_max_earner2 to_earnings* 
replace total_max_earner2=0 if total_max_earner2==.


#delimit ;
label define rel2 1 "Spouse"
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
				 0 "no earners"
                 99 "self" 
				 100 "self - no other earners" ;

#delimit cr

label values who_max_earn total_max_earner* rel2

// put in excel

tabout total_max_earner2 using "$results/Breadwinner_Distro.xls", c(freq col) clab(N Percent) f(0c 1p) replace

forvalues e=1/4{
	tabout total_max_earner2 using "$results/Breadwinner_Distro.xls" if educ==`e', c(freq col) clab(Educ=`e' Percent) f(0c 1p) append 
}


label define marital_status 1 "Married" 2 "Cohabiting" 3 "Widowed" 4 "Dissolved-Unpartnered" 5 "Never Married- Not partnered"
label values st_marital_status end_marital_status marital_status

tab total_max_earner2 if inlist(end_marital_status,3,4,5)

// creating an indicator of whether or not mom lives in extended household, then making a lookup table to match later
gen extended_hh=0

forvalues n=1/22{
replace extended_hh=1 if inlist(relationship`n',3,5,7,9,10,11,12,13,14,15,16,17,18,19,20) // anyone who is not spouse, partner, or child (1,2,4,6,8)
}

preserve
keep SSUID PNUM year total_max_earner2 extended_hh
save "$tempdir/household_lookup.dta", replace
restore

// for impact paper to get earner prior to transition (steps I did in ab)
* Missing value check
tab race, m
tab educ, m // .02%
drop if educ==.
tab last_marital_status, m // .02%
drop if last_marital_status==.

* ensure those who became mothers IN panel removed from sample in years they hadn't yet had a baby
gen bw60_mom=bw60  // need to retain this for future calculations for women who became mom in panel
replace bw60=. if year < yrfirstbirth & mom_panel==1
replace trans_bw60=. if year < yrfirstbirth & mom_panel==1
replace trans_bw60_alt=. if year < yrfirstbirth & mom_panel==1
replace trans_bw60_alt2=. if year < yrfirstbirth & mom_panel==1

sort SSUID PNUM year
gen bw60lag = 0 if bw60[_n-1]==0 & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)
replace bw60lag =1 if  bw60[_n-1]==1 & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)

tab trans_bw60_alt2 if bw60lag==0

tab total_max_earner2 if trans_bw60_alt2==1 & bw60lag==0 // should be all mom? - OKAY IT IS weeeee. so need to get LAGGED max earner?

gen max_earner_lag = total_max_earner2[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)
label values max_earner_lag rel2
browse SSUID PNUM year trans_bw60_alt2  total_max_earner total_max_earner2 max_earner_lag to_earnings* 

tab max_earner_lag if trans_bw60_alt2==1 & bw60lag==0 // so she could be MAX earner, but at like 51% not 60%. or she could be  30, someone else 20, someone else 20, etc. etc.

gen partnered=0
replace partnered=1 if inlist(last_marital_status,1,2)

gen partnered_st=0
replace partnered_st=1 if inlist(start_marital_status,1,2)

gen single_all=0
replace single_all=1 if partnered==0 & no_status_chg==1

gen partnered_all=0
replace partnered_all=1 if partnered_st==1 | single_all==0

gen partnered_no_chg=0
replace partnered_no_chg=1 if partnered_st==1 & no_status_chg==1

* gah
gen rel_status=.
replace rel_status=1 if single_all==1
replace rel_status=2 if partnered_all==1
label define rel 1 "Single" 2 "Partnered"
label values rel_status rel

gen rel_status_detail=.
replace rel_status_detail=1 if single_all==1
replace rel_status_detail=2 if partnered_no_chg==1
replace rel_status_detail=3 if partner_lose==1
replace rel_status_detail=2 if partnered_all==1 & rel_status_detail==.

label define rel_detail 1 "Single" 2 "Partnered" 3 "Dissolved"
label values rel_status_detail rel_detail

tab max_earner_lag if trans_bw60_alt2==1 & bw60lag==0 & partnered==0 // single
tab max_earner_lag if trans_bw60_alt2==1 & bw60lag==0 & partnered_st==0
tab max_earner_lag if trans_bw60_alt2==1 & bw60lag==0 & partnered==0 & no_status_chg==1 // single ALL YEAR, probably cleanest?

tab max_earner_lag if trans_bw60_alt2==1 & bw60lag==0 & partnered==1 // partnered -- need to make this partnered at SOME POINT? maybe get single all year and subtract?
tab max_earner_lag if trans_bw60_alt2==1 & bw60lag==0 & (partnered==1 | single_all==0) // partnered -- need to make this partnered at SOME POINT? maybe get single all year and subtract?

tab max_earner_lag if trans_bw60_alt2==1 & bw60lag==0 
tab max_earner_lag if trans_bw60_alt2==1 & bw60lag==0 & rel_status_detail==1 // single
tab max_earner_lag if trans_bw60_alt2==1 & bw60lag==0 & rel_status_detail==2 // partnered 
tab max_earner_lag if trans_bw60_alt2==1 & bw60lag==0 & rel_status_detail==3 // relationship dissolved

* get percentage of mom's earnings in year prior?  browse SSUID PNUM year thearn_alt earnings earnings_ratio to_earnings* should I do average HH, average mothers OR get the percentage by household, then average? I already have - earnings_ratio
tabstat thearn_alt, stats(mean p50)
tabstat earnings, stats(mean p50)
replace earnings_ratio=0 if earnings_ratio==. & earnings==0 & thearn_alt > 0 // wasn't counting moms with 0 earnings -- is this an issue elsewhere?? BUT still leaving as missing if NO earnings. is that right?
gen earnings_ratio_alt=earnings_ratio
replace earnings_ratio_alt=0 if earnings_ratio_alt==. // count as 0 if no earnings (instead of missing)

gen earnings_ratio_lag = earnings_ratio[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)
tabstat earnings_ratio_lag if trans_bw60_alt2==1 & bw60lag==0, stats(mean p50)
tabstat earnings_ratio_lag if trans_bw60_alt2==1 & bw60lag==0 & partnered==0 & no_status_chg==1, stats(mean p50)
tabstat earnings_ratio_lag if trans_bw60_alt2==1 & bw60lag==0 & (partnered==1 | single_all==0), stats(mean p50)

gen earnings_ratio_alt_lag = earnings_ratio_alt[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)
tabstat earnings_ratio_alt_lag if trans_bw60_alt2==1 & bw60lag==0, stats(mean p50)
tabstat earnings_ratio_alt_lag if trans_bw60_alt2==1 & bw60lag==0 & partnered==0 & no_status_chg==1, stats(mean p50)
tabstat earnings_ratio_alt_lag if trans_bw60_alt2==1 & bw60lag==0 & (partnered==1 | single_all==0), stats(mean p50)

/* Need to revisit all below as it's mostly redundant to file 9 now

********************************************************************************
* Partner descriptive info
********************************************************************************

foreach var in educ_sp race_sp employ_sp occ_sp age_sp tot_hrs_sp avg_hrs_sp{
gen `var'=.
}

forvalues n=1/22{
replace educ_sp=to_educ`n' if spart_num==`n'
replace race_sp=to_race`n' if spart_num==`n'
replace employ_sp=end_to_employ`n' if spart_num==`n'
replace occ_sp=end_to_occ_1`n' if spart_num==`n'
replace age_sp=to_age`n' if spart_num==`n'
replace tot_hrs_sp=to_TMWKHRS`n' if spart_num==`n'
replace avg_hrs_sp=avg_to_hrs`n' if spart_num==`n'
}

//check browse spart_num educ_sp to_educ* 


********************************************************************************
* Create spreadsheet
********************************************************************************

* Create table describing full sample of mothers and analytical sample.

putexcel set "$results/Descriptives60.xlsx", sheet(sample) replace
putexcel A1:D1 = "Characteristics of full sample of mothers and analytical sample", merge border(bottom)
putexcel B2 = ("All Mothers") D2 = ("Analytical sample") F2 = ("Partners"), border(bottom)
putexcel B3 = ("percent") D3 = ("percent") F3 = ("percent"), border(bottom)
putexcel A4 = "Marital Status"
putexcel A5 = " Spouse"
putexcel A6 = " Partner"
putexcel A7 = "Gain Partner" // (gain_partner)
putexcel A8 = "Lost Partner" // (lost_partner)
putexcel A9 = "Additional Birth" // (birth)
putexcel A10 = "Race/Ethnicity"
putexcel A11 = " Non-Hispanic White", txtindent(2)
putexcel A12 = " Black", txtindent(2)
putexcel A13 = " Asian", txtindent(2)
putexcel A14 = " Hispanic", txtindent(2)
putexcel A15 = " Other", txtindent(2)
putexcel A16 = "Education"
putexcel A17 = "Less than High School", txtindent(2)
putexcel A18 = "Diploma/GED", txtindent(2)
putexcel A19 = "Some College", txtindent(2)
putexcel A20 = "College Grad", txtindent(2)
putexcel A21 = "Advanced Degree", txtindent(2)
putexcel A22 = "Employment Status" // (will use end_employ for now)
putexcel A23 = "Full Time", txtindent(2)
putexcel A24 = "Part Time", txtindent(2)
putexcel A25 = "Not Working - Looking", txtindent(2)
putexcel A26 = "Not Working - Not Looking", txtindent(2)
putexcel A27 = "Occupation" // (will use end_occ_1 to start)
putexcel A28 = "Management", txtindent(2)
putexcel A29 = "STEM", txtindent(2)
putexcel A30 = "Education / Legal / Media", txtindent(2)
putexcel A31 = "Healthcare", txtindent(2)
putexcel A32 = "Service", txtindent(2)
putexcel A33 = "Sales", txtindent(2)
putexcel A34 = "Office / Admin", txtindent(2)
putexcel A35 = "Farming", txtindent(2)
putexcel A36 = "Construction", txtindent(2)
putexcel A37 = "Maintenance", txtindent(2)
putexcel A38 = "Production", txtindent(2)
putexcel A39 = "Transportation", txtindent(2)
putexcel A40 = "Military", txtindent(2)
putexcel A41 = "Primary Earner (60%)"


putexcel B42 = ("mean") D42= ("mean") F42= ("mean"), border(bottom)
putexcel A43 = "age"
putexcel A44 = "Years since first birth"
putexcel A45 = "personal earnings"
putexcel A46 = "household earnings"
putexcel A47 = "personal to household earnings ratio"
putexcel A48 = "alt earnings spec" // (earnings)
putexcel A49 = "total hours worked" // (tmwkhrs)
putexcel A50 = "average hours worked" // (avg_hrs)
putexcel A51 = "household size" // (hhsize)
putexcel A52 = "number of earners" // (numearners)
putexcel A53 = "number of minor children" // (minorchildren)
putexcel A54 = "number of preschool age children" // (preschoolchildren)
putexcel A55 = "average age of youngest child" // (youngest_age)
putexcel A56 = "average age of oldest child" // (oldest_age)
putexcel A57 = "average age at first birth" // (tage_fb)
putexcel A58 = "average number of jobs", border(bottom) // (end_rmnumjobs)

putexcel A59 = "unweighted N (individuals)"

********************************************************************************
* Fill in descriptive information
********************************************************************************

*******************************************
// Fill in table for full sample

recode spouse (0=0) (.001/1=1)
recode partner (0=0) (.001/1=1)

mean spouse [aweight=wpfinwgt] 
matrix spouse = 100*e(b)
local pspouse = spouse[1,1]

mean partner [aweight=wpfinwgt] 
matrix partner = 100*e(b)
local ppartner = partner[1,1]

mean gain_partner [aweight=wpfinwgt] 
matrix gain_partner = 100*e(b)
local gain_p = gain_partner[1,1]

mean lost_partner [aweight=wpfinwgt] 
matrix lost_partner = 100*e(b)
local lost_p= lost_partner[1,1]

mean birth [aweight=wpfinwgt] 
matrix birth = 100*e(b)
local birth = birth[1,1]

putexcel B5 = `pspouse', nformat(##.#)
putexcel B6 = `ppartner', nformat(##.#)
putexcel B7 = `gain_p', nformat(##.#)
putexcel B8 = `lost_p', nformat(##.#)
putexcel B9 = `birth', nformat(##.#)

** Full sample

local race "white black asian hispanic other"

forvalues r=1/5 {
   local re: word `r' of `race'
   gen `re' = race==`r'
   mean `re' [aweight=wpfinwgt] 
   matrix m`re' = 100*e(b)
   local p`re' = m`re'[1,1]
   local row = 10+`r'
   putexcel B`row' = `p`re'', nformat(##.#)
}

local ed "lesshs hs somecol univ adv"

forvalues e=1/5 {
   local educ : word `e' of `ed'
   gen `educ' = educ==`e'
   mean `educ' [aweight=wpfinwgt] 
   matrix m`educ' = 100*e(b)
   local p`educ' = m`educ'[1,1]
   local row = 16+`e'
   putexcel B`row' = `p`educ'', nformat(##.#)
}

local jobst "ft pt nwl nwnl"

forvalues j=1/4 {
   local job : word `j' of `jobst'
   gen `job' = end_employ==`j'
   mean `job' [aweight=wpfinwgt] 
   matrix m`job' = 100*e(b)
   local p`job' = m`job'[1,1]
   local row = 22+`j'
   putexcel B`row' = `p`job'', nformat(##.#)
}

local oc "mgmt stem educ_leg health serv sales off farm constr main prod trans mil"

forvalues o=1/13 {
   local occ : word `o' of `oc'
   gen `occ' = end_occ_1==`o'
   mean `occ' [aweight=wpfinwgt] 
   matrix m`occ' = 100*e(b)
   local p`occ' = m`occ'[1,1]
   local row = 27+`o'
   putexcel B`row' = `p`occ'', nformat(##.#)
}

mean bw60 [aweight=wpfinwgt] 
matrix mbw60 = 100*e(b)
local pbw60 = mbw60[1,1]
putexcel B41 = `pbw60', nformat(##.#)

local means "tage durmom tpearn thearn earnings_ratio earnings tmwkhrs avg_hrs hhsize numearner minorchildren preschoolchildren youngest_age oldest_age tage_fb end_rmnumjobs"

forvalues m=1/16{
    local var: word `m' of `means'
    mean `var' [aweight=wpfinwgt] 
    matrix m`var' = e(b)
    local v`m' = m`var'[1,1]
    local row = `m'+42
    putexcel B`row' = `v`m'', nformat(##.#)
}

egen	obvsfs 	= nvals(idnum)
local fs = obvsfs

putexcel B59 = `fs'

*******************************************
// Fill in table for full samples' partners

local race "white_sp black_sp asian_sp hispanic_sp other_sp"

forvalues r=1/5 {
   local re: word `r' of `race'
   gen `re' = race_sp==`r' if !missing(race_sp)
   mean `re' [aweight=wpfinwgt] 
   matrix m`re' = 100*e(b)
   local p`re' = m`re'[1,1]
   local row = 10+`r'
   putexcel F`row' = `p`re'', nformat(##.#)
}

local ed "lesshs_sp hs_sp somecol_sp univ_sp adv_sp"

forvalues e=1/5 {
   local educ : word `e' of `ed'
   gen `educ' = educ_sp==`e' if !missing(educ_sp)
   mean `educ' [aweight=wpfinwgt] 
   matrix m`educ' = 100*e(b)
   local p`educ' = m`educ'[1,1]
   local row = 16+`e'
   putexcel F`row' = `p`educ'', nformat(##.#)
}

local jobst "ft_sp pt_sp nwl_sp nwnl_sp"

forvalues j=1/4 {
   local job : word `j' of `jobst'
   gen `job' = employ_sp==`j' if !missing(employ_sp)
   mean `job' [aweight=wpfinwgt] 
   matrix m`job' = 100*e(b)
   local p`job' = m`job'[1,1]
   local row = 22+`j'
   putexcel F`row' = `p`job'', nformat(##.#)
}

local oc "mgmt_sp stem_sp educ_leg_sp health_sp serv_sp sales_sp off_sp farm_sp constr_sp main_sp prod_sp trans_sp mil_sp"

forvalues o=1/13 {
   local occ : word `o' of `oc'
   gen `occ' = occ_sp==`o' if !missing(occ_sp)
   mean `occ' [aweight=wpfinwgt] 
   matrix m`occ' = 100*e(b)
   local p`occ' = m`occ'[1,1]
   local row = 27+`o'
   putexcel F`row' = `p`occ'', nformat(##.#)
}

local means "age_sp earnings_sp earnings_a_sp tot_hrs_sp avg_hrs_sp"
local rowval "43 45 48 49 50"

forvalues m=1/5{
    local var: word `m' of `means'
    mean `var' [aweight=wpfinwgt] 
    matrix m`var' = e(b)
    local v`m' = m`var'[1,1]
    local row: word `m' of `rowval'
    putexcel F`row' = `v`m'', nformat(##.#)
}

*******************************************
// keep only observations with data in the current waves
keep if !missing(monthsobserved)

tab durmom

	egen	obvsnow 	= nvals(idnum)
	global 	obvsnow_n 	= obvsnow
	di "$obvsnow_n"

// and the previous wave, the only cases where we know about a *transition*
// except in year where woman becomes a mother. 
keep if !missing(monthsobservedL) | durmom==0 

tab durmom

	egen	obvsprev 	= nvals(idnum)
	global 	obvsprev_n 	= obvsprev
	di "$obvsprev_n"

	drop idnum obvsnow obvsprev

** Analytical sample

mean spouse [aweight=wpfinwgt] 
matrix sspouse = 100*e(b)
local pspouse = sspouse[1,1]

mean partner [aweight=wpfinwgt] 
matrix spartner = 100*e(b)
local ppartner = spartner[1,1]

mean gain_partner [aweight=wpfinwgt] 
matrix gain_partner = 100*e(b)
local gain_p = gain_partner[1,1]

mean lost_partner [aweight=wpfinwgt] 
matrix lost_partner = 100*e(b)
local lost_p= lost_partner[1,1]

mean birth [aweight=wpfinwgt] 
matrix birth = 100*e(b)
local birth = birth[1,1]

putexcel D5 = `pspouse', nformat(##.#)
putexcel D6 = `ppartner', nformat(##.#)
putexcel D7 = `gain_p', nformat(##.#)
putexcel D8 = `lost_p', nformat(##.#)
putexcel D9 = `birth', nformat(##.#)

local race "white black asian hispanic other"

forvalues r=1/5 {
   local re: word `r' of `race'
   mean `re' [aweight=wpfinwgt] 
   matrix sm`re' = 100*e(b)
   local p`re' = sm`re'[1,1]
   local row = 10+`r'
   putexcel D`row' = `p`re'', nformat(##.#)
}


local ed "lesshs hs somecol univ adv"

forvalues e=1/5 {
   local educ : word `e' of `ed'
   mean `educ' [aweight=wpfinwgt] 
   matrix m`educ' = 100*e(b)
   local p`educ' = m`educ'[1,1]
   local row = 16+`e'
   putexcel D`row' = `p`educ'', nformat(##.#)
}

local jobst "ft pt nwl nwnl"

forvalues j=1/4 {
   local job : word `j' of `jobst'
   mean `job' [aweight=wpfinwgt] 
   matrix m`job' = 100*e(b)
   local p`job' = m`job'[1,1]
   local row = 22+`j'
   putexcel D`row' = `p`job'', nformat(##.#)
}

local oc "mgmt stem educ_leg health serv sales off farm constr main prod trans mil"

forvalues o=1/13 {
   local occ : word `o' of `oc'
   mean `occ' [aweight=wpfinwgt] 
   matrix m`occ' = 100*e(b)
   local p`occ' = m`occ'[1,1]
   local row = 27+`o'
   putexcel D`row' = `p`occ'', nformat(##.#)
}

mean bw60 [aweight=wpfinwgt] 
matrix mbw60 = 100*e(b)
local pbw60 = mbw60[1,1]
putexcel D41 = `pbw60'

local means "tage durmom tpearn thearn earnings_ratio earnings tmwkhrs avg_hrs hhsize numearner minorchildren preschoolchildren youngest_age oldest_age tage_fb end_rmnumjobs"
forvalues m=1/16{
    local var: word `m' of `means'
    mean `var' [aweight=wpfinwgt] 
    matrix sm`var' = e(b)
    local v`m' = sm`var'[1,1]
    local row = `m'+42
    putexcel D`row' = `v`m'', nformat(##.#)
}

putexcel D59 = $obvsprev_n

save "$SIPP14keep/bw_descriptives.dta", replace
*/
