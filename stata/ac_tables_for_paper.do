*-------------------------------------------------------------------------------
* BREADWINNER PROJECT
* decomposition_equation.do
* Kim McErlean
*-------------------------------------------------------------------------------
di "$S_DATE"

********************************************************************************
* DESCRIPTION
********************************************************************************
* This file creates Tables 1-4 for the paper (basic descriptives of the sample)
* as well as tables for the results of the decomposition equation

* File used was created in ab_decomposition_equation.do

use "$tempdir/combined_bw_equation.dta", clear

********************************************************************************
* Creating tables for paper
********************************************************************************

// Table 1: Sample descriptives
putexcel set "$results/Breadwinner_Predictor_Tables", sheet(Table1) replace
putexcel A1:D1 = "Unweighted Ns", merge border(bottom) hcenter bold
putexcel B2 = "Total Sample"
putexcel C2 = "1996 SIPP"
putexcel D2 = "2014 SIPP"
putexcel A3 = "No. of respondents"
putexcel A4 = "No. of person-years"
putexcel A5 = "No. of transitions to primary earning status"
putexcel A6:D6 = "Weighted Descriptives", merge border(bottom) hcenter bold
putexcel A7 = "Median HH income at time t-1 (inflation-adjusted)"
putexcel A8 = "Mothers' median income at time t-1 (inflation-adjusted)"
putexcel A9 = "Race/ethnicity (time-invariant)"
putexcel A10 = "Non-Hispanic White", txtindent(4)
putexcel A11 = "Black", txtindent(4)
putexcel A12 = "Non-Hispanic Asian", txtindent(4)
putexcel A13 = "Hispanic", txtindent(4)
putexcel A14 = "Education (time-varying)"
putexcel A15 = "Less than HS", txtindent(4)
putexcel A16 = "HS Degree", txtindent(4)
putexcel A17 = "Some College", txtindent(4)
putexcel A18 = "College Plus", txtindent(4)
putexcel A19 = "Relationship Status (time-varying)"
putexcel A20 = "Married", txtindent(4)
putexcel A21 = "Cohabitating", txtindent(4)
putexcel A22 = "Single", txtindent(4)

local colu "C D"

// there is probably a more efficient way to do this but I am currently struggling

*Sample total
forvalues y=1/2{
	local col: word `y' of `colu'
	egen total_N_`y' = nvals(id) if survey_yr==`y'
	sum total_N_`y'
	replace total_N_`y' = r(mean)
	local total_N_`y' = total_N_`y'
	putexcel `col'3= `total_N_`y'', nformat(###,###)
	egen total_PY_`y' = count(id) if survey_yr==`y'
	sum total_PY_`y'
	replace total_PY_`y' = r(mean)
	local total_PY_`y' = total_PY_`y'
	putexcel `col'4= `total_PY_`y'', nformat(###,###)
}

egen total_N = nvals(id) 
global total_N = total_N
putexcel B3 = $total_N, nformat(###,###)
egen total_PY = count(id)
global total_PY = total_PY
putexcel B4 = $total_PY, nformat(###,###)

*Transitions
gen eligible=(bw60lag==0)
replace eligible=. if bw60lag==.
gen transitioned=0
replace transitioned=1 if trans_bw60_alt2==1 & bw60lag==0
replace transitioned=. if trans_bw60_alt2==.
// svy: tab eligible, obs
// this is what it needs to match: svy: tab survey trans_bw60_alt2 if bw60lag==0, row

local colu "C D"

forvalues y=1/2{
	local col: word `y' of `colu'
	** sum eligible if survey_yr==`y'
	** putexcel `col'5=(`r(mean)'*`r(N)'), nformat(###,###)
	sum transitioned if survey_yr==`y'
	putexcel `col'5=(`r(mean)'*`r(N)'), nformat(###,###)
}

