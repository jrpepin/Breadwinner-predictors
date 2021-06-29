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

/* this isn't going to work because weights vary by year - also doing PY version of race
// getting unique race counts for descriptives later. not convinced this is most efficient but struggling with how to do this with persons, not person-years, in long file with weights
keep race SSUID PNUM year wpfinwgt
 
// Reshape the data wide (1 person per row)
reshape wide race wpfinwgt, i(SSUID PNUM) j(year)
egen race = rowmin(race1995 race1996 race1997 race1998 race1999 race2000 race2013 race2014 race2015 race2016)
label values race race

tab race [aweight=wpfinwgt], gen(race)
*/

sort SSUID PNUM year

browse SSUID PNUM year bw60 trans_bw60 earnup8_all momup_only earn_lose earndown8_hh_all

// ensure those who became mothers IN panel removed from sample in years they hadn't yet had a baby
browse SSUID PNUM year bw60 trans_bw60 firstbirth yrfirstbirth if mom_panel==1
gen bw60_mom=bw60  // need to retain this for future calculations for women who became mom in panel
replace bw60=. if year < yrfirstbirth & mom_panel==1
replace trans_bw60=. if year < yrfirstbirth & mom_panel==1
replace trans_bw60_alt=. if year < yrfirstbirth & mom_panel==1
replace trans_bw60_alt2=. if year < yrfirstbirth & mom_panel==1

svyset [pweight = wpfinwgt]

recode partner_lose (2/6=1)

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

********************************************************************************
* First specification: "partner" is reference category, rest are unique
********************************************************************************

*Dt-l: mothers not breadwinning at t-1
svy: tab survey bw60lag, row // to ensure consecutive years, aka she is available to transition to BW the next year

*Mt = The proportion of mothers who experienced an increase in earnings. This is equal to the number of mothers who experienced an increase in earnings divided by Dt-1. Mothers only included if no one else in the HH experienced a change.

gen mt_mom = 0
replace mt_mom = 1 if earnup8_all==1 & earn_lose==0 & earndown8_hh_all==0
replace mt_mom = 1 if earn_change > 0 & earn_lose==0 & earn_change_hh==0 & mt_mom==0 // to capture those outside the 8% threshold (v. small amount)

svy: tab survey mt_mom if bw60lag==0, row
tab survey mt_mom if bw60lag==0 [aweight = wpfinwgt], row // validating this is the same as svy

*Bmt = the proportion of mothers who experience an increase in earnings that became breadwinners. This is equal to the number of mothers who experience an increase in earnings and became breadwinners divided by Mt.

svy: tab mt_mom trans_bw60_alt2 if survey==1996 & bw60lag==0, row
svy: tab mt_mom trans_bw60_alt2 if survey==2014 & bw60lag==0, row

*Ft = the proportion of mothers who had their partner lose earnings OR leave. If mothers earnings also went up, they are captured here, not above.
gen ft_partner_down = 0
replace ft_partner_down = 1 if earndown8_sp_all==1 & mt_mom==0 & partner_lose==0 // if partner left, want them there, not here
replace ft_partner_down = 1 if earn_change_sp <0 & earn_change_sp >-.08 & mt_mom==0 & ft_partner_down==0 & partner_lose==0

svy: tab survey ft_partner_down if bw60lag==0, row

	* splitting partner down into just partner down, or also mom up - we are going to use these more detailed categories
	gen ft_partner_down_only=0
	replace ft_partner_down_only = 1 if earndown8_sp_all==1 & earnup8_all==0 & mt_mom==0 & partner_lose==0 & ft_partner_down==1
	replace ft_partner_down_only = 1 if earn_change_sp <0 & earn_change_sp >-.08 & earnup8_all==0 & mt_mom==0 & ft_partner_down==1 & partner_lose==0
	
	gen ft_partner_down_mom=0
	replace ft_partner_down_mom = 1 if earndown8_sp_all==1 & earnup8_all==1 & mt_mom==0 & partner_lose==0 & ft_partner_down==1
	replace ft_partner_down_mom = 1 if earn_change_sp <0 & earn_change_sp >-.08 & earnup8_all==1 & mt_mom==0 & ft_partner_down==1 & partner_lose==0
	
	svy: tab survey ft_partner_down_only if bw60lag==0, row
	svy: tab survey ft_partner_down_mom if bw60lag==0, row
	
	
gen ft_partner_leave = 0
replace ft_partner_leave = 1 if partner_lose==1 & mt_mom==0

svy: tab survey ft_partner_leave if bw60lag==0, row

gen ft_overlap=0
replace ft_overlap = 1 if earn_lose==0 & earnup8_all==1 & earndown8_sp_all==1

*Bft = the proportion of mothers who had another household member lose earnings that became breadwinners
svy: tab ft_partner_down trans_bw60_alt2 if survey==1996 & bw60lag==0, row
svy: tab ft_partner_down trans_bw60_alt2 if survey==2014 & bw60lag==0, row 

svy: tab ft_partner_leave trans_bw60_alt2 if survey==1996 & bw60lag==0, row 
svy: tab ft_partner_leave trans_bw60_alt2 if survey==2014 & bw60lag==0, row 

svy: tab ft_partner_down_only trans_bw60_alt2 if survey==1996 & bw60lag==0, row
svy: tab ft_partner_down_only trans_bw60_alt2 if survey==2014 & bw60lag==0, row 

svy: tab ft_partner_down_mom trans_bw60_alt2 if survey==1996 & bw60lag==0, row 
svy: tab ft_partner_down_mom trans_bw60_alt2 if survey==2014 & bw60lag==0, row 

*Lt = the proportion of mothers who either stopped living with someone (besides their partner) who was an earner OR someone else in the household's earnings went down (again besides her partner). Partner is main category, so if a partner experienced changes as well as someone else in HH, they are captured above.
gen lt_other_changes = 0
replace lt_other_changes = 1 if (earn_lose==1 | earndown8_oth_all==1) & (mt_mom==0 & ft_partner_down==0 & ft_partner_leave==0)
	
svy: tab survey lt_other_changes if bw60lag==0, row

*BLt = the proportion of mothers who stopped living with someone who was an earner that became a Breadwinner
svy: tab lt_other_changes trans_bw60_alt2 if survey==1996 & bw60lag==0, row
svy: tab lt_other_changes trans_bw60_alt2 if survey==2014 & bw60lag==0, row


*validate
svy: tab survey trans_bw60_alt2, row
svy: tab survey trans_bw60_alt2 if bw60lag==0, row

// figuring out how to add in mothers who had their first birth in a panel
browse SSUID PNUM year firstbirth bw60 trans_bw60

svy: tab survey firstbirth, row
svy: tab survey firstbirth if bw60_mom==1 & bw60_mom[_n-1]==1 & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1) in 2/-1


********************************************************************************
* Putting Equation 1 into Excel
********************************************************************************
egen id = concat (SSUID PNUM)
destring id, replace

gen survey_yr = 1 if survey==1996
replace survey_yr = 2 if survey==2014

*****************************
* Overall

egen base_1 = count(id) if bw60lag==0 & survey==1996
egen base_2 = count(id) if bw60lag==0 & survey==2014

// variables: mt_mom ft_partner_down ft_partner_leave lt_other_changes

/*template
svy: mean mt_mom if bw60lag==0 & survey==1996
svy: mean mt_mom if bw60lag==0 & survey==2014
svy: mean trans_bw60_alt2 if bw60lag==0 & survey==1996 & mt_mom==1
svy: mean trans_bw60_alt2 if bw60lag==0 & survey==2014 & mt_mom==1
*/

putexcel set "$results/Breadwinner_Predictor_Equation", sheet(partner_ref) replace
putexcel A2:A3 = "Overall", merge
putexcel A5:A12 = "Education", merge
putexcel A14:A21 = "Race", merge
putexcel A23:A28 = "Education Groups", merge
putexcel B5:B6 = "Less than HS", merge
putexcel B7:B8 = "HS Degree", merge
putexcel B9:B10 = "Some College", merge
putexcel B11:B12 = "College Plus", merge
putexcel B14:B15 = "NH White", merge
putexcel B16:B17 = "Black", merge
putexcel B18:B19 = "NH Asian", merge
putexcel B20:B21 = "Hispanic", merge
putexcel B23:B24 = "HS or Less", merge
putexcel B25:B26 = "Some College", merge
putexcel B27:B28 = "College Plus", merge
putexcel C2 = ("1996") C5 = ("1996") C7 = ("1996") C9 = ("1996") C11 = ("1996") C14 = ("1996") C16 = ("1996") C18 = ("1996") C20 = ("1996") C23 = ("1996") C25 = ("1996") C27 = ("1996")
putexcel C3 = ("2014") C6 = ("2014") C8 = ("2014") C10 = ("2014") C12 = ("2014") C15 = ("2014") C17 = ("2014") C19 = ("2014") C21 = ("2014") C24 = ("2014") C26 = ("2014") C28 = ("2014")
putexcel D1 = "Mothers with an increase in earnings", border(bottom)
putexcel E1 = "Mothers with an increase in earnings AND became BW", border(bottom)
putexcel F1 = "Partner lost earnings and mom went up", border(bottom)
putexcel G1 = "Partner lost earnings and mom up AND became BW", border(bottom)
putexcel H1 = "Partner lost earnings only", border(bottom)
putexcel I1 = "Partner lost earnings only AND became BW", border(bottom)
putexcel J1 = "Partner left", border(bottom)
putexcel K1 = "Partner left AND became BW", border(bottom)
putexcel L1 = "Other member lost earnings / left", border(bottom)
putexcel M1 = "Other member lost earnings / left AND became BW", border(bottom)
putexcel N1 = "Rate of transition to BW", border(bottom)
putexcel O1 = "Total Difference", border(bottom)
putexcel P1 = "Rate Difference", border(bottom)
putexcel Q1 = "Composition Difference", border(bottom)
putexcel R1 = "Mom Component", border(bottom)
putexcel S1 = "Partner Down Mom Up Component", border(bottom)
putexcel T1 = "Partner Down Only Component", border(bottom)
putexcel U1 = "Partner Left Component", border(bottom)
putexcel V1 = "Other Component", border(bottom)

