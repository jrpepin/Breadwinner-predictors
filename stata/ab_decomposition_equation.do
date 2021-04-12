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

use "$SIPP14keep/combined_annual_bw_status.dta", clear

sort SSUID PNUM year

browse SSUID PNUM year bw60 trans_bw60 earnup8_all momup_only earn_lose earndown8_hh_all

// ensure those who became mothers IN panel removed from sample in years they hadn't yet had a baby
browse SSUID PNUM year bw60 trans_bw60 firstbirth yrfirstbirth if mom_panel==1
gen bw60_mom=bw60  // need to retain this for future calculations for women who became mom in panel
replace bw60=. if year < yrfirstbirth & mom_panel==1
replace trans_bw60=. if year < yrfirstbirth & mom_panel==1
replace trans_bw60_alt=. if year < yrfirstbirth & mom_panel==1
replace trans_bw60_alt2=. if year < yrfirstbirth & mom_panel==1


********************************************************************************
* Accounts for duplicate years
********************************************************************************

*Dt-l: mothers not breadwinning at t-1
tab survey bw60 // want those with a 0
tab survey bw60 if year==(year[_n+1]-1) // to ensure consecutive years, aka she is available to transition to BW the next year

*Mt = The proportion of mothers who experienced an increase in earnings. This is equal to the number of mothers who experienced an increase in earnings divided by Dt-1. Mothers only included if no one else in the HH experienced a change.

gen mt_mom = 0
replace mt_mom = 1 if earnup8_all==1 & earn_lose==0 & earndown8_hh_all==0
replace mt_mom = 1 if earn_change > 0 & earn_lose==0 & earn_change_hh==0 & mt_mom==0 // to capture those outside the 8% threshold (v. small amount)

* validate
	tab mt_mom momup_only
	* mt_mom is much higher than momup_only because there is a lot of overlap with mom's earnings going up AND someone else's going up. To me, this still feels like a success, so i included, but can update
	
tab survey mt_mom
tab survey momup_only

*Bmt = the proportion of mothers who experience an increase in earnings that became breadwinners. This is equal to the number of mothers who experience an increase in earnings and became breadwinners divided by Mt.

tab mt_mom trans_bw60_alt2 if survey==1996
tab mt_mom trans_bw60_alt2 if survey==2014

tab momup_only trans_bw60_alt2 if survey==1996
tab momup_only trans_bw60_alt2 if survey==2014

*Ft = the proportion of mothers who had another household member lose earnings. If mothers earnings also went up, they are captured here, not above.
gen ft_hh = 0
replace ft_hh = 1 if earn_lose==0 & earndown8_hh_all==1
replace ft_hh = 1 if earn_lose==0 & (earn_change_hh<0 & earn_change_hh>-.08) & (earn_change >0 & earn_change <.08) & ft_hh==0 // to capture those outside the 8% threshold (v. small amount)

tab survey ft_hh

	** Breaking down the ft_hh into partner and all other

	gen ft_partner=0
	replace ft_partner = 1 if earn_lose==0 & earnup8_all==0 & earndown8_sp_all==1 & earndown8_oth_all==0 // also saying NO ONE else in hh's earnings could go down, JUST partner

	gen ft_other=0
	replace ft_other = 1 if earn_lose==0 & earndown8_hh_all==1 & ((earnup8_all==1 & earndown8_sp_all==1) | (earndown8_sp_all==1 & earndown8_oth_all==1))
	replace ft_other = 1 if ft_hh==1 & ft_partner==0 & ft_other==0

	browse ft_hh ft_partner mt_mom earn_lose thearn thearn_alt earnings earnings_a_sp hh_earn other_earn earnup8_all earndown8_sp_all earndown8_oth_all // 
	earndown8_hh_all earn_change_sp earn_change_hh earn_change_oth if ft_hh==0 & ft_partner==1
	
	tab survey ft_partner
	tab survey ft_other

*Bft = the proportion of mothers who had another household member lose earnings that became breadwinners

tab ft_hh trans_bw60_alt2 if survey==1996
tab ft_hh trans_bw60_alt2 if survey==2014

tab ft_partner trans_bw60_alt2 if survey==1996
tab ft_partner trans_bw60_alt2 if survey==2014

tab ft_other trans_bw60_alt2 if survey==1996
tab ft_other trans_bw60_alt2 if survey==2014

*Lt = the proportion of mothers who stopped living with someone who was an earner. This is the main category, such that if mother's earnings went up or HH earnings went down AND someone left, they will be here.
	
tab survey earn_lose

