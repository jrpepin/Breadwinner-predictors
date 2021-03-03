********************************************************************************
* Import data  & create breadwinning measures
********************************************************************************
use "$SIPP14keep/sipp96_annual_bw_status.dta", clear


********************************************************************************
* Create breadwinning measures
********************************************************************************
// Create a lagged measure of breadwinning

gen bw50L=.
replace bw50L=bw50[_n-1] if PNUM==PNUM[_n-1] & SSUID==SSUID[_n-1] & year==(year[_n-1]+1) in 2/-1 
replace bw50L=. if year==1995 | year==1996 // in wave 1 we have no measure of breadwinning in previous wave
//browse SSUID PNUM year bw50 bw50L

gen bw60L=.
replace bw60L=bw60[_n-1] if PNUM==PNUM[_n-1] & SSUID==SSUID[_n-1] & year==(year[_n-1]+1) in 2/-1 
replace bw60L=. if year==1995 | year==1996 // in wave 1 we have no measure of breadwinning in previous wave

gen monthsobservedL=.
replace monthsobservedL=monthsobserved[_n-1] if PNUM==PNUM[_n-1] & SSUID==SSUID[_n-1] & year==(year[_n-1]+1) in 2/-1 

/*
gen minorbiochildrenL=.
replace minorbiochildrenL=minorbiochildren[_n-1] if PNUM==PNUM[_n-1] & SSUID==SSUID[_n-1] & year==(year[_n-1]+1) in 2/-1 
*/

// Create an indicators for whether individual transitioned into breadwinning for the first time (1) 
*  or has been observed breadwinning in the past (2). There is no measure for wave 1 because
* we cant know whether those breadwinning at wave 1 transitioned or were continuing
* in that status...except for women who became mothers in 2013, but there isn't a good
* reason to adjust code just for duration 0.

gen nprevbw50=0
replace nprevbw50=nprevbw50[_n-1] if PNUM==PNUM[_n-1] & SSUID==SSUID[_n-1] & year==(year[_n-1]+1) // in 2/-1 
replace nprevbw50=nprevbw50+1 if bw50[_n-1]==1 & PNUM==PNUM[_n-1] & SSUID==SSUID[_n-1] & year==(year[_n-1]+1)

gen nprevbw60=0
replace nprevbw60=nprevbw60[_n-1] if PNUM==PNUM[_n-1] & SSUID==SSUID[_n-1] & year==(year[_n-1]+1) // in 2/-1 
replace nprevbw60=nprevbw60+1 if bw60[_n-1]==1 & PNUM==PNUM[_n-1] & SSUID==SSUID[_n-1] & year==(year[_n-1]+1)

gen trans_bw50=.
replace trans_bw50=0 if bw50==0 & nprevbw50==0
replace trans_bw50=1 if bw50==1 & nprevbw50==0
replace trans_bw50=2 if nprevbw50 > 0
replace trans_bw50=. if year==1995 | year==1996

gen trans_bw60=.
replace trans_bw60=0 if bw60==0 & nprevbw60==0
replace trans_bw60=1 if bw60==1 & nprevbw60==0
replace trans_bw60=2 if nprevbw60 > 0
replace trans_bw60=. if year==1995 | year==1996

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

//
label define educ 1 "Less than HS" 2 "HS Diploma" 3 "Some College" 4 "College Plus"
label values educ educ

/*
label define race 1 "NH White" 2 "NH Black" 3 "NH Asian" 4 "Hispanic" 5 "Other"
label values race race

label define occupation 1 "Management" 2 "STEM" 3 "Education / Legal / Media" 4 "Healthcare" 5 "Service" 6 "Sales" 7 "Office / Admin" 8 "Farming" 9 "Construction" 10 "Maintenance" 11 "Production" 12 "Transportation" 13 "Military" 
label values st_occ* end_occ* occupation

label define employ 1 "Full Time" 2 "Part Time" 3 "Not Working - Looking" 4 "Not Working - Not Looking" // this is probably oversimplified at the moment
label values st_employ end_employ employ
*/