local colu1 "D F H J L"
local colu2 "E G I K M"
local i=1

foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
   	local col1: word `i' of `colu1'
	local col2: word `i' of `colu2'
		forvalues y=1/2{
			local row=`y'+1
			svy: mean `var' if bw60lag==0 & survey_yr==`y'
			matrix `var'_`y' = e(b)
			gen `var'_`y' = e(b)[1,1]
			svy: mean trans_bw60_alt2 if bw60lag==0 & survey_yr==`y' & `var'==1
			matrix `var'_`y'_bw = e(b)
			gen `var'_`y'_bw = e(b)[1,1]
			putexcel `col1'`row' = matrix(`var'_`y'), nformat(#.##%)
			putexcel `col2'`row' = matrix(`var'_`y'_bw), nformat(#.##%)
		}
	local ++i
}

gen bw_rate_96 = (mt_mom_1 * mt_mom_1_bw) + (ft_partner_down_only_1 * ft_partner_down_only_1_bw) + (ft_partner_down_mom_1 * ft_partner_down_mom_1_bw) + (ft_partner_leave_1 * ft_partner_leave_1_bw) + (lt_other_changes_1 * lt_other_changes_1_bw)
gen bw_rate_14 = (mt_mom_2 * mt_mom_2_bw) + (ft_partner_down_only_2 * ft_partner_down_only_2_bw) + (ft_partner_down_mom_2 * ft_partner_down_mom_2_bw) + (ft_partner_leave_2 * ft_partner_leave_2_bw) + (lt_other_changes_2 * lt_other_changes_2_bw)

gen comp96_rate14 = (mt_mom_1 * mt_mom_2_bw) + (ft_partner_down_only_1 * ft_partner_down_only_2_bw) + (ft_partner_down_mom_1 * ft_partner_down_mom_2_bw) + (ft_partner_leave_1 * ft_partner_leave_2_bw) + (lt_other_changes_1 * lt_other_changes_2_bw)
gen comp14_rate96 = (mt_mom_2 * mt_mom_1_bw) + (ft_partner_down_only_2 * ft_partner_down_only_1_bw) + (ft_partner_down_mom_2 * ft_partner_down_mom_1_bw) + (ft_partner_leave_2 * ft_partner_leave_1_bw) + (lt_other_changes_2 * lt_other_changes_1_bw)

gen total_gap = (bw_rate_14 - bw_rate_96)

// 1996 as reference
gen mom_change_x =  (mt_mom_2 * mt_mom_2_bw) + (ft_partner_down_only_1 * ft_partner_down_only_1_bw) + (ft_partner_down_mom_1 * ft_partner_down_mom_1_bw) + (ft_partner_leave_1 * ft_partner_leave_1_bw) + (lt_other_changes_1 * lt_other_changes_1_bw)
gen partner_down_only_chg_x = (mt_mom_1 * mt_mom_1_bw) + (ft_partner_down_only_2 * ft_partner_down_only_2_bw) + (ft_partner_down_mom_1 * ft_partner_down_mom_1_bw) + (ft_partner_leave_1 * ft_partner_leave_1_bw) + (lt_other_changes_1 * lt_other_changes_1_bw)
gen partner_down_mom_up_chg_x  =   (mt_mom_1 * mt_mom_1_bw) + (ft_partner_down_only_1 * ft_partner_down_only_1_bw) + (ft_partner_down_mom_2 * ft_partner_down_mom_2_bw) + (ft_partner_leave_1 * ft_partner_leave_1_bw) + (lt_other_changes_1 * lt_other_changes_1_bw)
gen partner_leave_change_x =  (mt_mom_1 * mt_mom_1_bw) + (ft_partner_down_only_1 * ft_partner_down_only_1_bw) + (ft_partner_down_mom_1 * ft_partner_down_mom_1_bw) + (ft_partner_leave_2 * ft_partner_leave_2_bw) + (lt_other_changes_1 * lt_other_changes_1_bw)
gen other_hh_change_x =  (mt_mom_1 * mt_mom_1_bw) + (ft_partner_down_only_1 * ft_partner_down_only_1_bw) + (ft_partner_down_mom_1 * ft_partner_down_mom_1_bw) + (ft_partner_leave_1 * ft_partner_leave_1_bw) + (lt_other_changes_2 * lt_other_changes_2_bw)


/* 2014 as reference
gen mom_change_y =  (mt_mom_1 * mt_mom_1_bw) + (ft_partner_down_2 * ft_partner_down_2_bw) + (ft_partner_leave_2 * ft_partner_leave_2_bw) + (lt_other_changes_2 * lt_other_changes_2_bw)
gen partner_down_change_y =  (mt_mom_2 * mt_mom_2_bw) + (ft_partner_down_1 * ft_partner_down_1_bw) + (ft_partner_leave_2 * ft_partner_leave_2_bw) + (lt_other_changes_2 * lt_other_changes_2_bw)
gen partner_down_only_chg_y = (mt_mom_2 * mt_mom_2_bw) + (ft_partner_down_only_1 * ft_partner_down_only_1_bw) + (ft_partner_down_mom_2 * ft_partner_down_mom_2_bw) + (ft_partner_leave_2 * ft_partner_leave_2_bw) + (lt_other_changes_2 * lt_other_changes_2_bw)
gen partner_down_mom_up_chg_y  =   (mt_mom_2 * mt_mom_2_bw) + (ft_partner_down_only_2 * ft_partner_down_only_2_bw) + (ft_partner_down_mom_1 * ft_partner_down_mom_1_bw) + (ft_partner_leave_2 * ft_partner_leave_2_bw) + (lt_other_changes_2 * lt_other_changes_2_bw)
gen partner_leave_change_y =  (mt_mom_2 * mt_mom_2_bw) + (ft_partner_down_2 * ft_partner_down_2_bw) + (ft_partner_leave_1 * ft_partner_leave_1_bw) + (lt_other_changes_2 * lt_other_changes_2_bw)
gen other_hh_change_y =  (mt_mom_2 * mt_mom_2_bw) + (ft_partner_down_2 * ft_partner_down_2_bw) + (ft_partner_leave_2 * ft_partner_leave_2_bw) + (lt_other_changes_1 * lt_other_changes_1_bw)
*/

