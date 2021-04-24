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

svyset [pweight = wpfinwgt]


********************************************************************************
* Accounts for duplicate years
********************************************************************************

*Dt-l: mothers not breadwinning at t-1
svy: tab survey bw60 if year==(year[_n+1]-1), row // to ensure consecutive years, aka she is available to transition to BW the next year

*Mt = The proportion of mothers who experienced an increase in earnings. This is equal to the number of mothers who experienced an increase in earnings divided by Dt-1. Mothers only included if no one else in the HH experienced a change.

gen mt_mom = 0
replace mt_mom = 1 if earnup8_all==1 & earn_lose==0 & earndown8_hh_all==0
replace mt_mom = 1 if earn_change > 0 & earn_lose==0 & earn_change_hh==0 & mt_mom==0 // to capture those outside the 8% threshold (v. small amount)

svy: tab survey mt_mom if bw60[_n-1]==0 & year==(year[_n-1]+1), row

svy: mean mt_mom if bw60[_n-1]==0 & year==(year[_n-1]+1) & survey==1996
svy: mean mt_mom if survey==1996

*Bmt = the proportion of mothers who experience an increase in earnings that became breadwinners. This is equal to the number of mothers who experience an increase in earnings and became breadwinners divided by Mt.

svy: tab mt_mom trans_bw60_alt2 if survey==1996 & bw60[_n-1]==0 & year==(year[_n-1]+1), row
svy: tab mt_mom trans_bw60_alt2 if survey==2014 & bw60[_n-1]==0 & year==(year[_n-1]+1), row

*Ft = the proportion of mothers who had their partner lose earnings OR leave. If mothers earnings also went up, they are captured here, not above.
gen ft_partner_down = 0
replace ft_partner_down = 1 if earndown8_sp_all==1 & mt_mom==0

svy: tab survey ft_partner_down if bw60[_n-1]==0 & year==(year[_n-1]+1), row

gen ft_partner_leave = 0
replace ft_partner_leave = 1 if lost_partner==1 & mt_mom==0

svy: tab survey ft_partner_leave if bw60[_n-1]==0 & year==(year[_n-1]+1), row

	browse ft_hh ft_partner mt_mom earn_lose thearn thearn_alt earnings earnings_a_sp hh_earn other_earn earnup8_all earndown8_sp_all earndown8_oth_all ///
	earndown8_hh_all earn_change_sp earn_change_hh earn_change_oth if ft_hh==0 & ft_partner==1
		
gen ft_overlap=0
replace ft_overlap = 1 if earn_lose==0 & earnup8_all==1 & earndown8_sp_all==1

*Bft = the proportion of mothers who had another household member lose earnings that became breadwinners
svy: tab ft_partner_down trans_bw60_alt2 if survey==1996 & bw60[_n-1]==0 & year==(year[_n-1]+1), row
svy: tab ft_partner_down trans_bw60_alt2 if survey==2014 & bw60[_n-1]==0 & year==(year[_n-1]+1), row 

svy: tab ft_partner_leave trans_bw60_alt2 if survey==1996 & bw60[_n-1]==0 & year==(year[_n-1]+1), row 
svy: tab ft_partner_leave trans_bw60_alt2 if survey==2014 & bw60[_n-1]==0 & year==(year[_n-1]+1), row 

*Lt = the proportion of mothers who either stopped living with someone (besides their partner) who was an earner OR someone else in the household's earnings went down (again besides her partner). Partner is main category, so if a partner experienced changes as well as someone else in HH, they are captured above.
gen lt_other_changes = 0
replace lt_other_changes = 1 if (earn_lose==1 | earndown8_oth_all==1) & (mt_mom==0 & ft_partner_down==0 & ft_partner_leave==0)
	
svy: tab survey lt_other_changes if bw60[_n-1]==0 & year==(year[_n-1]+1), row