*BLt = the proportion of mothers who stopped living with someone who was an earner that became a Breadwinner
tab earn_lose trans_bw60_alt2 if survey==1996
tab earn_lose trans_bw60_alt2 if survey==2014

*validate
tab survey trans_bw60_alt
tab survey trans_bw60_alt2


browse SSUID PNUM year bw60 trans_bw60 trans_bw60_alt trans_bw60_alt2 earnup8_all earndown8_hh_all earn_change earn_change_hh tpearn thearn mom_gain_earn hh_gain_earn hh_lose_earn if trans_bw60_alt2==1 & mt_mom==0 & ft_hh==0 & earn_lose==0 

browse SSUID PNUM year bw60 trans_bw60 trans_bw60_alt trans_bw60_alt2 earnup8_all earndown8_hh_all earn_change earn_change_hh tpearn thearn mom_gain_earn hh_gain_earn hh_lose_earn if  trans_bw60_alt2==1 & mt_mom==1 & ft_hh==1 & earn_lose==0 


// figuring out how to add in mothers who had their first birth in a panel
browse SSUID PNUM year firstbirth bw60 trans_bw60

tab survey firstbirth
tab survey firstbirth if bw60_mom==1 & bw60_mom[_n-1]==1 & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1) in 2/-1 

//what if had other changes?

browse firstbirth mt_mom ft_hh earn_lose if firstbirth==1 & bw60==1 & bw60[_n-1]==1 & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1) in 2/-1 

********************************************************************************
* Creating variables to have for each year
********************************************************************************
egen id = concat (SSUID PNUM)
destring id, replace

gen survey_yr = 1 if survey==1996
replace survey_yr = 2 if survey==2014

egen base_1 = count(id) if bw60==0 & year==(year[_n+1]-1) & survey==1996
egen base_2 = count(id) if bw60==0 & year==(year[_n+1]-1) & survey==2014

foreach var in mt_mom ft_hh earn_lose {
    forvalues y=1/2{
		egen `var'_`y' = count(id) if `var'==1 & survey_yr==`y'
		sum `var'_`y'
		replace `var'_`y' = r(mean)
		gen `var'_rt_`y' = `var'_`y' / base_`y'
		sum `var'_rt_`y'
		replace `var'_rt_`y' = r(mean)
		egen `var'_bw_`y' = count(id) if `var'==1 & trans_bw60_alt2==1 & survey_yr==`y'
		sum `var'_bw_`y'
		replace `var'_bw_`y' = r(mean)
		gen `var'_bw_rt_`y' = `var'_bw_`y' / `var'_`y'
		sum `var'_bw_rt_`y'
		replace `var'_bw_rt_`y' = r(mean)
	}
}

gen bw_rate_96 = (mt_mom_rt_1 * mt_mom_bw_rt_1) + (ft_hh_rt_1 * ft_hh_bw_rt_1) + (earn_lose_rt_1 * earn_lose_bw_rt_1)
gen bw_rate_14 = (mt_mom_rt_2 * mt_mom_bw_rt_2) + (ft_hh_rt_2 * ft_hh_bw_rt_2) + (earn_lose_rt_2 * earn_lose_bw_rt_2)
gen comp96_rate14 = (mt_mom_rt_1 * mt_mom_bw_rt_2) + (ft_hh_rt_1 * ft_hh_bw_rt_2) + (earn_lose_rt_1 * earn_lose_bw_rt_2)
gen comp14_rate96 = (mt_mom_rt_2 * mt_mom_bw_rt_1) + (ft_hh_rt_2 * ft_hh_bw_rt_1) + (earn_lose_rt_2 * earn_lose_bw_rt_1)

global total_gap = (bw_rate_14 - bw_rate_96)*100
global rate_diff = (bw_rate_14 - comp14_rate96)*100
global comp_diff = (bw_rate_14 - comp96_rate14)*100
global bw_rate_96 = bw_rate_96*100
global bw_rate_14 = bw_rate_14*100

display %9.3f ${total_gap}
display %9.3f ${rate_diff}
display %9.3f ${comp_diff}

// Create html document to describe results
dyndoc "$SIPP2014_code/predictor_decomp.md", saving($results/predictor_decomp.html) replace