global bw_rate_96 = bw_rate_96
putexcel N2 = $bw_rate_96, nformat(#.##%)
global bw_rate_14 = bw_rate_14
putexcel N3 = $bw_rate_14, nformat(#.##%)
global total_gap = (bw_rate_14 - bw_rate_96)
putexcel O2 = $total_gap, nformat(#.##%)
global rate_diff = (comp96_rate14 - bw_rate_96)
putexcel P2 = $rate_diff, nformat(#.##%)
global comp_diff = (comp14_rate96 - bw_rate_96)
putexcel Q2 = $comp_diff, nformat(#.##%)

// 1996 as reference
global mom_compt_x = ((mom_change_x - bw_rate_96) / total_gap)
putexcel R2 = $mom_compt_x, nformat(#.##%)
global partner_down_mom_compt_x = ((partner_down_mom_up_chg_x - bw_rate_96) / total_gap)
putexcel S2 = $partner_down_mom_compt_x, nformat(#.##%)
global partner_down_only_compt_x = ((partner_down_only_chg_x - bw_rate_96) / total_gap)
putexcel T2 = $partner_down_only_compt_x, nformat(#.##%)
global partner_leave_compt_x = ((partner_leave_change_x - bw_rate_96) / total_gap)
putexcel U2 = $partner_leave_compt_x, nformat(#.##%)
global other_hh_compt_x = ((other_hh_change_x - bw_rate_96) / total_gap)
putexcel V2 = $other_hh_compt_x, nformat(#.##%)

/* 2014 as reference - matches above so cut
global mom_compt_y = (bw_rate_14 - mom_change_y)*100
putexcel Z2 = $mom_compt_y, nformat(#.##)
global partner_down_compt_y = (bw_rate_14 - partner_down_change_y)*100
putexcel AA2 = $partner_down_compt_y, nformat(#.##)
global partner_down_only_compt_y = (bw_rate_14 - partner_down_only_chg_y)*100
putexcel AB2 = $partner_down_only_compt_y, nformat(#.##)
global partner_down_mom_compt_y = (bw_rate_14 - partner_down_mom_up_chg_y)*100
putexcel AC2 = $partner_down_mom_compt_y, nformat(#.##)
global partner_leave_compt_y = (bw_rate_14 - partner_leave_change_y)*100
putexcel AD2 = $partner_leave_compt_y, nformat(#.##)
global other_hh_compt_y = (bw_rate_14 - other_hh_change_y)*100
putexcel AE2 = $other_hh_compt_y, nformat(#.##)
*/

display %9.3f ${total_gap}
display %9.3f ${rate_diff}
display %9.3f ${comp_diff}

/* old component change
gen mom_change =  (mt_mom_2 * mt_mom_2_bw) - (mt_mom_1 * mt_mom_1_bw)
gen partner_down_change =  (ft_partner_down_2 * ft_partner_down_2_bw) - (ft_partner_down_1 * ft_partner_down_1_bw)
gen partner_down_only_chg = (ft_partner_down_only_2 * ft_partner_down_only_2_bw) - (ft_partner_down_only_1 * ft_partner_down_only_1_bw)
gen partner_down_mom_up_chg  =  (ft_partner_down_mom_2 * ft_partner_down_mom_2_bw) - (ft_partner_down_mom_1 * ft_partner_down_mom_1_bw)
gen partner_leave_change =  (ft_partner_leave_2 * ft_partner_leave_2_bw) - (ft_partner_leave_1 * ft_partner_leave_1_bw)
gen other_hh_change =  (lt_other_changes_2 * lt_other_changes_2_bw) - (lt_other_changes_1 * lt_other_changes_1_bw)

then just divided by total_gap
*/

*****************************
* By education

forvalues e=1/4{
	egen base_`e'_1 = count(id) if bw60==0 & year==(year[_n+1]-1) & survey==1996 & educ==`e'
	egen base_`e'_2 = count(id) if bw60==0 & year==(year[_n+1]-1) & survey==2014 & educ==`e'
}


forvalues e=1/4{
local colu1 "D F H J L"
local colu2 "E G I K M"
local i=1

foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		local col1: word `i' of `colu1'
		local col2: word `i' of `colu2'
		local row1=`e'*2
			forvalues y=1/2{
			    local row=`row1'+`y'+2
				svy: mean `var' if bw60lag==0 & survey_yr==`y' & educ==`e'
				matrix `var'_`e'_`y' = e(b)
				gen `var'_`e'_`y' = e(b)[1,1]
				svy: mean trans_bw60_alt2 if bw60lag==0 & survey_yr==`y' & `var'==1 & educ==`e'
				matrix `var'_`e'_`y'_bw = e(b)
				gen `var'_`e'_`y'_bw = e(b)[1,1]
				putexcel `col1'`row' = matrix(`var'_`e'_`y'), nformat(#.##%)
				putexcel `col2'`row' = matrix(`var'_`e'_`y'_bw), nformat(#.##%)
			}
		local ++i
	}
}

forvalues e=1/4{
	gen bw_rate_96_`e' = (mt_mom_`e'_1 * mt_mom_`e'_1_bw) + (ft_partner_down_only_`e'_1 * ft_partner_down_only_`e'_1_bw) + (ft_partner_down_mom_`e'_1 * ft_partner_down_mom_`e'_1_bw) + (ft_partner_leave_`e'_1 * ft_partner_leave_`e'_1_bw) + 	(lt_other_changes_`e'_1 * lt_other_changes_`e'_1_bw)
	gen bw_rate_14_`e' = (mt_mom_`e'_2 * mt_mom_`e'_2_bw) + (ft_partner_down_only_`e'_2 * ft_partner_down_only_`e'_2_bw) + (ft_partner_down_mom_`e'_2 * ft_partner_down_mom_`e'_2_bw) + (ft_partner_leave_`e'_2 * ft_partner_leave_`e'_2_bw) + 	(lt_other_changes_`e'_2 * lt_other_changes_`e'_2_bw)
	gen comp96_rate14_`e' = (mt_mom_`e'_1 * mt_mom_`e'_2_bw) + (ft_partner_down_only_`e'_1 * ft_partner_down_only_`e'_2_bw) + (ft_partner_down_mom_`e'_1 * ft_partner_down_mom_`e'_2_bw) + (ft_partner_leave_`e'_1 * ft_partner_leave_`e'_2_bw) + (lt_other_changes_`e'_1 * lt_other_changes_`e'_2_bw)
	gen comp14_rate96_`e' = (mt_mom_`e'_2 * mt_mom_`e'_1_bw) + (ft_partner_down_only_`e'_2 * ft_partner_down_only_`e'_1_bw) + (ft_partner_down_mom_`e'_2 * ft_partner_down_mom_`e'_1_bw) + (ft_partner_leave_`e'_2 * ft_partner_leave_`e'_1_bw) + (lt_other_changes_`e'_2 * lt_other_changes_`e'_1_bw)
	
	gen total_gap_`e' = (bw_rate_14_`e' - bw_rate_96_`e')
	
	gen mom_change_`e' =  (mt_mom_`e'_2 * mt_mom_`e'_2_bw) +  (ft_partner_down_only_`e'_1 * ft_partner_down_only_`e'_1_bw) + (ft_partner_down_mom_`e'_1 * ft_partner_down_mom_`e'_1_bw) + (ft_partner_leave_`e'_1 * ft_partner_leave_`e'_1_bw) + (lt_other_changes_`e'_1 * lt_other_changes_`e'_1_bw)
	gen partner_down_only_chg_`e' = (mt_mom_`e'_1 * mt_mom_`e'_1_bw) + (ft_partner_down_only_`e'_2 * ft_partner_down_only_`e'_2_bw) + (ft_partner_down_mom_`e'_1 * ft_partner_down_mom_`e'_1_bw) + (ft_partner_leave_`e'_1 * ft_partner_leave_`e'_1_bw) + (lt_other_changes_`e'_1 * lt_other_changes_`e'_1_bw)
	gen partner_down_mom_up_chg_`e'  =   (mt_mom_`e'_1 * mt_mom_`e'_1_bw) + (ft_partner_down_only_`e'_1 * ft_partner_down_only_`e'_1_bw) + (ft_partner_down_mom_`e'_2 * ft_partner_down_mom_`e'_2_bw) + (ft_partner_leave_`e'_1 * ft_partner_leave_`e'_1_bw) + (lt_other_changes_`e'_1 * lt_other_changes_`e'_1_bw)
	gen partner_leave_change_`e' =  (mt_mom_`e'_1 * mt_mom_`e'_1_bw) + (ft_partner_down_only_`e'_1 * ft_partner_down_only_`e'_1_bw) + (ft_partner_down_mom_`e'_1 * ft_partner_down_mom_`e'_1_bw) + (ft_partner_leave_`e'_2 * ft_partner_leave_`e'_2_bw) + (lt_other_changes_`e'_1 * lt_other_changes_`e'_1_bw)
	gen other_hh_change_`e' =  (mt_mom_`e'_1 * mt_mom_`e'_1_bw) + (ft_partner_down_only_`e'_1 * ft_partner_down_only_`e'_1_bw) + (ft_partner_down_mom_`e'_1 * ft_partner_down_mom_`e'_1_bw) + (ft_partner_leave_`e'_1 * ft_partner_leave_`e'_1_bw) + (lt_other_changes_`e'_2 * lt_other_changes_`e'_2_bw)
	
	local row = `e'*2+3
	local row2 = `e'*2+4
	global bw_rate_96_`e' = bw_rate_96_`e'
	putexcel N`row' = ${bw_rate_96_`e'}, nformat(#.##%)
	global bw_rate_14_`e' = bw_rate_14_`e'
	putexcel N`row2' = ${bw_rate_14_`e'}, nformat(#.##%)
	global total_gap_`e' = (bw_rate_14_`e' - bw_rate_96_`e')
	putexcel O`row' = ${total_gap_`e'}, nformat(#.##%)
	global rate_diff_`e' = (comp96_rate14_`e' - bw_rate_96_`e')
	putexcel P`row' = ${rate_diff_`e'}, nformat(#.##%)
	global comp_diff_`e' = (comp14_rate96_`e' - bw_rate_96_`e')
	putexcel Q`row' = ${comp_diff_`e'}, nformat(#.##%)
	
	global mom_component_`e' = ((mom_change_`e' - bw_rate_96_`e') / total_gap_`e')
	putexcel R`row' = ${mom_component_`e'}, nformat(#.##%)
	global partner_down_mom_component_`e' = ((partner_down_mom_up_chg_`e' - bw_rate_96_`e') / total_gap_`e')
	putexcel S`row' = ${partner_down_mom_component_`e'}, nformat(#.##%)
	global partner_down_only_component_`e' = ((partner_down_only_chg_`e' - bw_rate_96_`e') / total_gap_`e')
	putexcel T`row' = ${partner_down_only_component_`e'}, nformat(#.##%)
	global partner_leave_component_`e' = ((partner_leave_change_`e' - bw_rate_96_`e') / total_gap_`e')
	putexcel U`row' = ${partner_leave_component_`e'}, nformat(#.##%)
	global other_hh_component_`e' = ((other_hh_change_`e' - bw_rate_96_`e') / total_gap_`e')
	putexcel V`row' = ${other_hh_component_`e'}, nformat(#.##%)
}


*****************************
* By race

forvalues r=1/4{
	egen base_r`r'_1 = count(id) if bw60==0 & year==(year[_n+1]-1) & survey==1996 & race==`r'
	egen base_r`r'_2 = count(id) if bw60==0 & year==(year[_n+1]-1) & survey==2014 & race==`r'
}


forvalues r=1/4{
local colu1 "D F H J L"
local colu2 "E G I K M"
local i=1

foreach var in mt_mom  ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		local col1: word `i' of `colu1'
		local col2: word `i' of `colu2'
		local row1=`r'*2
			forvalues y=1/2{
			    local row=`row1'+`y'+11
				svy: mean `var' if bw60lag==0 & survey_yr==`y' & race==`r'
				matrix `var'_r`r'_`y' = e(b)
				gen `var'_r`r'_`y' = e(b)[1,1]
				svy: mean trans_bw60_alt2 if bw60lag==0 & survey_yr==`y' & `var'==1 & race==`r'
				matrix `var'_r`r'_`y'_bw = e(b)
				gen `var'_r`r'_`y'_bw = e(b)[1,1]
				putexcel `col1'`row' = matrix(`var'_r`r'_`y'), nformat(#.##%)
				putexcel `col2'`row' = matrix(`var'_r`r'_`y'_bw), nformat(#.##%)
			}
		local ++i
	}
}