*BLt = the proportion of mothers who stopped living with someone who was an earner that became a Breadwinner
svy: tab lt_other_changes trans_bw60_alt2 if survey==1996 & bw60[_n-1]==0 & year==(year[_n-1]+1), row
svy: tab lt_other_changes trans_bw60_alt2 if survey==2014 & bw60[_n-1]==0 & year==(year[_n-1]+1), row


*validate
svy: tab survey trans_bw60_alt2, row
svy: tab survey trans_bw60_alt2 if bw60[_n-1]==0 & year==(year[_n-1]+1), row


browse SSUID PNUM year bw60 trans_bw60 trans_bw60_alt trans_bw60_alt2 earnup8_all earndown8_hh_all earn_change earn_change_hh tpearn thearn mom_gain_earn hh_gain_earn hh_lose_earn if trans_bw60_alt2==1 & mt_mom==0 & ft_hh==0 & earn_lose==0 

browse SSUID PNUM year bw60 trans_bw60 trans_bw60_alt trans_bw60_alt2 earnup8_all earndown8_hh_all earn_change earn_change_hh tpearn thearn mom_gain_earn hh_gain_earn hh_lose_earn if  trans_bw60_alt2==1 & mt_mom==1 & ft_hh==1 & earn_lose==0 


// figuring out how to add in mothers who had their first birth in a panel
browse SSUID PNUM year firstbirth bw60 trans_bw60

svy: tab survey firstbirth, row
svy: tab survey firstbirth if bw60_mom==1 & bw60_mom[_n-1]==1 & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1) in 2/-1, row

//what if had other changes?

browse firstbirth mt_mom ft_hh earn_lose if firstbirth==1 & bw60==1 & bw60[_n-1]==1 & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1) in 2/-1 

********************************************************************************
* Trying to automate
********************************************************************************
egen id = concat (SSUID PNUM)
destring id, replace

gen survey_yr = 1 if survey==1996
replace survey_yr = 2 if survey==2014

*****************************
* Overall

egen base_1 = count(id) if bw60==0 & year==(year[_n+1]-1) & survey==1996
egen base_2 = count(id) if bw60==0 & year==(year[_n+1]-1) & survey==2014

/*template
svy: mean mt_mom if bw60[_n-1]==0 & year==(year[_n-1]+1) & survey==1996
svy: mean mt_mom if bw60[_n-1]==0 & year==(year[_n-1]+1) & survey==2014
svy: mean trans_bw60_alt2 if bw60[_n-1]==0 & year==(year[_n-1]+1) & survey==1996 & mt_mom==1
svy: mean trans_bw60_alt2 if bw60[_n-1]==0 & year==(year[_n-1]+1) & survey==2014 & mt_mom==1
*/

putexcel set "$results/Breadwinner_Predictor_Equation", sheet(data) replace
putexcel A2:A3 = "Overall", merge
putexcel A5:A12 = "Education", merge
putexcel A14:A21 = "Race", merge
putexcel B5:B6 = "Less than HS", merge
putexcel B7:B8 = "HS Degree", merge
putexcel B9:B10 = "Some College", merge
putexcel B11:B12 = "College Plus", merge
putexcel B14:B15 = "NH White", merge
putexcel B16:B17 = "Black", merge
putexcel B18:B19 = "NH Asian", merge
putexcel B20:B21 = "Hispanic", merge
putexcel C2 = ("1996") C5 = ("1996") C7 = ("1996") C9 = ("1996") C11 = ("1996") C14 = ("1996") C16 = ("1996") C18 = ("1996") C20 = ("1996")
putexcel C3 = ("2014") C6 = ("2014") C8 = ("2014") C10 = ("2014") C12 = ("2014") C15 = ("2014") C17 = ("2014") C19 = ("2014") C21 = ("2014")
putexcel D1 = "Mothers with an increase in earnings", border(bottom)
putexcel E1 = "Mothers with an increase in earnings AND became BW", border(bottom)
putexcel F1 = "Household member lost earnings", border(bottom)
putexcel G1 = "Household member lost earnings AND became BW", border(bottom)
putexcel H1 = "Partner lost earnings", border(bottom)
putexcel I1 = "Partner lost earnings AND became BW", border(bottom)
putexcel J1 = "Other member lost earnings", border(bottom)
putexcel K1 = "Other member lost earnings AND became BW", border(bottom)
putexcel L1 = "Earner left", border(bottom)
putexcel M1 = "Earner left AND became BW", border(bottom)
putexcel N1 = "Rate of transition to BW", border(bottom)
putexcel O1 = "Total Difference", border(bottom)
putexcel P1 = "Rate Difference", border(bottom)
putexcel Q1 = "Composition Difference", border(bottom)
putexcel R1 = "Mom Component", border(bottom)
putexcel S1 = "Partner Component", border(bottom)
putexcel T1 = "Other Component", border(bottom)
putexcel U1 = "Leaver Component", border(bottom)


