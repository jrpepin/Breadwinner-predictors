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
* Note: this relies on macros created in step ab, so cannot run this in isolation

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

// Table 2: Option 2
putexcel set "$results/Breadwinner_Predictor_Tables", sheet(Table2-option2) modify
putexcel A3 = "Event"
putexcel B3 = "Year"
putexcel C3 = ("All_events") E3 = ("All_events") G3 = ("All_events") I3 = ("All_events") K3 = ("All_events") M3 = ("All_events") O3 = ("All_events") Q3 = ("All_events")
putexcel D3 = ("Event_precipitated") F3 = ("Event_precipitated") H3 = ("Event_precipitated") J3 = ("Event_precipitated") L3 = ("Event_precipitated") N3 = ("Event_precipitated") ///
		P3 = ("Event_precipitated") R3 = ("Event_precipitated")
putexcel C1:D1 = "Total", merge border(bottom)
putexcel E1:J1 = "Education", merge border(bottom)
putexcel K1:R1 = "Race / ethnicity", merge border(bottom)
putexcel C2:D2 = "Total", merge border(bottom)
putexcel E2:F2 = "HS Degree or Less", merge border(bottom)
putexcel G2:H2 = "Some College", merge border(bottom)
putexcel I2:J2 = "College Plus", merge border(bottom)
putexcel K2:L2 = "NH White", merge border(bottom)
putexcel M2:N2 = "Black", merge border(bottom)
putexcel O2:P2 = "NH Asian", merge border(bottom)
putexcel Q2:R2 = "Hispanic", merge border(bottom)
putexcel A4:A5 = "Mothers only an increase in earnings"
putexcel A6:A7 = "Mothers increase in earnings and partner lost earnings"
putexcel A8:A9 = "Partner lost earnings only"
putexcel A10:A11 = "Partner left"
putexcel A12:A13 = "Other member lost earnings / left"
putexcel A14:A15 = "Transition rate to BW"
putexcel B4 = ("1996") B6 = ("1996") B8 = ("1996") B10 = ("1996") B12 = ("1996") B14= ("1996")
putexcel B5 = ("2014") B7 = ("2014") B9 = ("2014") B11 = ("2014") B13 = ("2014") B15 = ("2014")

local i=1
local row1 "4 6 8 10 12 5 7 9 11 13"

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