forvalues r=1/4{
	gen bw_rate_96_r`r' = (mt_mom_r`r'_1 * mt_mom_r`r'_1_bw) + (ft_partner_down_only_r`r'_1 * ft_partner_down_only_r`r'_1_bw) + (ft_partner_down_mom_r`r'_1 * ft_partner_down_mom_r`r'_1_bw) + (ft_partner_leave_r`r'_1 * ft_partner_leave_r`r'_1_bw) + 	(lt_other_changes_r`r'_1 * lt_other_changes_r`r'_1_bw)
	gen bw_rate_14_r`r' = (mt_mom_r`r'_2 * mt_mom_r`r'_2_bw) + (ft_partner_down_only_r`r'_2 * ft_partner_down_only_r`r'_2_bw) + (ft_partner_down_mom_r`r'_2 * ft_partner_down_mom_r`r'_2_bw) + (ft_partner_leave_r`r'_2 * ft_partner_leave_r`r'_2_bw) + 	(lt_other_changes_r`r'_2 * lt_other_changes_r`r'_2_bw)
	gen comp96_rate14_r`r' = (mt_mom_r`r'_1 * mt_mom_r`r'_2_bw) + (ft_partner_down_only_r`r'_1 * ft_partner_down_only_r`r'_2_bw) + (ft_partner_down_mom_r`r'_1 * ft_partner_down_mom_r`r'_2_bw) + (ft_partner_leave_r`r'_1 * ft_partner_leave_r`r'_2_bw) + (lt_other_changes_r`r'_1 * lt_other_changes_r`r'_2_bw)
	gen comp14_rate96_r`r' = (mt_mom_r`r'_2 * mt_mom_r`r'_1_bw) + (ft_partner_down_only_r`r'_2 * ft_partner_down_only_r`r'_1_bw) + (ft_partner_down_mom_r`r'_2 * ft_partner_down_mom_r`r'_1_bw) + (ft_partner_leave_r`r'_2 * ft_partner_leave_r`r'_1_bw) + (lt_other_changes_r`r'_2 * lt_other_changes_r`r'_1_bw)
	
	gen total_gap_r`r' = (bw_rate_14_r`r' - bw_rate_96_r`r')
	
	gen mom_change_r`r' =  (mt_mom_r`r'_2 * mt_mom_r`r'_2_bw) +  (ft_partner_down_only_r`r'_1 * ft_partner_down_only_r`r'_1_bw) + (ft_partner_down_mom_r`r'_1 * ft_partner_down_mom_r`r'_1_bw) + (ft_partner_leave_r`r'_1 * ft_partner_leave_r`r'_1_bw) + (lt_other_changes_r`r'_1 * lt_other_changes_r`r'_1_bw)
	gen partner_down_only_chg_r`r' = (mt_mom_r`r'_1 * mt_mom_r`r'_1_bw) + (ft_partner_down_only_r`r'_2 * ft_partner_down_only_r`r'_2_bw) + (ft_partner_down_mom_r`r'_1 * ft_partner_down_mom_r`r'_1_bw) + (ft_partner_leave_r`r'_1 * ft_partner_leave_r`r'_1_bw) + (lt_other_changes_r`r'_1 * lt_other_changes_r`r'_1_bw)
	gen partner_down_mom_up_chg_r`r'  =   (mt_mom_r`r'_1 * mt_mom_r`r'_1_bw) + (ft_partner_down_only_r`r'_1 * ft_partner_down_only_r`r'_1_bw) + (ft_partner_down_mom_r`r'_2 * ft_partner_down_mom_r`r'_2_bw) + (ft_partner_leave_r`r'_1 * ft_partner_leave_r`r'_1_bw) + (lt_other_changes_r`r'_1 * lt_other_changes_r`r'_1_bw)
	gen partner_leave_change_r`r' =  (mt_mom_r`r'_1 * mt_mom_r`r'_1_bw) + (ft_partner_down_only_r`r'_1 * ft_partner_down_only_r`r'_1_bw) + (ft_partner_down_mom_r`r'_1 * ft_partner_down_mom_r`r'_1_bw) + (ft_partner_leave_r`r'_2 * ft_partner_leave_r`r'_2_bw) + (lt_other_changes_r`r'_1 * lt_other_changes_r`r'_1_bw)
	gen other_hh_change_r`r' =  (mt_mom_r`r'_1 * mt_mom_r`r'_1_bw) + (ft_partner_down_only_r`r'_1 * ft_partner_down_only_r`r'_1_bw) + (ft_partner_down_mom_r`r'_1 * ft_partner_down_mom_r`r'_1_bw) + (ft_partner_leave_r`r'_1 * ft_partner_leave_r`r'_1_bw) + (lt_other_changes_r`r'_2 * lt_other_changes_r`r'_2_bw)
	
	local row = `r'*2+12
	local row2 = `r'*2+13
	global bw_rate_96_r`r' = bw_rate_96_r`r'
	putexcel N`row' = ${bw_rate_96_r`r'}, nformat(#.##%)
	global bw_rate_14_r`r' = bw_rate_14_r`r'
	putexcel N`row2' = ${bw_rate_14_r`r'}, nformat(#.##%)
	global total_gap_r`r' = (bw_rate_14_r`r' - bw_rate_96_r`r')
	putexcel O`row' = ${total_gap_r`r'}, nformat(#.##%)
	global rate_diff_r`r' = (comp96_rate14_r`r' - bw_rate_96_r`r')
	putexcel P`row' = ${rate_diff_r`r'}, nformat(#.##%)
	global comp_diff_r`r' = (comp14_rate96_r`r' - bw_rate_96_r`r')
	putexcel Q`row' = ${comp_diff_r`r'}, nformat(#.##%)
	
	global mom_component_r`r' = ((mom_change_r`r' - bw_rate_96_r`r') / total_gap_r`r')
	putexcel R`row' = ${mom_component_r`r'}, nformat(#.##%)
	global partner_down_mom_component_r`r' = ((partner_down_mom_up_chg_r`r' - bw_rate_96_r`r') / total_gap_r`r')
	putexcel S`row' = ${partner_down_mom_component_r`r'}, nformat(#.##%)
	global partner_down_only_component_r`r' = ((partner_down_only_chg_r`r' - bw_rate_96_r`r') / total_gap_r`r')
	putexcel T`row' = ${partner_down_only_component_r`r'}, nformat(#.##%)
	global partner_leave_component_r`r' = ((partner_leave_change_r`r' - bw_rate_96_r`r') / total_gap_r`r')
	putexcel U`row' = ${partner_leave_component_r`r'}, nformat(#.##%)
	global other_hh_component_r`r' = ((other_hh_change_r`r' - bw_rate_96_r`r') / total_gap_r`r')
	putexcel V`row' = ${other_hh_component_r`r'}, nformat(#.##%)
}


*****************************
* Combined education

recode educ (1/2=1) (3=2) (4=3), gen(educ_gp)
label define educ_gp 1 "Hs or Less" 2 "Some College" 3 "College Plus"
label values educ_gp educ_gp

forvalues e=1/3{
local colu1 "D F H J L"
local colu2 "E G I K M"
local i=1

foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		local col1: word `i' of `colu1'
		local col2: word `i' of `colu2'
		local row1=`e'*2
			forvalues y=1/2{
			    local row=`row1'+`y'+20
				svy: mean `var' if bw60lag==0 & survey_yr==`y' & educ_gp==`e'
				matrix `var'_e`e'_`y' = e(b)
				gen `var'_e`e'_`y' = e(b)[1,1]
				svy: mean trans_bw60_alt2 if bw60lag==0 & survey_yr==`y' & `var'==1 & educ_gp==`e'
				matrix `var'_e`e'_`y'_bw = e(b)
				gen `var'_e`e'_`y'_bw = e(b)[1,1]
				putexcel `col1'`row' = matrix(`var'_e`e'_`y'), nformat(#.##%)
				putexcel `col2'`row' = matrix(`var'_e`e'_`y'_bw), nformat(#.##%)
			}
		local ++i
	}
}