/*

********************************************************************************
* Original
********************************************************************************

*Dt-l: mothers not breadwinning at t-1
tab survey bw60 // want those with a 0
tab survey bw60 if year==(year[_n+1]-1) // to ensure consecutive years, aka she is available to transition to BW the next year

*Mt = The proportion of mothers who experienced an increase in earnings. This is equal to the number of mothers who experienced an increase in earnings divided by Dt-1. Mothers only included if no one else in the HH experienced a change.
	
tab survey mt_mom
tab survey momup_only

*Bmt = the proportion of mothers who experience an increase in earnings that became breadwinners. This is equal to the number of mothers who experience an increase in earnings and became breadwinners divided by Mt.

tab mt_mom trans_bw60 if survey==1996
tab mt_mom trans_bw60 if survey==2014

tab momup_only trans_bw60 if survey==1996
tab momup_only trans_bw60 if survey==2014

*Ft = the proportion of mothers who had another household member lose earnings. If mothers earnings also went up, they are captured here, not above.

tab survey ft_hh

*Bft = the proportion of mothers who had another household member lose earnings that became breadwinners

tab ft_hh trans_bw60 if survey==1996
tab ft_hh trans_bw60 if survey==2014

*Lt = the proportion of mothers who stopped living with someone who was an earner. This is the main category, such that if mother's earnings went up or HH earnings went down AND someone left, they will be here.
	
tab survey earn_lose

*BLt = the proportion of mothers who stopped living with someone who was an earner that became a Breadwinner
tab earn_lose trans_bw60 if survey==1996
tab earn_lose trans_bw60 if survey==2014

*validate
tab survey trans_bw60
tab survey trans_bw60_alt

// why don't match?@
browse SSUID PNUM year bw60 trans_bw60 trans_bw60_alt mt_mom ft_hh earn_lose earnup8_all earndown8_hh_all earn_change earn_change_hh mom_gain_earn hh_gain_earn hh_lose_earn if trans_bw60_alt==1

browse SSUID PNUM year bw60 trans_bw60 trans_bw60_alt earnup8_all earndown8_hh_all earn_change earn_change_hh mom_gain_earn hh_gain_earn hh_lose_earn if trans_bw60_alt==1 & mt_mom==0 & ft_hh==0 & earn_lose==0

// it's people whose 2013 are getting 1s as BW even with no history - need to figure this out
// 000418662994, 000860049040, 038418847765 - bw but earnings down - think small things like this explain discrepancy between total
// seemingly no changes: 104925944020, 203344808594, 203925241506


browse SSUID PNUM year bw60 trans_bw60 trans_bw60_alt earn_change earn_change_hh mom_gain_earn hh_gain_earn hh_lose_earn if inlist(SSUID,"000418662994", "000860049040", "038418847765", "104925944020", "203344808594", "203925241506")

// need to deal with non-consecutive years
// 0 v. missing, in the mom-gain-earn, think need to recalculate.

********************************************************************************
* Limited to children in residence at start and end of year
********************************************************************************

*Dt-l: mothers not breadwinning at t-1
tab survey bw60 if minors_fy==1 // want those with a 0

*Mt = The proportion of mothers who experienced an increase in earnings. This is equal to the number of mothers who experienced an increase in earnings divided by Dt-1. Mothers only included if no one else in the HH experienced a change.
	
tab survey mt_mom if minors_fy==1
tab survey momup_only if minors_fy==1

*Bmt = the proportion of mothers who experience an increase in earnings that became breadwinners. This is equal to the number of mothers who experience an increase in earnings and became breadwinners divided by Mt.

tab mt_mom trans_bw60_alt2 if survey==1996 & minors_fy==1
tab mt_mom trans_bw60_alt2 if survey==2014 & minors_fy==1

tab momup_only trans_bw60_alt2 if survey==1996 & minors_fy==1
tab momup_only trans_bw60_alt2 if survey==2014 & minors_fy==1

*Ft = the proportion of mothers who had another household member lose earnings. If mothers earnings also went up, they are captured here, not above.

tab survey ft_hh if minors_fy==1

*Bft = the proportion of mothers who had another household member lose earnings that became breadwinners

tab ft_hh trans_bw60_alt2 if survey==1996 & minors_fy==1
tab ft_hh trans_bw60_alt2 if survey==2014 & minors_fy==1

*Lt = the proportion of mothers who stopped living with someone who was an earner. This is the main category, such that if mother's earnings went up or HH earnings went down AND someone left, they will be here.
	
tab survey earn_lose if minors_fy==1

*BLt = the proportion of mothers who stopped living with someone who was an earner that became a Breadwinner
tab earn_lose trans_bw60_alt2 if survey==1996 & minors_fy==1
tab earn_lose trans_bw60_alt2 if survey==2014 & minors_fy==1

*validate
tab survey trans_bw60_alt if minors_fy==1
tab survey trans_bw60_alt2 if minors_fy==1
*/