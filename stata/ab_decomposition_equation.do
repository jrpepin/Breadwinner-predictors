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

********************************************************************************
* As-is
********************************************************************************

*Dt-l: mothers not breadwinning at t-1
tab survey bw60 // want those with a 0

*Mt = The proportion of mothers who experienced an increase in earnings. This is equal to the number of mothers who experienced an increase in earnings divided by Dt-1. Mothers only included if no one else in the HH experienced a change.

gen mt_mom_up = 0
replace mt_mom_up = 1 if earnup8_all==1 & earn_lose==0 & earndown8_hh_all==0

	* validate
	tab mt_mom_up momup_only
	* mt_mom_up is much higher than momup_only because there is a lot of overlap with mom's earnings going up AND someone else's going up. To me, this still feels like a success, so i included, but can update
	
tab survey mt_mom_up
tab survey momup_only

*Bmt = the proportion of mothers who experience an increase in earnings that became breadwinners. This is equal to the number of mothers who experience an increase in earnings and became breadwinners divided by Mt.

tab mt_mom_up trans_bw60 if survey==1996
tab mt_mom_up trans_bw60 if survey==2014

tab momup_only trans_bw60 if survey==1996
tab momup_only trans_bw60 if survey==2014

*Ft = the proportion of mothers who had another household member lose earnings. If mothers earnings also went up, they are captured here, not above.
gen ft_hh_down = 0
replace ft_hh_down = 1 if earn_lose==0 & earndown8_hh_all==1
	
	* validate : tab earndown8_hh_all ft_hh_down
	
tab survey ft_hh_down

*Bft = the proportion of mothers who had another household member lose earnings that became breadwinners

tab ft_hh_down trans_bw60 if survey==1996
tab ft_hh_down trans_bw60 if survey==2014

*Lt = the proportion of mothers who stopped living with someone who was an earner. This is the main category, such that if mother's earnings went up or HH earnings went down AND someone left, they will be here.
	
tab survey earn_lose

*BLt = the proportion of mothers who stopped living with someone who was an earner that became a Breadwinner
tab earn_lose trans_bw60 if survey==1996
tab earn_lose trans_bw60 if survey==2014

*validate
tab survey trans_bw60
tab survey trans_bw60_alt

// why don't match?@
browse SSUID PNUM year bw60 trans_bw60 trans_bw60_alt mt_mom_up ft_hh_down earn_lose earnup8_all earndown8_hh_all earn_change earn_change_hh mom_gain_earn hh_gain_earn hh_lose_earn if trans_bw60_alt==1

browse SSUID PNUM year bw60 trans_bw60 trans_bw60_alt earnup8_all earndown8_hh_all earn_change earn_change_hh mom_gain_earn hh_gain_earn hh_lose_earn if trans_bw60_alt==1 & mt_mom_up==0 & ft_hh_down==0 & earn_lose==0

// it's people whose 2013 are getting 1s as BW even with no history - need to figure this out
// 000418662994, 000860049040, 038418847765 - bw but earnings down - think small things like this explain discrepancy between total
// seemingly no changes: 104925944020, 203344808594, 203925241506


browse SSUID PNUM year bw60 trans_bw60 trans_bw60_alt earn_change earn_change_hh mom_gain_earn hh_gain_earn hh_lose_earn if inlist(SSUID,"000418662994", "000860049040", "038418847765", "104925944020", "203344808594", "203925241506")

// need to deal with non-consecutive years
// 0 v. missing, in the mom-gain-earn, think need to recalculate.

********************************************************************************
* Fixed duplicate years
********************************************************************************

*Dt-l: mothers not breadwinning at t-1
tab survey bw60 // want those with a 0

*Mt = The proportion of mothers who experienced an increase in earnings. This is equal to the number of mothers who experienced an increase in earnings divided by Dt-1. Mothers only included if no one else in the HH experienced a change.
	
tab survey mt_mom_up
tab survey momup_only

*Bmt = the proportion of mothers who experience an increase in earnings that became breadwinners. This is equal to the number of mothers who experience an increase in earnings and became breadwinners divided by Mt.

tab mt_mom_up trans_bw60_alt2 if survey==1996
tab mt_mom_up trans_bw60_alt2 if survey==2014

tab momup_only trans_bw60_alt2 if survey==1996
tab momup_only trans_bw60_alt2 if survey==2014

*Ft = the proportion of mothers who had another household member lose earnings. If mothers earnings also went up, they are captured here, not above.

tab survey ft_hh_down

*Bft = the proportion of mothers who had another household member lose earnings that became breadwinners

tab ft_hh_down trans_bw60_alt2 if survey==1996
tab ft_hh_down trans_bw60_alt2 if survey==2014

*Lt = the proportion of mothers who stopped living with someone who was an earner. This is the main category, such that if mother's earnings went up or HH earnings went down AND someone left, they will be here.
	
tab survey earn_lose

*BLt = the proportion of mothers who stopped living with someone who was an earner that became a Breadwinner
tab earn_lose trans_bw60_alt2 if survey==1996
tab earn_lose trans_bw60_alt2 if survey==2014

*validate
tab survey trans_bw60_alt
tab survey trans_bw60_alt2

browse SSUID PNUM year bw60 trans_bw60 trans_bw60_alt trans_bw60_alt2 earnup8_all earndown8_hh_all earn_change earn_change_hh tpearn thearn mom_gain_earn hh_gain_earn hh_lose_earn if trans_bw60_alt2==1 & mt_mom_up==0 & ft_hh_down==0 & earn_lose==0

// No changes, mom seems like only earner: 038860222545, 038860334510 - weirdly missing trans_bw60_alt, but NOT trans_bw60_alt2
// No changes, mom seems like only earner: 203052369737, 292136406232 - both versions match
// changes in a direction that doen't make sense: 038860814689, 077925241695

browse SSUID PNUM year bw60 trans_bw60 trans_bw60_alt trans_bw60_alt2 earnup8_all earndown8_hh_all earn_change earn_change_hh tpearn thearn mom_gain_earn hh_gain_earn hh_lose_earn if inlist(SSUID, "038860222545", "038860334510", "203052369737", "292136406232", "038860814689", "077925241695")

// 038860814689 - calculation for earn change doesn't seem right 2015-2016, same this person 077925241695, 1998-1999
// okay and the 0 to tpearn, not missing to tpearn.