forvalues e=1/3{
	gen bw_rate_96_e`e' = (mt_mom_e`e'_1 * mt_mom_e`e'_1_bw) + (ft_partner_down_only_e`e'_1 * ft_partner_down_only_e`e'_1_bw) + (ft_partner_down_mom_e`e'_1 * ft_partner_down_mom_e`e'_1_bw) + (ft_partner_leave_e`e'_1 * ft_partner_leave_e`e'_1_bw) + 	(lt_other_changes_e`e'_1 * lt_other_changes_e`e'_1_bw)
	gen bw_rate_14_e`e' = (mt_mom_e`e'_2 * mt_mom_e`e'_2_bw) + (ft_partner_down_only_e`e'_2 * ft_partner_down_only_e`e'_2_bw) + (ft_partner_down_mom_e`e'_2 * ft_partner_down_mom_e`e'_2_bw) + (ft_partner_leave_e`e'_2 * ft_partner_leave_e`e'_2_bw) + 	(lt_other_changes_e`e'_2 * lt_other_changes_e`e'_2_bw)
	gen comp96_rate14_e`e' = (mt_mom_e`e'_1 * mt_mom_e`e'_2_bw) + (ft_partner_down_only_e`e'_1 * ft_partner_down_only_e`e'_2_bw) + (ft_partner_down_mom_e`e'_1 * ft_partner_down_mom_e`e'_2_bw) + (ft_partner_leave_e`e'_1 * ft_partner_leave_e`e'_2_bw) + (lt_other_changes_e`e'_1 * lt_other_changes_e`e'_2_bw)
	gen comp14_rate96_e`e' = (mt_mom_e`e'_2 * mt_mom_e`e'_1_bw) + (ft_partner_down_only_e`e'_2 * ft_partner_down_only_e`e'_1_bw) + (ft_partner_down_mom_e`e'_2 * ft_partner_down_mom_e`e'_1_bw) + (ft_partner_leave_e`e'_2 * ft_partner_leave_e`e'_1_bw) + (lt_other_changes_e`e'_2 * lt_other_changes_e`e'_1_bw)
	
	gen total_gap_e`e' = (bw_rate_14_e`e' - bw_rate_96_e`e')
	
	gen mom_change_e`e' =  (mt_mom_e`e'_2 * mt_mom_e`e'_2_bw) +  (ft_partner_down_only_e`e'_1 * ft_partner_down_only_e`e'_1_bw) + (ft_partner_down_mom_e`e'_1 * ft_partner_down_mom_e`e'_1_bw) + (ft_partner_leave_e`e'_1 * ft_partner_leave_e`e'_1_bw) + (lt_other_changes_e`e'_1 * lt_other_changes_e`e'_1_bw)
	gen partner_down_only_chg_e`e' = (mt_mom_e`e'_1 * mt_mom_e`e'_1_bw) + (ft_partner_down_only_e`e'_2 * ft_partner_down_only_e`e'_2_bw) + (ft_partner_down_mom_e`e'_1 * ft_partner_down_mom_e`e'_1_bw) + (ft_partner_leave_e`e'_1 * ft_partner_leave_e`e'_1_bw) + (lt_other_changes_e`e'_1 * lt_other_changes_e`e'_1_bw)
	gen partner_down_mom_up_chg_e`e'  =   (mt_mom_e`e'_1 * mt_mom_e`e'_1_bw) + (ft_partner_down_only_e`e'_1 * ft_partner_down_only_e`e'_1_bw) + (ft_partner_down_mom_e`e'_2 * ft_partner_down_mom_e`e'_2_bw) + (ft_partner_leave_e`e'_1 * ft_partner_leave_e`e'_1_bw) + (lt_other_changes_e`e'_1 * lt_other_changes_e`e'_1_bw)
	gen partner_leave_change_e`e' =  (mt_mom_e`e'_1 * mt_mom_e`e'_1_bw) + (ft_partner_down_only_e`e'_1 * ft_partner_down_only_e`e'_1_bw) + (ft_partner_down_mom_e`e'_1 * ft_partner_down_mom_e`e'_1_bw) + (ft_partner_leave_e`e'_2 * ft_partner_leave_e`e'_2_bw) + (lt_other_changes_e`e'_1 * lt_other_changes_e`e'_1_bw)
	gen other_hh_change_e`e' =  (mt_mom_e`e'_1 * mt_mom_e`e'_1_bw) + (ft_partner_down_only_e`e'_1 * ft_partner_down_only_e`e'_1_bw) + (ft_partner_down_mom_e`e'_1 * ft_partner_down_mom_e`e'_1_bw) + (ft_partner_leave_e`e'_1 * ft_partner_leave_e`e'_1_bw) + (lt_other_changes_e`e'_2 * lt_other_changes_e`e'_2_bw)
	
	local row = `e'*2+21
	local row2 = `e'*2+22
	global bw_rate_96_e`e' = bw_rate_96_e`e'
	putexcel N`row' = ${bw_rate_96_e`e'}, nformat(#.##%)
	global bw_rate_14_e`e' = bw_rate_14_e`e'
	putexcel N`row2' = ${bw_rate_14_e`e'}, nformat(#.##%)
	global total_gap_e`e' = (bw_rate_14_e`e' - bw_rate_96_e`e')
	putexcel O`row' = ${total_gap_e`e'}, nformat(#.##%)
	global rate_diff_e`e' = (comp96_rate14_e`e' - bw_rate_96_e`e')
	putexcel P`row' = ${rate_diff_e`e'}, nformat(#.##%)
	global comp_diff_e`e' = (comp14_rate96_e`e' - bw_rate_96_e`e')
	putexcel Q`row' = ${comp_diff_e`e'}, nformat(#.##%)
	
	global mom_component_e`e' = ((mom_change_e`e' - bw_rate_96_e`e') / total_gap_e`e')
	putexcel R`row' = ${mom_component_e`e'}, nformat(#.##%)
	global partner_down_mom_component_e`e' = ((partner_down_mom_up_chg_e`e' - bw_rate_96_e`e') / total_gap_e`e')
	putexcel S`row' = ${partner_down_mom_component_e`e'}, nformat(#.##%)
	global partner_down_only_component_e`e' = ((partner_down_only_chg_e`e' - bw_rate_96_e`e') / total_gap_e`e')
	putexcel T`row' = ${partner_down_only_component_e`e'}, nformat(#.##%)
	global partner_leave_component_e`e' = ((partner_leave_change_e`e' - bw_rate_96_e`e') / total_gap_e`e')
	putexcel U`row' = ${partner_leave_component_e`e'}, nformat(#.##%)
	global other_hh_component_e`e' = ((other_hh_change_e`e' - bw_rate_96_e`e') / total_gap_e`e')
	putexcel V`row' = ${other_hh_component_e`e'}, nformat(#.##%)
}

********************************************************************************
* Second specification: "Mom" is reference category, rest are unique
********************************************************************************

*Dt-l: mothers not breadwinning at t-1
svy: tab survey bw60 if bw60lag==0, row // to ensure consecutive years, aka she is available to transition to BW the next year

*Mt = The proportion of mothers who experienced an increase in earnings. This is equal to the number of mothers who experienced an increase in earnings divided by Dt-1. This is now encompassing all mothers who experienced an increase, regardless if any other changes occurred.

gen mt2_mom = 0
replace mt2_mom = 1 if earnup8_all==1
replace mt2_mom = 1 if earn_change > 0 & earn_change <0.08 & mt2_mom==0 // to capture those outside the 8% threshold (v. small amount)

svy: tab survey mt2_mom if bw60lag==0, row

*Bmt = the proportion of mothers who experience an increase in earnings that became breadwinners. This is equal to the number of mothers who experience an increase in earnings and became breadwinners divided by Mt.

svy: tab mt2_mom trans_bw60_alt2 if survey==1996 & bw60lag==0, row
svy: tab mt2_mom trans_bw60_alt2 if survey==2014 & bw60lag==0, row

*Ft = the proportion of mothers who had their partner lose earnings OR leave. If mothers earnings also went up, they are captured above
gen ft2_partner_down = 0
replace ft2_partner_down = 1 if earndown8_sp_all==1 & earnup8_all==0 & mt2_mom==0 & partner_lose==0 // if partner left, want them there, not here
replace ft2_partner_down = 1 if earn_change_sp <0 & earn_change_sp >-.08 & earnup8_all==0 & mt2_mom==0 & ft2_partner_down==0 & partner_lose==0

svy: tab survey ft2_partner_down if bw60lag==0, row	
	
gen ft2_partner_leave = 0
replace ft2_partner_leave = 1 if partner_lose==1 & mt2_mom==0 & earnup8_all==0

svy: tab survey ft_partner_leave if bw60lag==0, row

*Bft = the proportion of mothers who had another household member lose earnings that became breadwinners
svy: tab ft2_partner_down trans_bw60_alt2 if survey==1996 & bw60lag==0, row
svy: tab ft2_partner_down trans_bw60_alt2 if survey==2014 & bw60lag==0, row 

svy: tab ft2_partner_leave trans_bw60_alt2 if survey==1996 & bw60lag==0, row 
svy: tab ft2_partner_leave trans_bw60_alt2 if survey==2014 & bw60lag==0, row 

*Lt = the proportion of mothers who either stopped living with someone (besides their partner) who was an earner OR someone else in the household's earnings went down (again besides her partner). Mom up is main category, so if mom experienced changes as well as someone else in HH, they are captured above. if mom didn't experience changes, but partner did, they are captured with partner, not here

gen lt2_other_changes = 0
replace lt2_other_changes = 1 if (earn_lose==1 | earndown8_oth_all==1) & (mt2_mom==0 & ft2_partner_down==0 & ft2_partner_leave==0)
	
svy: tab survey lt2_other_changes if bw60lag==0, row

*BLt = the proportion of mothers who stopped living with someone who was an earner that became a Breadwinner
svy: tab lt2_other_changes trans_bw60_alt2 if survey==1996 & bw60lag==0, row
svy: tab lt2_other_changes trans_bw60_alt2 if survey==2014 & bw60lag==0, row


*validate
svy: tab survey trans_bw60_alt2, row
svy: tab survey trans_bw60_alt2 if bw60lag==0, row



********************************************************************************
* Putting Equation 2 into Excel
********************************************************************************

*****************************
* Overall