putexcel D14 = $bw_rate_96, nformat(#.##%)
putexcel D15 = $bw_rate_14, nformat(#.##%)

forvalues e=1/3{
local colu1 "E G I"
local colu2 "F H J"
local row1 "4 6 8 10 12 5 7 9 11 13"
local i=1

	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		local row: word `i' of `row1'
		local col1: word `e' of `colu1'
		local col2: word `e' of `colu2'
		putexcel `col1'`row' = matrix(`var'_e`e'_1), nformat(#.##%)
		putexcel `col2'`row' = matrix(`var'_e`e'_1_bw), nformat(#.##%)
		local ++i
	}

	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		local row: word `i' of `row1'
		local col1: word `e' of `colu1'
		local col2: word `e' of `colu2'
		putexcel `col1'`row' = matrix(`var'_e`e'_2), nformat(#.##%)
		putexcel `col2'`row' = matrix(`var'_e`e'_2_bw), nformat(#.##%)
		local ++i
	}
}

forvalues e=1/3{
	local column1 "F H J"
	local col1: word `e' of `column1'
	putexcel `col1'14 = ${bw_rate_96_e`e'}, nformat(#.##%)
	putexcel `col1'15 = ${bw_rate_14_e`e'}, nformat(#.##%)
}

forvalues r=1/4{
local colu1 "K M O Q"
local colu2 "L N P R"
local row1 "4 6 8 10 12 5 7 9 11 13"

local i=1

	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		local row: word `i' of `row1'
		local col1: word `r' of `colu1'
		local col2: word `r' of `colu2'
		putexcel `col1'`row' = matrix(`var'_r`r'_1), nformat(#.##%)
		putexcel `col2'`row' = matrix(`var'_r`r'_1_bw), nformat(#.##%)
		local ++i
	}

	
	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		local row: word `i' of `row1'
		local col1: word `r' of `colu1'
		local col2: word `r' of `colu2'
		putexcel `col1'`row' = matrix(`var'_r`r'_2), nformat(#.##%)
		putexcel `col2'`row' = matrix(`var'_r`r'_2_bw), nformat(#.##%)
		local ++i
	}
}


forvalues r=1/4{
	local column1 "L N P R"

	local col1: word `r' of `column1'
	putexcel `col1'14 = ${bw_rate_96_r`r'}, nformat(#.##%)
	putexcel `col1'15 = ${bw_rate_14_r`r'}, nformat(#.##%)
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

// Table 4a: Partner's income change

putexcel set "$results/Breadwinner_Predictor_Tables", sheet(Table4a) modify
putexcel A1:J1 = "Median Income Loss for Partners - Total", merge border(bottom) hcenter
putexcel A2 = "Category"
putexcel B2 = "Label"
putexcel C2 = ("Pre_1996") D2 = ("Post_1996") E2 = ("% Change_1996") F2 = ("$ Change_1996")
putexcel G2 = ("Pre_2014") H2 = ("Post_2014") I2 = ("% Change_2014") J2 = ("$ Change_2014")
putexcel A3 = ("Total") B3 = ("Total")
putexcel A4:A6 = "Education"
putexcel B4 = ("HS or Less") B5 = ("Some College") B6 = ("College Plus") 
//putexcel I3 = (1) I4 = (2) I5 = (3)
putexcel A7:A10 = "Race"
putexcel B7 = ("NH White") B8 = ("Black") B9 = ("NH Asian") B10 = ("Hispanic") 

putexcel L1:U1 = "Mean Income Loss for Partners - Total", merge border(bottom) hcenter
putexcel L2 = "Category"
putexcel M2 = "Label" 
putexcel N2 = ("Pre_1996") P2 = ("Post_1996") R2 = ("% Change_1996")  T2 = ("$ Change_1996")
putexcel O2 = ("Pre_2014") Q2 = ("Post_2014") S2 = ("% Change_2014") U2 = ("$ Change_2014")
putexcel L3 = ("Total") M3 = ("Total")
putexcel L4:L6 = "Education"
putexcel M4= ("HS or Less") M5 = ("Some College") M6 = ("College Plus") 
putexcel L7:L10 = "Race"
putexcel M7 = ("NH White") M8 = ("Black") M9 = ("NH Asian") M10 = ("Hispanic") 

putexcel A12:J12 = "Median Income Loss for Partners - Mother became BW", merge border(bottom) hcenter
putexcel A13 = "Category"
putexcel B13 = "Label"
putexcel C13 = ("Pre_1996") D13 = ("Post_1996") E13 = ("% Change_1996") F13 = ("$ Change_1996")
putexcel G13 = ("Pre_2014") H13 = ("Post_2014") I13 = ("% Change_2014") J13 = ("$ Change_2014")
putexcel A14 = ("Total") B14 = ("Total")
putexcel A15:A17 = "Education"
putexcel B15 = ("HS or Less") B16 = ("Some College") B17 = ("College Plus") 
putexcel A18:A21 = "Race"
putexcel B18 = ("NH White") B19 = ("Black") B20 = ("NH Asian") B21 = ("Hispanic") 

putexcel L12:U12 = "Mean Income Loss for Partners - Mother became BW", merge border(bottom) hcenter
putexcel L13 = "Category"
putexcel M13 = "Label"
putexcel N13 = ("Pre_1996") P13 = ("Post_1996") R13 = ("% Change_1996")  T13 = ("$ Change_1996")
putexcel O13 = ("Pre_2014") Q13 = ("Post_2014") S13 = ("% Change_2014") U13 = ("$ Change_2014")
putexcel L14 = ("Total") M14 = ("Total")
putexcel L15:L17 = "Education"
putexcel M15= ("HS or Less") M16 = ("Some College") M17 = ("College Plus") 
putexcel L18:L21 = "Race"
putexcel M18 = ("NH White") M19 = ("Black") M20 = ("NH Asian") M21 = ("Hispanic") 

* All partners who lost earnings
* do we want pre and post or can I just get the average change?
* like mean earn_change_raw if earn_change_raw < 0?

sum earnings_sp_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & earn_change_raw_sp[_n+1]<0, detail // pre
putexcel C3=`r(p50)', nformat(###,###)
putexcel N3=`r(mean)', nformat(###,###)
sum earnings_sp_adj if survey_yr==1 & earn_change_raw_sp<0, detail // post change
putexcel D3=`r(p50)', nformat(###,###)
putexcel O3=`r(mean)', nformat(###,###)
putexcel E3=formula(=(D3-C3)/C3), nformat(#.##%)
putexcel F3=formula(=D3-C3), nformat(###,###)
putexcel P3=formula(=(O3-N3)/N3), nformat(#.##%)
putexcel Q3=formula(=O3-N3), nformat(###,###)

sum earnings_sp_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & earn_change_raw_sp[_n+1]<0, detail // pre
putexcel G3=`r(p50)', nformat(###,###)
putexcel R3=`r(mean)', nformat(###,###)
sum earnings_sp_adj if survey_yr==2 & earn_change_raw_sp<0, detail // post change
putexcel H3=`r(p50)', nformat(###,###)
putexcel S3=`r(mean)', nformat(###,###)
putexcel I3=formula(=(H3-G3)/G3), nformat(#.##%)
putexcel J3=formula(=H3-G3), nformat(###,###)
putexcel T3=formula(=(S3-R3)/R3), nformat(#.##%)
putexcel U3=formula(=S3-R3), nformat(###,###)

local row1 "4 5 6"
forvalues e=1/3{
    local row: word `e' of `row1'	
	
	sum earnings_sp_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & earn_change_raw_sp[_n+1]<0 & educ_gp==`e', detail // pre
	putexcel C`row'=`r(p50)', nformat(###,###)
	putexcel N`row'=`r(mean)', nformat(###,###)
	sum earnings_sp_adj if survey_yr==1 & earn_change_raw_sp<0  & educ_gp==`e', detail // post change
	putexcel D`row'=`r(p50)', nformat(###,###)
	putexcel O`row'=`r(mean)', nformat(###,###)
	putexcel E`row'=formula((D`row'-C`row')/C`row'), nformat(#.##%)
	putexcel F`row'=formula((D`row'-C`row')), nformat(###,###)
	putexcel P`row'=formula((O`row'-N`row')/N`row'), nformat(#.##%)
	putexcel Q`row'=formula((O`row'-N`row')), nformat(###,###)
	
	sum earnings_sp_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & earn_change_raw_sp[_n+1]<0 & educ_gp==`e', detail // pre
	putexcel G`row'=`r(p50)', nformat(###,###)
	putexcel R`row'=`r(mean)', nformat(###,###)
	sum earnings_sp_adj if survey_yr==2 & earn_change_raw_sp<0  & educ_gp==`e', detail // post change
	putexcel H`row'=`r(p50)', nformat(###,###)
	putexcel S`row'=`r(mean)', nformat(###,###)
	putexcel I`row'=formula((H`row'-G`row')/G`row'), nformat(#.##%)
	putexcel J`row'=formula((H`row'-G`row')), nformat(###,###)
	putexcel T`row'=formula((S`row'-R`row')/R`row'), nformat(#.##%)
	putexcel U`row'=formula((S`row'-R`row')), nformat(###,###)
}

local row2 "7 8 9 10"
forvalues r=1/4{
    local row: word `r' of `row2'	
	sum earnings_sp_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & earn_change_raw_sp[_n+1]<0 & race==`r', detail // pre
	putexcel C`row'=`r(p50)', nformat(###,###)
	putexcel N`row'=`r(mean)', nformat(###,###)
	sum earnings_sp_adj if survey_yr==1 & earn_change_raw_sp<0  & race==`r', detail // post change
	putexcel D`row'=`r(p50)', nformat(###,###)
	putexcel O`row'=`r(mean)', nformat(###,###)
	putexcel E`row'=formula((D`row'-C`row')/C`row'), nformat(#.##%)
	putexcel F`row'=formula((D`row'-C`row')), nformat(###,###)
	putexcel P`row'=formula((O`row'-N`row')/N`row'), nformat(#.##%)
	putexcel Q`row'=formula((O`row'-N`row')), nformat(###,###)
	
	sum earnings_sp_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & earn_change_raw_sp[_n+1]<0 & race==`r', detail // pre
	putexcel G`row'=`r(p50)', nformat(###,###)
	putexcel R`row'=`r(mean)', nformat(###,###)
	sum earnings_sp_adj if survey_yr==2 & earn_change_raw_sp<0  & race==`r', detail // post change
	putexcel H`row'=`r(p50)', nformat(###,###)
	putexcel S`row'=`r(mean)', nformat(###,###)
	putexcel I`row'=formula((H`row'-G`row')/G`row'), nformat(#.##%)
	putexcel J`row'=formula((H`row'-G`row')), nformat(###,###)
	putexcel T`row'=formula((S`row'-R`row')/R`row'), nformat(#.##%)
	putexcel U`row'=formula((S`row'-R`row')), nformat(###,###)
}


* Just those where mother became BW (and partner had earnings loss)
sum earnings_sp_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & earn_change_raw_sp[_n+1]<0, detail // pre
putexcel C14=`r(p50)', nformat(###,###)
putexcel N14=`r(mean)', nformat(###,###)
sum earnings_sp_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & earn_change_raw_sp<0, detail // post
putexcel D14=`r(p50)', nformat(###,###)
putexcel O14=`r(mean)', nformat(###,###)
putexcel E14=formula(=(D14-C14)/C14), nformat(#.##%)
putexcel F14=formula(=D14-C14), nformat(###,###)
putexcel P14=formula(=(O14-N14)/N14), nformat(#.##%)
putexcel Q14=formula(=O14-N14), nformat(###,###)

sum earnings_sp_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & earn_change_raw_sp[_n+1]<0, detail  // pre
putexcel G14=`r(p50)', nformat(###,###)
putexcel R14=`r(mean)', nformat(###,###)
sum earnings_sp_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & earn_change_raw_sp<0, detail // post
putexcel H14=`r(p50)', nformat(###,###)
putexcel S14=`r(mean)', nformat(###,###)
putexcel I14=formula(=(H14-G14)/G14), nformat(#.##%)
putexcel J14=formula(=H14-G14), nformat(###,###)
putexcel T14=formula(=(S14-R14)/R14), nformat(#.##%)
putexcel U14=formula(=S14-R14), nformat(###,###)

local row1 "15 16 17"
forvalues e=1/3{
    local row: word `e' of `row1'	
	
	sum earnings_sp_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & educ_gp==`e' & survey_yr==1 & earn_change_raw_sp[_n+1]<0, detail // pre-1996
	putexcel C`row'=`r(p50)', nformat(###,###)
	putexcel N`row'=`r(mean)', nformat(###,###)
	sum earnings_sp_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & educ_gp==`e' & survey_yr==1 & earn_change_raw_sp<0, detail // post-1996
	putexcel D`row'=`r(p50)', nformat(###,###)
	putexcel O`row'=`r(mean)', nformat(###,###)
	putexcel E`row'=formula((D`row'-C`row')/C`row'), nformat(#.##%)
	putexcel F`row'=formula((D`row'-C`row')), nformat(###,###)
	putexcel P`row'=formula((O`row'-N`row')/N`row'), nformat(#.##%)
	putexcel Q`row'=formula((O`row'-N`row')), nformat(###,###)
		
	sum earnings_sp_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & educ_gp==`e' & survey_yr==2 & earn_change_raw_sp[_n+1]<0, detail // pre-2014
	putexcel G`row'=`r(p50)', nformat(###,###)
	putexcel R`row'=`r(mean)', nformat(###,###)
	sum earnings_sp_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & educ_gp==`e' & survey_yr==2 & earn_change_raw_sp<0, detail // post-2014
	putexcel H`row'=`r(p50)', nformat(###,###)
	putexcel S`row'=`r(mean)', nformat(###,###)
	putexcel I`row'=formula((H`row'-G`row')/G`row'), nformat(#.##%)
	putexcel J`row'=formula((H`row'-G`row')), nformat(###,###)
	putexcel T`row'=formula((S`row'-R`row')/R`row'), nformat(#.##%)
	putexcel U`row'=formula((S`row'-R`row')), nformat(###,###)
}

local row2 "18 19 20 21"
forvalues r=1/4{
    local row: word `r' of `row2'	
	sum earnings_sp_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & race==`r' & survey_yr==1 & earn_change_raw_sp[_n+1]<0, detail // pre-1996
	putexcel C`row'=`r(p50)', nformat(###,###)
	putexcel N`row'=`r(mean)', nformat(###,###)
	sum earnings_sp_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & race==`r' & survey_yr==1 & earn_change_raw_sp<0, detail // post-1996
	putexcel D`row'=`r(p50)', nformat(###,###)
	putexcel O`row'=`r(mean)', nformat(###,###)
	putexcel E`row'=formula((D`row'-C`row')/C`row'), nformat(#.##%)
	putexcel F`row'=formula((D`row'-C`row')), nformat(###,###)
	putexcel P`row'=formula((O`row'-N`row')/N`row'), nformat(#.##%)
	putexcel Q`row'=formula((O`row'-N`row')), nformat(###,###)
		
	sum earnings_sp_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & race==`r' & survey_yr==2 & earn_change_raw_sp[_n+1]<0, detail // pre-2014
	putexcel G`row'=`r(p50)', nformat(###,###)
	putexcel R`row'=`r(mean)', nformat(###,###)
	sum earnings_sp_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & race==`r' & survey_yr==2 & earn_change_raw_sp<0, detail // post-2014
	putexcel H`row'=`r(p50)', nformat(###,###)
	putexcel S`row'=`r(mean)', nformat(###,###)
	putexcel I`row'=formula((H`row'-G`row')/G`row'), nformat(#.##%)
	putexcel J`row'=formula((H`row'-G`row')), nformat(###,###)
	putexcel T`row'=formula((S`row'-R`row')/R`row'), nformat(#.##%)
	putexcel U`row'=formula((S`row'-R`row')), nformat(###,###)
}

// Table 4b: Mother's Income Change

putexcel set "$results/Breadwinner_Predictor_Tables", sheet(Table4b) modify
putexcel A1:J1 = "Median Income Gain for Mothers - Total", merge border(bottom) hcenter
putexcel A2 = "Category"
putexcel B2 = "Label"
putexcel C2 = ("Pre_1996") D2 = ("Post_1996") E2 = ("% Change_1996") F2 = ("$ Change_1996")
putexcel G2 = ("Pre_2014") H2 = ("Post_2014") I2 = ("% Change_2014") J2 = ("$ Change_2014")
putexcel A3 = ("Total") B3 = ("Total")
putexcel A4:A6 = "Education"
putexcel B4 = ("HS or Less") B5 = ("Some College") B6 = ("College Plus") 
putexcel A7:A10 = "Race"
putexcel B7 = ("NH White") B8 = ("Black") B9 = ("NH Asian") B10 = ("Hispanic") 

putexcel A12:J12 = "Median Income Gain for Mothers - Mother became BW", merge border(bottom) hcenter
putexcel A13 = "Category"
putexcel B13 = "Label"
putexcel C13 = ("Pre_1996") D13 = ("Post_1996") E13 = ("% Change_1996") F13 = ("$ Change_1996")
putexcel G13 = ("Pre_2014") H13 = ("Post_2014") I13 = ("% Change_2014") J13 = ("$ Change_2014")
putexcel A14 = ("Total") B14 = ("Total")
putexcel A15:A17 = "Education"
putexcel B15 = ("HS or Less") B16 = ("Some College") B17 = ("College Plus") 
putexcel A18:A21 = "Race"
putexcel B18 = ("NH White") B19 = ("Black") B20 = ("NH Asian") B21 = ("Hispanic") 

* All mothers who gained earnings
* do we want pre and post or can I just get the average change?
* like mean earn_change_raw if earn_change_raw < 0?

sum earnings_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & earn_change_raw[_n+1]>0, detail // pre
putexcel C3=`r(p50)', nformat(###,###)
sum earnings_adj if survey_yr==1 & earn_change_raw>0, detail // post change
putexcel D3=`r(p50)', nformat(###,###)
putexcel E3=formula(=(D3-C3)/C3), nformat(#.##%)
putexcel F3=formula(=D3-C3), nformat(###,###)

sum earnings_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & earn_change_raw[_n+1]>0, detail // pre
putexcel G3=`r(p50)', nformat(###,###)
sum earnings_adj if survey_yr==2 & earn_change_raw>0, detail // post change
putexcel H3=`r(p50)', nformat(###,###)
putexcel I3=formula(=(H3-G3)/G3), nformat(#.##%)
putexcel J3=formula(=H3-G3), nformat(###,###)

local row1 "4 5 6"
forvalues e=1/3{
    local row: word `e' of `row1'	
	
	sum earnings_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & earn_change_raw[_n+1]>0 & educ_gp==`e', detail // pre
	putexcel C`row'=`r(p50)', nformat(###,###)
	sum earnings_adj if survey_yr==1 & earn_change_raw>0  & educ_gp==`e', detail // post change
	putexcel D`row'=`r(p50)', nformat(###,###)
	putexcel E`row'=formula((D`row'-C`row')/C`row'), nformat(#.##%)
	putexcel F`row'=formula((D`row'-C`row')), nformat(###,###)
	
	sum earnings_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & earn_change_raw[_n+1]>0 & educ_gp==`e', detail // pre
	putexcel G`row'=`r(p50)', nformat(###,###)
	sum earnings_adj if survey_yr==2 & earn_change_raw>0  & educ_gp==`e', detail // post change
	putexcel H`row'=`r(p50)', nformat(###,###)
	putexcel I`row'=formula((H`row'-G`row')/G`row'), nformat(#.##%)
	putexcel J`row'=formula((H`row'-G`row')), nformat(###,###)
}

local row2 "7 8 9 10"
forvalues r=1/4{
    local row: word `r' of `row2'	
	sum earnings_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & earn_change_raw[_n+1]>0 & race==`r', detail // pre
	putexcel C`row'=`r(p50)', nformat(###,###)
	sum earnings_adj if survey_yr==1 & earn_change_raw>0  & race==`r', detail // post change
	putexcel D`row'=`r(p50)', nformat(###,###)
	putexcel E`row'=formula((D`row'-C`row')/C`row'), nformat(#.##%)
	putexcel F`row'=formula((D`row'-C`row')), nformat(###,###)
	
	sum earnings_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & earn_change_raw[_n+1]>0 & race==`r', detail // pre
	putexcel G`row'=`r(p50)', nformat(###,###)
	sum earnings_adj if survey_yr==2 & earn_change_raw>0  & race==`r', detail // post change
	putexcel H`row'=`r(p50)', nformat(###,###)
	putexcel I`row'=formula((H`row'-G`row')/G`row'), nformat(#.##%)
	putexcel J`row'=formula((H`row'-G`row')), nformat(###,###)
}


* Just those where mother became BW (and she gained earnings loss)
sum earnings_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & earn_change_raw[_n+1]>0, detail // pre
putexcel C14=`r(p50)', nformat(###,###)
sum earnings_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & earn_change_raw>0, detail // post
putexcel D14=`r(p50)', nformat(###,###)
putexcel E14=formula(=(D14-C14)/C14), nformat(#.##%)
putexcel F14=formula(=D14-C14), nformat(###,###)

sum earnings_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & earn_change_raw[_n+1]>0, detail  // pre
putexcel G14=`r(p50)', nformat(###,###)
sum earnings_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & earn_change_raw>0, detail // post
putexcel H14=`r(p50)', nformat(###,###)
putexcel I14=formula(=(H14-G14)/G14), nformat(#.##%)
putexcel J14=formula(=H14-G14), nformat(###,###)

local row1 "15 16 17"
forvalues e=1/3{
    local row: word `e' of `row1'	
	
	sum earnings_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & educ_gp==`e' & survey_yr==1 & earn_change_raw[_n+1]>0, detail // pre-1996
	putexcel C`row'=`r(p50)', nformat(###,###)
	sum earnings_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & educ_gp==`e' & survey_yr==1 & earn_change_raw>0, detail // post-1996
	putexcel D`row'=`r(p50)', nformat(###,###)
	putexcel E`row'=formula((D`row'-C`row')/C`row'), nformat(#.##%)
	putexcel F`row'=formula((D`row'-C`row')), nformat(###,###)
		
	sum earnings_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & educ_gp==`e' & survey_yr==2 & earn_change_raw[_n+1]>0, detail // pre-2014
	putexcel G`row'=`r(p50)', nformat(###,###)
	sum earnings_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & educ_gp==`e' & survey_yr==2 & earn_change_raw>0, detail // post-2014
	putexcel H`row'=`r(p50)', nformat(###,###)
	putexcel I`row'=formula((H`row'-G`row')/G`row'), nformat(#.##%)
	putexcel J`row'=formula((H`row'-G`row')), nformat(###,###)
}

local row2 "18 19 20 21"
forvalues r=1/4{
    local row: word `r' of `row2'	
	sum earnings_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & race==`r' & survey_yr==1 & earn_change_raw[_n+1]>0, detail // pre-1996
	putexcel C`row'=`r(p50)', nformat(###,###)
	sum earnings_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & race==`r' & survey_yr==1 & earn_change_raw>0, detail // post-1996
	putexcel D`row'=`r(p50)', nformat(###,###)
	putexcel E`row'=formula((D`row'-C`row')/C`row'), nformat(#.##%)
	putexcel F`row'=formula((D`row'-C`row')), nformat(###,###)
		
	sum earnings_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & race==`r' & survey_yr==2 & earn_change_raw[_n+1]>0, detail // pre-2014
	putexcel G`row'=`r(p50)', nformat(###,###)
	sum earnings_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & race==`r' & survey_yr==2 & earn_change_raw>0, detail // post-2014
	putexcel H`row'=`r(p50)', nformat(###,###)
	putexcel I`row'=formula((H`row'-G`row')/G`row'), nformat(#.##%)
	putexcel J`row'=formula((H`row'-G`row')), nformat(###,###)
}


// Table 5:  HH raw income change with each breadwinner component
putexcel set "$results/Breadwinner_Predictor_Tables", sheet(Table5-raw) modify
putexcel A3 = "Event"
putexcel B3 = "Year"
putexcel C3 = ("All_events") E3 = ("All_events") G3 = ("All_events") I3 = ("All_events") K3 = ("All_events") M3 = ("All_events") O3 = ("All_events") Q3 = ("All_events")
putexcel D3 = ("Event_precipitated") F3 = ("Event_precipitated") H3 = ("Event_precipitated") J3 = ("Event_precipitated") L3 = ("Event_precipitated") N3 = ("Event_precipitated") ///
		P3 = ("Event_precipitated") R3 = ("Event_precipitated")
putexcel C1:D1 = "Total", merge border(bottom)
putexcel E1:J1 = "Education", merge border(bottom)
putexcel K1:R1 = "Race / ethnicity", merge border(bottom)
putexcel C2:D2 = "Total", merge border(bottom)
putexcel E2:F2 = "HS Degree or Less", merge border(bottom)
putexcel G2:H2 = "Some College", merge border(bottom)
putexcel I2:J2 = "College Plus", merge border(bottom)
putexcel K2:L2 = "NH White", merge border(bottom)
putexcel M2:N2 = "Black", merge border(bottom)
putexcel O2:P2 = "NH Asian", merge border(bottom)
putexcel Q2:R2 = "Hispanic", merge border(bottom)
putexcel A4:A5 = "Mothers only an increase in earnings"
putexcel A6:A7 = "Mothers increase in earnings and partner lost earnings"
putexcel A8:A9 = "Partner lost earnings only"
putexcel A10:A11 = "Partner left"
putexcel A12:A13 = "Other member lost earnings / left"
putexcel B4 = ("1996") B6 = ("1996") B8 = ("1996") B10 = ("1996") B12 = ("1996")
putexcel B5 = ("2014") B7 = ("2014") B9 = ("2014") B11 = ("2014") B13 = ("2014")

* All mothers who experienced a change
local i=1

foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
	local row1 = `i'*2+2
		
	sum thearn_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & `var'[_n+1]==1, detail // pre
	local p50_pre =`r(p50)'
	sum thearn_adj if year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & `var'==1, detail // post - is this the same as bw60lag==0? okay yes
	local p50_post =`r(p50)'
	putexcel C`row1'=formula(=(`p50_post' - `p50_pre')), nformat(###,###)

	local row2 = `i'*2+3
	sum thearn_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & `var'[_n+1]==1, detail  // pre
	local p50_pre =`r(p50)'
	sum thearn_adj if year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & `var'==1, detail // post
	local p50_post =`r(p50)'
	putexcel C`row2'=formula(=(`p50_post' - `p50_pre')), nformat(###,###)

	local ++i
}

* Mothers who experienced change AND became BW
local i=1

foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
	local row1 = `i'*2+2
		
	sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & `var'[_n+1]==1, detail // pre
	local p50_pre =`r(p50)'
	sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & `var'==1, detail // post
	local p50_post =`r(p50)'
	putexcel D`row1'=formula(=(`p50_post' - `p50_pre')), nformat(###,###)

	local row2 = `i'*2+3
	sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & `var'[_n+1]==1, detail  // pre
	local p50_pre =`r(p50)'
	sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & `var'==1, detail // post
	local p50_post =`r(p50)'
	putexcel D`row2'=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
	
	local ++i
}


local col1x "E G I"
local col2x "F H J"
forvalues e=1/3{
local i = 1
	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
    local col1: word `e' of `col1x'	
	local col2: word `e' of `col2x'
	local row1 = `i'*2+2
	local row2 = `i'*2+3
	
* All changes - 1996	
	sum thearn_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & `var'[_n+1]==1  & educ_gp==`e', detail // pre
	local p50_pre =`r(p50)'
	sum thearn_adj if year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & `var'==1  & educ_gp==`e', detail // post 
	local p50_post =`r(p50)'
	putexcel `col1'`row1'=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
	
* BW changes - 1996
	sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & `var'[_n+1]==1 & educ_gp==`e', detail // pre
	local p50_pre =`r(p50)'
	sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & `var'==1 & educ_gp==`e', detail // post
	local p50_post =`r(p50)'
	putexcel `col2'`row1'=formula(=(`p50_post' - `p50_pre')), nformat(###,###)

* All changes - 2014
	sum thearn_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & `var'[_n+1]==1 & educ_gp==`e', detail  // pre
	local p50_pre =`r(p50)'
	sum thearn_adj if year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & `var'==1 & educ_gp==`e', detail // post
	local p50_post =`r(p50)'
	putexcel `col1'`row2'=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
	
* BW changes - 2014
	sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & `var'[_n+1]==1 & educ_gp==`e', detail // pre
	local p50_pre =`r(p50)'
	sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & `var'==1 & educ_gp==`e', detail // post
	local p50_post =`r(p50)'
	putexcel `col2'`row2'=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
	
	local ++i
	}
}

local col1x "K M O Q"
local col2x "L N P R"
forvalues r=1/4{
local i = 1
	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
    local col1: word `r' of `col1x'	
	local col2: word `r' of `col2x'
	local row1 = `i'*2+2
	local row2 = `i'*2+3
	
* All changes - 1996	
	sum thearn_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & `var'[_n+1]==1  & race==`r', detail // pre
	local p50_pre =`r(p50)'
	sum thearn_adj if year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & `var'==1  & race==`r', detail // post 
	local p50_post =`r(p50)'
	putexcel `col1'`row1'=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
	
* BW changes - 1996
	sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & `var'[_n+1]==1 & race==`r', detail // pre
	local p50_pre =`r(p50)'
	sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & `var'==1 & race==`r', detail // post
	local p50_post =`r(p50)'
	putexcel `col2'`row1'=formula(=(`p50_post' - `p50_pre')), nformat(###,###)

* All changes - 2014
	sum thearn_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & `var'[_n+1]==1 & race==`r', detail  // pre
	local p50_pre =`r(p50)'
	sum thearn_adj if year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & `var'==1 & race==`r', detail // post
	local p50_post =`r(p50)'
	putexcel `col1'`row2'=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
	
* BW changes - 2014; there is a capture here because race of 3 has no observations for partner-left and became BW
	capture sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & `var'[_n+1]==1 & race==`r', detail // pre
	capture local p50_pre =`r(p50)'
	capture sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & `var'==1 & race==`r', detail // post
	capture local p50_post =`r(p50)'
	capture putexcel `col2'`row2'=formula(=(`p50_post' - `p50_pre')), nformat(###,###)
	
	local ++i
	}
}

putexcel P11 = 0 // this is to cover the above point about no observations

/*for raw change
* All mothers who experienced a change
local i=1

foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
	local row1 = `i'*2+2
		
	sum thearn_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==1 & `var'[_n+1]==1, detail // pre
	local p50_pre =`r(p50)'
	sum thearn_adj if year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==1 & `var'==1, detail // post - is this the same as bw60lag==0? okay yes
	local p50_post =`r(p50)'
	putexcel C`row1'=formula(=(`p50_post' - `p50_pre') / `p50_pre'), nformat(###,###)

	local row2 = `i'*2+3
	sum thearn_adj if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & `var'[_n+1]==1, detail  // pre
	local p50_pre =`r(p50)'
	sum thearn_adj if year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & `var'==1, detail // post
	local p50_post =`r(p50)'
	putexcel C`row2'=formula(=(`p50_post' - `p50_pre') / `p50_pre'), nformat(###,###)

	local ++i
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


/*
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
