*-------------------------------------------------------------------------------
* BREADWINNER PROJECT
* bw_transitions.do
* Kelly Raley and Joanna Pepin
*-------------------------------------------------------------------------------
di "$S_DATE"

********************************************************************************
* DESCRIPTION
********************************************************************************
* Create basic descriptive statistics of sample as well as others in the HH

* The data file used in this script was produced by annualize.do
* It is restricted to mothers living with minor children.

********************************************************************************
* Import data
********************************************************************************
use "$SIPP14keep/annual_bw_status.dta", clear

********************************************************************************
* Address missing data
********************************************************************************
// 	Create a tempory unique person id variable
	sort SSUID PNUM
	
	egen id = concat (SSUID PNUM)
	destring id, gen(idnum)
	format idnum %20.0f
	drop id
	
	unique 	idnum 
	
/* / Make sure starting sample size is consistent. // currently not working but I think this is because I edited things - revisit this later
	egen newsample2 = nvals(idnum) 
	global newsamplesize2 = newsample2
	di "$newsamplesize2"

	di "$newsamplesize"
	di "$newsamplesize2"

	if ("$newsamplesize" == "$newsamplesize2") {
		display "Success! Sample sizes consistent."
		}
		else {
		display as error "The sample size is different than annualize."
		exit
		}
*/

label define educ 1 "Less than HS" 2 "HS Diploma" 3 "Some College" 4 "College Degree" 5 "Advanced Degree"
label values educ educ

label define race 1 "NH White" 2 "NH Black" 3 "NH Asian" 4 "Hispanic" 5 "Other"
label values race race

label define occupation 1 "Management" 2 "STEM" 3 "Education / Legal / Media" 4 "Healthcare" 5 "Service" 6 "Sales" 7 "Office / Admin" 8 "Farming" 9 "Construction" 10 "Maintenance" 11 "Production" 12 "Transportation" 13 "Military" 
label values st_occ* end_occ* occupation

label define employ 1 "Full Time" 2 "Part Time" 3 "Not Working - Looking" 4 "Not Working - Not Looking" // this is probably oversimplified at the moment
label values st_employ end_employ employ

// Look at how many respondents first appeared in each wave
tab first_wave wave 

// Look at percent breadwinning (60%) by wave and years of motherhood
table durmom wave, contents(mean bw60) format(%3.2g)

********************************************************************************
* Create spreadsheet
********************************************************************************

* Create table describing full sample of mothers and analytical sample.

putexcel set "$results/Descriptives60.xlsx", sheet(sample) replace
putexcel A1:D1 = "Characteristics of full sample of mothers and analytical sample", merge border(bottom)
putexcel B2 = ("All Mothers") D2 = ("Analytical sample"), border(bottom)
putexcel B3 = ("percent") D3 = ("percent"), border(bottom)
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


putexcel B42 = ("mean") D42= ("mean"), border(bottom)
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

// Fill in table for full sample

recode spouse (0=0) (.001/1=1)
recode partner (0=0) (.001/1=1)

mean spouse [aweight=wpfinwgt] 
matrix spouse = 100*e(b)
local pspouse = spouse[1,1]

mean partner [aweight=wpfinwgt] 
matrix partner = 100*e(b)
local ppartner = partner[1,1]

putexcel B5 = `pspouse', nformat(##.#)
putexcel B6 = `ppartner', nformat(##.#)

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


// keep only observations with data in the current waves
keep if !missing(monthsobserved)

tab durmom

	egen	obvsnow 	= nvals(idnum)
	global 	obvsnow_n 	= obvsnow
	di "$obvsnow_n"

// and the previous wave, the only cases where we know about a *transition*
// except in year where woman becomes a mother. 
keep if !missing(monthsobserved) | durmom==0 // was there supposed to be an L here? I maybe cut this out

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

putexcel D5 = `pspouse', nformat(##.#)
putexcel D6 = `ppartner', nformat(##.#)


forvalues r=1/5 {
   local re: word `r' of `race'
   mean `re' [aweight=wpfinwgt] 
   matrix sm`re' = 100*e(b)
   local p`re' = sm`re'[1,1]
   local row = 10+`r'
   putexcel D`row' = `p`re'', nformat(##.#)
}


forvalues e=1/5 {
   local educ : word `e' of `ed'
   mean `educ' [aweight=wpfinwgt] 
   matrix m`educ' = 100*e(b)
   local p`educ' = m`educ'[1,1]
   local row = 16+`e'
   putexcel D`row' = `p`educ'', nformat(##.#)
}

forvalues j=1/4 {
   local job : word `j' of `jobst'
   mean `job' [aweight=wpfinwgt] 
   matrix m`job' = 100*e(b)
   local p`job' = m`job'[1,1]
   local row = 22+`j'
   putexcel D`row' = `p`job'', nformat(##.#)
}


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