putexcel set "$results/Breadwinner_Predictor_Equation", sheet(mom_ref) modify
putexcel A2:A3 = "Overall", merge
putexcel A5:A12 = "Education", merge
putexcel A14:A21 = "Race", merge
putexcel A23:A28 = "Education Groups", merge
putexcel B5:B6 = "Less than HS", merge
putexcel B7:B8 = "HS Degree", merge
putexcel B9:B10 = "Some College", merge
putexcel B11:B12 = "College Plus", merge
putexcel B14:B15 = "NH White", merge
putexcel B16:B17 = "Black", merge
putexcel B18:B19 = "NH Asian", merge
putexcel B20:B21 = "Hispanic", merge
putexcel B23:B24 = "HS or Less", merge
putexcel B25:B26 = "Some College", merge
putexcel B27:B28 = "College Plus", merge
putexcel C2 = ("1996") C5 = ("1996") C7 = ("1996") C9 = ("1996") C11 = ("1996") C14 = ("1996") C16 = ("1996") C18 = ("1996") C20 = ("1996") C23 = ("1996") C25 = ("1996") C27 = ("1996")
putexcel C3 = ("2014") C6 = ("2014") C8 = ("2014") C10 = ("2014") C12 = ("2014") C15 = ("2014") C17 = ("2014") C19 = ("2014") C21 = ("2014") C24 = ("2014") C26 = ("2014") C28 = ("2014")
putexcel D1 = "Mothers with an increase in earnings", border(bottom)
putexcel E1 = "Mothers with an increase in earnings AND became BW", border(bottom)
putexcel F1 = "Partner lost earnings", border(bottom)
putexcel G1 = "Partner lost earnings AND became BW", border(bottom)
putexcel H1 = "Partner left", border(bottom)
putexcel I1 = "Partner left AND became BW", border(bottom)
putexcel J1 = "Other member lost earnings / left", border(bottom)
putexcel K1 = "Other member lost earnings / left AND became BW", border(bottom)
putexcel L1 = "Rate of transition to BW", border(bottom)
putexcel M1 = "Total Difference", border(bottom)
putexcel N1 = "Rate Difference", border(bottom)
putexcel O1 = "Composition Difference", border(bottom)
putexcel P1 = "Mom Component", border(bottom)
putexcel Q1 = "Partner Down Component", border(bottom)
putexcel R1 = "Partner Left Component", border(bottom)
putexcel S1 = "Other Component", border(bottom)


local colu1 "D F H J"
local colu2 "E G I K"
local i=1

foreach var in mt2_mom ft2_partner_down ft2_partner_leave lt2_other_changes{
   	local col1: word `i' of `colu1'
	local col2: word `i' of `colu2'
		forvalues y=1/2{
			local row=`y'+1
			svy: mean `var' if bw60lag==0 & survey_yr==`y'
			matrix `var'_`y' = e(b)
			gen `var'_`y' = e(b)[1,1]
			svy: mean trans_bw60_alt2 if bw60lag==0 & survey_yr==`y' & `var'==1
			matrix `var'_`y'_bw = e(b)
			gen `var'_`y'_bw = e(b)[1,1]
			putexcel `col1'`row' = matrix(`var'_`y'), nformat(#.##%)
			putexcel `col2'`row' = matrix(`var'_`y'_bw), nformat(#.##%)
		}
	local ++i
}

gen e2_bw_rate_96 = (mt2_mom_1 * mt2_mom_1_bw) + (ft2_partner_down_1 * ft2_partner_down_1_bw) + (ft2_partner_leave_1 * ft2_partner_leave_1_bw) + (lt2_other_changes_1 * lt2_other_changes_1_bw)
gen e2_bw_rate_14 = (mt2_mom_2 * mt2_mom_2_bw) + (ft2_partner_down_2 * ft2_partner_down_2_bw) + (ft2_partner_leave_2 * ft2_partner_leave_2_bw) + (lt2_other_changes_2 * lt2_other_changes_2_bw)
gen e2_comp96_rate14 = (mt2_mom_1 * mt2_mom_2_bw) + (ft2_partner_down_1 * ft2_partner_down_2_bw) + (ft2_partner_leave_1 * ft2_partner_leave_2_bw) + (lt2_other_changes_1 * lt2_other_changes_2_bw)
gen e2_comp14_rate96 = (mt2_mom_2 * mt2_mom_1_bw) + (ft2_partner_down_2 * ft2_partner_down_1_bw) + (ft2_partner_leave_2 * ft2_partner_leave_1_bw) + (lt2_other_changes_2 * lt2_other_changes_1_bw)
gen e2_total_gap = (e2_bw_rate_14 - e2_bw_rate_96)
gen e2_mom_change =  (mt2_mom_2 * mt2_mom_2_bw) + (ft2_partner_down_1 * ft2_partner_down_1_bw) + (ft2_partner_leave_1 * ft2_partner_leave_1_bw) + (lt2_other_changes_1 * lt2_other_changes_1_bw)
gen e2_partner_down_change =  (mt2_mom_1 * mt2_mom_1_bw) + (ft2_partner_down_2 * ft2_partner_down_2_bw) + (ft2_partner_leave_1 * ft2_partner_leave_1_bw) + (lt2_other_changes_1 * lt2_other_changes_1_bw)
gen e2_partner_leave_change =  (mt2_mom_1 * mt2_mom_1_bw) + (ft2_partner_down_1 * ft2_partner_down_1_bw) + (ft2_partner_leave_2 * ft2_partner_leave_2_bw) + (lt2_other_changes_1 * lt2_other_changes_1_bw)
gen e2_other_hh_change =  (mt2_mom_1 * mt2_mom_1_bw) + (ft2_partner_down_1 * ft2_partner_down_1_bw) + (ft2_partner_leave_1 * ft2_partner_leave_1_bw) + (lt2_other_changes_2 * lt2_other_changes_2_bw)

global e2_bw_rate_96 = e2_bw_rate_96*100
putexcel L2 = $e2_bw_rate_96, nformat(#.##)
global e2_bw_rate_14 = e2_bw_rate_14*100
putexcel L3 = $e2_bw_rate_14, nformat(#.##)
global e2_total_gap = (e2_bw_rate_14 - e2_bw_rate_96)*100
putexcel M2 = $e2_total_gap, nformat(#.##)
global e2_rate_diff = (e2_comp96_rate14 - e2_bw_rate_96)*100
putexcel N2 = $e2_rate_diff, nformat(#.##)
global e2_comp_diff = (e2_comp14_rate96 - e2_bw_rate_96)*100
putexcel O2 = $e2_comp_diff, nformat(#.##)
global e2_mom_component = (e2_mom_change - e2_bw_rate_96)*100
putexcel P2 = $e2_mom_component, nformat(#.##)
global e2_partner_down_component = (e2_partner_down_change - e2_bw_rate_96)*100
putexcel Q2 = $e2_partner_down_component, nformat(#.##)
global e2_partner_leave_component = (e2_partner_leave_change - e2_bw_rate_96)*100
putexcel R2 = $e2_partner_leave_component, nformat(#.##)
global e2_other_hh_component = (e2_other_hh_change - e2_bw_rate_96)*100
putexcel S2 = $e2_other_hh_component, nformat(#.##)

display %9.3f ${e2_total_gap}
display %9.3f ${e2_rate_diff}
display %9.3f ${e2_comp_diff}

putexcel P3 = formula(=P2/M2), nformat(#.##)
putexcel Q3 = formula(=Q2/M2), nformat(#.##)
putexcel R3 = formula(=R2/M2), nformat(#.##)
putexcel S3 = formula(=S2/M2), nformat(#.##)


/* old component defs:
gen e2_mom_change =  (mt2_mom_2 * mt2_mom_2_bw) - (mt2_mom_1 * mt2_mom_1_bw)
gen e2_partner_down_change =  (ft2_partner_down_2 * ft2_partner_down_2_bw) - (ft2_partner_down_1 * ft2_partner_down_1_bw)
gen e2_partner_leave_change =  (ft2_partner_leave_2 * ft2_partner_leave_2_bw) - (ft2_partner_leave_1 * ft2_partner_leave_1_bw)
gen e2_other_hh_change =  (lt2_other_changes_2 * lt2_other_changes_2_bw) - (lt2_other_changes_1 * lt2_other_changes_1_bw)
*/


*****************************
* By education

forvalues e=1/4{
local colu1 "D F H J"
local colu2 "E G I K"
local i=1

foreach var in mt2_mom ft2_partner_down ft2_partner_leave lt2_other_changes{
    	local col1: word `i' of `colu1'
		local col2: word `i' of `colu2'
		local row1=`e'*2
			forvalues y=1/2{
			    local row=`row1'+`y'+2
				svy: mean `var' if bw60lag==0 & survey_yr==`y' & educ==`e'
				matrix `var'_`e'_`y' = e(b)
				gen `var'_`e'_`y' = e(b)[1,1]
				svy: mean trans_bw60_alt2 if bw60lag==0 & survey_yr==`y' & `var'==1 & educ==`e'
				matrix `var'_`e'_`y'_bw = e(b)
				gen `var'_`e'_`y'_bw = e(b)[1,1]
				putexcel `col1'`row' = matrix(`var'_`e'_`y'), nformat(#.##%)
				putexcel `col2'`row' = matrix(`var'_`e'_`y'_bw), nformat(#.##%)
			}
		local ++i
	}
}

forvalues e=1/4{
	gen e2_bw_rate_96_`e' = (mt2_mom_`e'_1 * mt2_mom_`e'_1_bw) + (ft2_partner_down_`e'_1 * ft2_partner_down_`e'_1_bw) + (ft2_partner_leave_`e'_1 * ft2_partner_leave_`e'_1_bw) + ///
	(lt2_other_changes_`e'_1 * lt2_other_changes_`e'_1_bw)
	gen e2_bw_rate_14_`e' = (mt2_mom_`e'_2 * mt2_mom_`e'_2_bw) + (ft2_partner_down_`e'_2 * ft2_partner_down_`e'_2_bw) + (ft2_partner_leave_`e'_2 * ft2_partner_leave_`e'_2_bw) + ///
	(lt2_other_changes_`e'_2 * lt2_other_changes_`e'_2_bw)
	gen e2_comp96_rate14_`e' = (mt2_mom_`e'_1 * mt2_mom_`e'_2_bw) + (ft2_partner_down_`e'_1 * ft2_partner_down_`e'_2_bw) + (ft2_partner_leave_`e'_1 * ft2_partner_leave_`e'_2_bw) + ///
	(lt2_other_changes_`e'_1 * lt2_other_changes_`e'_2_bw)
	gen e2_comp14_rate96_`e' = (mt2_mom_`e'_2 * mt2_mom_`e'_1_bw) + (ft2_partner_down_`e'_2 * ft2_partner_down_`e'_1_bw) + (ft2_partner_leave_`e'_2 * ft2_partner_leave_`e'_1_bw) + ///
	(lt2_other_changes_`e'_2 * lt2_other_changes_`e'_1_bw)
	
	gen e2_total_gap_`e' = (e2_bw_rate_14_`e' - e2_bw_rate_96_`e')
	gen e2_mom_change_`e' =  (mt2_mom_`e'_2 * mt2_mom_`e'_2_bw) + (ft2_partner_down_`e'_1 * ft2_partner_down_`e'_1_bw) + (ft2_partner_leave_`e'_1 * ft2_partner_leave_`e'_1_bw) + (lt2_other_changes_`e'_1 * lt2_other_changes_`e'_1_bw)
	gen e2_partner_down_change_`e' =  (mt2_mom_`e'_1 * mt2_mom_`e'_1_bw) + (ft2_partner_down_`e'_2 * ft2_partner_down_`e'_2_bw) + (ft2_partner_leave_`e'_1 * ft2_partner_leave_`e'_1_bw) + (lt2_other_changes_`e'_1 * lt2_other_changes_`e'_1_bw)
	gen e2_partner_leave_change_`e' =  (mt2_mom_`e'_1 * mt2_mom_`e'_1_bw) + (ft2_partner_down_`e'_1 * ft2_partner_down_`e'_1_bw) + (ft2_partner_leave_`e'_2 * ft2_partner_leave_`e'_2_bw) + (lt2_other_changes_`e'_1 * lt2_other_changes_`e'_1_bw)
	gen e2_other_hh_change_`e' =  (mt2_mom_`e'_1 * mt2_mom_`e'_1_bw) + (ft2_partner_down_`e'_1 * ft2_partner_down_`e'_1_bw) + (ft2_partner_leave_`e'_1 * ft2_partner_leave_`e'_1_bw) + (lt2_other_changes_`e'_2 * lt2_other_changes_`e'_2_bw)
	
	
	local row = `e'*2+3
	local row2 = `e'*2+4
	global e2_bw_rate_96_`e' = e2_bw_rate_96_`e'*100
	putexcel L`row' = ${e2_bw_rate_96_`e'}, nformat(#.##)
	global e2_bw_rate_14_`e' = e2_bw_rate_14_`e'*100
	putexcel L`row2' = ${e2_bw_rate_14_`e'}, nformat(#.##)
	global e2_total_gap_`e' = (e2_bw_rate_14_`e' - e2_bw_rate_96_`e')*100
	putexcel M`row' = ${e2_total_gap_`e'}, nformat(#.##)
	global e2_rate_diff_`e' = (e2_comp96_rate14_`e' - e2_bw_rate_96_`e')*100
	putexcel N`row' = ${e2_rate_diff_`e'}, nformat(#.##)
	global e2_comp_diff_`e' = (e2_comp14_rate96_`e' - e2_bw_rate_96_`e')*100
	putexcel O`row' = ${e2_comp_diff_`e'}, nformat(#.##)
	global e2_mom_component_`e' = (e2_mom_change_`e' - e2_bw_rate_96_`e')*100
	putexcel P`row' = ${e2_mom_component_`e'}, nformat(#.##)
	global e2_partner_down_component_`e' = (e2_partner_down_change_`e' - e2_bw_rate_96_`e')*100
	putexcel Q`row' = ${e2_partner_down_component_`e'}, nformat(#.##)
	global e2_partner_leave_component_`e' = (e2_partner_leave_change_`e'- e2_bw_rate_96_`e')*100
	putexcel R`row' = ${e2_partner_leave_component_`e'}, nformat(#.##)
	global e2_other_hh_component_`e' = (e2_other_hh_change_`e' - e2_bw_rate_96_`e')*100
	putexcel S`row' = ${e2_other_hh_component_`e'}, nformat(#.##)
}

