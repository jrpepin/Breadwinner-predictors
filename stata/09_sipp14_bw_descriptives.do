*-------------------------------------------------------------------------------
* BREADWINNER PROJECT
* bw_descriptives.do
* Kelly Raley and Joanna Pepin
*-------------------------------------------------------------------------------
di "$S_DATE"

********************************************************************************
* DESCRIPTION
********************************************************************************
* Create basic descriptive statistics of what events preceded breadwinning
* for mothers who became breadwinners during the panel

* The data file used in this script was produced by annualize.do
* It is NOT restricted to mothers living with minor children.

********************************************************************************
* Import data  & create breadwinning measures
********************************************************************************
use "$SIPP14keep/annual_bw_status.dta", clear


********************************************************************************
* Create breadwinning measures
********************************************************************************
// Create a lagged measure of breadwinning

gen bw50L=.
replace bw50L=bw50[_n-1] if PNUM==PNUM[_n-1] & SSUID==SSUID[_n-1] & year==(year[_n-1]+1) in 2/-1 
replace bw50L=. if year==2013 // in wave 1 we have no measure of breadwinning in previous wave
//browse SSUID PNUM year bw50 bw50L

gen bw60L=.
replace bw60L=bw60[_n-1] if PNUM==PNUM[_n-1] & SSUID==SSUID[_n-1] & year==(year[_n-1]+1) in 2/-1 
replace bw60L=. if year==2013 // in wave 1 we have no measure of breadwinning in previous wave

gen monthsobservedL=.
replace monthsobservedL=monthsobserved[_n-1] if PNUM==PNUM[_n-1] & SSUID==SSUID[_n-1] & year==(year[_n-1]+1) in 2/-1 

gen minorbiochildrenL=.
replace minorbiochildrenL=minorbiochildren[_n-1] if PNUM==PNUM[_n-1] & SSUID==SSUID[_n-1] & year==(year[_n-1]+1) in 2/-1 


// Create an indicators for whether individual transitioned into breadwinning for the first time (1) 
*  or has been observed breadwinning in the past (2). There is no measure for wave 1 because
* we cant know whether those breadwinning at wave 1 transitioned or were continuing
* in that status...except for women who became mothers in 2013, but there isn't a good
* reason to adjust code just for duration 0.

gen nprevbw50=0
replace nprevbw50=nprevbw50[_n-1] if PNUM==PNUM[_n-1] & SSUID==SSUID[_n-1] & year==(year[_n-1]+1) // in 2/-1 
replace nprevbw50=nprevbw50+1 if bw50[_n-1]==1 & PNUM==PNUM[_n-1] & SSUID==SSUID[_n-1] & year==(year[_n-1]+1)
// browse SSUID PNUM year nprevbw50 bw50 bw50L

gen nprevbw60=0
replace nprevbw60=nprevbw60[_n-1] if PNUM==PNUM[_n-1] & SSUID==SSUID[_n-1] & year==(year[_n-1]+1) // in 2/-1 
replace nprevbw60=nprevbw60+1 if bw60[_n-1]==1 & PNUM==PNUM[_n-1] & SSUID==SSUID[_n-1] & year==(year[_n-1]+1)

gen trans_bw50=.
replace trans_bw50=0 if bw50==0 & nprevbw50==0
replace trans_bw50=1 if bw50==1 & nprevbw50==0
replace trans_bw50=2 if nprevbw50 > 0
replace trans_bw50=. if year==2013

gen trans_bw60=.
replace trans_bw60=0 if bw60==0 & nprevbw60==0
replace trans_bw60=1 if bw60==1 & nprevbw60==0
replace trans_bw60=2 if nprevbw60 > 0
replace trans_bw60=. if year==2013

// browse SSUID PNUM year nprevbw50 bw50 bw50L trans_bw50

drop nprevbw50 nprevbw60*	

********************************************************************************
* Address missing data & some value labels that dropped off
********************************************************************************
// 	Create a tempory unique person id variable
	sort SSUID PNUM
	
	egen id = concat (SSUID PNUM)
	destring id, gen(idnum)
	format idnum %20.0f
	drop id
	
	unique 	idnum 
	
