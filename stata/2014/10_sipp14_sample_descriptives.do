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
replace total_max_earner=who_max_earn if (earnings==. & hh_earn_max>0 & hh_earn_max!=.) | (hh_earn_max > earnings & earnings!=. & hh_earn_max!=.)
replace total_max_earner=99 if (earnings>0 & earnings!=. & hh_earn_max==.) | (hh_earn_max < earnings & earnings!=. & hh_earn_max!=.)

gen total_max_earner2=total_max_earner
replace total_max_earner2=100 if total_max_earner==99 & (hh_earn_max==0 | hh_earn_max==.) // splitting out the "self" view to delineate between hh where mother is primary earner because she is the only earner

browse SSUID PNUM year who_max_earn hh_earn_max earnings total_max_earner total_max_earner2 to_earnings*


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
                 99 "self" 
				 100 "self - no other earners" ;

#delimit cr

label values who_max_earn total_max_earner* rel2

// put in excel

tabout total_max_earner2 using "$results/Breadwinner_Distro.xls", c(freq col) clab(N Percent) f(0c 1p) replace

forvalues e=1/4{
	tabout total_max_earner2 using "$results/Breadwinner_Distro.xls" if educ==`e', c(freq col) clab(Educ=`e' Percent) f(0c 1p) append 
}

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