local r1 "5 7 9 11"
local r2 "6 8 10 12"

forvalues e=1/4{
    local row1: word `e' of `r1'
	local row2: word `e' of `r2'
	putexcel P`row2' = formula(=P`row1'/M`row1'), nformat(#.##)
	putexcel Q`row2' = formula(=Q`row1'/M`row1'), nformat(#.##)
	putexcel R`row2' = formula(=R`row1'/M`row1'), nformat(#.##)
	putexcel S`row2' = formula(=S`row1'/M`row1'), nformat(#.##)
}


*****************************
* By race

forvalues r=1/4{
local colu1 "D F H J"
local colu2 "E G I K"
local i=1

foreach var in mt2_mom ft2_partner_down ft2_partner_leave lt2_other_changes{
		local col1: word `i' of `colu1'
		local col2: word `i' of `colu2'
		local row1=`r'*2
			forvalues y=1/2{
			    local row=`row1'+`y'+11
				svy: mean `var' if bw60lag==0 & survey_yr==`y' & race==`r'
				matrix `var'_r`r'_`y' = e(b)
				gen `var'_r`r'_`y' = e(b)[1,1]
				svy: mean trans_bw60_alt2 if bw60lag==0 & survey_yr==`y' & `var'==1 & race==`r'
				matrix `var'_r`r'_`y'_bw = e(b)
				gen `var'_r`r'_`y'_bw = e(b)[1,1]
				putexcel `col1'`row' = matrix(`var'_r`r'_`y'), nformat(#.##%)
				putexcel `col2'`row' = matrix(`var'_r`r'_`y'_bw), nformat(#.##%)
			}
		local ++i
	}
}

forvalues r=1/4{
	gen e2_bw_rate_96_r`r' = (mt2_mom_r`r'_1 * mt2_mom_r`r'_1_bw) + (ft2_partner_down_r`r'_1 * ft2_partner_down_r`r'_1_bw) + (ft2_partner_leave_r`r'_1 * ft2_partner_leave_r`r'_1_bw) + ///
	(lt2_other_changes_r`r'_1 * lt2_other_changes_r`r'_1_bw)
	gen e2_bw_rate_14_r`r' = (mt2_mom_r`r'_2 * mt2_mom_r`r'_2_bw) + (ft2_partner_down_r`r'_2 * ft2_partner_down_r`r'_2_bw) + (ft2_partner_leave_r`r'_2 * ft2_partner_leave_r`r'_2_bw) + ///
	(lt2_other_changes_r`r'_2 * lt2_other_changes_r`r'_2_bw)
	gen e2_comp96_rate14_r`r' = (mt2_mom_r`r'_1 * mt2_mom_r`r'_2_bw) + (ft2_partner_down_r`r'_1 * ft2_partner_down_r`r'_2_bw) + (ft2_partner_leave_r`r'_1 * ft2_partner_leave_r`r'_2_bw) + ///
	(lt2_other_changes_r`r'_1 * lt2_other_changes_r`r'_2_bw)
	gen e2_comp14_rate96_r`r' = (mt2_mom_r`r'_2 * mt2_mom_r`r'_1_bw) + (ft2_partner_down_r`r'_2 * ft2_partner_down_r`r'_1_bw) + (ft2_partner_leave_r`r'_2 * ft2_partner_leave_r`r'_1_bw) + ///
	(lt2_other_changes_r`r'_2 * lt2_other_changes_r`r'_1_bw)
	
	gen e2_total_gap_r`r' = (e2_bw_rate_14_r`r' - e2_bw_rate_96_r`r')
	gen e2_mom_change_r`r' =  (mt2_mom_r`r'_2 * mt2_mom_r`r'_2_bw) + (ft2_partner_down_r`r'_1 * ft2_partner_down_r`r'_1_bw) + (ft2_partner_leave_r`r'_1 * ft2_partner_leave_r`r'_1_bw) + (lt2_other_changes_r`r'_1 * lt2_other_changes_r`r'_1_bw)
	gen e2_partner_down_change_r`r' =  (mt2_mom_r`r'_1 * mt2_mom_r`r'_1_bw) + (ft2_partner_down_r`r'_2 * ft2_partner_down_r`r'_2_bw) + (ft2_partner_leave_r`r'_1 * ft2_partner_leave_r`r'_1_bw) + (lt2_other_changes_r`r'_1 * lt2_other_changes_r`r'_1_bw)
	gen e2_partner_leave_change_r`r' =  (mt2_mom_r`r'_1 * mt2_mom_r`r'_1_bw) + (ft2_partner_down_r`r'_1 * ft2_partner_down_r`r'_1_bw) + (ft2_partner_leave_r`r'_2 * ft2_partner_leave_r`r'_2_bw) + (lt2_other_changes_r`r'_1 * lt2_other_changes_r`r'_1_bw)
	gen e2_other_hh_change_r`r' =  (mt2_mom_r`r'_1 * mt2_mom_r`r'_1_bw) + (ft2_partner_down_r`r'_1 * ft2_partner_down_r`r'_1_bw) + (ft2_partner_leave_r`r'_1 * ft2_partner_leave_r`r'_1_bw) + (lt2_other_changes_r`r'_2 * lt2_other_changes_r`r'_2_bw)

	local row = `r'*2+12
	local row2 = `r'*2+13
	global e2_bw_rate_96_r`r' = e2_bw_rate_96_r`r'*100
	putexcel L`row' = ${e2_bw_rate_96_r`r'}, nformat(#.##)
	global e2_bw_rate_14_r`r' = e2_bw_rate_14_r`r'*100
	putexcel L`row2' = ${e2_bw_rate_14_r`r'}, nformat(#.##)
	global e2_total_gap_r`r' = (e2_bw_rate_14_r`r' - e2_bw_rate_96_r`r')*100
	putexcel M`row' = ${e2_total_gap_r`r'}, nformat(#.##)
	global e2_rate_diff_r`r' = (e2_comp96_rate14_r`r' - e2_bw_rate_96_r`r')*100
	putexcel N`row' = ${e2_rate_diff_r`r'}, nformat(#.##)
	global e2_comp_diff_r`r' = (e2_comp14_rate96_r`r' - e2_bw_rate_96_r`r')*100
	putexcel O`row' = ${e2_comp_diff_r`r'}, nformat(#.##)
	global e2_mom_component_r`r' = (e2_mom_change_r`r' - e2_bw_rate_96_r`r')*100
	putexcel P`row' = ${e2_mom_component_r`r'}, nformat(#.##)
	global e2_partner_down_component_r`r' = (e2_partner_down_change_r`r' - e2_bw_rate_96_r`r')*100
	putexcel Q`row' = ${e2_partner_down_component_r`r'}, nformat(#.##)
	global e2_partner_leave_component_r`r' = (e2_partner_leave_change_r`r' - e2_bw_rate_96_r`r')*100
	putexcel R`row' = ${e2_partner_leave_component_r`r'}, nformat(#.##)
	global e2_other_hh_component_r`r' = (e2_other_hh_change_r`r' - e2_bw_rate_96_r`r')*100
	putexcel S`row' = ${e2_other_hh_component_r`r'}, nformat(#.##)
}

