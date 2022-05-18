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
putexcel M1 = "Rate of Outcome", border(bottom)
putexcel N1 = "Total Difference", border(bottom)
putexcel O1 = "Alt Rate", border(bottom)
putexcel P1 = "Rate Difference", border(bottom)
putexcel Q1 = "Alt Comp", border(bottom)
putexcel R1 = "Composition Difference", border(bottom)
putexcel S1 = "Mom Component", border(bottom)
putexcel T1 = "Partner Down Mom Up Component", border(bottom)
putexcel U1 = "Partner Down Only Component", border(bottom)
putexcel V1 = "Partner Left Component", border(bottom)
putexcel W1 = "Other Component", border(bottom)

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


// Calculating rates needed
forvalues r=2/28{
	putexcel M`r'=formula((C`r'*D`r')+(E`r'*F`r')+(G`r'*H`r')+(I`r'*J`r')+(K`r'*L`r')), nformat(#.##%)
}

local row "2 4 6 9 11 13 16 18 20 23 25 27"
local i=1

forvalues r=1/12{
	local row1: word `i' of `row'
	local row2 = `row1'+1
	putexcel O`row1'=formula((C`row1'*D`row2')+(E`row1'*F`row2')+(G`row1'*H`row2')+(I`row1'*J`row2')+(K`row1'*L`row2')), nformat(#.##%) // setting rate to other group
	putexcel Q`row1'=formula((C`row2'*D`row1')+(E`row2'*F`row1')+(G`row2'*H`row1')+(I`row2'*J`row1')+(K`row2'*L`row1')), nformat(#.##%) // setting composition to other group
	putexcel N`row1'=formula(M`row2'-M`row1'), nformat(#.##%) // total diff
	putexcel P`row1'=formula(O`row1'-M`row1'), nformat(#.##%) // rate diff
	putexcel R`row1'=formula(Q`row1'-M`row1'), nformat(#.##%) // comp diff
	local ++i
}


// need to figure out how to do the specific elements. might need to go back to the matrices. just difficult because it's not systematic like by race and class; i keep swapping reference groups