replace birth=0 if birth==.
replace first_birth=0 if first_birth==.

// Look at percent breadwinning (60%) by year and years of motherhood
table durmom year, contents(mean bw60) format(%3.2g)

********************************************************************************
* Descriptives of characteristics of women who transitioned to breadwinning
********************************************************************************
putexcel set "$results/Breadwinner_Characteristics_1996", sheet(data) replace
putexcel C1:D1 = "1996", merge border(bottom)
putexcel E1:F1 = "1997", merge border(bottom)
putexcel G1:H1 = "1998", merge border(bottom)
putexcel I1:J1 = "1999", merge border(bottom)
putexcel K1:L1 = "Total", merge border(bottom)
putexcel M1:N1 = "All Children in HH", merge border(bottom)
putexcel O1:P1 = "Non-BW Comparison", merge border(bottom)
putexcel C2 = ("Year") E2 = ("Year") G2 = ("Year") I2 = ("Year") K2 = ("Year") M2 = ("Year") O2 = ("Year"), border(bottom)
putexcel D2 = ("Prior Year") F2 = ("Prior Year") H2 = ("Prior Year") J2 = ("Prior Year") L2 = ("Prior Year") N2 = ("Prior Year") P2 = ("Prior Year"), border(bottom)
putexcel A3:A4="Births", merge vcenter
putexcel B3 = "First Birth"
putexcel B4 = "Subsequent Birth"
putexcel A5:A17="Job Changes", merge vcenter
putexcel B5 = "Full-Time->Part-Time"
putexcel B6 = "Full-Time-> No Job"
putexcel B7 = "Part-Time-> No Job"
putexcel B8 = "Part-Time->Full-Time"
putexcel B9 = "No Job->PT"
putexcel B10 = "No Job->FT"
putexcel B11 = "No Job Change"
putexcel B12 = "Employer Change"
putexcel B13 = "Better Job"
putexcel B14 = "One to Many Jobs"
putexcel B15 = "Many to one job"
putexcel B16 = "Added a job"
putexcel B17 = "Lost a job"
putexcel A18:A21="Average Changes", merge vcenter
putexcel B18 = "R Earnings Change - Average"
putexcel B19 = "HH Earnings Change - Average"
putexcel B20 = "R Hours Change - Average"
putexcel B21 = "R Wages Change - Average"
putexcel A22:A29="Thresholds", merge vcenter
putexcel B22 = "R Earnings Up 8%"
putexcel B23 = "R Earnings Down 8%"
putexcel B24 = "HH Earnings Up 8%"
putexcel B25 = "HH Earnings Down 8%"
putexcel B26 = "R Hours Up 5%"
putexcel B27 = "R Hours Down 5%"
putexcel B28 = "R Wages Up 8%"
putexcel B29 = "R Wages Down 8%"
putexcel A30:A31="Median Changes", merge vcenter
putexcel B30 = "R Earnings Change - Median"
putexcel B31 = "HH Earnings Change - Median"
putexcel A32:A35="Changes in Earner Status", merge vcenter
putexcel B32 = "R Became Earner"
putexcel B33 = "R Stopped Earning"
putexcel B34 = "Someone else in HH Became Earner"
putexcel B35 = "Someone else in HH Stopped Earning"

putexcel B37 = "Total Sample / Just BWs"

sort SSUID PNUM year

// firthbirth - needs own code because mother had to be a BW in year prior to having a child
local colu1 "C E G I"

* by year
	forvalues y=96/99{
		local i=`y'-95
		local col1: word `i' of `colu1'
		mean first_birth if bw60==1 & year==19`y' & bw60[_n-1]==1 & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
		matrix mfirst_birth`y' = e(b)
		putexcel `col1'3 = matrix(mfirst_birth`y'), nformat(#.##%)
		}

