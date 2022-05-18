*-------------------------------------------------------------------------------
* BREADWINNER PROJECT
* consequences_decomp.do
* Kim McErlean
*-------------------------------------------------------------------------------
di "$S_DATE"

********************************************************************************
* DESCRIPTION
********************************************************************************
* This file....

use "$tempdir/bw_consequences.dta", clear // created in step ad

// variables: mt_mom ft_partner_down ft_partner_leave lt_other_changes
// create outcome as binary variables
tab mechanism, gen(mechanism)
rename mechanism1 default
rename mechanism2 reserve
rename mechanism3 empower

// svyset [pweight = wpfinwgt]

/*template
mean mt_mom if educ_gp==1
mean mt_mom if educ_gp==3
mean empower if mt_mom==1 & educ_gp==1
mean empower if mt_mom==1 & educ_gp==3

mean mt_mom if educ_gp==1
mean mt_mom if educ_gp==2
mean empower if mt_mom==1 & educ_gp==1
mean empower if mt_mom==1 & educ_gp==2

mean mt_mom if educ_gp==3
mean mt_mom if educ_gp==2
mean empower if mt_mom==1 & educ_gp==3
mean empower if mt_mom==1 & educ_gp==2
*/

putexcel set "$results/Consequences_decomposition", sheet(Sheet1) replace
putexcel A2:A7 = "Empower", merge vcenter
putexcel A9:A14 = "Default", merge vcenter
putexcel A16:A21 = "Empower", merge vcenter
putexcel A23:A28 = "Default", merge vcenter

putexcel B2 = ("LTHS") B3 = ("College") B4 = ("Some College") B5 = ("College") B6 = ("LTHS") B7 = ("Some College")
putexcel B9 = ("LTHS") B10 = ("College") B11 = ("Some College") B12 = ("College") B13 = ("LTHS") B14 = ("Some College")
putexcel B16 = ("White") B17 = ("Black") B18 = ("White") B19 = ("Hispanic") B20 = ("Black") B21 = ("Hispanic")
putexcel B23 = ("White") B24 = ("Black") B25 = ("White") B26 = ("Hispanic") B27 = ("Black") B28 = ("Hispanic")

putexcel C1 = "Mom Up", border(bottom)
putexcel D1 = "Mom Up and Outcome", border(bottom)
putexcel E1 = "Partner Down Mom Up", border(bottom)
putexcel F1 = "Partner Down Mom Up and Outcome", border(bottom)
putexcel G1 = "Partner Down", border(bottom)
putexcel H1 = "Partner Down and Outcome", border(bottom)
putexcel I1 = "Partner left", border(bottom)
putexcel J1 = "Partner left and Outcome", border(bottom)
putexcel K1 = "Other member change", border(bottom)
putexcel L1 = "Other member change and Outcome", border(bottom)
putexcel M1 = "Rate of transition to BW", border(bottom)
putexcel N1 = "Total Difference", border(bottom)
putexcel O1 = "Rate Difference", border(bottom)
putexcel P1 = "Composition Difference", border(bottom)
putexcel Q1 = "Mom Component", border(bottom)
putexcel R1 = "Partner Down Mom Up Component", border(bottom)
putexcel S1 = "Partner Down Only Component", border(bottom)
putexcel T1 = "Partner Left Component", border(bottom)
putexcel U1 = "Other Component", border(bottom)

local colu1 "C E G I K C E G I K"
local colu2 "D F H J L D F H J L"
local outcome "empower default"
local i=1
local x=1

// education