local colu1 "D F H J L"
local colu2 "E G I K M"
local i=1

foreach var in mt_mom ft_hh ft_partner ft_other earn_lose{
   	local col1: word `i' of `colu1'
	local col2: word `i' of `colu2'
		forvalues y=1/2{
			local row=`y'+1
			svy: mean `var' if bw60[_n-1]==0 & year==(year[_n-1]+1) & survey_yr==`y'
			matrix `var'_`y' = e(b)
			gen `var'_`y' = e(b)[1,1]
			svy: mean trans_bw60_alt2 if bw60[_n-1]==0 & year==(year[_n-1]+1) & survey_yr==`y' & `var'==1
			matrix `var'_`y'_bw = e(b)
			gen `var'_`y'_bw = e(b)[1,1]
			putexcel `col1'`row' = matrix(`var'_`y'), nformat(#.##%)
			putexcel `col2'`row' = matrix(`var'_`y'_bw), nformat(#.##%)
		}
	local ++i
}

gen bw_rate_96 = (mt_mom_1 * mt_mom_1_bw) + (ft_partner_1 * ft_partner_1_bw) + (ft_other_1 * ft_other_1_bw) + (earn_lose_1 * earn_lose_1_bw)
gen bw_rate_14 = (mt_mom_2 * mt_mom_2_bw) + (ft_partner_2 * ft_partner_2_bw) + (ft_other_2 * ft_other_2_bw) + (earn_lose_2 * earn_lose_2_bw)
gen comp96_rate14 = (mt_mom_1 * mt_mom_2_bw) + (ft_partner_1 * ft_partner_2_bw) + (ft_other_1 * ft_other_2_bw) + (earn_lose_1 * earn_lose_2_bw)
gen comp14_rate96 = (mt_mom_2 * mt_mom_1_bw) + (ft_partner_2 * ft_partner_1_bw) + (ft_other_2 * ft_other_1_bw) + (earn_lose_2 * earn_lose_1_bw)
gen total_gap = (bw_rate_14 - bw_rate_96)
gen mom_change =  (mt_mom_2 * mt_mom_2_bw) - (mt_mom_1 * mt_mom_1_bw)
gen partner_change =  (ft_partner_2 * ft_partner_2_bw) - (ft_partner_1 * ft_partner_1_bw)
gen other_hh_change =  (ft_other_2 * ft_other_2_bw) - (ft_other_1 * ft_other_1_bw)
gen leaver_change =  (earn_lose_2 * earn_lose_2_bw) - (earn_lose_1 * earn_lose_1_bw)

global bw_rate_96 = bw_rate_96*100
putexcel N2 = $bw_rate_96, nformat(#.##)
global bw_rate_14 = bw_rate_14*100
putexcel N3 = $bw_rate_14, nformat(#.##)
global total_gap = (bw_rate_14 - bw_rate_96)*100
putexcel O2 = $total_gap, nformat(#.##)
global rate_diff = (comp96_rate14 - bw_rate_96)*100
putexcel P2 = $rate_diff, nformat(#.##)
global comp_diff = (comp14_rate96 - bw_rate_96)*100
putexcel Q2 = $comp_diff, nformat(#.##)
global mom_component = (mom_change / total_gap) * 100
putexcel R2 = $mom_component, nformat(#.##)
global partner_component = (partner_change / total_gap) * 100
putexcel S2 = $partner_component, nformat(#.##)
global other_hh_component = (other_hh_change / total_gap) * 100
putexcel T2 = $other_hh_component, nformat(#.##)
global leaver_component = (leaver_change / total_gap) * 100
putexcel U2 = $leaver_component, nformat(#.##)

display %9.3f ${total_gap}
display %9.3f ${rate_diff}
display %9.3f ${comp_diff}

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
	foreach var in mt_mom ft_hh ft_partner ft_other earn_lose{
		local col1: word `i' of `colu1'
		local col2: word `i' of `colu2'
		local row1=`e'*2
			forvalues y=1/2{
			    local row=`row1'+`y'+2
				svy: mean `var' if bw60[_n-1]==0 & year==(year[_n-1]+1) & survey_yr==`y' & educ==`e'
				matrix `var'_`e'_`y' = e(b)
				gen `var'_`e'_`y' = e(b)[1,1]
				svy: mean trans_bw60_alt2 if bw60[_n-1]==0 & year==(year[_n-1]+1) & survey_yr==`y' & `var'==1 & educ==`e'
				matrix `var'_`e'_`y'_bw = e(b)
				gen `var'_`e'_`y'_bw = e(b)[1,1]
				putexcel `col1'`row' = matrix(`var'_`e'_`y'), nformat(#.##%)
				putexcel `col2'`row' = matrix(`var'_`e'_`y'_bw), nformat(#.##%)
			}
		local ++i
	}
}

forvalues e=1/4{
	gen bw_rate_96_`e' = (mt_mom_`e'_1 * mt_mom_`e'_1_bw) + (ft_partner_`e'_1 * ft_partner_`e'_1_bw) + (ft_other_`e'_1 * ft_other_`e'_1_bw) + ///
	(earn_lose_`e'_1 * earn_lose_`e'_1_bw)
	gen bw_rate_14_`e' = (mt_mom_`e'_2 * mt_mom_`e'_2_bw) + (ft_partner_`e'_2 * ft_partner_`e'_2_bw) + (ft_other_`e'_2 * ft_other_`e'_2_bw) + ///
	(earn_lose_`e'_2 * earn_lose_`e'_2_bw)
	gen comp96_rate14_`e' = (mt_mom_`e'_1 * mt_mom_`e'_2_bw) + (ft_partner_`e'_1 * ft_partner_`e'_2_bw) + (ft_other_`e'_1 * ft_other_`e'_2_bw) + ///
	(earn_lose_`e'_1 * earn_lose_`e'_2_bw)
	gen comp14_rate96_`e' = (mt_mom_`e'_2 * mt_mom_`e'_1_bw) + (ft_partner_`e'_2 * ft_partner_`e'_1_bw) + (ft_other_`e'_2 * ft_other_`e'_1_bw) + ///
	(earn_lose_`e'_2 * earn_lose_`e'_1_bw)
	
	gen total_gap_`e' = (bw_rate_14_`e' - bw_rate_96_`e')
	gen mom_change_`e' =  (mt_mom_`e'_2 * mt_mom_`e'_2_bw) - (mt_mom_`e'_1 * mt_mom_`e'_1_bw)
	gen partner_change_`e' =  (ft_partner_`e'_2 * ft_partner_`e'_2_bw) - (ft_partner_`e'_1 * ft_partner_`e'_1_bw)
	gen other_hh_change_`e' =  (ft_other_`e'_2 * ft_other_`e'_2_bw) - (ft_other_`e'_1 * ft_other_`e'_1_bw)
	gen leaver_change_`e' =  (earn_lose_`e'_2 * earn_lose_`e'_2_bw) - (earn_lose_`e'_1 * earn_lose_`e'_1_bw)

	local row = `e'*2+3
	local row2 = `e'*2+4
	global bw_rate_96_`e' = bw_rate_96_`e'*100
	putexcel N`row' = ${bw_rate_96_`e'}, nformat(#.##)
	global bw_rate_14_`e' = bw_rate_14_`e'*100
	putexcel N`row2' = ${bw_rate_14_`e'}, nformat(#.##)
	global total_gap_`e' = (bw_rate_14_`e' - bw_rate_96_`e')*100
	putexcel O`row' = ${total_gap_`e'}, nformat(#.##)
	global rate_diff_`e' = (comp96_rate14_`e' - bw_rate_96_`e')*100
	putexcel P`row' = ${rate_diff_`e'}, nformat(#.##)
	global comp_diff_`e' = (comp14_rate96_`e' - bw_rate_96_`e')*100
	putexcel Q`row' = ${comp_diff_`e'}, nformat(#.##)
	global mom_component_`e' = (mom_change_`e' / total_gap_`e') * 100
	putexcel R`row' = ${mom_component_`e'}, nformat(#.##)
	global partner_component_`e' = (partner_change_`e' / total_gap_`e') * 100
	putexcel S`row' = ${partner_component_`e'}, nformat(#.##)
	global other_hh_component_`e' = (other_hh_change_`e' / total_gap_`e') * 100
	putexcel T`row' = ${other_hh_component_`e'}, nformat(#.##)
	global leaver_component_`e' = (leaver_change_`e' / total_gap_`e') * 100
	putexcel U`row' = ${leaver_component_`e'}, nformat(#.##)
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
	foreach var in mt_mom ft_hh ft_partner ft_other earn_lose{
		local col1: word `i' of `colu1'
		local col2: word `i' of `colu2'
		local row1=`r'*2
			forvalues y=1/2{
			    local row=`row1'+`y'+11
				svy: mean `var' if bw60[_n-1]==0 & year==(year[_n-1]+1) & survey_yr==`y' & race==`r'
				matrix `var'_r`r'_`y' = e(b)
				gen `var'_r`r'_`y' = e(b)[1,1]
				svy: mean trans_bw60_alt2 if bw60[_n-1]==0 & year==(year[_n-1]+1) & survey_yr==`y' & `var'==1 & race==`r'
				matrix `var'_r`r'_`y'_bw = e(b)
				gen `var'_r`r'_`y'_bw = e(b)[1,1]
				putexcel `col1'`row' = matrix(`var'_r`r'_`y'), nformat(#.##%)
				putexcel `col2'`row' = matrix(`var'_r`r'_`y'_bw), nformat(#.##%)
			}
		local ++i
	}
}