* total
	mean first_birth if bw60==1 & bw60[_n-1]==1 & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	matrix mfirst_birth = e(b)
	putexcel I3 = matrix(mfirst_birth), nformat(#.##%)

// Job changes - respondent and spouse - temp putting birth in here for now
	* Renaming for length later
	rename num_jobs_up numjobs_up
	rename num_jobs_down numjobs_down
	
* quick recode so 1 signals any transition not number of transitions
	foreach var in full_part full_no part_no part_full no_part no_full no_job_chg jobchange betterjob many_jobs one_job numjobs_up numjobs_down{
	replace `var' = 1 if `var' > 1
	}
	
// birth not currently working because not tracked post 1996

local job_vars "full_part full_no part_no part_full no_part no_full no_job_chg jobchange betterjob many_jobs one_job numjobs_up numjobs_down"
local colu1 "C E G I"
local colu2 "D F H J"

*by year
forvalues w=1/13 {
	forvalues y=97/99{
		local i=`y'-95
		local row=`w'+4
		local col1: word `i' of `colu1'
		local col2: word `i' of `colu2'
		local var: word `w' of `job_vars'
		mean `var' if trans_bw60==1 & year==19`y'
		matrix m`var'`y' = e(b)
		mean `var' if trans_bw60[_n+1]==1 & year[_n+1]==19`y' & SSUID==SSUID[_n+1] & PNUM==PNUM[_n+1]
		matrix pr`var'`y' = e(b)
		putexcel `col1'`row' = matrix(m`var'`y'), nformat(#.##%)
		putexcel `col2'`row' = matrix(pr`var'`y'), nformat(#.##%)
		}
}

* total
forvalues w=1/13 {
		local row=`w'+4
		local var: word `w' of `job_vars'
		mean `var' if trans_bw60==1
		matrix m`var'= e(b)
		mean `var' if trans_bw60[_n+1]==1 & SSUID==SSUID[_n+1] & PNUM==PNUM[_n+1]
		matrix pr`var' = e(b)
		putexcel K`row' = matrix(m`var'), nformat(#.##%)
		putexcel L`row' = matrix(pr`var'), nformat(#.##%)

}

* just those with ALL kids at home // temporary until I have full file with actual # of kids in HH
forvalues w=1/13 {
		local row=`w'+4
		local var: word `w' of `job_vars'
		mean `var' if trans_bw60==1 & emomlivh==1
		matrix m`var'= e(b)
		mean `var' if trans_bw60[_n+1]==1 & emomlivh[_n+1]==1 & SSUID==SSUID[_n+1] & PNUM==PNUM[_n+1]
		matrix pr`var' = e(b)
		putexcel M`row' = matrix(m`var'), nformat(#.##%)
		putexcel N`row' = matrix(pr`var'), nformat(#.##%)

}

* Compare to non-BW
forvalues w=1/13 {
		local row=`w'+4
		local var: word `w' of `job_vars'
		mean `var' if trans_bw60==0
		matrix m`var'= e(b)
		mean `var' if trans_bw60[_n+1]==0 & SSUID==SSUID[_n+1] & PNUM==PNUM[_n+1]
		matrix pr`var' = e(b)
		putexcel O`row' = matrix(m`var'), nformat(#.##%)
		putexcel P`row' = matrix(pr`var'), nformat(#.##%)

}

// Earnings changes

* Using earnings not tpearn which is the sum of all earnings and won't be negative
* First create a variable that indicates percent change YoY
by SSUID PNUM (year), sort: gen earn_change = ((earnings-earnings[_n-1])/earnings[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]

* Variable for all earnings in HH besides R
gen hh_earn=thearn-earnings // might need a better HH earn variable that isn't negative
by SSUID PNUM (year), sort: gen earn_change_hh = ((hh_earn-hh_earn[_n-1])/hh_earn[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]

// coding changes up and down
* Mother
gen earnup8=0
replace earnup8 = 1 if earn_change >=.08000000
replace earnup8=. if earn_change==.
gen earndown8=0
replace earndown8 = 1 if earn_change <=-.08000000
replace earndown8=. if earn_change==.


* HH excl mother
gen earnup8_hh=0
replace earnup8_hh = 1 if earn_change_hh >=.08000000
replace earnup8_hh=. if earn_change_hh==.
gen earndown8_hh=0
replace earndown8_hh = 1 if earn_change_hh <=-.08000000
replace earndown8_hh=. if earn_change_hh==.

// Raw hours changes

* First create a variable that indicates percent change YoY
by SSUID PNUM (year), sort: gen hours_change = ((avg_mo_hrs-avg_mo_hrs[_n-1])/avg_mo_hrs[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
browse SSUID PNUM year avg_mo_hrs hours_change

// coding changes up and down
* Mother
gen hours_up5=0
replace hours_up5 = 1 if hours_change >=.0500000
replace hours_up5=. if hours_change==.
gen hoursdown5=0
replace hoursdown5 = 1 if hours_change <=-.0500000
replace hoursdown5=. if hours_change==.

// Wage variables

* First create a variable that indicates percent change YoY
by SSUID PNUM (year), sort: gen wage_chg = ((avg_wk_rate-avg_wk_rate[_n-1])/avg_wk_rate[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
browse SSUID PNUM year avg_wk_rate wage_chg

// coding changes up and down
* Mother
gen wagesup8=0
replace wagesup8 = 1 if wage_chg >=.0800000
replace wagesup8=. if wage_chg==.
gen wagesdown8=0
replace wagesdown8 = 1 if wage_chg <=-.0800000
replace wagesdown8=. if wage_chg==.
// browse SSUID PNUM year avg_hrs hours_change hours_up hoursdown


* then put changes in Excel
local chg_vars "earn_change earn_change_hh hours_change wage_chg earnup8 earndown8 earnup8_hh earndown8_hh hours_up5 hoursdown5 wagesup8 wagesdown8"

local colu1 "C E G I"

* by year
forvalues w=1/12 {
	forvalues y=97/99{
		local i=`y'-95
		local row=`w'+17
		local col1: word `i' of `colu1'
		local var: word `w' of `chg_vars'
		mean `var' if trans_bw60==1 & year==19`y'
		matrix m`var'`y' = e(b)
		putexcel `col1'`row' = matrix(m`var'`y'), nformat(#.##%)
		}
}

* total
forvalues w=1/12 {
		local row=`w'+17
		local var: word `w' of `chg_vars'
		mean `var' if trans_bw60==1
		matrix m`var' = e(b)
		putexcel K`row' = matrix(m`var'), nformat(#.##%)
}

* just those with all kids at home
forvalues w=1/12 {
		local row=`w'+17
		local var: word `w' of `chg_vars'
		mean `var' if trans_bw60==1 & emomlivh==1
		matrix m`var' = e(b)
		putexcel M`row' = matrix(m`var'), nformat(#.##%)
}

* compare to non-BW
forvalues w=1/12{
		local row=`w'+17
		local var: word `w' of `chg_vars'
		mean `var' if trans_bw60==0
		matrix m`var' = e(b)
		putexcel O`row' = matrix(m`var'), nformat(#.##%)
}

// median changes instead of mean because of outliers
* then calculate changes
local chg_vars "earn_change earn_change_hh"

local colu1 "C E G I"

* by year
forvalues w=1/2 {
	forvalues y=97/99{
		local i=`y'-95
		local row=`w'+29
		local col1: word `i' of `colu1'
		local var: word `w' of `chg_vars'
		summarize `var' if trans_bw60==1 & year==19`y', detail
		matrix m`var'`y' = r(p50)
		putexcel `col1'`row' = matrix(m`var'`y'), nformat(#.##%)
		}
}

* total
forvalues w=1/2 {
		local row=`w'+29
		local var: word `w' of `chg_vars'
		summarize `var' if trans_bw60==1, detail
		matrix m`var' = r(p50)
		putexcel K`row' = matrix(m`var'), nformat(#.##%)
}


* just those with all kids at home
forvalues w=1/2 {
		local row=`w'+29
		local var: word `w' of `chg_vars'
		summarize `var' if trans_bw60==1 & emomlivh==1, detail
		matrix m`var' = r(p50)
		putexcel M`row' = matrix(m`var'), nformat(#.##%)
}

* compare to non-BW
forvalues w=1/2 {
		local row=`w'+29
		local var: word `w' of `chg_vars'
		summarize `var' if trans_bw60==0, detail
		matrix m`var' = r(p50)
		putexcel O`row' = matrix(m`var'), nformat(#.##%)
}


// Testing changes from no earnings to earnings for all (Mother, Partner, Others)

by SSUID PNUM (year), sort: gen mom_gain_earn = (earnings!=0 & earnings[_n-1]==0) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
by SSUID PNUM (year), sort: gen mom_lose_earn = (earnings==0 & earnings[_n-1]!=0) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
by SSUID PNUM (year), sort: gen hh_gain_earn = (hh_earn!=0 & hh_earn[_n-1]==0) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
by SSUID PNUM (year), sort: gen hh_lose_earn = (hh_earn==0 & hh_earn[_n-1]!=0) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
	
local earn_status_vars "mom_gain_earn mom_lose_earn hh_gain_earn hh_lose_earn"

local colu1 "C E G I"

* by year
forvalues w=1/4 {
	forvalues y=97/99{
		local i=`y'-95
		local row=`w'+31
		local col1: word `i' of `colu1'
		local var: word `w' of `earn_status_vars'
		mean `var' if trans_bw60==1 & year==19`y'
		matrix m`var'`y' = e(b)
		putexcel `col1'`row' = matrix(m`var'`y'), nformat(#.##%)
		}
}

* total
forvalues w=1/4 {
		local row=`w'+31
		local var: word `w' of `earn_status_vars'
		mean `var' if trans_bw60==1
		matrix m`var' = e(b)
		putexcel K`row' = matrix(m`var'), nformat(#.##%)
}

* just those with ALL kids at home
forvalues w=1/4 {
		local row=`w'+31
		local var: word `w' of `earn_status_vars'
		mean `var' if trans_bw60==1 & emomlivh==1
		matrix m`var' = e(b)
		putexcel M`row' = matrix(m`var'), nformat(#.##%)
}

* compare to non-BW
forvalues w=1/4 {
		local row=`w'+31
		local var: word `w' of `earn_status_vars'
		mean `var' if trans_bw60==0
		matrix m`var' = e(b)
		putexcel O`row' = matrix(m`var'), nformat(#.##%)
}

**** adding in sample sizes

local colu1 "C E G I"
local colu2 "D F H J"

forvalues y=97/99{
	local i=`y'-95
	local col1: word `i' of `colu1'
	local col2: word `i' of `colu2'
	egen total_`y' = nvals(idnum) if year==19`y'
	bysort total_`y': replace total_`y' = total_`y'[1] 
	local total_`y' = total_`y'
	display `total_`y''
	putexcel `col1'37 = `total_`y''
	egen bw_`y' = nvals(idnum) if year==19`y' & trans_bw60==1
	bysort bw_`y': replace bw_`y' = bw_`y'[1] 
	local bw_`y' = bw_`y'
	putexcel `col2'37 = `bw_`y''
}

egen total_samp = nvals(idnum)
egen bw_samp = nvals(idnum) if trans_bw60==1
local total_samp = total_samp
local bw_samp = bw_samp

putexcel K37 = `total_samp'
putexcel L37 = `bw_samp'


egen total_samp_ch = nvals(idnum) if emomlivh==1
bysort year (total_samp_ch) : replace total_samp_ch = total_samp_ch[1] // bc of missing values from sample restriction, need to copy values to all rows to get local macro to not be missing
egen bw_samp_ch = nvals(idnum) if trans_bw60==1 &  emomlivh==1
bysort idnum (bw_samp_ch) : replace bw_samp_ch = bw_samp_ch[1]
local total_samp_ch = total_samp_ch
local bw_samp_ch = bw_samp_ch

putexcel M37 = `total_samp_ch'
putexcel N37 = `bw_samp_ch'


save "$SIPP14keep/96_bw_descriptives.dta", replace