/*
// Make sure starting sample size is consistent. // this will only work if everything run in one session
	egen newsample2 = nvals(idnum) 
	global newsamplesize2 = newsample2
	di "$newsamplesize2"

	di "$newsamplesize"
	di "$newsamplesize2"

	if ("$newsamplesize" == "$newsamplesize2") {
		display "Success! Sample sizes consistent."
		}
		else {
		display as error "The sample size is different than annualize."
		exit
		}
*/

label define educ 1 "Less than HS" 2 "HS Diploma" 3 "Some College" 4 "College Degree" 5 "Advanced Degree"
label values educ educ

label define race 1 "NH White" 2 "NH Black" 3 "NH Asian" 4 "Hispanic" 5 "Other"
label values race race

label define occupation 1 "Management" 2 "STEM" 3 "Education / Legal / Media" 4 "Healthcare" 5 "Service" 6 "Sales" 7 "Office / Admin" 8 "Farming" 9 "Construction" 10 "Maintenance" 11 "Production" 12 "Transportation" 13 "Military" 
label values st_occ* end_occ* occupation

label define employ 1 "Full Time" 2 "Part Time" 3 "Not Working - Looking" 4 "Not Working - Not Looking" // this is probably oversimplified at the moment
label values st_employ end_employ employ

replace birth=0 if birth==.
replace firstbirth=0 if firstbirth==.


#delimit ;
label define arel 1 "Spouse"
                  2 "Unmarried partner"
                  3 "Biological parent"
                  4 "Biological child"
                  5 "Step parent"
                  6 "Step child"
                  7 "Adoptive parent"
                  8 "Adoptive child"
                  9 "Grandparent"
                 10 "Grandchild"
                 11 "Biological siblings"
                 12 "Half siblings"
                 13 "Step siblings"
                 14 "Adopted siblings"
                 15 "Other siblings"
                 16 "In-law"
                 17 "Aunt, Uncle, Niece, Nephew"
                 18 "Other relationship"   
                 19 "Foster parent/Child"
                 20 "Other non-relative"
                 99 "self" ;

#delimit cr

label values relationship* arel

// Look at how many respondents first appeared in each wave
tab first_wave wave 

// Look at percent breadwinning (60%) by wave and years of motherhood
table durmom wave, contents(mean bw60) format(%3.2g)

********************************************************************************
* Descriptives of characteristics of women who transitioned to breadwinning
********************************************************************************
putexcel set "$results/Breadwinner_Characteristics", sheet(data) replace
putexcel C1:D1 = "2014", merge border(bottom)
putexcel E1:F1 = "2015", merge border(bottom)
putexcel G1:H1 = "2016", merge border(bottom)
putexcel I1:J1 = "Total", merge border(bottom)
putexcel C2 = ("Year") E2 = ("Year") G2 = ("Year") I2 = ("Year"), border(bottom)
putexcel D2 = ("Prior Year") F2 = ("Prior Year") H2 = ("Prior Year") J2 = ("Prior Year"), border(bottom)
putexcel A3:A10="Marital Status", merge vcenter
putexcel B3= "Single -> Cohabit"
putexcel B4= "Single -> Married"
putexcel B5= "Cohabit -> Married"
putexcel B6= "Cohabit -> Dissolved"
putexcel B7= "Married -> Dissolved"
putexcel B8= "Married -> Widowed"
putexcel B9= "Married -> Cohabit"
putexcel B10= "No Status Change"
putexcel A11:A18="Household Status", merge vcenter
putexcel B11 = "Member Left"
putexcel B12 = "Earner Left"
putexcel B13 = "Earner -> Non-earner"
putexcel B14 = "Member Gained"
putexcel B15 = "Earner Gained"
putexcel B16 = "Non-earner -> earner"
putexcel B17 = "R became earner"
putexcel B18 = "R became non-earner"
putexcel A19:A30="Earnings Changes", merge vcenter
putexcel B19 = "R Earnings Up"
putexcel B20 = "R Earnings Down"
putexcel B21 = "Spouse Earnings Up"
putexcel B22 = "Spouse Earnings Down"
putexcel B23 = "HH Earnings Up"
putexcel B24 = "HH Earnings Down"
putexcel B25 = "Other Earnings Up"
putexcel B26 = "Other Earnings Down"
putexcel B27 = "R Earnings Change"
putexcel B28 = "Spouse Earnings Change"
putexcel B29 = "HH Earnings Change"
putexcel B30 = "Other Earnings Change"
putexcel A31:A32="Births", merge vcenter
putexcel B31 = "First Birth"
putexcel B32 = "Subsequent Birth"
putexcel A33:A48="Job Changes", merge vcenter
putexcel B33 = "Employer Change"
putexcel B34 = "Full-Time->Part-Time"
putexcel B35 = "Full-Time-> No Job"
putexcel B36 = "Part-Time-> No Job"
putexcel B37 = "Part-Time->Full-Time"
putexcel B38 = "No Job->PT"
putexcel B39 = "No Job->FT"
putexcel B40 = "No Job Change"
putexcel B41 = "Spouse Employer Change"
putexcel B42 = "Spouse Full-Time->Part-Time"
putexcel B43 = "Spouse Full-Time-> No Job"
putexcel B44 = "Spouse Part-Time-> No Job"
putexcel B45 = "Spouse Part-Time->Full-Time"
putexcel B46 = "Spouse No Job->PT"
putexcel B47 = "Spouse No Job->FT"
putexcel B48 = "Spouse No Job Change"
putexcel A49:A54="Hours Changes", merge vcenter
putexcel B49 = "R Hours Up"
putexcel B50 = "R Hours Down"
putexcel B51 = "Spouse Hours Up"
putexcel B52 = "Spouse Hours Down"
putexcel B53 = "R Hours Change"
putexcel B54 = "Spouse Hours Change"
putexcel A55:A56="Poverty Changes", merge vcenter
putexcel B55 = "Left Poverty"
putexcel B56 = "Entered Poverty"