foreach outcome in empower default{
	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		local col1: word `i' of `colu1'
		local col2: word `i' of `colu2'
		
		
		local row1=`x'*`x'*`x'+1
		local row2=`x'*`x'*`x'+2
		sum `var' if educ_gp==1
		putexcel `col1'`row1' = `r(mean)', nformat(#.##%)
		sum `var' if educ_gp==3
		putexcel `col1'`row2' = `r(mean)', nformat(#.##%)
		sum `outcome' if `var'==1 & educ_gp==1
		putexcel `col2'`row1' = `r(mean)', nformat(#.##%)
		sum `outcome' if `var'==1 & educ_gp==3
		putexcel `col2'`row2' = `r(mean)', nformat(#.##%)
	
		local row3=`x'*`x'*`x'+3
		local row4=`x'*`x'*`x'+4
		sum `var' if educ_gp==2
		putexcel `col1'`row3' = `r(mean)', nformat(#.##%)
		sum `var' if educ_gp==3
		putexcel `col1'`row4' = `r(mean)', nformat(#.##%)
		sum `outcome' if `var'==1 & educ_gp==2
		putexcel `col2'`row3'= `r(mean)', nformat(#.##%)
		sum `outcome' if `var'==1 & educ_gp==3
		putexcel `col2'`row4' = `r(mean)', nformat(#.##%)
		
		local row5=`x'*`x'*`x'+5
		local row6=`x'*`x'*`x'+6
		sum `var' if educ_gp==1
		putexcel `col1'`row5' = `r(mean)', nformat(#.##%)
		sum `var' if educ_gp==2
		putexcel `col1'`row6' = `r(mean)', nformat(#.##%)
		sum `outcome' if `var'==1 & educ_gp==1
		putexcel `col2'`row5' = `r(mean)', nformat(#.##%)
		sum `outcome' if `var'==1 & educ_gp==2
		putexcel `col2'`row6' = `r(mean)', nformat(#.##%)
		
		local ++i
		}
	local ++x
}


// race
local colu1 "C E G I K C E G I K"
local colu2 "D F H J L D F H J L"
local outcome "empower default"
local i=1
local x=1

foreach outcome in empower default{
	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		local col1: word `i' of `colu1'
		local col2: word `i' of `colu2'
		
		
		local row1=`x'*`x'*`x'+15
		local row2=`x'*`x'*`x'+16
		sum `var' if race==1
		putexcel `col1'`row1' = `r(mean)', nformat(#.##%)
		sum `var' if race==2
		putexcel `col1'`row2' = `r(mean)', nformat(#.##%)
		sum `outcome' if `var'==1 & race==1
		putexcel `col2'`row1' = `r(mean)', nformat(#.##%)
		sum `outcome' if `var'==1 & race==2
		putexcel `col2'`row2' = `r(mean)', nformat(#.##%)
	
		local row3=`x'*`x'*`x'+17
		local row4=`x'*`x'*`x'+18
		sum `var' if race==1
		putexcel `col1'`row3' = `r(mean)', nformat(#.##%)
		sum `var' if race==4
		putexcel `col1'`row4' = `r(mean)', nformat(#.##%)
		sum `outcome' if `var'==1 & race==1
		putexcel `col2'`row3'= `r(mean)', nformat(#.##%)
		sum `outcome' if `var'==1 & race==4
		putexcel `col2'`row4' = `r(mean)', nformat(#.##%)
		
		local row5=`x'*`x'*`x'+19
		local row6=`x'*`x'*`x'+20
		sum `var' if race==2
		putexcel `col1'`row5' = `r(mean)', nformat(#.##%)
		sum `var' if race==4
		putexcel `col1'`row6' = `r(mean)', nformat(#.##%)
		sum `outcome' if `var'==1 & race==2
		putexcel `col2'`row5' = `r(mean)', nformat(#.##%)
		sum `outcome' if `var'==1 & race==4
		putexcel `col2'`row6' = `r(mean)', nformat(#.##%)
		
		local ++i
		}
	local ++x
}



***************************************
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

// just rate element of each component - everything held at 1996 except the rate part of the component I am interested in
gen mom_change_r =  (mt_mom_1 * mt_mom_2_bw) + (ft_partner_down_only_1 * ft_partner_down_only_1_bw) + (ft_partner_down_mom_1 * ft_partner_down_mom_1_bw) + (ft_partner_leave_1 * ft_partner_leave_1_bw) + (lt_other_changes_1 * lt_other_changes_1_bw)
gen partner_down_only_chg_r = (mt_mom_1 * mt_mom_1_bw) + (ft_partner_down_only_1 * ft_partner_down_only_2_bw) + (ft_partner_down_mom_1 * ft_partner_down_mom_1_bw) + (ft_partner_leave_1 * ft_partner_leave_1_bw) + (lt_other_changes_1 * lt_other_changes_1_bw)
gen partner_down_mom_up_chg_r  =   (mt_mom_1 * mt_mom_1_bw) + (ft_partner_down_only_1 * ft_partner_down_only_1_bw) + (ft_partner_down_mom_1 * ft_partner_down_mom_2_bw) + (ft_partner_leave_1 * ft_partner_leave_1_bw) + (lt_other_changes_1 * lt_other_changes_1_bw)
gen partner_leave_change_r =  (mt_mom_1 * mt_mom_1_bw) + (ft_partner_down_only_1 * ft_partner_down_only_1_bw) + (ft_partner_down_mom_1 * ft_partner_down_mom_1_bw) + (ft_partner_leave_1 * ft_partner_leave_2_bw) + (lt_other_changes_1 * lt_other_changes_1_bw)
gen other_hh_change_r =  (mt_mom_1 * mt_mom_1_bw) + (ft_partner_down_only_1 * ft_partner_down_only_1_bw) + (ft_partner_down_mom_1 * ft_partner_down_mom_1_bw) + (ft_partner_leave_1 * ft_partner_leave_1_bw) + (lt_other_changes_1 * lt_other_changes_2_bw)
ther_hh_change_y =  (mt_mom_2 * mt_mom_2_bw) + (ft_partner_down_2 * ft_partner_down_2_bw) + (ft_partner_leave_2 * ft_partner_leave_2_bw) + (lt_other_changes_1 * lt_other_changes_1_bw)

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

// 1996 as reference - just rate
global mom_compt_r = ((mom_change_r - bw_rate_96) / total_gap)
putexcel R3 = $mom_compt_r, nformat(#.##%)
global partner_down_mom_compt_r = ((partner_down_mom_up_chg_r - bw_rate_96) / total_gap)
putexcel S3 = $partner_down_mom_compt_r, nformat(#.##%)
global partner_down_only_compt_r = ((partner_down_only_chg_r - bw_rate_96) / total_gap)
putexcel T3 = $partner_down_only_compt_r, nformat(#.##%)
global partner_leave_compt_r = ((partner_leave_change_r - bw_rate_96) / total_gap)
putexcel U3 = $partner_leave_compt_r, nformat(#.##%)
global other_hh_compt_r = ((other_hh_change_r - bw_rate_96) / total_gap)
putexcel V3 = $other_hh_compt_r, nformat(#.##%)