** sum eligible
** putexcel B5=(`r(mean)'*`r(N)'), nformat(###,###)
sum transitioned
putexcel B5=(`r(mean)'*`r(N)'), nformat(###,###)

*Income 
* HH
sum thearn_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID  [aweight=wpfinwgt], detail // is this t-1?
putexcel B7=`r(p50)', nformat(###,###)
sum thearn_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 [aweight=wpfinwgt], detail // is this t-1?
putexcel C7=`r(p50)', nformat(###,###)
sum thearn_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 [aweight=wpfinwgt], detail
putexcel D7=`r(p50)', nformat(###,###)

*Mother
sum earnings_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID [aweight=wpfinwgt], detail // is this t-1?
putexcel B8=`r(p50)', nformat(###,###)
sum earnings_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 [aweight=wpfinwgt], detail // is this t-1?
putexcel C8=`r(p50)', nformat(###,###)
sum earnings_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 [aweight=wpfinwgt], detail 
putexcel D8=`r(p50)', nformat(###,###)

* Race
tab race [aweight=wpfinwgt], gen(race)
// test: svy: mean race1

local colu "C D"
local i=1

foreach var in race1 race2 race3 race4{
		
		forvalues y=1/2{
			local col: word `y' of `colu'
			local row = `i'+9
			svy: mean `var' if survey_yr==`y'
			matrix `var'_`y' = e(b)
			putexcel `col'`row' = matrix(`var'_`y'), nformat(#.##%)
		}
		
		svy: mean `var'
		matrix `var' = e(b)
		putexcel B`row' = matrix(`var'), nformat(#.##%)
		local ++i
	}

* Education
tab educ [aweight=wpfinwgt], gen(educ)
// test: svy: mean educ1

local colu "C D"
local i=1

foreach var in educ1 educ2 educ3 educ4{
		
		forvalues y=1/2{
			local col: word `y' of `colu'
			local row = `i'+14
			svy: mean `var' if survey_yr==`y'
			matrix `var'_`y' = e(b)
			putexcel `col'`row' = matrix(`var'_`y'), nformat(#.##%)
		}
		
		svy: mean `var'
		matrix `var' = e(b)
		putexcel B`row' = matrix(`var'), nformat(#.##%)
		local ++i
	}
	

* Marital Status - December of prior year
recode last_marital_status (1=1) (2=2) (3/5=3), gen(marital_status_t1)
label define marr 1 "Married" 2 "Cohabiting" 3 "Single"
label values marital_status_t1 marr

tab marital_status_t1 [aweight=wpfinwgt], gen(marst)

local colu "C D"
local i=1

foreach var in marst1 marst2 marst3{
		
		forvalues y=1/2{
			local col: word `y' of `colu'
			local row = `i'+19
			svy: mean `var' if survey_yr==`y'
			matrix `var'_`y' = e(b)
			putexcel `col'`row' = matrix(`var'_`y'), nformat(#.##%)
		}
		
		svy: mean `var'
		matrix `var' = e(b)
		putexcel B`row' = matrix(`var'), nformat(#.##%)
		local ++i
	}


/* Marital Status - change in year

gen married = no_status_chg==1 & end_marital_status==1
gen cohab = no_status_chg==1 & end_marital_status==2
gen single = no_status_chg==1 & inlist(end_marital_status,3,4,5)

local status_vars "married cohab single sing_coh sing_mar coh_mar coh_diss marr_diss marr_wid marr_coh"

forvalues w=1/10 {
	forvalues y=1/2{
		local col: word `y' of `colu'
		local row = `w'+19
		local var: word `w' of `status_vars'
		egen n_`var'_`y' = count(id) if survey_yr==`y' & `var'==1
		sum n_`var'_`y'
		replace n_`var'_`y' = r(mean)
		local n_`var'_`y' = n_`var'_`y'
		putexcel `col'`row'= `n_`var'_`y'', nformat(###,###)
		}
		
	egen n_`var' = count(id) if `var'==1
	sum n_`var'
	replace n_`var' = r(mean)
	local n_`var' = n_`var'
	putexcel B`row'= `n_`var'', nformat(###,###)
}

forvalues w=1/10 {
	forvalues y=1/2{
		local col: word `y' of `colu'
		local row = `w'+19
		local var: word `w' of `status_vars'
		sum `var' if survey_yr==`y'
		putexcel `col'`row' = `r(mean)', nformat(#.##%)
		}
		
	sum `var'
	putexcel B`row' =`r(mean)', nformat(#.##%)
}
*/

// Table 2: Overall equation

putexcel set "$results/Breadwinner_Predictor_Tables", sheet(Table2) modify
putexcel B1:C1 = "Total", merge border(bottom)
putexcel D1:I1 = "Education", merge border(bottom)
putexcel J1:Q1 = "Race / ethnicity", merge border(bottom)
putexcel B2:C2 = "Total", merge border(bottom)
putexcel D2:E2 = "HS Degree or Less", merge border(bottom)
putexcel F2:G2 = "Some College", merge border(bottom)
putexcel H2:I2 = "College Plus", merge border(bottom)
putexcel J2:K2 = "NH White", merge border(bottom)
putexcel L2:M2 = "Black", merge border(bottom)
putexcel N2:O2 = "NH Asian", merge border(bottom)
putexcel P2:Q2 = "Hispanic", merge border(bottom)
putexcel A3:Q3 = "1996 precipitating events", merge hcenter bold border(bottom)
putexcel A4 = "Event"
putexcel B4 = ("All events") D4 = ("All events") F4 = ("All events") H4 = ("All events") J4 = ("All events") L4 = ("All events") N4 = ("All events") P4 = ("All events")
putexcel C4 = ("Event precipitated") E4 = ("Event precipitated") G4 = ("Event precipitated") I4 = ("Event precipitated") K4 = ("Event precipitated") M4 = ("Event precipitated") O4 = ("Event precipitated") Q4 = ("Event precipitated")
putexcel A5 = "Mothers only an increase in earnings"
putexcel A6 = "Mothers increase in earnings and partner lost earnings"
putexcel A7 = "Partner lost earnings only"
putexcel A8 = "Partner left"
putexcel A9 = "Other member lost earnings / left"
putexcel A10 = "Rate of transition to BW"

putexcel A11:Q11 = "2014 precipitating events", merge hcenter bold border(bottom)
putexcel A12 = "Event"
putexcel B12 = ("All events") D12 = ("All events") F12 = ("All events") H12 = ("All events") J12 = ("All events") L12 = ("All events") N12 = ("All events") P12 = ("All events")
putexcel C12 = ("Event precipitated") E12 = ("Event precipitated") G12 = ("Event precipitated") I12 = ("Event precipitated") K12 = ("Event precipitated") M12 = ("Event precipitated") O12 = ("Event precipitated") Q12 = ("Event precipitated")
putexcel A13 = "Mothers only an increase in earnings"
putexcel A14 = "Mothers increase in earnings and partner lost earnings"
putexcel A15 = "Partner lost earnings only"
putexcel A16 = "Partner left"
putexcel A17 = "Other member lost earnings / left"
putexcel A18 = "Rate of transition to BW"

local i=1

foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		local row = `i'+4
		putexcel B`row' = matrix(`var'_1), nformat(#.##%)
		putexcel C`row' = matrix(`var'_1_bw), nformat(#.##%)
		local ++i
}

foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		local row = `i'+7
		putexcel B`row' = matrix(`var'_2), nformat(#.##%)
		putexcel C`row' = matrix(`var'_2_bw), nformat(#.##%)
		local ++i
}

putexcel C10 = $bw_rate_96, nformat(#.##%)
putexcel C18 = $bw_rate_14, nformat(#.##%)

forvalues e=1/3{
local colu1 "D F H"
local colu2 "E G I"
local i=1

	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		local col1: word `e' of `colu1'
		local col2: word `e' of `colu2'
		local row=`i'+4
		putexcel `col1'`row' = matrix(`var'_e`e'_1), nformat(#.##%)
		putexcel `col2'`row' = matrix(`var'_e`e'_1_bw), nformat(#.##%)
		local ++i
	}

	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		local col1: word `e' of `colu1'
		local col2: word `e' of `colu2'
		local row=`i'+7
		putexcel `col1'`row' = matrix(`var'_e`e'_2), nformat(#.##%)
		putexcel `col2'`row' = matrix(`var'_e`e'_2_bw), nformat(#.##%)
		local ++i
	}
}


forvalues e=1/3{
	local column1 "E G I"
	local col1: word `e' of `column1'
	putexcel `col1'10 = ${bw_rate_96_e`e'}, nformat(#.##%)
	putexcel `col1'18 = ${bw_rate_14_e`e'}, nformat(#.##%)
}

forvalues r=1/4{
local colu1 "J L N P"
local colu2 "K M O Q"

local i=1

	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		local col1: word `r' of `colu1'
		local col2: word `r' of `colu2'
		local row=`i'+4
		putexcel `col1'`row' = matrix(`var'_r`r'_1), nformat(#.##%)
		putexcel `col2'`row' = matrix(`var'_r`r'_1_bw), nformat(#.##%)
		local ++i
	}

	
	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		local col1: word `r' of `colu1'
		local col2: word `r' of `colu2'
		local row=`i'+7
		putexcel `col1'`row' = matrix(`var'_r`r'_2), nformat(#.##%)
		putexcel `col2'`row' = matrix(`var'_r`r'_2_bw), nformat(#.##%)
		local ++i
	}
}


forvalues r=1/4{
	local column1 "K M O Q"

	local col1: word `r' of `column1'
	putexcel `col1'10 = ${bw_rate_96_r`r'}, nformat(#.##%)
	putexcel `col1'18 = ${bw_rate_14_r`r'}, nformat(#.##%)
}

// Table 3: Change Components

putexcel set "$results/Breadwinner_Predictor_Tables", sheet(Table3) modify
putexcel A1 = "Component"
putexcel B1 = "Total"
putexcel C1:E1 = "Education", merge
putexcel F1:I1 = "Race / Ethnicity", merge
putexcel C2 = ("HS or Less") D2 = ("Some College") E2 = ("College Plus") 
putexcel F2 = ("NH White") G2 = ("Black") H2 = ("NH Asian") I2 = ("Hispanic") 
putexcel A3 = "Total Gap to Explain"
putexcel A4 = "Rate Component"
putexcel A5 = "Composition Component"
putexcel A6 = "Mom Component"
putexcel A7 = "Partner Down Mom Up Component"
putexcel A8 = "Partner Down Only Component"
putexcel A9 = "Partner Left Component"
putexcel A10 = "Other HH Change Component"

putexcel B3 = $total_gap, nformat(#.##%)
putexcel B4 = formula($rate_diff / $total_gap), nformat(#.##%)
putexcel B5 = formula($comp_diff / $total_gap), nformat(#.##%)
putexcel B6 = $mom_compt_x, nformat(#.##%)
putexcel B7 = $partner_down_mom_compt_x, nformat(#.##%)
putexcel B8 = $partner_down_only_compt_x, nformat(#.##%)
putexcel B9 = $partner_leave_compt_x, nformat(#.##%)
putexcel B10 = $other_hh_compt_x, nformat(#.##%)

* Education and Race

local col1 "C D E"

forvalues e=1/3{
    local col: word `e' of `col1'
	putexcel `col'3 = ${total_gap_e`e'}, nformat(#.##%)
	putexcel `col'4 = formula(${rate_diff_e`e'} / ${total_gap_e`e'}), nformat(#.##%)
	putexcel `col'5 = formula(${comp_diff_e`e'} / ${total_gap_e`e'}), nformat(#.##%)
	putexcel `col'6 = ${mom_component_e`e'}, nformat(#.##%)
	putexcel `col'7 = ${partner_down_mom_component_e`e'}, nformat(#.##%)
	putexcel `col'8 = ${partner_down_only_component_e`e'}, nformat(#.##%)
	putexcel `col'9 = ${partner_leave_component_e`e'}, nformat(#.##%)
	putexcel `col'10 = ${other_hh_component_e`e'}, nformat(#.##%)
}

local col1 "F G H I"

forvalues r=1/4{
    local col: word `r' of `col1'
	putexcel `col'3 = ${total_gap_r`r'}, nformat(#.##%)
	putexcel `col'4 = formula(${rate_diff_r`r'} / ${total_gap_r`r'}), nformat(#.##%)
	putexcel `col'5 = formula(${comp_diff_r`r'} / ${total_gap_r`r'}), nformat(#.##%)
	putexcel `col'6 = ${mom_component_r`r'}, nformat(#.##%)
	putexcel `col'7 = ${partner_down_mom_component_r`r'}, nformat(#.##%)
	putexcel `col'8 = ${partner_down_only_component_r`r'}, nformat(#.##%)
	putexcel `col'9 = ${partner_leave_component_r`r'}, nformat(#.##%)
	putexcel `col'10 = ${other_hh_component_r`r'}, nformat(#.##%)
}

// Table 4: Median Income Change

putexcel set "$results/Breadwinner_Predictor_Tables", sheet(Table4) modify
putexcel A1 = "category"
putexcel B1 = "label"
putexcel C1 = "time"
putexcel D1 = "year"
putexcel E1 = "dollars_adj"
putexcel A2:A7 = "Education"
putexcel A8:A15 = "Race"
putexcel A16:A17 = "Total"
putexcel B2:B3 = ("HS or Less") B4:B5 = ("Some College") B6:B7 = ("College Plus") 
putexcel B8:B9 = ("NH White") B10:B11 = ("Black") B12:B13 = ("NH Asian") B14:B15 = ("Hispanic") 
putexcel B16:B17 = "Total"
putexcel C2 = ("Post") C4 = ("Post") C6 = ("Post") C8 = ("Post") C10 = ("Post") C12 = ("Post") C14 = ("Post") C16 = ("Post")
putexcel C3 = ("Pre") C5 = ("Pre") C7 = ("Pre") C9 = ("Pre") C11 = ("Pre") C13 = ("Pre") C15 = ("Pre") C17 = ("Pre")
putexcel D2:D17 = "1996"

putexcel A18:A23 = "Education"
putexcel A24:A31 = "Race"
putexcel A32:A33 = "Total"
putexcel B18:B19 = ("HS or Less") B20:B21 = ("Some College") B22:B23 = ("College Plus") 
putexcel B24:B25 = ("NH White") B26:B27 = ("Black") B28:B29 = ("NH Asian") B30:B31 = ("Hispanic") 
putexcel B32:B33 = "Total"
putexcel C18 = ("Post") C20 = ("Post") C22 = ("Post") C24 = ("Post") C26 = ("Post") C28 = ("Post") C30 = ("Post") C32 = ("Post")
putexcel C19 = ("Pre") C21 = ("Pre") C23 = ("Pre") C25 = ("Pre") C27 = ("Pre") C29 = ("Pre") C31 = ("Pre") C33 = ("Pre")
putexcel D18:D33 = "2014"

// putexcel I3 = (1) I4 = (2) I5 = (3)
// putexcel I6 = (4) I7 = (5) I8 = (6) I9 = (7) 

sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1, detail // post
putexcel E16=`r(p50)', nformat(###,###)
sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1, detail // pre
putexcel E17=`r(p50)', nformat(###,###)
// putexcel E2=formula(=(D2-C2)/C2), nformat(#.##%)

sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2, detail // post
putexcel E32 =`r(p50)', nformat(###,###)
sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2, detail  // pre
putexcel E33=`r(p50)', nformat(###,###)
// putexcel H2=formula(=(G2-F2)/F2), nformat(#.##%)


local row1x "2 4 6"
local row2x "3 5 7"
local row3x "18 20 22"
local row4x "19 21 23"

forvalues e=1/3{
    local row1: word `e' of `row1x'	
	local row2: word `e' of `row2x'
	sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & educ_gp==`e' & survey_yr==1, detail // post-1996
	putexcel E`row1'=`r(p50)', nformat(###,###)
	sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & educ_gp==`e' & survey_yr==1, detail // pre-1996
	putexcel E`row2'=`r(p50)', nformat(###,###)
	
	local row3: word `e' of `row3x'	
	local row4: word `e' of `row4x'
	sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & educ_gp==`e' & survey_yr==2, detail // post-2014
	putexcel E`row3'=`r(p50)', nformat(###,###)
	sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & educ_gp==`e' & survey_yr==2, detail // pre-2014
	putexcel E`row4'=`r(p50)', nformat(###,###)
	
	/*
	local col3: word `e' of `colu3'	
	sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & educ_gp==`e', detail // pre-total
	putexcel `col3'10=`r(p50)', nformat(###,###)
	sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & educ_gp==`e', detail // post-total
	putexcel `col3'11=`r(p50)', nformat(###,###)
	putexcel `col3'12=formula((`col3'11-`col3'10)/`col3'10), nformat(#.##%)
	*/
}

local row1x "8 10 12 14"
local row2x "9 11 13 15"
local row3x "24 26 28 30"
local row4x "25 27 29 31"

forvalues r=1/4{
    local row1: word `r' of `row1x'	
	local row2: word `r' of `row2x'	
	sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & race==`r' & survey_yr==1, detail // post-1996
	putexcel E`row1'=`r(p50)', nformat(###,###)
	sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & race==`r' & survey_yr==1, detail // pre-1996
	putexcel E`row2'=`r(p50)', nformat(###,###)

    local row3: word `r' of `row3x'	
	local row4: word `r' of `row4x'	
	sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & race==`r' & survey_yr==2, detail // post-2014
	putexcel E`row3'=`r(p50)', nformat(###,###)
	sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & race==`r' & survey_yr==2, detail // pre-2014
	putexcel E`row4'=`r(p50)', nformat(###,###)
		
	/*
	local col3: word `r' of `colu3'	
	sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & race==`r', detail // pre-total
	putexcel `col3'17=`r(p50)', nformat(###,###)
	sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & race==`r', detail // post-total
	putexcel `col3'18=`r(p50)', nformat(###,###)
	putexcel `col3'19=formula((`col3'18-`col3'17)/`col3'17), nformat(#.##%)
	*/
}


/* Old format
putexcel set "$results/Breadwinner_Predictor_Tables", sheet(Table4) modify
putexcel A1:D1 = "Changes in Median Household Income upon BW Transition", merge hcenter
putexcel B2 = ("1996") C2 = ("2014") D2 = ("total")
putexcel A3 = "Pre-Transition Median HH Income"
putexcel A4 = "Post-Transition Median HH Income"
putexcel A5 = "Percent Change Post Transition"

sum thearn_alt if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1, detail // pre
putexcel B3=`r(p50)', nformat(###,###)
sum thearn_alt if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1, detail // post
putexcel B4=`r(p50)', nformat(###,###)

sum thearn_alt if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2, detail  // pre
putexcel C3=`r(p50)', nformat(###,###)
sum thearn_alt if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2, detail // post
putexcel C4=`r(p50)', nformat(###,###)

sum thearn_alt if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID , detail // pre
putexcel D3=`r(p50)', nformat(###,###)
sum thearn_alt if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1], detail // post
putexcel D4=`r(p50)', nformat(###,###)

putexcel B5=formula((B4-B3)/B3), nformat(#.##%)
putexcel C5=formula((C4-C3)/C3), nformat(#.##%)
putexcel D5=formula((D4-D3)/D3), nformat(#.##%)

putexcel B8:D8 = "Less than HS", merge hcenter
putexcel E8:G8 = "HS Degree", merge hcenter
putexcel H8:J8 = "Some College", merge hcenter
putexcel K8:M8 = "College Plus", merge hcenter
putexcel B9 = ("1996") E9 = ("1996") H9 = ("1996") K9 = ("1996")
putexcel C9 = ("2014") F9 = ("2014") I9 = ("2014") L9 = ("2014")
putexcel D9 = ("Total") G9 = ("Total") J9 = ("Total") M9 = ("Total")
putexcel A10 = "Pre-Transition Median HH Income"
putexcel A11 = "Post-Transition Median HH Income"
putexcel A12 = "Percent Change Post Transition"

local colu1 "B E H K"
local colu2 "C F I L"
local colu3 "D G J M"

forvalues e=1/4{
    local col1: word `e' of `colu1'	
	sum thearn_alt if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & educ==`e' & survey_yr==1, detail // pre-1996
	putexcel `col1'10=`r(p50)', nformat(###,###)
	sum thearn_alt if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & educ==`e' & survey_yr==1, detail // post-1996
	putexcel `col1'11=`r(p50)', nformat(###,###)
	putexcel `col1'12=formula((`col1'11-`col1'10)/`col1'10), nformat(#.##%)
	
	local col2: word `e' of `colu2'	
	sum thearn_alt if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & educ==`e' & survey_yr==2, detail // pre-2014
	putexcel `col2'10=`r(p50)', nformat(###,###)
	sum thearn_alt if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & educ==`e' & survey_yr==2, detail // post-2014
	putexcel `col2'11=`r(p50)', nformat(###,###)
	putexcel `col2'12=formula((`col2'11-`col2'10)/`col2'10), nformat(#.##%)
	
	local col3: word `e' of `colu3'	
	sum thearn_alt if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & educ==`e', detail // pre-total
	putexcel `col3'10=`r(p50)', nformat(###,###)
	sum thearn_alt if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & educ==`e', detail // post-total
	putexcel `col3'11=`r(p50)', nformat(###,###)
	putexcel `col3'12=formula((`col3'11-`col3'10)/`col3'10), nformat(#.##%)
}

putexcel B15:D15 = "NH White", merge hcenter
putexcel E15:G15 = "Black", merge hcenter
putexcel H15:J15 = "NH Asian", merge hcenter
putexcel K15:M15 = "Hisapnic", merge hcenter
putexcel B16 = ("1996") E16 = ("1996") H16 = ("1996") K16 = ("1996")
putexcel C16 = ("2014") F16 = ("2014") I16 = ("2014") L16 = ("2014")
putexcel D16 = ("Total") G16 = ("Total") J16 = ("Total") M16 = ("Total")
putexcel A17 = "Pre-Transition Median HH Income"
putexcel A18 = "Post-Transition Median HH Income"
putexcel A19 = "Percent Change Post Transition"

local colu1 "B E H K"
local colu2 "C F I L"
local colu3 "D G J M"

forvalues r=1/4{
    local col1: word `r' of `colu1'	
	sum thearn_alt if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & race==`r' & survey_yr==1, detail // pre-1996
	putexcel `col1'17=`r(p50)', nformat(###,###)
	sum thearn_alt if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & race==`r' & survey_yr==1, detail // post-1996
	putexcel `col1'18=`r(p50)', nformat(###,###)
	putexcel `col1'19=formula((`col1'18-`col1'17)/`col1'17), nformat(#.##%)
	
	local col2: word `r' of `colu2'	
	sum thearn_alt if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & race==`r' & survey_yr==2, detail // pre-2014
	putexcel `col2'17=`r(p50)', nformat(###,###)
	sum thearn_alt if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & race==`r' & survey_yr==2, detail // post-2014
	putexcel `col2'18=`r(p50)', nformat(###,###)
	putexcel `col2'19=formula((`col2'18-`col2'17)/`col2'17), nformat(#.##%)
	
	local col3: word `r' of `colu3'	
	sum thearn_alt if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & race==`r', detail // pre-total
	putexcel `col3'17=`r(p50)', nformat(###,###)
	sum thearn_alt if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & race==`r', detail // post-total
	putexcel `col3'18=`r(p50)', nformat(###,###)
	putexcel `col3'19=formula((`col3'18-`col3'17)/`col3'17), nformat(#.##%)
}
*/

// Figure 1: Pie Chart for Incidence
putexcel set "$results/Breadwinner_Predictor_Fig1", sheet(Fig1) replace
putexcel A1 = "Event"
putexcel B1 = "Year"
putexcel C1 = "All_events"
putexcel D1 = "Event_precipitated"
putexcel A2:A3 = "Mothers only an increase in earnings"
putexcel A4:A5 = "Mothers increase in earnings and partner lost earnings"
putexcel A6:A7 = "Partner lost earnings only"
putexcel A8:A9 = "Partner left"
putexcel A10:A11 = "Other member lost earnings / left"
putexcel A12:A13 = "No Changes"
putexcel B2 = ("1996") B4 = ("1996") B6 = ("1996") B8 = ("1996") B10 = ("1996") B12 = ("1996") 
putexcel B3 = ("2014") B5 = ("2014") B7 = ("2014") B9 = ("2014") B11 = ("2014") B13 = ("2014")

local i=1
local row1 "2 4 6 8 10 3 5 7 9 11"

foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		local row: word `i' of `row1'
		putexcel C`row' = matrix(`var'_1), nformat(#.##%)
		putexcel D`row' = matrix(`var'_1_bw), nformat(#.##%)
		local ++i
}

foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		local row: word `i' of `row1'
		putexcel C`row' = matrix(`var'_2), nformat(#.##%)
		putexcel D`row' = matrix(`var'_2_bw), nformat(#.##%)
		local ++i
}

putexcel C12 = formula(1-(C2+C4+C6+C8+C10)), nformat(#.##%)
putexcel C13 = formula(1-(C3+C5+C7+C9+C11)), nformat(#.##%)

import excel "$results/Breadwinner_Predictor_Fig1", sheet(Fig1) firstrow case(lower) clear

graph pie all_events if year=="1996", over(event) title("1996 Incidence of Precipitating Events") plabel(_all percent, color(white) format(%4.1f)) sort descending ///
pie(1, color(gs10)) pie(2, color(navy)) pie(3, color(green)) pie(4, color(orange)) pie(5, color(maroon)) pie(6, color(purple))
graph export "$results/Events_1996.png", as(png) name("Graph") replace

graph pie all_events if year=="2014", over(event) title("2014 Incidence of Precipitating Events") plabel(_all percent, color(white) format(%4.1f)) sort descending ///
pie(1, color(gs10)) pie(2, color(navy)) pie(3, color(green)) pie(4, color(orange)) pie(5, color(maroon)) pie(6, color(purple))
graph export "$results/Events_2014.png", as(png) name("Graph") replace

// Figure 2: Bar Chart for income

/* commenting out - moving to R
***************************************** NOTE: sometimes this is working for me directly and othertimes, it is not. The best way I have found at the moment is to have to open and paste the formulas in Table 4 as values. I appreciate this is not sustainable. I am going to work on hardcoding so this step is not necessary, but I need a break from attempting to figure this out. Clearing doesn't work, putexcel save / clear doesn't work. I can't figure out what I am doing when it does work and when it doesn't**************88

import excel "$results/Breadwinner_Predictor_Tables", sheet(Table4) firstrow case(lower) clear

label define categories 1 "HS or Less" 2 "Some College" 3 "College Plus" 4 "NH White" 5 "Black" 6 "NH Asian" 7 "Hispanic"
label values value categories

graph bar change_1996 change_2014 if category=="Education", over(value) blabel(bar, format(%9.2f)) title ("Change in Median Household Income upon BW Transition") subtitle("by education") ytitle("Percentage Change post-Transition")  legend(label(1 "1996") label(2 "2014") size(small)) plotregion(fcolor(white)) graphregion(fcolor(white)) ylabel(-.6(.2).2, labsize(small))
graph export "$results/Income_Education.png", as(png) name("Graph") replace

graph bar change_1996 change_2014 if category=="Race", over(value) blabel(bar, format(%9.2f)) title ("Change in Median Household Income upon BW Transition") subtitle("by race / ethnicity") ytitle("Percentage Change post-Transition")  legend(label(1 "1996") label(2 "2014") size(small)) plotregion(fcolor(white)) graphregion(fcolor(white)) ylabel(-.6(.2).2, labsize(small))
graph export "$results/Income_Race.png", as(png) name("Graph") replace

graph bar change_1996 change_2014 if category=="Total", blabel(bar, format(%9.2f)) title ("Change in Median Household Income upon BW Transition") subtitle("overall") ytitle("Percentage Change post-Transition")  legend(label(1 "1996") label(2 "2014") size(small)) plotregion(fcolor(white)) graphregion(fcolor(white)) ylabel(-.6(.2).2, labsize(small)) bargap(10)  outergap(*5) 
graph export "$results/Income_Total.png", as(png) name("Graph") replace
*/

/*------------------------------------------------------------------------------------------------------*/

********************************************************************************
* Some exploration
********************************************************************************
/* Commenting this out since I am now using an excel file in the step above this
log using "$logdir/exploratory_data.log", replace

browse SSUID PNUM year earnings thearn_alt earnings_ratio bw60 bw50 trans_bw60_alt2

gen earnings_ratio_m = earnings_ratio
replace earnings_ratio=0 if earnings_ratio==.

tabstat earnings_ratio, by(survey_yr) statistics(mean p50)
tabstat earnings_ratio if bw60==1, by(survey_yr) statistics(mean p50)
tabstat earnings_ratio if trans_bw60_alt2==1, by(survey_yr) statistics(mean p50)

sum earnings_ratio if survey_yr==1, detail
sum earnings_ratio if survey_yr==2, detail

recode earnings_ratio (0=0) (0.00000001/0.249999999=1) (.2500000/.499999=2) (.50000/.599999=3) (.600000/.7499999=4) (.7500000/.999999=5) (1=6), gen(earn_ratio_gp)
label define ratio 0 "0" 1 "0.0-25%" 2 "25-49%" 3 "50-60%" 4 "60-75%" 5 "75%-99%" 6 "100%"
label values earn_ratio_gp ratio

tab survey_yr earn_ratio_gp, row

tabstat thearn_alt, by(survey_yr) statistics(mean p50)
tabstat thearn_alt, by(bw60) statistics(mean p50) // on average, female bws hh earnings are lower, BUT doesn't change upon transition for those households specifically?
tabstat thearn_alt, by(trans_bw60_alt2) statistics(mean p50) // on average, female bws hh earnings are lower, BUT doesn't change upon transition for those households specifically?

tabstat thearn_alt if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1], statistics(mean p50) // this is average POST transition - 35952.83
tabstat thearn_alt if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID , statistics(mean p50) // pre? 40092.59

tabstat thearn_alt if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1, statistics(mean p50)
tabstat thearn_alt if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1, statistics(mean p50)

tabstat thearn_alt if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2, statistics(mean p50)
tabstat thearn_alt if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2, statistics(mean p50)

tabstat earnings if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1], statistics(mean p50)
tabstat earnings if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID , statistics(mean p50)

tabstat earnings if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1, statistics(mean p50)
tabstat earnings if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1, statistics(mean p50)

tabstat earnings if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2, statistics(mean p50)
tabstat earnings if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2, statistics(mean p50)

tabstat earnings_ratio if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1], statistics(mean p50)
tabstat earnings_ratio if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID , statistics(mean p50)

tabstat earnings_ratio if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1, statistics(mean p50)
tabstat earnings_ratio if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1, statistics(mean p50)

tabstat earnings_ratio if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2, statistics(mean p50)
tabstat earnings_ratio if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2, statistics(mean p50)

* total earnings change of partner with mom as BW
tabstat earn_change_sp if trans_bw60_alt2==1, by(survey) statistics(mean p50)
tabstat earn_change_raw_sp if trans_bw60_alt2==1, by(survey) statistics(mean p50)

* Earnings change of partners who experienced a decrease + mom BW	
tabstat earn_change_sp if trans_bw60_alt2==1 & earndown8_sp_all==1, by(survey) statistics(mean p50)
tabstat earn_change_raw_sp if trans_bw60_alt2==1 & earndown8_sp_all==1, by(survey) statistics(mean p50)

* Earnings change of partners who experienced a decrease - regardless of BW status
tabstat earn_change_sp if earndown8_sp_all==1, by(survey) statistics(mean p50)
tabstat earn_change_raw_sp if earndown8_sp_all==1, by(survey) statistics(mean p50)

log close

*/
*tabstat thearn_alt[_n-1] if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) // does this work for PRE? NO

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