// Marital status changes
	*First need to calculate those with no status change
	tab no_status_chg
	tab no_status_chg if trans_bw60==1 & year==2014
	tab no_status_chg if trans_bw60[_n+1]==1 & year[_n+1]==2014 // samples match when I do like this but with different distributions, and the sample for both matches those who became breadwinners in 2014 (578 at the moment) - which is what I want. However, now concerned that they are not necessarily the same people - hence below
	tab no_status_chg if trans_bw60[_n+1]==1 & year[_n+1]==2014 & SSUID==SSUID[_n+1] & PNUM==PNUM[_n+1] // we might not always have the year prior, so this makes sure we are still getting data for the same person? - sample drops, which is to be expected

	* quick recode so 1 signals any transition not number of transitions
	foreach var in sing_coh sing_mar coh_mar coh_diss marr_diss marr_wid marr_coh no_status_chg{
	replace `var' = 1 if `var' > 1
	}

local status_vars "sing_coh sing_mar coh_mar coh_diss marr_diss marr_wid marr_coh no_status_chg"
local colu1 "C E G"
local colu2 "D F H"

*by year
forvalues w=1/8 {
	forvalues y=14/16{
		local i=`y'-13
		local row=`w'+2
		local col1: word `i' of `colu1'
		local col2: word `i' of `colu2'
		local var: word `w' of `status_vars'
		mean `var' if trans_bw60==1 & year==20`y'
		matrix m`var'`y' = e(b)
		mean `var' if trans_bw60[_n+1]==1 & year[_n+1]==20`y' & SSUID==SSUID[_n+1] & PNUM==PNUM[_n+1]
		matrix pr`var'`y' = e(b)
		putexcel `col1'`row' = matrix(m`var'`y'), nformat(#.##%)
		putexcel `col2'`row' = matrix(pr`var'`y'), nformat(#.##%)
		}
}

* total
forvalues w=1/8 {
		local row=`w'+2
		local var: word `w' of `status_vars'
		mean `var' if trans_bw60==1
		matrix m`var'= e(b)
		mean `var' if trans_bw60[_n+1]==1 & SSUID==SSUID[_n+1] & PNUM==PNUM[_n+1]
		matrix pr`var' = e(b)
		putexcel I`row' = matrix(m`var'), nformat(#.##%)
		putexcel J`row' = matrix(pr`var'), nformat(#.##%)

}


// Household changes

	* quick recode so 1 signals any transition not number of transitions
	foreach var in hh_lose earn_lose earn_non hh_gain earn_gain non_earn resp_earn resp_non{
	replace `var' = 1 if `var' > 1
	}

local hh_vars "hh_lose earn_lose earn_non hh_gain earn_gain non_earn resp_earn resp_non"
local colu1 "C E G"
local colu2 "D F H"
	
* by year
forvalues w=1/8 {
	forvalues y=14/16{
		local i=`y'-13
		local row=`w'+10
		local col1: word `i' of `colu1'
		local col2: word `i' of `colu2'
		local var: word `w' of `hh_vars'
		mean `var' if trans_bw60==1 & year==20`y'
		matrix m`var'`y' = e(b)
		mean `var' if trans_bw60[_n+1]==1 & year[_n+1]==20`y' & SSUID==SSUID[_n+1] & PNUM==PNUM[_n+1]
		matrix pr`var'`y' = e(b)
		putexcel `col1'`row' = matrix(m`var'`y'), nformat(#.##%)
		putexcel `col2'`row' = matrix(pr`var'`y'), nformat(#.##%)
		}
}

* total
forvalues w=1/8 {
		local row=`w'+10
		local var: word `w' of `hh_vars'
		mean `var' if trans_bw60==1
		matrix m`var'= e(b)
		mean `var' if trans_bw60[_n+1]==1 & SSUID==SSUID[_n+1] & PNUM==PNUM[_n+1]
		matrix pr`var' = e(b)
		putexcel I`row' = matrix(m`var'), nformat(#.##%)
		putexcel J`row' = matrix(pr`var'), nformat(#.##%)

}


// Earnings changes
	// Do we care who else’s earnings changed up or down? Or just that they did. Maybe do any change up or down, then spouse up or down (see code in descriptives file), then anyone NOT spouse -do as TOTAL CHANGE? or by person?

* First create a variable that indicates percent change YoY
by SSUID PNUM (year), sort: gen earn_change = ((tpearn-tpearn[_n-1])/tpearn[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	// testing a mean, then up over a threshold, down over a threshold
	gen earn_up=0
	replace earn_up = 1 if earn_change >=.2000000
	replace earn_up=. if earn_change==.
	gen earn_down=0
	replace earn_down = 1 if earn_change <=-.2000000
	replace earn_down=. if earn_change==.
	// browse SSUID PNUM year tpearn earn_change earn_up earn_down

* then doing for partner specifically
* first get partner specific earnings
	gen spousenum=.
	forvalues n=1/22{
	replace spousenum=`n' if relationship`n'==1
	}

	gen partnernum=.
	forvalues n=1/22{
	replace partnernum=`n' if relationship`n'==2
	}

	gen spart_num=spousenum
	replace spart_num=partnernum if spart_num==.

	gen earnings_sp=.
	gen earnings_a_sp=.

	forvalues n=1/22{
	replace earnings_sp=to_TPEARN`n' if spart_num==`n'
	replace earnings_a_sp=to_earnings`n' if spart_num==`n'
	}

	//check: browse spart_num earnings_sp to_TPEARN* 

* then create variables
by SSUID PNUM (year), sort: gen earn_change_sp = ((earnings_sp-earnings_sp[_n-1])/earnings_sp[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	// testing a mean, then up over a threshold, down over a threshold
	gen earn_up_sp=0
	replace earn_up_sp = 1 if earn_change_sp >=.2000000
	replace earn_up_sp=. if earn_change_sp==.
	gen earn_down_sp=0
	replace earn_down_sp = 1 if earn_change_sp <=-.2000000
	replace earn_down_sp=. if earn_change_sp==.

* Variable for all earnings in HH besides R
gen hh_earn=thearn-tpearn
by SSUID PNUM (year), sort: gen earn_change_hh = ((hh_earn-hh_earn[_n-1])/hh_earn[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	// testing a mean, then up over a threshold, down over a threshold
	gen earn_up_hh=0
	replace earn_up_hh = 1 if earn_change_hh >=.2000000
	replace earn_up_hh=. if earn_change_hh==.
	gen earn_down_hh=0
	replace earn_down_hh = 1 if earn_change_hh <=-.2000000
	replace earn_down_hh=. if earn_change_hh==.

* Variable for all earnings in HH besides R + partner
gen other_earn=thearn-tpearn-earnings_sp
by SSUID PNUM (year), sort: gen earn_change_oth = ((other_earn-other_earn[_n-1])/other_earn[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	// testing a mean, then up over a threshold, down over a threshold
	gen earn_up_oth=0
	replace earn_up_oth = 1 if earn_change_oth >=.2000000
	replace earn_up_oth=. if earn_change_oth==.
	gen earn_down_oth=0
	replace earn_down_oth = 1 if earn_change_oth <=-.2000000
	replace earn_down_oth=. if earn_change_oth==.
//browse thearn tpearn earnings_sp hh_earn other_earn

* then calculate changes
local earn_vars "earn_up earn_down earn_up_sp earn_down_sp earn_up_hh earn_down_hh earn_up_oth earn_down_oth"
local colu1 "C E G"

* by year
forvalues w=1/8 {
	forvalues y=14/16{
		local i=`y'-13
		local row=`w'+18
		local col1: word `i' of `colu1'
		local var: word `w' of `earn_vars'
		mean `var' if trans_bw60==1 & year==20`y'
		matrix m`var'`y' = e(b)
		putexcel `col1'`row' = matrix(m`var'`y'), nformat(#.##%)
		}
}

* total
forvalues w=1/8 {
		local row=`w'+18
		local var: word `w' of `earn_vars'
		mean `var' if trans_bw60==1
		matrix m`var' = e(b)
		putexcel I`row' = matrix(m`var'), nformat(#.##%)
}

local change_vars "earn_change earn_change_sp earn_change_hh earn_change_oth"
local colu1 "C E G"

* by year
forvalues w=1/4 {
	forvalues y=14/16{
		local i=`y'-13
		local row=`w'+26
		local col1: word `i' of `colu1'
		local var: word `w' of `change_vars'
		mean `var' if trans_bw60==1 & year==20`y'
		matrix m`var'`y' = e(b)
		putexcel `col1'`row' = matrix(m`var'`y'), nformat(#.##%)
		}
}

* total
forvalues w=1/4 {
		local row=`w'+26
		local var: word `w' of `change_vars'
		mean `var' if trans_bw60==1
		matrix m`var' = e(b)
		putexcel I`row' = matrix(m`var'), nformat(#.##%)
}
	
// First birth
local colu1 "C E G"
local colu2 "D F H"

* by year
forvalues y=14/16{
	local i=`y'-13
	local row=31
	local col1: word `i' of `colu1'
	local col2: word `i' of `colu2'
	mean firstbirth if trans_bw60==1 & year==20`y'
	matrix mbirth`y' = e(b)
	mean firstbirth if trans_bw60[_n+1]==1 & year[_n+1]==20`y' & SSUID==SSUID[_n+1] & PNUM==PNUM[_n+1]
	matrix prbirth`y' = e(b)
	putexcel `col1'`row' = matrix(mbirth`y'), nformat(#.##%)
	putexcel `col2'`row' = matrix(prbirth`y'), nformat(#.##%)
}

*total
mean firstbirth if trans_bw60==1
matrix mfirstbirth= e(b)
mean firstbirth if trans_bw60[_n+1]==1 & SSUID==SSUID[_n+1] & PNUM==PNUM[_n+1]
matrix prfirstbirth = e(b)
putexcel I31 = matrix(mfirstbirth), nformat(#.##%)
putexcel J31 = matrix(prfirstbirth), nformat(#.##%)

// Subsequent birth
local colu1 "C E G"
local colu2 "D F H"

* by year
forvalues y=14/16{
	local i=`y'-13
	local row=32
	local col1: word `i' of `colu1'
	local col2: word `i' of `colu2'
	mean birth if trans_bw60==1 & year==20`y'
	matrix mbirths`y' = e(b)
	mean birth if trans_bw60[_n+1]==1 & year[_n+1]==20`y' & SSUID==SSUID[_n+1] & PNUM==PNUM[_n+1]
	matrix prbirths`y' = e(b)
	putexcel `col1'`row' = matrix(mbirths`y'), nformat(#.##%)
	putexcel `col2'`row' = matrix(prbirths`y'), nformat(#.##%)
}

*total
mean birth if trans_bw60==1
matrix mbirths= e(b)
mean birth if trans_bw60[_n+1]==1 & SSUID==SSUID[_n+1] & PNUM==PNUM[_n+1]
matrix prbirths = e(b)
putexcel I32 = matrix(mbirths), nformat(#.##%)
putexcel J32 = matrix(prbirths), nformat(#.##%)

// Job changes
	* quick recode so 1 signals any transition not number of transitions
	foreach var in jobchange full_part full_no part_no part_full no_part no_full no_job_chg jobchange_sp full_part_sp full_no_sp part_no_sp part_full_sp no_part_sp no_full_sp no_job_chg_sp{
	replace `var' = 1 if `var' > 1
	}
	
local job_vars "jobchange full_part full_no part_no part_full no_part no_full no_job_chg jobchange_sp full_part_sp full_no_sp part_no_sp part_full_sp no_part_sp no_full_sp no_job_chg_sp"
local colu1 "C E G"
local colu2 "D F H"

*by year
forvalues w=1/16 {
	forvalues y=14/16{
		local i=`y'-13
		local row=`w'+32
		local col1: word `i' of `colu1'
		local col2: word `i' of `colu2'
		local var: word `w' of `job_vars'
		mean `var' if trans_bw60==1 & year==20`y'
		matrix m`var'`y' = e(b)
		mean `var' if trans_bw60[_n+1]==1 & year[_n+1]==20`y' & SSUID==SSUID[_n+1] & PNUM==PNUM[_n+1]
		matrix pr`var'`y' = e(b)
		putexcel `col1'`row' = matrix(m`var'`y'), nformat(#.##%)
		putexcel `col2'`row' = matrix(pr`var'`y'), nformat(#.##%)
		}
}

* total
forvalues w=1/16 {
		local row=`w'+32
		local var: word `w' of `job_vars'
		mean `var' if trans_bw60==1
		matrix m`var'= e(b)
		mean `var' if trans_bw60[_n+1]==1 & SSUID==SSUID[_n+1] & PNUM==PNUM[_n+1]
		matrix pr`var' = e(b)
		putexcel I`row' = matrix(m`var'), nformat(#.##%)
		putexcel J`row' = matrix(pr`var'), nformat(#.##%)

}

// Raw hours changes

* First create a variable that indicates percent change YoY
by SSUID PNUM (year), sort: gen hours_change = ((avg_hrs-avg_hrs[_n-1])/avg_hrs[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
browse SSUID PNUM year avg_hrs hours_change

	// testing a mean, then up over a threshold, down over a threshold
	gen hours_up=0
	replace hours_up = 1 if hours_change >=.1500000
	replace hours_up=. if hours_change==.
	gen hours_down=0
	replace hours_down = 1 if hours_change <=-.1500000
	replace hours_down=. if hours_change==.
	// browse SSUID PNUM year avg_hrs hours_change hours_up hours_down

* then doing for partner specifically
* first get partner specific hours

	gen hours_sp=.
	forvalues n=1/22{
	replace hours_sp=avg_to_hrs`n' if spart_num==`n'
	}

	//check: browse spart_num hours_sp avg_to_hrs* 

* then create variables
by SSUID PNUM (year), sort: gen hours_change_sp = ((hours_sp-hours_sp[_n-1])/hours_sp[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	// testing a mean, then up over a threshold, down over a threshold
	gen hours_up_sp=0
	replace hours_up_sp = 1 if hours_change_sp >=.1500000
	replace hours_up_sp=. if hours_change_sp==.
	gen hours_down_sp=0
	replace hours_down_sp = 1 if hours_change_sp <=-.1500000
	replace hours_down_sp=. if hours_change_sp==.

* then calculate changes
local hours_vars "hours_up hours_down hours_up_sp hours_down_sp"
local colu1 "C E G"

* by year
forvalues w=1/4 {
	forvalues y=14/16{
		local i=`y'-13
		local row=`w'+48
		local col1: word `i' of `colu1'
		local var: word `w' of `hours_vars'
		mean `var' if trans_bw60==1 & year==20`y'
		matrix m`var'`y' = e(b)
		putexcel `col1'`row' = matrix(m`var'`y'), nformat(#.##%)
		}
}

* total
forvalues w=1/4 {
		local row=`w'+48
		local var: word `w' of `hours_vars'
		mean `var' if trans_bw60==1
		matrix m`var' = e(b)
		putexcel I`row' = matrix(m`var'), nformat(#.##%)
}

local hr_change_vars "hours_change hours_change_sp"
local colu1 "C E G"

* by year
forvalues w=1/2 {
	forvalues y=14/16{
		local i=`y'-13
		local row=`w'+52
		local col1: word `i' of `colu1'
		local var: word `w' of `hr_change_vars'
		mean `var' if trans_bw60==1 & year==20`y'
		matrix m`var'`y' = e(b)
		putexcel `col1'`row' = matrix(m`var'`y'), nformat(#.##%)
		}
}

* total
forvalues w=1/2 {
		local row=`w'+52
		local var: word `w' of `hr_change_vars'
		mean `var' if trans_bw60==1
		matrix m`var' = e(b)
		putexcel I`row' = matrix(m`var'), nformat(#.##%)
}

// Poverty // need to pull back in for partner
drop pov_level
recode thincpovt2 (0/0.4999999=1) (.500000/1.2499999=2) (1.250000/1.499999=3) (1.500000/1.8499999999=4) (1.850000000/1.999999=5) (2.0000000/3.999999=6) (4.0000000/1000=7), gen(pov_level)
label define pov_level 1 "< 50%" 2 "50-125%" 3 "125-150%" 4 "150-185%" 5 "185-200%" 6 "200-400%" 7 "400%+" // http://neocando.case.edu/cando/pdf/CensusPovertyandIncomeIndicators.pdf - to determine thresholds
label values pov_level pov_level

gen out_pov=0
replace out_pov=1 if inrange(pov_level,6,7) & inrange(pov_level[_n-1],1,5) & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
gen in_pov=0
replace in_pov=1 if inrange(pov_level,1,5) & inrange(pov_level[_n-1],6,7) & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]

local pov_change_vars "out_pov in_pov"
local colu1 "C E G"

* by year
forvalues w=1/2 {
	forvalues y=14/16{
		local i=`y'-13
		local row=`w'+54
		local col1: word `i' of `colu1'
		local var: word `w' of `pov_change_vars'
		mean `var' if trans_bw60==1 & year==20`y'
		matrix m`var'`y' = e(b)
		putexcel `col1'`row' = matrix(m`var'`y'), nformat(#.##%)
		}
}

* total
forvalues w=1/2 {
		local row=`w'+54
		local var: word `w' of `pov_change_vars'
		mean `var' if trans_bw60==1
		matrix m`var' = e(b)
		putexcel I`row' = matrix(m`var'), nformat(#.##%)
}
	
********************************************************************************
* Concurrent changes
********************************************************************************

//can't do change variables because that's a mean and has too many values

local vars1 "sing_coh sing_mar coh_mar coh_diss marr_diss marr_wid marr_coh no_status_chg firstbirth birth hh_lose earn_lose earn_non hh_gain earn_gain non_earn resp_earn resp_non earn_up earn_down earn_up_sp earn_down_sp earn_up_hh earn_down_hh earn_up_oth earn_down_oth jobchange full_part full_no part_no part_full no_part no_full no_job_chg jobchange_sp full_part_sp full_no_sp part_no_sp part_full_sp no_part_sp no_full_sp no_job_chg_sp hours_up hours_down hours_up_sp hours_down_sp out_pov in_pov"

local vars2 "sing_coh sing_mar coh_mar coh_diss marr_diss marr_wid marr_coh no_status_chg firstbirth birth hh_lose earn_lose earn_non hh_gain earn_gain non_earn resp_earn resp_non earn_up earn_down earn_up_sp earn_down_sp earn_up_hh earn_down_hh earn_up_oth earn_down_oth jobchange full_part full_no part_no part_full no_part no_full no_job_chg jobchange_sp full_part_sp full_no_sp part_no_sp part_full_sp no_part_sp no_full_sp no_job_chg_sp hours_up hours_down hours_up_sp hours_down_sp out_pov in_pov"

local colu "B C D E F G H I J K L M N O P Q R S T U V W X Y Z AA AB AC AD AE AF AG AH AI AJ AK AL AM AN AO AP AQ AR AS AT AU AV AW"

putexcel set "$results/Breadwinner_Characteristics", sheet(matrix) modify

putexcel A2= "Single -> Cohabit" B1= "Single -> Cohabit"
putexcel A3= "Single -> Married" C1= "Single -> Married"
putexcel A4= "Cohabit -> Married" D1= "Cohabit -> Married"
putexcel A5= "Cohabit -> Dissolved" E1= "Cohabit -> Dissolved"
putexcel A6= "Married -> Dissolved" F1= "Married -> Dissolved"
putexcel A7= "Married -> Widowed" G1= "Married -> Widowed"
putexcel A8= "Married -> Cohabit" H1= "Married -> Cohabit"
putexcel A9= "No Status Change" I1= "No Status Change"
putexcel A10 = "First Birth" J1= "First Birth"
putexcel A11 = "Another Birth" K1= "Another Birth"
putexcel A12 = "Member Left" L1= "Member Left"
putexcel A13 = "Earner Left" M1= "Earner Left"
putexcel A14 = "Earner -> Non-earner" N1= "Earner -> Non-earner"
putexcel A15 = "Member Gained" O1= "Member Gained"
putexcel A16 = "Earner Gained" P1= "Earner Gained"
putexcel A17 = "Non-earner -> earner" Q1= "Non-earner -> earner"
putexcel A19 = "R became earner" R1= "R became earner"
putexcel A19 = "R became non-earner" S1= "R became non-earner"
putexcel A20 = "R Earnings Up" T1= "R Earnings Up"
putexcel A21 = "R Earnings Down" U1= "R Earnings Down"
putexcel A22 = "Spouse Earnings Up" V1= "Spouse Earnings Up"
putexcel A23 = "Spouse Earnings Down" W1= "Spouse Earnings Down"
putexcel A24 = "HH Earnings Up" X1= "HH Earnings Up"
putexcel A25 = "HH Earnings Down" Y1= "HH Earnings Down"
putexcel A26 = "Other Earnings Up" Z1= "Other Earnings Up"
putexcel A27 = "Other Earnings Down" AA1= "Other Earnings Down"
putexcel A28 = "Employer Change" AB1 = "Employer Change"
putexcel A29 = "Full-Time->Part-Time" AC1 = "Full-Time->Part-Time"
putexcel A30 = "Full-Time-> No Job" AD1 = "Full-Time-> No Job"
putexcel A31 = "Part-Time-> No Job" AE1 = "Part-Time-> No Job"
putexcel A32 = "Part-Time->Full-Time" AF1 = "Part-Time->Full-Time"
putexcel A33 = "No Job->PT" AG1 = "No Job->PT"
putexcel A34 = "No Job->FT" AH1 = "No Job->FT"
putexcel A35 = "No Job Change" AI1 = "No Job Change"
putexcel A36 = "Spouse Employer Change" AJ1 = "Spouse Employer Change"
putexcel A37 = "Spouse Full-Time->Part-Time" AK1 = "Spouse Full-Time->Part-Time"
putexcel A38 = "Spouse Full-Time-> No Job" AL1 = "Spouse Full-Time-> No Job"
putexcel A39 = "Spouse Part-Time-> No Job" AM1 = "Spouse Part-Time-> No Job"
putexcel A40 = "Spouse Part-Time->Full-Time" AN1 = "Spouse Part-Time->Full-Time"
putexcel A41 = "Spouse No Job->PT" AO1 = "Spouse No Job->PT"
putexcel A42 = "Spouse No Job->FT" AP1 = "Spouse No Job->FT"
putexcel A43 = "Spouse No Job Change" AQ1 = "Spouse No Job Change"
putexcel A44 = "R Hours Up" AR1 = "R Hours Up"
putexcel A45 = "R Hours Down" AS1 = "R Hours Down"
putexcel A46 = "Spouse Hours Up" AT1 = "Spouse Hours Up"
putexcel A47 = "Spouse Hours Down" AU1 = "Spouse Hours Down"
putexcel A48 = "Left Poverty" AV1 = "Left Poverty"
putexcel A49 = "Entered Poverty" AW1 = "Entered Poverty"



forvalues v=1/48{
local var1: word `v' of `vars1'
local row =`v'+1
	forvalues x=1/48{
	local col: word `x' of `colu'
	local var2: word `x' of `vars2'
	tab `var1' `var2' if trans_bw60==1, matcell(`var1'_`var2'_1)
	mata: st_matrix("`var1'_`var2'_1", (st_matrix("`var1'_`var2'_1")  :/ sum(st_matrix("`var1'_`var2'_1"))))
	mat `var1'_`var2' = `var1'_`var2'_1[2,2]
	putexcel `col'`row' = matrix(`var1'_`var2'), nformat(#.##%) 
	}
}

/* logic to follow
tab sing_coh hh_lose if trans_bw60==1 & year==2014, matcell(test)
mata: st_matrix("test", (st_matrix("test")  :/ sum(st_matrix("test"))))
mat B = test[2,2]
matrix list B = has just the value I want
*/


save "$SIPP14keep/bw_descriptives.dta", replace
