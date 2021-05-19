*-------------------------------------------------------------------------------
* BREADWINNER PROJECT
* decomposition_equation.do
* Kelly Raley and Joanna Pepin
*-------------------------------------------------------------------------------
di "$S_DATE"

********************************************************************************
* DESCRIPTION
********************************************************************************
* This file pulls values for the decomposition equation

* File used was created in aa_combined_models.do

use "$combined_data/combined_annual_bw_status.dta", clear

drop if year==1995 // at most, respondents were observed one month in 1995. Not enough data here.

sort SSUID PNUM year

*browse SSUID PNUM year bw60 trans_bw60 earnup8_all momup_only earn_lose earndown8_hh_all
// browsing is a good way to check your logic, but you won't catch rare inconsistencies this way

// ensure those who became mothers IN panel removed from sample in years they hadn't yet had a baby
*browse SSUID PNUM year bw60 trans_bw60 firstbirth yrfirstbirth if mom_panel==1
gen bw60_mom=bw60  // need to retain this for future calculations for women who became mom in panel
replace bw60=. if year < yrfirstbirth & mom_panel==1
replace trans_bw60=. if year < yrfirstbirth & mom_panel==1
replace trans_bw60_alt=. if year < yrfirstbirth & mom_panel==1
replace trans_bw60_alt2=. if year < yrfirstbirth & mom_panel==1

svyset [pweight = wpfinwgt]

recode partner_lose (2/6=1)

********************************************************************************
* First specification: "partner" is reference category, rest are unique
********************************************************************************

*Dt-l: mothers not breadwinning at t-1
svy: tab survey bw60 if year==(year[_n+1]-1), row // to ensure consecutive years, aka she is available to transition to BW the next year
// NOTE THAT THIS ISN'T PERFECT. Sometimes year==(year[_n+1]-1), but the previous record is from a different person.
// this SHOULD be tab survey bw60 if year==(year[_n+1]-1) & (SSUID==SSUID[_n+1] & PNUM==PNUM[_n+1]), row
// tab survey bw60 if year==(year[_n+1]-1)

// let me show you that this is true:
gen prev_year = (year==(year[_n+1]-1))
// this creates a dummy variable for whether the previous observation is from the same person the year earlier
gen same_person = ((SSUID==SSUID[_n+1] & PNUM==PNUM[_n+1]) & year==(year[_n+1]-1)) 

tab prev_year same_person
// If year==(year[_n+1]-1) was completely perfect, you'd have all the cases on the diagonals. 
// In most cases the code works as intended, but in a small number of cases, it does not. 

* OK so the whole point of the year==(year[_n+1]-1) code was to identify cases that were 
* breadwining in the previous observation. You could do this by creating a breadwinning in previous year variable as such: 

gen bw60lag = 0 if bw60[_n-1]==0 & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)
replace bw60lag =1 if  bw60[_n-1]==1 & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)

tab bw60lag bw60L


* replace all the year==(year[_n+1]-1) below with 
// ((SSUID==SSUID[_n+1] & PNUM==PNUM[_n+1]) & year==(year[_n+1]-1)) but having long strings of conditionals (if this, that, something else, and another thing...etc) 
// highly error prone. It is much better to figure out a way to simplify the problem so that you don't need long conditionals.

// What is a better way to create create a measure based on the characteristics of the same person in the previous year? Use reshape.
// But in this case, we already have the variable we need: bw60L



tab survey bw60L // this has more in 2014
tab survey bw60lag // these bottom 2 match
tab survey bw60 if year==(year[_n+1]-1) & (SSUID==SSUID[_n+1] & PNUM==PNUM[_n+1])

svy: tab survey mt_mom if bw60L==0, row
svy: tab survey mt_mom if bw60[_n-1]==0 & year==(year[_n-1]+1), row


/*---------------------------------------------------PRACTICE---------------------------------------------------*/
use "$combined_data/combined_annual_bw_status.dta", clear

local reshape_vars survey bw60 earnup8_all earn_lose earndown8_hh_all earn_change earn_change_hh earndown8_sp_all partner_lose earn_change_sp earn_lose earndown8_oth_all firstbirth
 
// Reshape the data wide (1 person per row)
reshape wide `reshape_vars', i(SSUID PNUM) j(year)



/* reference variables
gen mt_mom = 0
replace mt_mom = 1 if earnup8_all==1 & earn_lose==0 & earndown8_hh_all==0
replace mt_mom = 1 if earn_change > 0 & earn_lose==0 & earn_change_hh==0 & mt_mom==0 // to capture those outside the 8% threshold (v. small amount)

svy: tab survey mt_mom if bw60[_n-1]==0 & year==(year[_n-1]+1), row

svy: tab mt_mom trans_bw60_alt2 if survey==1996 & bw60[_n-1]==0 & year==(year[_n-1]+1), row
svy: tab mt_mom trans_bw60_alt2 if survey==2014 & bw60[_n-1]==0 & year==(year[_n-1]+1), row

*Ft = the proportion of mothers who had their partner lose earnings OR leave. If mothers earnings also went up, they are captured here, not above.
gen ft_partner_down = 0
replace ft_partner_down = 1 if earndown8_sp_all==1 & mt_mom==0 & partner_lose==0 // if partner left, want them there, not here
replace ft_partner_down = 1 if earn_change_sp <0 & earn_change_sp >-.08 & mt_mom==0 & ft_partner_down==0 & partner_lose==0

svy: tab survey ft_partner_down if bw60[_n-1]==0 & year==(year[_n-1]+1), row

svy: tab ft_partner_down trans_bw60_alt2 if survey==1996 & bw60[_n-1]==0 & year==(year[_n-1]+1), row
svy: tab ft_partner_down trans_bw60_alt2 if survey==2014 & bw60[_n-1]==0 & year==(year[_n-1]+1), row 

gen ft_partner_leave = 0
replace ft_partner_leave = 1 if partner_lose==1 & mt_mom==0

svy: tab survey ft_partner_leave if bw60[_n-1]==0 & year==(year[_n-1]+1), row

svy: tab ft_partner_leave trans_bw60_alt2 if survey==1996 & bw60[_n-1]==0 & year==(year[_n-1]+1), row 
svy: tab ft_partner_leave trans_bw60_alt2 if survey==2014 & bw60[_n-1]==0 & year==(year[_n-1]+1), row 

*Lt = the proportion of mothers who either stopped living with someone (besides their partner) who was an earner OR someone else in the household's earnings went down (again besides her partner). Partner is main category, so if a partner experienced changes as well as someone else in HH, they are captured above.
gen lt_other_changes = 0
replace lt_other_changes = 1 if (earn_lose==1 | earndown8_oth_all==1) & (mt_mom==0 & ft_partner_down==0 & ft_partner_leave==0)
	
svy: tab survey lt_other_changes if bw60[_n-1]==0 & year==(year[_n-1]+1), row

*BLt = the proportion of mothers who stopped living with someone who was an earner that became a Breadwinner
svy: tab lt_other_changes trans_bw60_alt2 if survey==1996 & bw60[_n-1]==0 & year==(year[_n-1]+1), row
svy: tab lt_other_changes trans_bw60_alt2 if survey==2014 & bw60[_n-1]==0 & year==(year[_n-1]+1), row

// figuring out how to add in mothers who had their first birth in a panel
browse SSUID PNUM year firstbirth bw60 trans_bw60

svy: tab survey firstbirth, row
svy: tab survey firstbirth if bw60_mom==1 & bw60_mom[_n-1]==1 & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1) in 2/-1
*/