*-------------------------------------------------------------------------------
* BREADWINNER PROJECT
* sample_descriptives.do
* Kelly Raley and Joanna Pepin
*-------------------------------------------------------------------------------
di "$S_DATE"

********************************************************************************
* DESCRIPTION
********************************************************************************
* Create basic descriptive statistics of sample as well as others in the HH

* The data file used in this script was produced by bw_descriptives.do

********************************************************************************
* Import data
********************************************************************************
use "$SIPP96keep/96_bw_descriptives.dta", clear

********************************************************************************
* Calculating who is primary earner in each HH
********************************************************************************
egen hh_earn_max = rowmax (to_earnings1-to_earnings17)
// browse SSUID PNUM year hh_earn_max earnings to_earnings* 

gen who_max_earn=.
forvalues n=1/17{
replace who_max_earn=relationship`n' if to_earnings`n'==hh_earn_max
}

// browse SSUID PNUM year who_max_earn hh_earn_max earnings to_earnings* relationship*

gen total_max_earner=.
replace total_max_earner=who_max_earn if (earnings==. & hh_earn_max>0 & hh_earn_max!=.) | (hh_earn_max > earnings & earnings!=. & hh_earn_max!=.)
replace total_max_earner=99 if (earnings>0 & earnings!=. & hh_earn_max==.) | (hh_earn_max < earnings & earnings!=. & hh_earn_max!=.)

gen total_max_earner2=total_max_earner
replace total_max_earner2=100 if total_max_earner==99 & (hh_earn_max==0 | hh_earn_max==.) // splitting out mothers who are primary earners because no one else is an earner in HH

browse SSUID PNUM year who_max_earn hh_earn_max earnings total_max_earner total_max_earner2 to_earnings*


#delimit ;
label define rel2 1 "Spouse"
                  2 "Unmarried partner"
                  10 "Biological parent"
				  11 "Stepparent"
				  12 "Step / adoptive parent"
				  13 "Adoptive parent"
				  14 "Foster parent"
				  15 "Other parent"
                  20 "Biological child"
				  21 "Step child"
                  22 "Step / adopted child"
                  23 "Adoptive child"
                  24 "Foster child"
				  25 "Other child"
				  30 "Bio sib"
				  31 "Half sib"
				  32 "Step sib"
				  33 "Adopted siblings"
				  34 "Other sib"
				  40 "Grandparent"
				  41 "Grandchild"
                  42 "Uncle/ aunt"
				  43 "Nephew / niece"
				  50 "Parent in law"
				  51 "Daughter / son in law"
				  52 "Sibling in law"
				  55 "Other relative"
				  61 "Roommate / housemate"
				  62 "Roomer / boarder"
				  63 "Paid employee"
				  65 "Other non-relative"
                  99 "self" 
				  100 "self - no other earners" ;

#delimit cr

label values who_max_earn total_max_earner* rel2

// put in excel

tabout total_max_earner2 using "$results/Breadwinner_Distro_96.xls", c(freq col) clab(N Percent) f(0c 1p) replace

forvalues e=1/4{
	tabout total_max_earner2 using "$results/Breadwinner_Distro_96.xls" if educ==`e', c(freq col) clab(Educ=`e' Percent) f(0c 1p) append 
}

label define marital_status 1 "Married" 2 "Cohabiting" 3 "Widowed" 4 "Dissolved-Unpartnered" 5 "Never Married- Not partnered"
label values st_marital_status end_marital_status marital_status

tab total_max_earner2 if inlist(end_marital_status,3,4,5)