forvalues r=1/4{
	gen bw_rate_96_r`r' = (mt_mom_r`r'_1 * mt_mom_r`r'_1_bw) + (ft_partner_r`r'_1 * ft_partner_r`r'_1_bw) + (ft_other_r`r'_1 * ft_other_r`r'_1_bw) + ///
	(earn_lose_r`r'_1 * earn_lose_r`r'_1_bw)
	gen bw_rate_14_r`r' = (mt_mom_r`r'_2 * mt_mom_r`r'_2_bw) + (ft_partner_r`r'_2 * ft_partner_r`r'_2_bw) + (ft_other_r`r'_2 * ft_other_r`r'_2_bw) + ///
	(earn_lose_r`r'_2 * earn_lose_r`r'_2_bw)
	gen comp96_rate14_r`r' = (mt_mom_r`r'_1 * mt_mom_r`r'_2_bw) + (ft_partner_r`r'_1 * ft_partner_r`r'_2_bw) + (ft_other_r`r'_1 * ft_other_r`r'_2_bw) + ///
	(earn_lose_r`r'_1 * earn_lose_r`r'_2_bw)
	gen comp14_rate96_r`r' = (mt_mom_r`r'_2 * mt_mom_r`r'_1_bw) + (ft_partner_r`r'_2 * ft_partner_r`r'_1_bw) + (ft_other_r`r'_2 * ft_other_r`r'_1_bw) + ///
	(earn_lose_r`r'_2 * earn_lose_r`r'_1_bw)
	
	gen total_gap_r`r' = (bw_rate_14_r`r' - bw_rate_96_r`r')
	gen mom_change_r`r' =  (mt_mom_r`r'_2 * mt_mom_r`r'_2_bw) - (mt_mom_r`r'_1 * mt_mom_r`r'_1_bw)
	gen partner_change_r`r' =  (ft_partner_r`r'_2 * ft_partner_r`r'_2_bw) - (ft_partner_r`r'_1 * ft_partner_r`r'_1_bw)
	gen other_hh_change_r`r' =  (ft_other_r`r'_2 * ft_other_r`r'_2_bw) - (ft_other_r`r'_1 * ft_other_r`r'_1_bw)
	gen leaver_change_r`r' =  (earn_lose_r`r'_2 * earn_lose_r`r'_2_bw) - (earn_lose_r`r'_1 * earn_lose_r`r'_1_bw)

	local row = `r'*2+12
	local row2 = `r'*2+13
	global bw_rate_96_r`r' = bw_rate_96_r`r'*100
	putexcel N`row' = ${bw_rate_96_r`r'}, nformat(#.##)
	global bw_rate_14_r`r' = bw_rate_14_r`r'*100
	putexcel N`row2' = ${bw_rate_14_r`r'}, nformat(#.##)
	global total_gap_r`r' = (bw_rate_14_r`r' - bw_rate_96_r`r')*100
	putexcel O`row' = ${total_gap_r`r'}, nformat(#.##)
	global rate_diff_r`r' = (comp96_rate14_r`r' - bw_rate_96_r`r')*100
	putexcel P`row' = ${rate_diff_r`r'}, nformat(#.##)
	global comp_diff_r`r' = (comp14_rate96_r`r' - bw_rate_96_r`r')*100
	putexcel Q`row' = ${comp_diff_r`r'}, nformat(#.##)
	global mom_component_r`r' = (mom_change_r`r' / total_gap_r`r') * 100
	putexcel R`row' = ${mom_component_r`r'}, nformat(#.##)
	global partner_component_r`r' = (partner_change_r`r' / total_gap_r`r') * 100
	putexcel S`row' = ${partner_component_r`r'}, nformat(#.##)
	global other_hh_component_r`r' = (other_hh_change_r`r' / total_gap_r`r') * 100
	putexcel T`row' = ${other_hh_component_r`r'}, nformat(#.##)
	global leaver_component_r`r' = (leaver_change_r`r' / total_gap_r`r') * 100
	putexcel U`row' = ${leaver_component_r`r'}, nformat(#.##)
}

