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
tab no_status_chg
tab no_status_chg if trans_bw60==1 & year==2014
tab no_status_chg if trans_bw60[_n+1]==1 & year[_n+1]==2014 // samples match when I do like this but with different distributions, and the sample for both matches those who became breadwinners in 2014 (578 at the moment) - which is what I want. However, now concerned that they are not necessarily the same people - hence below
tab no_status_chg if trans_bw60[_n+1]==1 & year[_n+1]==2014 & SSUID==SSUID[_n+1] & PNUM==PNUM[_n+1] // we might not always have the year prior, so this makes sure we are still getting data for the same person? - sample drops, which is to be expected

// Marital status changes
forvalues y=2014/2016{
	foreach var in sing_coh sing_mar coh_mar coh_diss marr_diss marr_wid marr_coh no_status_chg{
	tab `var' if trans_bw60==1 & year==`y'
	tab `var' if trans_bw60[_n+1]==1 & year[_n+1]==`y' & SSUID==SSUID[_n+1] & PNUM==PNUM[_n+1]
	}
}

// Household changes
forvalues y=2014/2016{
	foreach var in hh_lose earn_lose earn_non hh_gain earn_gain non_earn resp_earn resp_non{
	tab `var' if trans_bw60==1 & year==`y'
	tab `var' if trans_bw60[_n+1]==1 & year[_n+1]==`y' & SSUID==SSUID[_n+1] & PNUM==PNUM[_n+1]
	}
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
forvalues y=2014/2016{
	foreach var in earn_up earn_down earn_up_sp earn_down_sp earn_up_hh earn_down_hh earn_up_oth earn_down_oth{
	tab `var' if trans_bw60==1 & year==`y'
	tab `var' if trans_bw60[_n+1]==1 & year[_n+1]==`y' & SSUID==SSUID[_n+1] & PNUM==PNUM[_n+1]
	}
	foreach var in earn_change earn_change_sp earn_change_hh earn_change_oth{
	tabstat `var' if trans_bw60==1 & year==`y'
	}
}
	
// First birth
forvalues y=2014/2016{
	tab firstbirth if trans_bw60==1 & year==`y'
	tab firstbirth if trans_bw60[_n+1]==1 & year[_n+1]==`y' & SSUID==SSUID[_n+1] & PNUM==PNUM[_n+1]
}	
	
// Concurrent changes

save "$SIPP14keep/bw_descriptives.dta", replace