local r1 "14 16 18 20"
local r2 "15 17 19 21"

forvalues r=1/4{
    local row1: word `r' of `r1'
	local row2: word `r' of `r2'
	putexcel P`row2' = formula(=P`row1'/M`row1'), nformat(#.##)
	putexcel Q`row2' = formula(=Q`row1'/M`row1'), nformat(#.##)
	putexcel R`row2' = formula(=R`row1'/M`row1'), nformat(#.##)
	putexcel S`row2' = formula(=S`row1'/M`row1'), nformat(#.##)
}

*****************************
* Combined education


forvalues e=1/3{
local colu1 "D F H J"
local colu2 "E G I K"
local i=1

foreach var in mt2_mom ft2_partner_down ft2_partner_leave lt2_other_changes{
		local col1: word `i' of `colu1'
		local col2: word `i' of `colu2'
		local row1=`e'*2
			forvalues y=1/2{
			    local row=`row1'+`y'+20
				svy: mean `var' if bw60lag==0 & survey_yr==`y' & educ_gp==`e'
				matrix `var'_e`e'_`y' = e(b)
				gen `var'_e`e'_`y' = e(b)[1,1]
				svy: mean trans_bw60_alt2 if bw60lag==0 & survey_yr==`y' & `var'==1 & educ_gp==`e'
				matrix `var'_e`e'_`y'_bw = e(b)
				gen `var'_e`e'_`y'_bw = e(b)[1,1]
				putexcel `col1'`row' = matrix(`var'_e`e'_`y'), nformat(#.##%)
				putexcel `col2'`row' = matrix(`var'_e`e'_`y'_bw), nformat(#.##%)
			}
		local ++i
	}
}

forvalues e=1/3{
	gen e2_bw_rate_96_e`e' = (mt2_mom_e`e'_1 * mt2_mom_e`e'_1_bw) + (ft2_partner_down_e`e'_1 * ft2_partner_down_e`e'_1_bw) + (ft2_partner_leave_e`e'_1 * ft2_partner_leave_e`e'_1_bw) + ///
	(lt2_other_changes_e`e'_1 * lt2_other_changes_e`e'_1_bw)
	gen e2_bw_rate_14_e`e' = (mt2_mom_e`e'_2 * mt2_mom_e`e'_2_bw) + (ft2_partner_down_e`e'_2 * ft2_partner_down_e`e'_2_bw) + (ft2_partner_leave_e`e'_2 * ft2_partner_leave_e`e'_2_bw) + ///
	(lt2_other_changes_e`e'_2 * lt2_other_changes_e`e'_2_bw)
	gen e2_comp96_rate14_e`e' = (mt2_mom_e`e'_1 * mt2_mom_e`e'_2_bw) + (ft2_partner_down_e`e'_1 * ft2_partner_down_e`e'_2_bw) + (ft2_partner_leave_e`e'_1 * ft2_partner_leave_e`e'_2_bw) + ///
	(lt2_other_changes_e`e'_1 * lt2_other_changes_e`e'_2_bw)
	gen e2_comp14_rate96_e`e' = (mt2_mom_e`e'_2 * mt2_mom_e`e'_1_bw) + (ft2_partner_down_e`e'_2 * ft2_partner_down_e`e'_1_bw) + (ft2_partner_leave_e`e'_2 * ft2_partner_leave_e`e'_1_bw) + ///
	(lt2_other_changes_e`e'_2 * lt2_other_changes_e`e'_1_bw)
	
	gen e2_total_gap_e`e' = (e2_bw_rate_14_e`e' - e2_bw_rate_96_e`e')
	gen e2_mom_change_e`e' =  (mt2_mom_e`e'_2 * mt2_mom_e`e'_2_bw) + (ft2_partner_down_e`e'_1 * ft2_partner_down_e`e'_1_bw) + (ft2_partner_leave_e`e'_1 * ft2_partner_leave_e`e'_1_bw) + (lt2_other_changes_e`e'_1 * lt2_other_changes_e`e'_1_bw)
	gen e2_partner_down_change_e`e' =  (mt2_mom_e`e'_1 * mt2_mom_e`e'_1_bw) + (ft2_partner_down_e`e'_2 * ft2_partner_down_e`e'_2_bw) + (ft2_partner_leave_e`e'_1 * ft2_partner_leave_e`e'_1_bw) + (lt2_other_changes_e`e'_1 * lt2_other_changes_e`e'_1_bw)
	gen e2_partner_leave_change_e`e' =  (mt2_mom_e`e'_1 * mt2_mom_e`e'_1_bw) + (ft2_partner_down_e`e'_1 * ft2_partner_down_e`e'_1_bw) + (ft2_partner_leave_e`e'_2 * ft2_partner_leave_e`e'_2_bw) + (lt2_other_changes_e`e'_1 * lt2_other_changes_e`e'_1_bw)
	gen e2_other_hh_change_e`e' =  (mt2_mom_e`e'_1 * mt2_mom_e`e'_1_bw) + (ft2_partner_down_e`e'_1 * ft2_partner_down_e`e'_1_bw) + (ft2_partner_leave_e`e'_1 * ft2_partner_leave_e`e'_1_bw) + (lt2_other_changes_e`e'_2 * lt2_other_changes_e`e'_2_bw)

	local row = `e'*2+21
	local row2 = `e'*2+22
	global e2_bw_rate_96_e`e' = e2_bw_rate_96_e`e'*100
	putexcel L`row' = ${e2_bw_rate_96_e`e'}, nformat(#.##)
	global e2_bw_rate_14_e`e' = e2_bw_rate_14_e`e'*100
	putexcel L`row2' = ${e2_bw_rate_14_e`e'}, nformat(#.##)
	global e2_total_gap_e`e' = (e2_bw_rate_14_e`e' - e2_bw_rate_96_e`e')*100
	putexcel M`row' = ${e2_total_gap_e`e'}, nformat(#.##)
	global e2_rate_diff_e`e' = (e2_comp96_rate14_e`e' - e2_bw_rate_96_e`e')*100
	putexcel N`row' = ${e2_rate_diff_e`e'}, nformat(#.##)
	global e2_comp_diff_e`e' = (e2_comp14_rate96_e`e' - e2_bw_rate_96_e`e')*100
	putexcel O`row' = ${e2_comp_diff_e`e'}, nformat(#.##)
	global e2_mom_component_e`e' = (e2_mom_change_e`e' - e2_bw_rate_96_e`e')*100
	putexcel P`row' = ${e2_mom_component_e`e'}, nformat(#.##)
	global e2_partner_down_component_e`e' = (e2_partner_down_change_e`e' - e2_bw_rate_96_e`e')*100
	putexcel Q`row' = ${e2_partner_down_component_e`e'}, nformat(#.##)
	global e2_partner_leave_component_e`e' = (e2_partner_leave_change_e`e' - e2_bw_rate_96_e`e')*100
	putexcel R`row' = ${e2_partner_leave_component_e`e'}, nformat(#.##)
	global e2_other_hh_component_e`e' = (e2_other_hh_change_e`e' - e2_bw_rate_96_e`e')*100
	putexcel S`row' = ${e2_other_hh_component_e`e'}, nformat(#.##)
}

local r1 "23 25 27"
local r2 "24 26 28"

forvalues e=1/3{
    local row1: word `e' of `r1'
	local row2: word `e' of `r2'
	putexcel P`row2' = formula(=P`row1'/M`row1'), nformat(#.##)
	putexcel Q`row2' = formula(=Q`row1'/M`row1'), nformat(#.##)
	putexcel R`row2' = formula(=R`row1'/M`row1'), nformat(#.##)
	putexcel S`row2' = formula(=S`row1'/M`row1'), nformat(#.##)
}

*****************************
// Create html document to describe results
dyndoc "$bw_base_code/Predictor_Decomposition.md", saving($results/Predictor_Decomposition.html) replace

drop base_1 base_2

save "$tempdir/combined_bw_equation.dta", replace