*****************************
// Create html document to describe results
dyndoc "$SIPP2014_code/Predictor_Decomposition.md", saving($results/Predictor_Decomposition.html) replace


/*

********************************************************************************
* Original specification (results presented in 4/22 meeting)
********************************************************************************
* we changed breakdowns to isolate partner. Before we isolated declines v. left.


*Dt-l: mothers not breadwinning at t-1
svy: tab survey bw60 if year==(year[_n+1]-1), row // to ensure consecutive years, aka she is available to transition to BW the next year

*Mt = The proportion of mothers who experienced an increase in earnings. This is equal to the number of mothers who experienced an increase in earnings divided by Dt-1. Mothers only included if no one else in the HH experienced a change.

gen mt_mom = 0
replace mt_mom = 1 if earnup8_all==1 & earn_lose==0 & earndown8_hh_all==0
replace mt_mom = 1 if earn_change > 0 & earn_lose==0 & earn_change_hh==0 & mt_mom==0 // to capture those outside the 8% threshold (v. small amount)

svy: tab survey mt_mom if bw60[_n-1]==0 & year==(year[_n-1]+1), row

svy: mean mt_mom if bw60[_n-1]==0 & year==(year[_n-1]+1) & survey==1996
svy: mean mt_mom if survey==1996

*Bmt = the proportion of mothers who experience an increase in earnings that became breadwinners. This is equal to the number of mothers who experience an increase in earnings and became breadwinners divided by Mt.

svy: tab mt_mom trans_bw60_alt2 if survey==1996 & bw60[_n-1]==0 & year==(year[_n-1]+1), row
svy: tab mt_mom trans_bw60_alt2 if survey==2014 & bw60[_n-1]==0 & year==(year[_n-1]+1), row

*Ft = the proportion of mothers who had another household member lose earnings. If mothers earnings also went up, they are captured here, not above.
gen ft_hh = 0
replace ft_hh = 1 if earn_lose==0 & earndown8_hh_all==1
replace ft_hh = 1 if earn_lose==0 & (earn_change_hh<0 & earn_change_hh>-.08) & (earn_change >0 & earn_change <.08) & ft_hh==0 // to capture those outside the 8% threshold (v. small amount)

svy: tab survey ft_hh if bw60[_n-1]==0 & year==(year[_n-1]+1), row

	** Breaking down the ft_hh into partner and all other

	gen ft_partner=0
	replace ft_partner = 1 if earn_lose==0 & earnup8_all==0 & earndown8_sp_all==1 & earndown8_oth_all==0 // also saying NO ONE else in hh's earnings could go down, JUST partner

	gen ft_other=0
	replace ft_other = 1 if earn_lose==0 & earndown8_hh_all==1 & ((earnup8_all==1 & earndown8_sp_all==1) | (earndown8_sp_all==1 & earndown8_oth_all==1))
	replace ft_other = 1 if ft_hh==1 & ft_partner==0 & ft_other==0

	browse ft_hh ft_partner mt_mom earn_lose thearn thearn_alt earnings earnings_a_sp hh_earn other_earn earnup8_all earndown8_sp_all earndown8_oth_all ///
	earndown8_hh_all earn_change_sp earn_change_hh earn_change_oth if ft_hh==0 & ft_partner==1
	
	svy: tab survey ft_partner if bw60[_n-1]==0 & year==(year[_n-1]+1), row
	svy: tab survey ft_other if bw60[_n-1]==0 & year==(year[_n-1]+1), row
	
	gen ft_overlap=0
	replace ft_overlap = 1 if earn_lose==0 & earnup8_all==1 & earndown8_sp_all==1

*Bft = the proportion of mothers who had another household member lose earnings that became breadwinners
svy: tab ft_hh trans_bw60_alt2 if survey==1996 & bw60[_n-1]==0 & year==(year[_n-1]+1), row
svy: tab ft_hh trans_bw60_alt2 if survey==2014 & bw60[_n-1]==0 & year==(year[_n-1]+1), row 

svy: tab ft_partner trans_bw60_alt2 if survey==1996 & bw60[_n-1]==0 & year==(year[_n-1]+1), row 
svy: tab ft_partner trans_bw60_alt2 if survey==2014 & bw60[_n-1]==0 & year==(year[_n-1]+1), row 

svy: tab ft_other trans_bw60_alt2 if survey==1996 & bw60[_n-1]==0 & year==(year[_n-1]+1), row
svy: tab ft_other trans_bw60_alt2 if survey==2014 & bw60[_n-1]==0 & year==(year[_n-1]+1), row

*Lt = the proportion of mothers who stopped living with someone who was an earner. This is the main category, such that if mother's earnings went up or HH earnings went down AND someone left, they will be here.
	
svy: tab survey earn_lose if bw60[_n-1]==0 & year==(year[_n-1]+1), row


*BLt = the proportion of mothers who stopped living with someone who was an earner that became a Breadwinner
svy: tab earn_lose trans_bw60_alt2 if survey==1996 & bw60[_n-1]==0 & year==(year[_n-1]+1), row
svy: tab earn_lose trans_bw60_alt2 if survey==2014 & bw60[_n-1]==0 & year==(year[_n-1]+1), row

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