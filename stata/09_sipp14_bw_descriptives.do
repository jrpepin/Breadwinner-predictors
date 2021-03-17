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
replace nprevbw50=nprevbw50[_n-1] if PNUM==PNUM[_n-1] & SSUID==SSUID[_n-1] & year==(year[_n-1]+1) in 2/-1 
replace nprevbw50=nprevbw50+1 if bw50[_n-1]==1 & PNUM==PNUM[_n-1] & SSUID==SSUID[_n-1] & year==(year[_n-1]+1)
// browse SSUID PNUM year nprevbw50 bw50 bw50L

gen nprevbw60=0
replace nprevbw60=nprevbw60[_n-1] if PNUM==PNUM[_n-1] & SSUID==SSUID[_n-1] & year==(year[_n-1]+1) in 2/-1 
replace nprevbw60=nprevbw60+1 if bw60[_n-1]==1 & PNUM==PNUM[_n-1] & SSUID==SSUID[_n-1] & year==(year[_n-1]+1)

// for some mothers, year of first wave is not the year they appear in our sample. trying an alternate code
bysort SSUID PNUM (year): egen firstyr = min(year)

// browse SSUID PNUM year firstyr

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

gen trans_bw60_alt = trans_bw60
replace trans_bw60_alt=. if year==firstyr

// browse SSUID PNUM year firstyr nprevbw60 bw60 bw60L trans_bw60 trans_bw60_alt first_wave if inlist(SSUID, "000418500162", "000418209903", "000418334944")

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

label define race 1 "NH White" 2 "Black" 3 "NH Asian" 4 "Hispanic" 5 "Other"
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
putexcel K1:L1 = "Non-BW Comparison", merge border(bottom)
putexcel C2 = ("Year") E2 = ("Year") G2 = ("Year") I2 = ("Year") K2 = ("Year"), border(bottom)
putexcel D2 = ("Prior Year") F2 = ("Prior Year") H2 = ("Prior Year") J2 = ("Prior Year") L2 = ("Prior Year"), border(bottom)
putexcel A3:A10="Marital Status", merge vcenter
putexcel B3 = "Single -> Cohabit"
putexcel B4 = "Single -> Married"
putexcel B5 = "Cohabit -> Married"
putexcel B6 = "Cohabit -> Dissolved"
putexcel B7 = "Married -> Dissolved"
putexcel B8 = "Married -> Widowed"
putexcel B9 = "Married -> Cohabit"
putexcel B10 = "No Status Change"
putexcel A11:A22="Household Status", merge vcenter
putexcel B11 = "Member Left"
putexcel B12 = "Earner Left"
putexcel B13 = "Earner -> Non-earner"
putexcel B14 = "Member Gained"
putexcel B15 = "Earner Gained"
putexcel B16 = "Non-earner -> earner"
putexcel B17 = "R became earner"
putexcel B18 = "R became non-earner"
putexcel B19 = "Gained Pre-school aged children"
putexcel B20 = "Lost pre-school aged children"
putexcel B21 = "Gained parents"
putexcel B22 = "Lost parents"
putexcel A23:A24="Births", merge vcenter
putexcel B23 = "Subsequent Birth"
putexcel B24 = "First Birth"
putexcel A25:A51="Job Changes", merge vcenter
putexcel B25 = "Full-Time->Part-Time"
putexcel B26 = "Full-Time-> No Job"
putexcel B27 = "Part-Time-> No Job"
putexcel B28 = "Part-Time->Full-Time"
putexcel B29 = "No Job->PT"
putexcel B30 = "No Job->FT"
putexcel B31 = "No Job Change"
putexcel B32 = "Employer Change"
putexcel B33 = "Better Job"
putexcel B34 = "Job exit due to pregnancy"
putexcel B35 = "One to Many Jobs"
putexcel B36 = "Many to one job"
putexcel B37 = "Added a job"
putexcel B38 = "Lost a job"
putexcel B39 = "Spouse Full-Time->Part-Time"
putexcel B40 = "Spouse Full-Time-> No Job"
putexcel B41 = "Spouse Part-Time-> No Job"
putexcel B42 = "Spouse Part-Time->Full-Time"
putexcel B43 = "Spouse No Job->PT"
putexcel B44 = "Spouse No Job->FT"
putexcel B45 = "Spouse No Job Change"
putexcel B46 = "Spouse Employer Change"
putexcel B47 = "Spouse Better Job"
putexcel B48 = "Spouse One to Many Jobs"
putexcel B49 = "Spouse Many to one job"
putexcel B50 = "Spouse Added a job"
putexcel B51 = "Spouse Lost a job"
putexcel A52:A63="Disability", merge vcenter
putexcel B52 = "Into 'difficult to find a job'"
putexcel B53 = "Out of 'difficult fo find a job'"
putexcel B54 = "Into 'condition that limits work'"
putexcel B55 = "Out of 'condition that limits work'"
putexcel B56 = "Into 'core disability'"
putexcel B57 = "Out of 'core disability'"
putexcel B58 = "Spouse Into 'difficult to find a job'"
putexcel B59 = "Spouse Out of 'difficult fo find a job'"
putexcel B60 = "Spouse Into 'condition that limits work'"
putexcel B61 = "Spouse Out of 'condition that limits work'"
putexcel B62 = "Spouse Into 'core disability'"
putexcel B63 = "Spouse Out of 'core disability'"
putexcel A64:A65="Welfare", merge vcenter
putexcel B64 = "Into welfare"
putexcel B65 = "Out of welfare"
putexcel A66:A71="Child care", merge vcenter
putexcel B66 = "Into 'Child care prevented from working more'"
putexcel B67 = "Out of 'Child care prevented from working more'"
putexcel B68 = "Received child care assistance"
putexcel B69 = "Stopped receiving child care assistance"
putexcel B70 = "Onto a child care wait list"
putexcel B71 = "Off a child care wait list"
putexcel A72:A73="Moves", merge vcenter
putexcel B72 = "Moved for relationship"
putexcel B73 = "Moved for independence"
putexcel A74:A79="Education Changes", merge vcenter
putexcel B74 = "Gained education"
putexcel B75 = "Enrolled in school"
putexcel B76 = "Stopped being enrolled in school"
putexcel B77 = "Spouse Gained education"
putexcel B78 = "Spouse Enrolled in school"
putexcel B79 = "Spouse Stopped being enrolled in school"
putexcel A80:A91="Average Changes", merge vcenter
putexcel B80 = "R Earnings Change - Average"
putexcel B81 = "Spouse Earnings Change - Average"
putexcel B82 = "HH Earnings Change - Average"
putexcel B83 = "Other Earnings Change - Average"
putexcel B84 = "R Raw Earnings Change - Average"
putexcel B85 = "Spouse Raw Earnings Change - Average"
putexcel B86 = "HH Raw Earnings Change - Average"
putexcel B87 = "Other Raw Earnings Change - Average"
putexcel B88 = "R Hours Change - Average"
putexcel B89 = "Spouse Hours Change - Average"
putexcel B90 = "R Wages Change - Average"
putexcel B91 = "Spouse Wages Change - Average"
putexcel A92:A103="Earnings Thresholds", merge vcenter
putexcel B92 = "R Earnings Up 8%"
putexcel B93 = "R Earnings Down 8%"
putexcel B94 = "Spouse Earnings Up 8%"
putexcel B95 = "Spouse Earnings Down 8%"
putexcel B96 = "HH Earnings Up 8%"
putexcel B97 = "HH Earnings Down 8%"
putexcel B98 = "Other Earnings Up 8%"
putexcel B99 = "Other Earnings Down 8%"
putexcel B100 = "Child Earnings Up 8%"
putexcel B101 = "Child Earnings Down 8%"
putexcel B102 = "Parent Earnings Up 8%"
putexcel B103 = "Parent Earnings Down 8%"
putexcel A104:A107="Hours Thresholds", merge vcenter
putexcel B104 = "R Hours Up 5%"
putexcel B105 = "R Hours Down 5%"
putexcel B106 = "Spouse Hours Up 5%"
putexcel B107 = "Spouse Hours Down 5%"
putexcel A108:A111="Wages Changes", merge vcenter
putexcel B108 = "R Wages Up 8%"
putexcel B109 = "R Wages Down 8%"
putexcel B110 = "Spouse Wages Up 8%"
putexcel B111 = "Spouse Wages Down 8%"
putexcel A112:A123="Median Changes", merge vcenter
putexcel B112 = "R Earnings Change - Median"
putexcel B113 = "Spouse Earnings Change - Median"
putexcel B114 = "HH Earnings Change - Median"
putexcel B115 = "Other Earnings Change - Median"
putexcel B116 = "R Raw Earnings Change - Median"
putexcel B117 = "Spouse Raw Earnings Change - Median"
putexcel B118 = "HH Raw Earnings Change - Median"
putexcel B119 = "Other Raw Earnings Change - Median"
putexcel B120 = "R Hours Change - Median"
putexcel B121 = "Spouse Hours Change - Median"
putexcel B122 = "R Wages Change - Median"
putexcel B123 = "Spouse Wages Change - Median"
putexcel A124:A135="Alt Earnings Threshold", merge vcenter
putexcel B124 = "R Earnings Change - Average"
putexcel B125 = "Spouse Earnings Change - Average"
putexcel B126 = "HH Earnings Change - Average"
putexcel B127 = "Other Earnings Change - Average"
putexcel B128 = "R Earnings Up 8%"
putexcel B129 = "R Earnings Down 8%"
putexcel B130 = "Spouse Earnings Up 8%"
putexcel B131 = "Spouse Earnings Down 8%"
putexcel B132 = "HH Earnings Up 8%"
putexcel B133 = "HH Earnings Down 8%"
putexcel B134 = "HH Earnings Up 8%"
putexcel B135 = "HH Earnings Down 8%"
putexcel A136:A159="Comprehensive Status Changes", merge vcenter
putexcel B136 = "Mom Earnings up 8%"
putexcel B137 = "Mom Hours up 5%"
putexcel B138 = "Mom Wages up 8%"
putexcel B139 = "Mom Earnings up 8% - Alt"
putexcel B140 = "Mom Earnings Down 8%"
putexcel B141 = "Mom Hours down 5%"
putexcel B142 = "Mom Wages down 8%"
putexcel B143 = "Mom Earnings Down 8% - Alt"
putexcel B144 = "Partner Earnings up 8%"
putexcel B145 = "Partner Hours up 5%"
putexcel B146 = "Partner Wages up 8%"
putexcel B147 = "Partner Earnings up 8% - Alt"
putexcel B148 = "Partner Earnings Down 8%"
putexcel B149 = "Partner Hours down 5%"
putexcel B150 = "Partner Wages down 8%"
putexcel B151 = "Partner Earnings Down 8% - Alt"
putexcel B152 = "HH Earnings up 8%"
putexcel B153 = "HH Earnings up 8% - Alt"
putexcel B154 = "HH Earnings down 8%"
putexcel B155 = "HH Earnings down 8% - Alt"
putexcel B156 = "Other Earnings up 8%"
putexcel B157 = "Other Earnings up 8% - Alt"
putexcel B158 = "Other Earnings down 8%"
putexcel B159 = "Other Earnings down 8% - Alt"
putexcel A160:A167="Changes in Earner Status", merge vcenter
putexcel B160 = "R Became Earner"
putexcel B161 = "R Stopped Earning"
putexcel B162 = "Spouse Became Earner"
putexcel B163 = "Spouse Stopped Earning"
putexcel B164 = "HH Became Earner"
putexcel B165 = "HH Stopped Earning"
putexcel B166 = "Other Became Earner"
putexcel B167 = "Other Stopped Earning"
putexcel A168:A185="Relevant Overlaps", merge vcenter
putexcel B168 = "Mom Earnings Up, Partner Down"
putexcel B169 = "Mom Earnings Up, Someone else down"
putexcel B170 = "Mom Earnings Up, Child down"
putexcel B171 = "Mom Earnings Up, Parent down"
putexcel B172 = "Mom Earnings Up Only"
putexcel B173 = "Mom Earnings Unchanged, HH Down"
putexcel B174 = "Mom Earnings Unchanged, Partner Down"
putexcel B175 = "Mom Earnings Unchanged, Someone else Down"
putexcel B176 = "Mom Earnings Unchanged, Child down"
putexcel B176 = "Mom Earnings Unchanged, Parent down"
putexcel B177 = "Mom Earnings Up, Earner Left HH"
putexcel B178 = "Mom Earnings Unchanged, Earner Left HH"
putexcel B179 = "Mom Earnings Up, Relationship Ended"
putexcel B181 = "Mom Earnings Unchanged, Relationship Ended"
putexcel B182 = "Mom Earnings Up, Partner Up"
putexcel B183 = "Mom Earnings Up, Someone else Up"
putexcel B184 = "Mom Earnings Down, Partner Down"
putexcel B185 = "Mom Earnings Down, Someone else down"
putexcel B187 = "Total Sample / Just BWs"

sort SSUID PNUM year

* putexcel B156 = "First Birth - year of BW" // update above and cut this
* putexcel B157 = "First Birth - prior year BW" // update above and cut this

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

* Compare to non-BW
forvalues w=1/8 {
		local row=`w'+2
		local var: word `w' of `status_vars'
		mean `var' if trans_bw60==0
		matrix m`var'= e(b)
		mean `var' if trans_bw60[_n+1]==0 & SSUID==SSUID[_n+1] & PNUM==PNUM[_n+1]
		matrix pr`var' = e(b)
		putexcel K`row' = matrix(m`var'), nformat(#.##%)
		putexcel L`row' = matrix(pr`var'), nformat(#.##%)

}


// Household changes

	* quick recode so 1 signals any transition not number of transitions
	foreach var in hh_lose earn_lose earn_non hh_gain earn_gain non_earn resp_earn resp_non prekid_gain prekid_lose parents_gain parents_lose{
	replace `var' = 1 if `var' > 1
	}

local hh_vars "hh_lose earn_lose earn_non hh_gain earn_gain non_earn resp_earn resp_non prekid_gain prekid_lose parents_gain parents_lose birth"
local colu1 "C E G"
local colu2 "D F H"
	
* by year
forvalues w=1/13 {
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
forvalues w=1/13 {
		local row=`w'+10
		local var: word `w' of `hh_vars'
		mean `var' if trans_bw60==1
		matrix m`var'= e(b)
		mean `var' if trans_bw60[_n+1]==1 & SSUID==SSUID[_n+1] & PNUM==PNUM[_n+1]
		matrix pr`var' = e(b)
		putexcel I`row' = matrix(m`var'), nformat(#.##%)
		putexcel J`row' = matrix(pr`var'), nformat(#.##%)

}

* compare to non-BW
forvalues w=1/13 {
		local row=`w'+10
		local var: word `w' of `hh_vars'
		mean `var' if trans_bw60==0
		matrix m`var'= e(b)
		mean `var' if trans_bw60[_n+1]==0 & SSUID==SSUID[_n+1] & PNUM==PNUM[_n+1]
		matrix pr`var' = e(b)
		putexcel K`row' = matrix(m`var'), nformat(#.##%)
		putexcel L`row' = matrix(pr`var'), nformat(#.##%)

}

// firthbirth - needs own code because mother had to be a BW in year prior to having a child
local colu1 "C E G"

* by year
	forvalues y=14/16{
		local i=`y'-13
		local col1: word `i' of `colu1'
		mean firstbirth if bw60==1 & year==20`y' & bw60[_n-1]==1 & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
		matrix mfirstbirth`y' = e(b)
		putexcel `col1'24 = matrix(mfirstbirth`y'), nformat(#.##%)
		}

* total
	mean firstbirth if bw60==1 & bw60[_n-1]==1 & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	matrix mfirstbirth = e(b)
	putexcel I24 = matrix(mfirstbirth), nformat(#.##%)


// Job changes - respondent and spouse
	* Renaming for length later
	rename num_jobs_up numjobs_up
	rename num_jobs_down numjobs_down
	rename num_jobs_up_sp numjobs_up_sp
	rename num_jobs_down_sp numjobs_down_sp
	
	* quick recode so 1 signals any transition not number of transitions
	foreach var in full_part full_no part_no part_full no_part no_full no_job_chg jobchange betterjob left_preg many_jobs one_job numjobs_up numjobs_down full_part_sp full_no_sp part_no_sp part_full_sp no_part_sp no_full_sp no_job_chg_sp jobchange_sp betterjob_sp many_jobs_sp one_job_sp numjobs_up_sp numjobs_down_sp{
	replace `var' = 1 if `var' > 1
	}
	
local job_vars "full_part full_no part_no part_full no_part no_full no_job_chg jobchange betterjob left_preg many_jobs one_job numjobs_up numjobs_down full_part_sp full_no_sp part_no_sp part_full_sp no_part_sp no_full_sp no_job_chg_sp jobchange_sp betterjob_sp many_jobs_sp one_job_sp numjobs_up_sp numjobs_down_sp"
local colu1 "C E G"
local colu2 "D F H"

*by year
forvalues w=1/27 {
	forvalues y=14/16{
		local i=`y'-13
		local row=`w'+24
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
forvalues w=1/27 {
		local row=`w'+24
		local var: word `w' of `job_vars'
		mean `var' if trans_bw60==1
		matrix m`var'= e(b)
		mean `var' if trans_bw60[_n+1]==1 & SSUID==SSUID[_n+1] & PNUM==PNUM[_n+1]
		matrix pr`var' = e(b)
		putexcel I`row' = matrix(m`var'), nformat(#.##%)
		putexcel J`row' = matrix(pr`var'), nformat(#.##%)

}

* Compare to non-BW
forvalues w=1/27 {
		local row=`w'+24
		local var: word `w' of `job_vars'
		mean `var' if trans_bw60==0
		matrix m`var'= e(b)
		mean `var' if trans_bw60[_n+1]==0 & SSUID==SSUID[_n+1] & PNUM==PNUM[_n+1]
		matrix pr`var' = e(b)
		putexcel K`row' = matrix(m`var'), nformat(#.##%)
		putexcel L`row' = matrix(pr`var'), nformat(#.##%)

}

// Remaining change variables - disability, welfare, child care, and education
	* quick recode so 1 signals any transition not number of transitions
	foreach var in efindjob_in efindjob_out edisabl_in edisabl_out rdis_alt_in rdis_alt_out efindjob_in_sp edisabl_in_sp efindjob_out_sp edisabl_out_sp rdis_alt_in_sp rdis_alt_out_sp welfare_in welfare_out ch_workmore_yes ch_workmore_no childasst_yes childasst_no ch_waitlist_yes ch_waitlist_no move_relat move_indep educ_change enrolled_yes enrolled_no educ_change_sp enrolled_yes_sp enrolled_no_sp{
	replace `var' = 1 if `var' > 1
	}
	
local other_vars "efindjob_in efindjob_out edisabl_in edisabl_out rdis_alt_in rdis_alt_out efindjob_in_sp edisabl_in_sp efindjob_out_sp edisabl_out_sp rdis_alt_in_sp rdis_alt_out_sp welfare_in welfare_out ch_workmore_yes ch_workmore_no childasst_yes childasst_no ch_waitlist_yes ch_waitlist_no move_relat move_indep educ_change enrolled_yes enrolled_no educ_change_sp enrolled_yes_sp enrolled_no_sp"
local colu1 "C E G"
local colu2 "D F H"

*by year
forvalues w=1/28 {
	forvalues y=14/16{
		local i=`y'-13
		local row=`w'+51
		local col1: word `i' of `colu1'
		local col2: word `i' of `colu2'
		local var: word `w' of `other_vars'
		mean `var' if trans_bw60==1 & year==20`y'
		matrix m`var'`y' = e(b)
		mean `var' if trans_bw60[_n+1]==1 & year[_n+1]==20`y' & SSUID==SSUID[_n+1] & PNUM==PNUM[_n+1]
		matrix pr`var'`y' = e(b)
		putexcel `col1'`row' = matrix(m`var'`y'), nformat(#.##%)
		putexcel `col2'`row' = matrix(pr`var'`y'), nformat(#.##%)
		}
}

* total
forvalues w=1/28 {
		local row=`w'+51
		local var: word `w' of `other_vars'
		mean `var' if trans_bw60==1
		matrix m`var'= e(b)
		mean `var' if trans_bw60[_n+1]==1 & SSUID==SSUID[_n+1] & PNUM==PNUM[_n+1]
		matrix pr`var' = e(b)
		putexcel I`row' = matrix(m`var'), nformat(#.##%)
		putexcel J`row' = matrix(pr`var'), nformat(#.##%)

}

* Compare to non-BW
forvalues w=1/28 {
		local row=`w'+51
		local var: word `w' of `other_vars'
		mean `var' if trans_bw60==0
		matrix m`var'= e(b)
		mean `var' if trans_bw60[_n+1]==0 & SSUID==SSUID[_n+1] & PNUM==PNUM[_n+1]
		matrix pr`var' = e(b)
		putexcel K`row' = matrix(m`var'), nformat(#.##%)
		putexcel L`row' = matrix(pr`var'), nformat(#.##%)

}

// Earnings changes

* Using earnings not tpearn which is the sum of all earnings and won't be negative
* First create a variable that indicates percent change YoY
by SSUID PNUM (year), sort: gen earn_change = ((earnings-earnings[_n-1])/earnings[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
by SSUID PNUM (year), sort: gen earn_change_raw = (earnings-earnings[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]

// browse SSUID PNUM year earnings earn_change earn_change_raw

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
by SSUID PNUM (year), sort: gen earn_change_sp = ((earnings_a_sp-earnings_a_sp[_n-1])/earnings_a_sp[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
by SSUID PNUM (year), sort: gen earn_change_raw_sp = (earnings_a_sp-earnings_a_sp[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]

* Variable for all earnings in HH besides R
gen hh_earn=thearn-earnings // might need a better HH earn variable that isn't negative
by SSUID PNUM (year), sort: gen earn_change_hh = ((hh_earn-hh_earn[_n-1])/hh_earn[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
by SSUID PNUM (year), sort: gen earn_change_raw_hh = (hh_earn-hh_earn[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]

* Variable for all earnings in HH besides R + partner - eventually break this down to WHO? (like child, parent, etc)
gen other_earn=thearn-earnings-earnings_a_sp // might need a better HH earn variable that isn't negative
by SSUID PNUM (year), sort: gen earn_change_oth = ((other_earn-other_earn[_n-1])/other_earn[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
by SSUID PNUM (year), sort: gen earn_change_raw_oth = (other_earn-other_earn[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]

** QA & checks
	/* plots to determine thresholds
	histogram earn_change if earn_change < .25 & earn_change > -.25, width(.01) xlab(-.25(.01).25, labsize(tiny)) percent
	histogram earn_change_sp if earn_change_sp < .25 & earn_change_sp > -.25, width(.01) xlab(-.25(.01).25, labsize(tiny)) percent
	histogram earn_change_hh if earn_change_hh < .25 & earn_change_hh > -.25, width(.01) xlab(-.25(.01).25, labsize(tiny)) percent
	histogram earn_change if earn_change < .5 & earn_change > -.5 & trans_bw60==1, width(.01) xlab(-.5(.05).5, labsize(tiny)) percent
	histogram earn_change_sp if earn_change_sp < .5 & earn_change_sp > -.5 & trans_bw60==1, width(.01) xlab(-.5(.05).5, labsize(tiny)) percent
	histogram earn_change_hh if earn_change_hh < .5 & earn_change_hh > -.5 & trans_bw60==1, width(.01) xlab(-.5(.05).5, labsize(tiny)) percent


	histogram hours_change if hours_change < .25 & hours_change > -.25, width(.01) xlab(-.25(.01).25, labsize(tiny)) percent
	histogram hours_change_sp if hours_change_sp < .25 & hours_change_sp > -.25, width(.01) xlab(-.25(.01).25, labsize(tiny)) percent
	* histogram hours_change_hh if hours_change_hh < .25 & hours_change_hh > -.25, width(.01) xlab(-.25(.01).25, labsize(tiny)) percent // didn't create these yet
	histogram hours_change if hours_change < .5 & hours_change > -.5 & trans_bw60==1, width(.01) xlab(-.5(.05).5, labsize(tiny)) percent
	histogram hours_change_sp if hours_change_sp < .5 & hours_change_sp > -.5 & trans_bw60==1, width(.01) xlab(-.5(.05).5, labsize(tiny)) percent
	* histogram hours_change_hh if hours_change_hh < .5 & hours_change_hh > -.5 & trans_bw60==1, width(.01) xlab(-.5(.05).5, labsize(tiny)) percent // didn't create these yet

	histogram wage_chg if wage_chg < .25 & wage_chg > -.25, width(.01) xlab(-.25(.01).25, labsize(tiny)) percent
	histogram wage_chg_sp if wage_chg_sp < .25 & wage_chg_sp > -.25, width(.01) xlab(-.25(.01).25, labsize(tiny)) percent
	* histogram wage_chg_hh if wage_chg_hh < .25 & wage_chg_hh > -.25, width(.01) xlab(-.25(.01).25, labsize(tiny)) percent // didn't create these yet
	histogram wage_chg if wage_chg < .5 & wage_chg > -.5 & trans_bw60==1, width(.01) xlab(-.5(.05).5, labsize(tiny)) percent
	histogram wage_chg_sp if wage_chg_sp < .5 & wage_chg_sp > -.5 & trans_bw60==1, width(.01) xlab(-.5(.05).5, labsize(tiny)) percent
	* histogram wage_chg_hh if wage_chg_hh < .5 & wage_chg_hh > -.5 & trans_bw60==1, width(.01) xlab(-.5(.05).5, labsize(tiny)) percent // didn't create these yet
	
	log using "$logdir/change_details.log"
	sum earn_change, detail
	sum earn_change_sp, detail
	sum earn_change_hh, detail
	sum earn_change if trans_bw60==1, detail
	sum earn_change_sp if trans_bw60==1, detail
	sum earn_change_hh if trans_bw60==1, detail
	sum hours_change, detail
	sum hours_change_sp, detail
	sum hours_change if trans_bw60==1, detail
	sum hours_change_sp if trans_bw60==1, detail
	sum wage_chg, detail
	sum wage_chg_sp, detail
	sum wage_chg if trans_bw60==1, detail
	sum wage_chg_sp if trans_bw60==1, detail
	log close

	*/

	// browse SSUID PNUM year earnings earn_change if trans_bw60==1 & earn_change >1
	// browse SSUID PNUM year earnings earn_change if earn_change >10 & earn_change!=. // trying to understand big jumps in earnings

// coding changes up and down
* Mother
gen earnup8=0
replace earnup8 = 1 if earn_change >=.08000000
replace earnup8=. if earn_change==.
gen earndown8=0
replace earndown8 = 1 if earn_change <=-.08000000
replace earndown8=. if earn_change==.

// browse SSUID PNUM year tpearn earn_change earnup8 earndown8

* partner
gen earnup8_sp=0
replace earnup8_sp = 1 if earn_change_sp >=.08000000
replace earnup8_sp=. if earn_change_sp==.
gen earndown8_sp=0
replace earndown8_sp = 1 if earn_change_sp <=-.08000000
replace earndown8_sp=. if earn_change_sp==.
	

* HH excl mother
gen earnup8_hh=0
replace earnup8_hh = 1 if earn_change_hh >=.08000000
replace earnup8_hh=. if earn_change_hh==.
gen earndown8_hh=0
replace earndown8_hh = 1 if earn_change_hh <=-.08000000
replace earndown8_hh=. if earn_change_hh==.
	
* HH excl mother and partner
gen earnup8_oth=0
replace earnup8_oth = 1 if earn_change_oth >=.08000000
replace earnup8_oth=. if earn_change_oth==.
gen earndown8_oth=0
replace earndown8_oth = 1 if earn_change_oth <=-.08000000
replace earndown8_oth=. if earn_change_oth==.
	
//browse thearn tpearn earnings_sp hh_earn other_earn

// Looking at other HH member changes

* First calculate a change measure for all earnings
forvalues n=1/22{
	by SSUID PNUM (year), sort: gen to_earn_change`n' = ((to_earnings`n'-to_earnings`n'[_n-1])/to_earnings`n'[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
}

* these are currently capturing *any* change from child or parent, not a specific one (say highest earner)
gen earnup8_child=0
gen earndown8_child=0
forvalues n=1/22{
	replace earnup8_child=1 if to_earn_change`n' >=.08000000 & to_earn_change`n'!=. & relationship`n'==4
	replace earndown8_child=1 if to_earn_change`n' <=-.08000000 & to_earn_change`n'!=. & relationship`n'==4
}

gen earnup8_par=0
gen earndown8_par=0
forvalues n=1/22{
	replace earnup8_par=1 if to_earn_change`n' >=.08000000 & to_earn_change`n'!=. & relationship`n'==3
	replace earndown8_par=1 if to_earn_change`n' <=-.08000000 & to_earn_change`n'!=. & relationship`n'==3
}

browse earnup8_child earndown8_child earnup8_par earndown8_par to_earn_change* relationship*

// Raw hours changes

* First create a variable that indicates percent change YoY
by SSUID PNUM (year), sort: gen hours_change = ((avg_hrs-avg_hrs[_n-1])/avg_hrs[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
browse SSUID PNUM year avg_hrs hours_change

* then doing for partner specifically
* first get partner specific hours

	gen hours_sp=.
	forvalues n=1/22{
	replace hours_sp=avg_to_hrs`n' if spart_num==`n'
	}

	//check: browse spart_num hours_sp avg_to_hrs* 

* then create variables
by SSUID PNUM (year), sort: gen hours_change_sp = ((hours_sp-hours_sp[_n-1])/hours_sp[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]

// coding changes up and down
* Mother
gen hours_up5=0
replace hours_up5 = 1 if hours_change >=.0500000
replace hours_up5=. if hours_change==.
gen hoursdown5=0
replace hoursdown5 = 1 if hours_change <=-.0500000
replace hoursdown5=. if hours_change==.
// browse SSUID PNUM year avg_hrs hours_change hours_up hoursdown

* Partner
gen hours_up5_sp=0
replace hours_up5_sp = 1 if hours_change_sp >=.0500000
replace hours_up5_sp=. if hours_change_sp==.
gen hoursdown5_sp=0
replace hoursdown5_sp = 1 if hours_change_sp <=-.0500000
replace hoursdown5_sp=. if hours_change_sp==.

// Wage variables

* First create a variable that indicates percent change YoY - using just job 1 for now, as that's already a lot of variables
foreach var in ejb1_payhr1 tjb1_annsal1 tjb1_hourly1 tjb1_wkly1 tjb1_bwkly1 tjb1_mthly1 tjb1_smthly1 tjb1_other1 tjb1_gamt1{
by SSUID PNUM (year), sort: gen `var'_chg = ((`var'-`var'[_n-1])/`var'[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]  
}

egen wage_chg = rowmin (tjb1_annsal1_chg tjb1_hourly1_chg tjb1_wkly1_chg tjb1_bwkly1_chg tjb1_mthly1_chg tjb1_smthly1_chg tjb1_other1_chg tjb1_gamt1_chg)
browse SSUID PNUM year wage_chg tjb1_annsal1_chg tjb1_hourly1_chg tjb1_wkly1_chg tjb1_bwkly1_chg tjb1_mthly1_chg tjb1_smthly1_chg tjb1_other1_chg tjb1_gamt1_chg // need to go back to annual file and fix ejb1_payhr1 to not be a mean

* then doing for partner specifically
* first get partner specific hours

foreach var in EJB1_PAYHR1 TJB1_ANNSAL1 TJB1_HOURLY1 TJB1_WKLY1 TJB1_BWKLY1 TJB1_MTHLY1 TJB1_SMTHLY1 TJB1_OTHER1 TJB1_GAMT1{
gen `var'_sp=.
	forvalues n=1/22{
	replace `var'_sp=to_`var'`n' if spart_num==`n'
	}
}

foreach var in EJB1_PAYHR1_sp TJB1_ANNSAL1_sp TJB1_HOURLY1_sp TJB1_WKLY1_sp TJB1_BWKLY1_sp TJB1_MTHLY1_sp TJB1_SMTHLY1_sp TJB1_OTHER1_sp TJB1_GAMT1_sp{
by SSUID PNUM (year), sort: gen `var'_chg = ((`var'-`var'[_n-1])/`var'[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]  
}

egen wage_chg_sp = rowmin (EJB1_PAYHR1_sp_chg TJB1_ANNSAL1_sp_chg TJB1_HOURLY1_sp_chg TJB1_WKLY1_sp_chg TJB1_BWKLY1_sp_chg TJB1_MTHLY1_sp_chg TJB1_SMTHLY1_sp_chg TJB1_OTHER1_sp_chg TJB1_GAMT1_sp_chg)

// coding changes up and down
* Mother
gen wagesup8=0
replace wagesup8 = 1 if wage_chg >=.0800000
replace wagesup8=. if wage_chg==.
gen wagesdown8=0
replace wagesdown8 = 1 if wage_chg <=-.0800000
replace wagesdown8=. if wage_chg==.
// browse SSUID PNUM year avg_hrs hours_change hours_up hoursdown

* Partner 
gen wagesup8_sp=0
replace wagesup8_sp = 1 if wage_chg_sp >=.0800000
replace wagesup8_sp=. if wage_chg_sp==.
gen wagesdown8_sp=0
replace wagesdown8_sp = 1 if wage_chg_sp <=-.0800000
replace wagesdown8_sp=. if wage_chg_sp==.

* then put changes in Excel
local chg_vars "earn_change earn_change_sp earn_change_hh earn_change_oth earn_change_raw earn_change_raw_oth earn_change_raw_hh earn_change_raw_sp hours_change hours_change_sp wage_chg wage_chg_sp earnup8 earndown8 earnup8_sp earndown8_sp earnup8_hh earndown8_hh earnup8_oth earndown8_oth earnup8_child earndown8_child earnup8_par earndown8_par hours_up5 hoursdown5 hours_up5_sp hoursdown5_sp wagesup8 wagesdown8 wagesup8_sp wagesdown8_sp"

foreach var in `chg_vars'{
	gen `var'_m=`var'
	replace `var'=0 if `var'==. // updating so base is full sample, even if not applicable, but retaining a version of the variables with missing just in case
}

local colu1 "C E G"

* by year
forvalues w=1/32 {
	forvalues y=14/16{
		local i=`y'-13
		local row=`w'+79
		local col1: word `i' of `colu1'
		local var: word `w' of `chg_vars'
		mean `var' if trans_bw60==1 & year==20`y'
		matrix m`var'`y' = e(b)
		putexcel `col1'`row' = matrix(m`var'`y'), nformat(#.##%)
		}
}

* total
forvalues w=1/32 {
		local row=`w'+79
		local var: word `w' of `chg_vars'
		mean `var' if trans_bw60==1
		matrix m`var' = e(b)
		putexcel I`row' = matrix(m`var'), nformat(#.##%)
}

* compare to non-BW
forvalues w=1/32 {
		local row=`w'+79
		local var: word `w' of `chg_vars'
		mean `var' if trans_bw60==0
		matrix m`var' = e(b)
		putexcel K`row' = matrix(m`var'), nformat(#.##%)
}

// median changes instead of mean because of outliers - using _m variables because otherwise median is 0 across the board
* then calculate changes
local med_chg_vars "earn_change_m earn_change_sp_m earn_change_hh_m earn_change_oth_m earn_change_raw_m earn_change_raw_oth_m earn_change_raw_hh_m earn_change_raw_sp_m hours_change_m hours_change_sp_m wage_chg_m wage_chg_sp_m"

local colu1 "C E G"

* by year
forvalues w=1/12 {
	forvalues y=14/16{
		local i=`y'-13
		local row=`w'+111
		local col1: word `i' of `colu1'
		local var: word `w' of `med_chg_vars'
		summarize `var' if trans_bw60==1 & year==20`y', detail
		matrix m`var'`y' = r(p50)
		putexcel `col1'`row' = matrix(m`var'`y'), nformat(#.##%)
		}
}

* total
forvalues w=1/12 {
		local row=`w'+111
		local var: word `w' of `med_chg_vars'
		summarize `var' if trans_bw60==1, detail
		matrix m`var' = r(p50)
		putexcel I`row' = matrix(m`var'), nformat(#.##%)
}

* compare to non-BW
forvalues w=1/12 {
		local row=`w'+111
		local var: word `w' of `med_chg_vars'
		summarize `var' if trans_bw60==0, detail
		matrix m`var' = r(p50)
		putexcel K`row' = matrix(m`var'), nformat(#.##%)
}

// Testing placing a min earnings threshold to calculate changes in earnings (>$500 in a year) - the $500 is based on outliers I observed, seems like the minimum amount that will remove those outliers

* Respondent
	by SSUID PNUM (year), sort: gen earn_change_alt = ((earnings-earnings[_n-1])/earnings[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & earnings[_n-1] > 500
	gen earnup_alt8=0
	replace earnup_alt8 = 1 if earn_change_alt >=.08000000
	replace earnup_alt8=. if earn_change_alt==.
	gen earndown_alt8=0
	replace earndown_alt8 = 1 if earn_change_alt <=-.08000000
	replace earndown_alt8=. if earn_change_alt==.

*Partner
	by SSUID PNUM (year), sort: gen earn_change_alt_sp = ((earnings_a_sp-earnings_a_sp[_n-1])/earnings_a_sp[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & earnings_a_sp[_n-1] > 500
	gen earnup_alt8_sp=0
	replace earnup_alt8_sp = 1 if earn_change_alt_sp >=.08000000
	replace earnup_alt8_sp=. if earn_change_alt_sp==.
	gen earndown_alt8_sp=0
	replace earndown_alt8_sp = 1 if earn_change_alt_sp <=-.08000000
	replace earndown_alt8_sp=. if earn_change_alt_sp==.
	
* All earnings in HH besides R
	by SSUID PNUM (year), sort: gen earn_change_alt_hh = ((hh_earn-hh_earn[_n-1])/hh_earn[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & hh_earn[_n-1] > 500
	gen earnup_alt8_hh=0
	replace earnup_alt8_hh = 1 if earn_change_alt_hh >=.08000000
	replace earnup_alt8_hh=. if earn_change_alt_hh==.
	gen earndown_alt8_hh=0
	replace earndown_alt8_hh = 1 if earn_change_alt_hh <=-.08000000
	replace earndown_alt8_hh=. if earn_change_alt_hh==.
	
* All earnings in HH besides R + partner
	by SSUID PNUM (year), sort: gen earn_change_alt_oth = ((other_earn-other_earn[_n-1])/other_earn[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & other_earn[_n-1] > 500
	gen earnup_alt8_oth=0
	replace earnup_alt8_oth = 1 if earn_change_alt_oth >=.08000000
	replace earnup_alt8_oth=. if earn_change_alt_oth==.
	gen earndown_alt8_oth=0
	replace earndown_alt8_oth = 1 if earn_change_alt_oth <=-.08000000
	replace earndown_alt8_oth=. if earn_change_alt_oth==.

* then calculate changes
local alt_chg_vars "earn_change_alt earn_change_alt_sp earn_change_alt_hh earn_change_alt_oth earnup_alt8 earndown_alt8 earnup_alt8_sp earndown_alt8_sp earnup_alt8_hh earndown_alt8_hh earnup_alt8_oth earndown_alt8_oth"

foreach var in `alt_chg_vars'{
	gen `var'_m=`var'
	replace `var'=0 if `var'==.
}

local colu1 "C E G"

* by year
forvalues w=1/12 {
	forvalues y=14/16{
		local i=`y'-13
		local row=`w'+123
		local col1: word `i' of `colu1'
		local var: word `w' of `alt_chg_vars'
		mean `var' if trans_bw60==1 & year==20`y'
		matrix m`var'`y' = e(b)
		putexcel `col1'`row' = matrix(m`var'`y'), nformat(#.##%)
		}
}

* total
forvalues w=1/12 {
		local row=`w'+123
		local var: word `w' of `alt_chg_vars'
		mean `var' if trans_bw60==1
		matrix m`var' = e(b)
		putexcel I`row' = matrix(m`var'), nformat(#.##%)
}

* compare to  non-BW
forvalues w=1/12 {
		local row=`w'+123
		local var: word `w' of `alt_chg_vars'
		mean `var' if trans_bw60==0
		matrix m`var' = e(b)
		putexcel K`row' = matrix(m`var'), nformat(#.##%)
}

// Testing changes from no earnings to earnings for all (Mother, Partner, Others)

by SSUID PNUM (year), sort: gen mom_gain_earn = (earnings!=. & earnings[_n-1]==.) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
by SSUID PNUM (year), sort: gen mom_lose_earn = (earnings==. & earnings[_n-1]!=.) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
by SSUID PNUM (year), sort: gen part_gain_earn = (earnings_a_sp!=. & earnings_a_sp[_n-1]==.) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
by SSUID PNUM (year), sort: gen part_lose_earn = (earnings_a_sp==. & earnings_a_sp[_n-1]!=.) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
by SSUID PNUM (year), sort: gen hh_gain_earn = (hh_earn!=. & hh_earn[_n-1]==.) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
by SSUID PNUM (year), sort: gen hh_lose_earn = (hh_earn==. & hh_earn[_n-1]!=.) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
by SSUID PNUM (year), sort: gen oth_gain_earn = (other_earn!=. & other_earn[_n-1]==.) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] 
by SSUID PNUM (year), sort: gen oth_lose_earn = (other_earn==. & other_earn[_n-1]!=.) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]

// recoding change variables to account for both changes in earnings for those already earning as well as adding those who became earners

foreach var in earnup8 hours_up5 wagesup8 earnup_alt8{
	gen `var'_all = `var'
	replace `var'_all=1 if mom_gain_earn==1
}

foreach var in earndown8 hoursdown5 wagesdown8 earndown_alt8{
	gen `var'_all = `var'
	replace `var'_all=1 if mom_lose_earn==1
}

foreach var in earnup8_sp hours_up5_sp wagesup8_sp earnup_alt8_sp{
	gen `var'_all = `var'
	replace `var'_all=1 if part_gain_earn==1
}

foreach var in earndown8_sp hoursdown5_sp wagesdown8_sp earndown_alt8_sp{
	gen `var'_all = `var'
	replace `var'_all=1 if part_lose_earn==1
}

foreach var in earnup8_hh earnup_alt8_hh{
	gen `var'_all = `var'
	replace `var'_all=1 if hh_gain_earn==1
}

foreach var in earndown8_hh earndown_alt8_hh{
	gen `var'_all = `var'
	replace `var'_all=1 if hh_lose_earn==1
}

foreach var in earnup8_oth earnup_alt8_oth{
	gen `var'_all = `var'
	replace `var'_all=1 if oth_gain_earn==1
}

foreach var in earndown8_oth earndown_alt8_oth{
	gen `var'_all = `var'
	replace `var'_all=1 if oth_lose_earn==1
}

local all_vars "earnup8_all hours_up5_all wagesup8_all earnup_alt8_all earndown8_all hoursdown5_all wagesdown8_all earndown_alt8_all earnup8_sp_all hours_up5_sp_all wagesup8_sp_all earnup_alt8_sp_all earndown8_sp_all hoursdown5_sp_all wagesdown8_sp_all earndown_alt8_sp_all earnup8_hh_all earnup_alt8_hh_all earndown8_hh_all earndown_alt8_hh_all earnup8_oth_all earnup_alt8_oth_all earndown8_oth_all earndown_alt8_oth_all"

local colu1 "C E G"

* by year
forvalues w=1/24 {
	forvalues y=14/16{
		local i=`y'-13
		local row=`w'+135
		local col1: word `i' of `colu1'
		local var: word `w' of `all_vars'
		mean `var' if trans_bw60==1 & year==20`y'
		matrix m`var'`y' = e(b)
		putexcel `col1'`row' = matrix(m`var'`y'), nformat(#.##%)
		}
}

* total
forvalues w=1/24 {
		local row=`w'+135
		local var: word `w' of `all_vars'
		mean `var' if trans_bw60==1
		matrix m`var' = e(b)
		putexcel I`row' = matrix(m`var'), nformat(#.##%)
}

* compare to  non-BW
forvalues w=1/24 {
		local row=`w'+135
		local var: word `w' of `all_vars'
		mean `var' if trans_bw60==0
		matrix m`var' = e(b)
		putexcel K`row' = matrix(m`var'), nformat(#.##%)
}



local earn_status_vars "mom_gain_earn mom_lose_earn part_gain_earn part_lose_earn hh_gain_earn hh_lose_earn oth_gain_earn oth_lose_earn"

foreach var in `earn_status_vars'{
	gen `var'_m=`var'
	replace `var'=0 if `var'==.
}

local colu1 "C E G"

* by year
forvalues w=1/8 {
	forvalues y=14/16{
		local i=`y'-13
		local row=`w'+159
		local col1: word `i' of `colu1'
		local var: word `w' of `earn_status_vars'
		mean `var' if trans_bw60==1 & year==20`y'
		matrix m`var'`y' = e(b)
		putexcel `col1'`row' = matrix(m`var'`y'), nformat(#.##%)
		}
}

* total
forvalues w=1/8 {
		local row=`w'+159
		local var: word `w' of `earn_status_vars'
		mean `var' if trans_bw60==1
		matrix m`var' = e(b)
		putexcel I`row' = matrix(m`var'), nformat(#.##%)
}

* compare to non-BW
forvalues w=1/8 {
		local row=`w'+159
		local var: word `w' of `earn_status_vars'
		mean `var' if trans_bw60==0
		matrix m`var' = e(b)
		putexcel K`row' = matrix(m`var'), nformat(#.##%)
}


// adding some core overlap views = currently base is total sample, per meeting 3/4, want a consistent view. so, even if woman doesn't have a partner, for now that is 0 not missing

* Mother earnings up, anyone else down
gen momup_anydown=0
replace momup_anydown=1 if earnup8_all==1 & earndown8_hh_all==1
* Mother earnings up, partner earnings down
gen momup_partdown=0
replace momup_partdown=1 if earnup8_all==1 & earndown8_sp_all==1
* Mother earnings up, someone else's earnings down
gen momup_othdown=0
replace momup_othdown=1 if earnup8_all==1 & earndown8_oth_all==1 // this "oth" view is all hh earnings except mom and partner so accounts for other hh earning changes
* Mother earnings up, child's earnings down
gen momup_childdown=0
replace momup_childdown=1 if earnup8_all==1 & earndown8_child==1
* Mother earnings up, parent's earnings down
gen momup_parentdown=0
replace momup_parentdown=1 if earnup8_all==1 & earndown8_par==1
* Mother earnings up, no one else's earnings changed
gen momup_only=0
replace momup_only=1 if earnup8_all==1 & earndown8_hh_all==0 // this hh view is all hh earnings eXCEPT MOM so if 0, means no one else changed
* Mother's earnings did not change, HH's earnings down
gen momno_hhdown=0
replace momno_hhdown=1 if earnup8_all==0 & earndown8_all==0 & earndown8_hh_all==1
* Mother earnings did not change, anyone else down
gen momno_anydown=0
replace momno_anydown=1 if earnup8_all==0 & earndown8_all==0 & earndown8_hh_all==1
* Mother's earnings did not change, partner's earnings down
gen momno_partdown=0
replace momno_partdown=1 if earnup8_all==0 & earndown8_all==0 & earndown8_sp_all==1
* Mothers earnings did not change, someone else's earnings went down
gen momno_othdown=0
replace momno_othdown=1 if earnup8_all==0 & earndown8_all==0 & earndown8_oth_all==1
* Mother's earnings did not change, child's earnings down
gen momno_childdown=0
replace momno_childdown=1 if earnup8_all==0 & earndown8_all==0 & earndown8_child==1
* Mother's earnings did not change, parent's earnings down
gen momno_parentdown=0
replace momno_parentdown=1 if earnup8_all==0 & earndown8_all==0 & earndown8_par==1
* Mother earnings up, earner left household
gen momup_othleft=0
replace momup_othleft=1 if earnup8_all==1 & earn_lose==1
* Mother earnings did not change, earner left household
gen momno_othleft=0
replace momno_othleft=1 if earnup8_all==0 & earndown8_all==0 & earn_lose==1
* Mother earnings up, relationship ended
gen momup_relend=0
replace momup_relend=1 if earnup8_all==1 & (coh_diss==1 | marr_diss==1)
* Mother earnings did not change, relationship ended
gen momno_relend=0
replace momno_relend=1 if earnup8_all==0 & earndown8_all==0 & (coh_diss==1 | marr_diss==1)
* Mother earnings up, anyone else's earnings up
gen momup_anyup=0
replace momup_anyup=1 if earnup8_all==1 & earnup8_hh_all==1
* Mother earnings up, partner earnings up
gen momup_partup=0
replace momup_partup=1 if earnup8_all==1 & earnup8_sp_all==1
* Mother earnings up, someone else's earnings up
gen momup_othup=0
replace momup_othup=1 if earnup8_all==1 & earnup8_oth_all==1
* Mother earnings down, anyone else's earnings down
gen momdown_anydown=0
replace momdown_anydown=1 if earndown8_all==1 & earndown8_hh_all==1
* Mother earnings down, partner earnings down
gen momdown_partdown=0
replace momdown_partdown=1 if earndown8_all==1 & earndown8_sp_all==1
* Mother earnings down, someone else's earnings down
gen momdown_othdown=0
replace momdown_othdown=1 if earndown8_all==1 & earndown8_oth_all==1

local overlap_vars "momup_partdown momup_othdown momup_childdown momup_parentdown momup_only momno_hhdown momno_partdown momno_othdown momno_childdown momno_parentdown momup_othleft momno_othleft momup_relend momno_relend momup_partup momup_othup momdown_partdown momdown_othdown"

local colu1 "C E G"

* by year
forvalues w=1/18 {
	forvalues y=14/16{
		local i=`y'-13
		local row=`w'+167
		local col1: word `i' of `colu1'
		local var: word `w' of `overlap_vars'
		mean `var' if trans_bw60==1 & year==20`y'
		matrix m`var'`y' = e(b)
		putexcel `col1'`row' = matrix(m`var'`y'), nformat(#.##%)
		}
}

* total
forvalues w=1/18 {
		local row=`w'+167
		local var: word `w' of `overlap_vars'
		mean `var' if trans_bw60==1
		matrix m`var' = e(b)
		putexcel I`row' = matrix(m`var'), nformat(#.##%)
}

* compare to non-BW
forvalues w=1/18 {
		local row=`w'+167
		local var: word `w' of `overlap_vars'
		mean `var' if trans_bw60==0
		matrix m`var' = e(b)
		putexcel K`row' = matrix(m`var'), nformat(#.##%)
}

**** adding in sample sizes

local colu1 "C E G"
local colu2 "D F H"

forvalues y=14/16{
	local i=`y'-13
	local col1: word `i' of `colu1'
	local col2: word `i' of `colu2'
	egen total_`y' = nvals(idnum) if year==20`y'
	bysort total_`y': replace total_`y' = total_`y'[1] 
	local total_`y' = total_`y'
	display `total_`y''
	putexcel `col1'187 = `total_`y''
	egen bw_`y' = nvals(idnum) if year==20`y' & trans_bw60==1
	bysort bw_`y': replace bw_`y' = bw_`y'[1] 
	local bw_`y' = bw_`y'
	putexcel `col2'187 = `bw_`y''
}

egen total_samp = nvals(idnum)
egen bw_samp = nvals(idnum) if trans_bw60==1
local total_samp = total_samp
local bw_samp = bw_samp

putexcel I187 = `total_samp'
putexcel J187 = `bw_samp'


********************************************************************************
* Now breaking down by education
********************************************************************************
putexcel set "$results/Breadwinner_Characteristics", sheet(Education_Breakdown) modify
putexcel C1 = ("Less than HS") D1 = ("HS Degree") E1 = ("Some College") F1 = ("College Plus"), border(bottom)
putexcel C2 = ("Year") D2 = ("Year") E2 = ("Year") F2 = ("Year"), border(bottom)
putexcel A3:A10="Marital Status", merge vcenter
putexcel B3 = "Single -> Cohabit"
putexcel B4 = "Single -> Married"
putexcel B5 = "Cohabit -> Married"
putexcel B6 = "Cohabit -> Dissolved"
putexcel B7 = "Married -> Dissolved"
putexcel B8 = "Married -> Widowed"
putexcel B9 = "Married -> Cohabit"
putexcel B10 = "No Status Change"
putexcel A11:A22="Household Status", merge vcenter
putexcel B11 = "Member Left"
putexcel B12 = "Earner Left"
putexcel B13 = "Earner -> Non-earner"
putexcel B14 = "Member Gained"
putexcel B15 = "Earner Gained"
putexcel B16 = "Non-earner -> earner"
putexcel B17 = "R became earner"
putexcel B18 = "R became non-earner"
putexcel B19 = "Gained Pre-school aged children"
putexcel B20 = "Lost pre-school aged children"
putexcel B21 = "Gained parents"
putexcel B22 = "Lost parents"
putexcel A23:A24="Births", merge vcenter
putexcel B23 = "Subsequent Birth"
putexcel B24 = "First Birth"
putexcel A25:A51="Job Changes", merge vcenter
putexcel B25 = "Full-Time->Part-Time"
putexcel B26 = "Full-Time-> No Job"
putexcel B27 = "Part-Time-> No Job"
putexcel B28 = "Part-Time->Full-Time"
putexcel B29 = "No Job->PT"
putexcel B30 = "No Job->FT"
putexcel B31 = "No Job Change"
putexcel B32 = "Employer Change"
putexcel B33 = "Better Job"
putexcel B34 = "Job exit due to pregnancy"
putexcel B35 = "One to Many Jobs"
putexcel B36 = "Many to one job"
putexcel B37 = "Added a job"
putexcel B38 = "Lost a job"
putexcel B39 = "Spouse Full-Time->Part-Time"
putexcel B40 = "Spouse Full-Time-> No Job"
putexcel B41 = "Spouse Part-Time-> No Job"
putexcel B42 = "Spouse Part-Time->Full-Time"
putexcel B43 = "Spouse No Job->PT"
putexcel B44 = "Spouse No Job->FT"
putexcel B45 = "Spouse No Job Change"
putexcel B46 = "Spouse Employer Change"
putexcel B47 = "Spouse Better Job"
putexcel B48 = "Spouse One to Many Jobs"
putexcel B49 = "Spouse Many to one job"
putexcel B50 = "Spouse Added a job"
putexcel B51 = "Spouse Lost a job"
putexcel A52:A63="Disability", merge vcenter
putexcel B52 = "Into 'difficult to find a job'"
putexcel B53 = "Out of 'difficult fo find a job'"
putexcel B54 = "Into 'condition that limits work'"
putexcel B55 = "Out of 'condition that limits work'"
putexcel B56 = "Into 'core disability'"
putexcel B57 = "Out of 'core disability'"
putexcel B58 = "Spouse Into 'difficult to find a job'"
putexcel B59 = "Spouse Out of 'difficult fo find a job'"
putexcel B60 = "Spouse Into 'condition that limits work'"
putexcel B61 = "Spouse Out of 'condition that limits work'"
putexcel B62 = "Spouse Into 'core disability'"
putexcel B63 = "Spouse Out of 'core disability'"
putexcel A64:A65="Welfare", merge vcenter
putexcel B64 = "Into welfare"
putexcel B65 = "Out of welfare"
putexcel A66:A71="Child care", merge vcenter
putexcel B66 = "Into 'Child care prevented from working more'"
putexcel B67 = "Out of 'Child care prevented from working more'"
putexcel B68 = "Received child care assistance"
putexcel B69 = "Stopped receiving child care assistance"
putexcel B70 = "Onto a child care wait list"
putexcel B71 = "Off a child care wait list"
putexcel A72:A73="Moves", merge vcenter
putexcel B72 = "Moved for relationship"
putexcel B73 = "Moved for independence"
putexcel A74:A79="Education Changes", merge vcenter
putexcel B74 = "Gained education"
putexcel B75 = "Enrolled in school"
putexcel B76 = "Stopped being enrolled in school"
putexcel B77 = "Spouse Gained education"
putexcel B78 = "Spouse Enrolled in school"
putexcel B79 = "Spouse Stopped being enrolled in school"
putexcel A80:A91="Average Changes", merge vcenter
putexcel B80 = "R Earnings Change - Average"
putexcel B81 = "Spouse Earnings Change - Average"
putexcel B82 = "HH Earnings Change - Average"
putexcel B83 = "Other Earnings Change - Average"
putexcel B84 = "R Raw Earnings Change - Average"
putexcel B85 = "Spouse Raw Earnings Change - Average"
putexcel B86 = "HH Raw Earnings Change - Average"
putexcel B87 = "Other Raw Earnings Change - Average"
putexcel B88 = "R Hours Change - Average"
putexcel B89 = "Spouse Hours Change - Average"
putexcel B90 = "R Wages Change - Average"
putexcel B91 = "Spouse Wages Change - Average"
putexcel A92:A103="Earnings Thresholds", merge vcenter
putexcel B92 = "R Earnings Up 8%"
putexcel B93 = "R Earnings Down 8%"
putexcel B94 = "Spouse Earnings Up 8%"
putexcel B95 = "Spouse Earnings Down 8%"
putexcel B96 = "HH Earnings Up 8%"
putexcel B97 = "HH Earnings Down 8%"
putexcel B98 = "Other Earnings Up 8%"
putexcel B99 = "Other Earnings Down 8%"
putexcel B100 = "Child Earnings Up 8%"
putexcel B101 = "Child Earnings Down 8%"
putexcel B102 = "Parent Earnings Up 8%"
putexcel B103 = "Parent Earnings Down 8%"
putexcel A104:A107="Hours Thresholds", merge vcenter
putexcel B104 = "R Hours Up 5%"
putexcel B105 = "R Hours Down 5%"
putexcel B106 = "Spouse Hours Up 5%"
putexcel B107 = "Spouse Hours Down 5%"
putexcel A108:A111="Wages Changes", merge vcenter
putexcel B108 = "R Wages Up 8%"
putexcel B109 = "R Wages Down 8%"
putexcel B110 = "Spouse Wages Up 8%"
putexcel B111 = "Spouse Wages Down 8%"
putexcel A112:A123="Median Changes", merge vcenter
putexcel B112 = "R Earnings Change - Median"
putexcel B113 = "Spouse Earnings Change - Median"
putexcel B114 = "HH Earnings Change - Median"
putexcel B115 = "Other Earnings Change - Median"
putexcel B116 = "R Raw Earnings Change - Median"
putexcel B117 = "Spouse Raw Earnings Change - Median"
putexcel B118 = "HH Raw Earnings Change - Median"
putexcel B119 = "Other Raw Earnings Change - Median"
putexcel B120 = "R Hours Change - Median"
putexcel B121 = "Spouse Hours Change - Median"
putexcel B122 = "R Wages Change - Median"
putexcel B123 = "Spouse Wages Change - Median"
putexcel A124:A135="Alt Earnings Threshold", merge vcenter
putexcel B124 = "R Earnings Change - Average"
putexcel B125 = "Spouse Earnings Change - Average"
putexcel B126 = "HH Earnings Change - Average"
putexcel B127 = "Other Earnings Change - Average"
putexcel B128 = "R Earnings Up 8%"
putexcel B129 = "R Earnings Down 8%"
putexcel B130 = "Spouse Earnings Up 8%"
putexcel B131 = "Spouse Earnings Down 8%"
putexcel B132 = "HH Earnings Up 8%"
putexcel B133 = "HH Earnings Down 8%"
putexcel B134 = "HH Earnings Up 8%"
putexcel B135 = "HH Earnings Down 8%"
putexcel A136:A159="Comprehensive Status Changes", merge vcenter
putexcel B136 = "Mom Earnings up 8%"
putexcel B137 = "Mom Hours up 5%"
putexcel B138 = "Mom Wages up 8%"
putexcel B139 = "Mom Earnings up 8% - Alt"
putexcel B140 = "Mom Earnings Down 8%"
putexcel B141 = "Mom Hours down 5%"
putexcel B142 = "Mom Wages down 8%"
putexcel B143 = "Mom Earnings Down 8% - Alt"
putexcel B144 = "Partner Earnings up 8%"
putexcel B145 = "Partner Hours up 5%"
putexcel B146 = "Partner Wages up 8%"
putexcel B147 = "Partner Earnings up 8% - Alt"
putexcel B148 = "Partner Earnings Down 8%"
putexcel B149 = "Partner Hours down 5%"
putexcel B150 = "Partner Wages down 8%"
putexcel B151 = "Partner Earnings Down 8% - Alt"
putexcel B152 = "HH Earnings up 8%"
putexcel B153 = "HH Earnings up 8% - Alt"
putexcel B154 = "HH Earnings down 8%"
putexcel B155 = "HH Earnings down 8% - Alt"
putexcel B156 = "Other Earnings up 8%"
putexcel B157 = "Other Earnings up 8% - Alt"
putexcel B158 = "Other Earnings down 8%"
putexcel B159 = "Other Earnings down 8% - Alt"
putexcel A160:A167="Changes in Earner Status", merge vcenter
putexcel B160 = "R Became Earner"
putexcel B161 = "R Stopped Earning"
putexcel B162 = "Spouse Became Earner"
putexcel B163 = "Spouse Stopped Earning"
putexcel B164 = "HH Became Earner"
putexcel B165 = "HH Stopped Earning"
putexcel B166 = "Other Became Earner"
putexcel B167 = "Other Stopped Earning"
putexcel A168:A185="Relevant Overlaps", merge vcenter
putexcel B168 = "Mom Earnings Up, Partner Down"
putexcel B169 = "Mom Earnings Up, Someone else down"
putexcel B170 = "Mom Earnings Up, Child down"
putexcel B171 = "Mom Earnings Up, Parent down"
putexcel B172 = "Mom Earnings Up Only"
putexcel B173 = "Mom Earnings Unchanged, HH Down"
putexcel B174 = "Mom Earnings Unchanged, Partner Down"
putexcel B175 = "Mom Earnings Unchanged, Someone else Down"
putexcel B176 = "Mom Earnings Unchanged, Child down"
putexcel B176 = "Mom Earnings Unchanged, Parent down"
putexcel B177 = "Mom Earnings Up, Earner Left HH"
putexcel B178 = "Mom Earnings Unchanged, Earner Left HH"
putexcel B179 = "Mom Earnings Up, Relationship Ended"
putexcel B181 = "Mom Earnings Unchanged, Relationship Ended"
putexcel B182 = "Mom Earnings Up, Partner Up"
putexcel B183 = "Mom Earnings Up, Someone else Up"
putexcel B184 = "Mom Earnings Down, Partner Down"
putexcel B185 = "Mom Earnings Down, Someone else down"

putexcel B187 = "Total Sample"
putexcel B188 = "Breadwinners"

sort SSUID PNUM year

// Partner and HH status changes
local status_vars "sing_coh sing_mar coh_mar coh_diss marr_diss marr_wid marr_coh no_status_chg hh_lose earn_lose earn_non hh_gain earn_gain non_earn resp_earn resp_non prekid_gain prekid_lose parents_gain parents_lose birth"

local colu1 "C D E F"

forvalues w=1/21 {
	forvalues e=1/4{
		local i=`e'
		local row=`w'+2
		local col1: word `i' of `colu1'
		local var: word `w' of `status_vars'
		mean `var' if trans_bw60==1 & educ==`e'
		matrix m`var'`e' = e(b)
		putexcel `col1'`row' = matrix(m`var'`e'), nformat(#.##%)
		}
}

// firthbirth - needs own code because mother had to be a BW in year prior to having a child
local colu1 "C D E F"

	forvalues e=2/4{ // no obs for educ==1, so starting with 2
		local i=`e'
		local col1: word `i' of `colu1'
		mean firstbirth if bw60==1 & bw60[_n-1]==1 & educ==`e' & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
		matrix mfirstbirth`e' = e(b)
		putexcel `col1'24 = matrix(mfirstbirth`e'), nformat(#.##%)
		}

// no observations, is that true? there should be some bc there are at overall level
browse SSUID PNUM year firstbirth bw60 educ if mom_panel==1
tab educ firstbirth if bw60==1 & bw60[_n-1]==1 & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
tab educ firstbirth if bw60==1 & bw60[_n-1]==1 & educ>1 & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] // so it's just the less than HS that have no observations.
		
// Job changes - respondent and spouse	
local job_vars "full_part full_no part_no part_full no_part no_full no_job_chg jobchange betterjob left_preg many_jobs one_job numjobs_up numjobs_down full_part_sp full_no_sp part_no_sp part_full_sp no_part_sp no_full_sp no_job_chg_sp jobchange_sp betterjob_sp many_jobs_sp one_job_sp numjobs_up_sp numjobs_down_sp"

local colu1 "C D E F"

forvalues w=1/27 {
	forvalues e=1/4{
		local i=`e'
		local row=`w'+24
		local col1: word `i' of `colu1'
		local var: word `w' of `job_vars'
		mean `var' if trans_bw60==1 & educ==`e'
		matrix m`var'`e' = e(b)
		putexcel `col1'`row' = matrix(m`var'`e'), nformat(#.##%)
		}
}

// Remaining change variables - disability, welfare, child care, and education

local other_vars "efindjob_in efindjob_out edisabl_in edisabl_out rdis_alt_in rdis_alt_out efindjob_in_sp edisabl_in_sp efindjob_out_sp edisabl_out_sp rdis_alt_in_sp rdis_alt_out_sp welfare_in welfare_out ch_workmore_yes ch_workmore_no childasst_yes childasst_no ch_waitlist_yes ch_waitlist_no move_relat move_indep educ_change enrolled_yes enrolled_no educ_change_sp enrolled_yes_sp enrolled_no_sp"

local colu1 "C D E F"

forvalues w=1/28 {
	forvalues e=1/4{
		local i=`e'
		local row=`w'+51
		local col1: word `i' of `colu1'
		local var: word `w' of `other_vars'
		mean `var' if trans_bw60==1 & educ==`e'
		matrix m`var'`e' = e(b)
		putexcel `col1'`row' = matrix(m`var'`e'), nformat(#.##%)
		}
}

// Earnings, hours, and wage changes

local chg_vars "earn_change earn_change_sp earn_change_hh earn_change_oth earn_change_raw earn_change_raw_oth earn_change_raw_hh earn_change_raw_sp hours_change hours_change_sp wage_chg wage_chg_sp earnup8 earndown8 earnup8_sp earndown8_sp earnup8_hh earndown8_hh earnup8_oth earndown8_oth earnup8_child earndown8_child earnup8_par earndown8_par hours_up5 hoursdown5 hours_up5_sp hoursdown5_sp wagesup8 wagesdown8 wagesup8_sp wagesdown8_sp"

local colu1 "C D E F"

forvalues w=1/32{
	forvalues e=1/4{
		local i=`e'
		local row=`w'+79
		local col1: word `i' of `colu1'
		local var: word `w' of `chg_vars'
		mean `var' if trans_bw60==1 & educ==`e'
		matrix m`var'`e' = e(b)
		putexcel `col1'`row' = matrix(m`var'`e'), nformat(#.##%)
		}
}

// median changes instead of mean because of outliers

local med_chg_vars "earn_change_m earn_change_sp_m earn_change_hh_m earn_change_oth_m earn_change_raw_m earn_change_raw_oth_m earn_change_raw_hh_m earn_change_raw_sp_m hours_change_m hours_change_sp_m wage_chg_m wage_chg_sp_m"

local colu1 "C D E F"

forvalues w=1/12{
	forvalues e=1/4{
		local i=`e'
		local row=`w'+111
		local col1: word `i' of `colu1'
		local var: word `w' of `med_chg_vars'
		summarize `var' if trans_bw60==1 & educ==`e', detail
		matrix m`var'`e' = r(p50)
		putexcel `col1'`row' = matrix(m`var'`e'), nformat(#.##%)
		}
}

// Testing placing a min earnings threshold to calculate changes in earnings (>$500 in a year)




// Testing placing a min earnings threshold to calculate changes in earnings (>$500 in a year)
local alt_chg_vars "earn_change_alt earn_change_alt_sp earn_change_alt_hh earn_change_alt_oth earnup_alt8 earndown_alt8 earnup_alt8_sp earndown_alt8_sp earnup_alt8_hh earndown_alt8_hh earnup_alt8_oth earndown_alt8_oth"

local colu1 "C D E F"

forvalues w=1/12 {
	forvalues e=1/4{
		local i=`e'
		local row=`w'+123
		local col1: word `i' of `colu1'
		local var: word `w' of `alt_chg_vars'
		mean `var' if trans_bw60==1  & educ==`e'
		matrix m`var'`e' = e(b)
		putexcel `col1'`row' = matrix(m`var'`e'), nformat(#.##%)
		}
}


local all_vars "earnup8_all hours_up5_all wagesup8_all earnup_alt8_all earndown8_all hoursdown5_all wagesdown8_all earndown_alt8_all earnup8_sp_all hours_up5_sp_all wagesup8_sp_all earnup_alt8_sp_all earndown8_sp_all hoursdown5_sp_all wagesdown8_sp_all earndown_alt8_sp_all earnup8_hh_all earnup_alt8_hh_all earndown8_hh_all earndown_alt8_hh_all earnup8_oth_all earnup_alt8_oth_all earndown8_oth_all earndown_alt8_oth_all"

local colu1 "C D E F"

forvalues w=1/24 {
	forvalues e=1/4{
		local i=`e'
		local row=`w'+135
		local col1: word `i' of `colu1'
		local var: word `w' of `all_vars'
		mean `var' if trans_bw60==1  & educ==`e'
		matrix m`var'`e' = e(b)
		putexcel `col1'`row' = matrix(m`var'`e'), nformat(#.##%)
		}
}


// Testing changes from no earnings to earnings for all (Mother, Partner, Others)

local earn_status_vars "mom_gain_earn mom_lose_earn part_gain_earn part_lose_earn hh_gain_earn hh_lose_earn oth_gain_earn oth_lose_earn"

local colu1 "C D E F"

forvalues w=1/8 {
	forvalues e=1/4{
		local i=`e'
		local row=`w'+159
		local col1: word `i' of `colu1'
		local var: word `w' of `earn_status_vars'
		mean `var' if trans_bw60==1 & educ==`e'
		matrix m`var'`e' = e(b)
		putexcel `col1'`row' = matrix(m`var'`e'), nformat(#.##%)
		}
}

// relevant overlap vars

local overlap_vars "momup_partdown momup_othdown momup_childdown momup_parentdown momup_only momno_hhdown momno_partdown momno_othdown momno_childdown momno_parentdown momup_othleft momno_othleft momup_relend momno_relend momup_partup momup_othup momdown_partdown momdown_othdown"

local colu1 "C D E F"

* by year
forvalues w=1/18 {
	forvalues e=1/4{
		local i=`e'
		local row=`w'+167
		local col1: word `i' of `colu1'
		local var: word `w' of `overlap_vars'
		mean `var' if trans_bw60==1 & educ==`e'
		matrix m`var'`e' = e(b)
		putexcel `col1'`row' = matrix(m`var'`e'), nformat(#.##%)
		}
}


**** adding in sample sizes

local colu1 "C D E F"


forvalues e=1/4{
	local i=`e'
	local col1: word `i' of `colu1'
	egen total_`e' = nvals(idnum) if educ==`e'
	bysort total_`e': replace total_`e' = total_`e'[1] 
	local total_`e' = total_`e'
	egen bw_`e' = nvals(idnum) if educ==`e' & trans_bw60==1
	bysort bw_`e': replace bw_`e' = bw_`e'[1] 
	local bw_`e' = bw_`e'
	putexcel `col1'187 = `total_`e''
	putexcel `col1'188 = `bw_`e''
	}

	
********************************************************************************
* Now breaking down by race / ethnicity
********************************************************************************
putexcel set "$results/Breadwinner_Characteristics", sheet(Race_Breakdown) modify
putexcel C1 = ("NH White") D1 = ("Black") E1 = ("NH Asian") F1 = ("Hispanic"), border(bottom)
putexcel C2 = ("Year") D2 = ("Year") E2 = ("Year") F2 = ("Year"), border(bottom)
putexcel A3:A10="Marital Status", merge vcenter
putexcel B3 = "Single -> Cohabit"
putexcel B4 = "Single -> Married"
putexcel B5 = "Cohabit -> Married"
putexcel B6 = "Cohabit -> Dissolved"
putexcel B7 = "Married -> Dissolved"
putexcel B8 = "Married -> Widowed"
putexcel B9 = "Married -> Cohabit"
putexcel B10 = "No Status Change"
putexcel A11:A22="Household Status", merge vcenter
putexcel B11 = "Member Left"
putexcel B12 = "Earner Left"
putexcel B13 = "Earner -> Non-earner"
putexcel B14 = "Member Gained"
putexcel B15 = "Earner Gained"
putexcel B16 = "Non-earner -> earner"
putexcel B17 = "R became earner"
putexcel B18 = "R became non-earner"
putexcel B19 = "Gained Pre-school aged children"
putexcel B20 = "Lost pre-school aged children"
putexcel B21 = "Gained parents"
putexcel B22 = "Lost parents"
putexcel A23:A24="Births", merge vcenter
putexcel B23 = "Subsequent Birth"
putexcel B24 = "First Birth"
putexcel A25:A51="Job Changes", merge vcenter
putexcel B25 = "Full-Time->Part-Time"
putexcel B26 = "Full-Time-> No Job"
putexcel B27 = "Part-Time-> No Job"
putexcel B28 = "Part-Time->Full-Time"
putexcel B29 = "No Job->PT"
putexcel B30 = "No Job->FT"
putexcel B31 = "No Job Change"
putexcel B32 = "Employer Change"
putexcel B33 = "Better Job"
putexcel B34 = "Job exit due to pregnancy"
putexcel B35 = "One to Many Jobs"
putexcel B36 = "Many to one job"
putexcel B37 = "Added a job"
putexcel B38 = "Lost a job"
putexcel B39 = "Spouse Full-Time->Part-Time"
putexcel B40 = "Spouse Full-Time-> No Job"
putexcel B41 = "Spouse Part-Time-> No Job"
putexcel B42 = "Spouse Part-Time->Full-Time"
putexcel B43 = "Spouse No Job->PT"
putexcel B44 = "Spouse No Job->FT"
putexcel B45 = "Spouse No Job Change"
putexcel B46 = "Spouse Employer Change"
putexcel B47 = "Spouse Better Job"
putexcel B48 = "Spouse One to Many Jobs"
putexcel B49 = "Spouse Many to one job"
putexcel B50 = "Spouse Added a job"
putexcel B51 = "Spouse Lost a job"
putexcel A52:A63="Disability", merge vcenter
putexcel B52 = "Into 'difficult to find a job'"
putexcel B53 = "Out of 'difficult fo find a job'"
putexcel B54 = "Into 'condition that limits work'"
putexcel B55 = "Out of 'condition that limits work'"
putexcel B56 = "Into 'core disability'"
putexcel B57 = "Out of 'core disability'"
putexcel B58 = "Spouse Into 'difficult to find a job'"
putexcel B59 = "Spouse Out of 'difficult fo find a job'"
putexcel B60 = "Spouse Into 'condition that limits work'"
putexcel B61 = "Spouse Out of 'condition that limits work'"
putexcel B62 = "Spouse Into 'core disability'"
putexcel B63 = "Spouse Out of 'core disability'"
putexcel A64:A65="Welfare", merge vcenter
putexcel B64 = "Into welfare"
putexcel B65 = "Out of welfare"
putexcel A66:A71="Child care", merge vcenter
putexcel B66 = "Into 'Child care prevented from working more'"
putexcel B67 = "Out of 'Child care prevented from working more'"
putexcel B68 = "Received child care assistance"
putexcel B69 = "Stopped receiving child care assistance"
putexcel B70 = "Onto a child care wait list"
putexcel B71 = "Off a child care wait list"
putexcel A72:A73="Moves", merge vcenter
putexcel B72 = "Moved for relationship"
putexcel B73 = "Moved for independence"
putexcel A74:A79="Education Changes", merge vcenter
putexcel B74 = "Gained education"
putexcel B75 = "Enrolled in school"
putexcel B76 = "Stopped being enrolled in school"
putexcel B77 = "Spouse Gained education"
putexcel B78 = "Spouse Enrolled in school"
putexcel B79 = "Spouse Stopped being enrolled in school"
putexcel A80:A91="Average Changes", merge vcenter
putexcel B80 = "R Earnings Change - Average"
putexcel B81 = "Spouse Earnings Change - Average"
putexcel B82 = "HH Earnings Change - Average"
putexcel B83 = "Other Earnings Change - Average"
putexcel B84 = "R Raw Earnings Change - Average"
putexcel B85 = "Spouse Raw Earnings Change - Average"
putexcel B86 = "HH Raw Earnings Change - Average"
putexcel B87 = "Other Raw Earnings Change - Average"
putexcel B88 = "R Hours Change - Average"
putexcel B89 = "Spouse Hours Change - Average"
putexcel B90 = "R Wages Change - Average"
putexcel B91 = "Spouse Wages Change - Average"
putexcel A92:A103="Earnings Thresholds", merge vcenter
putexcel B92 = "R Earnings Up 8%"
putexcel B93 = "R Earnings Down 8%"
putexcel B94 = "Spouse Earnings Up 8%"
putexcel B95 = "Spouse Earnings Down 8%"
putexcel B96 = "HH Earnings Up 8%"
putexcel B97 = "HH Earnings Down 8%"
putexcel B98 = "Other Earnings Up 8%"
putexcel B99 = "Other Earnings Down 8%"
putexcel B100 = "Child Earnings Up 8%"
putexcel B101 = "Child Earnings Down 8%"
putexcel B102 = "Parent Earnings Up 8%"
putexcel B103 = "Parent Earnings Down 8%"
putexcel A104:A107="Hours Thresholds", merge vcenter
putexcel B104 = "R Hours Up 5%"
putexcel B105 = "R Hours Down 5%"
putexcel B106 = "Spouse Hours Up 5%"
putexcel B107 = "Spouse Hours Down 5%"
putexcel A108:A111="Wages Changes", merge vcenter
putexcel B108 = "R Wages Up 8%"
putexcel B109 = "R Wages Down 8%"
putexcel B110 = "Spouse Wages Up 8%"
putexcel B111 = "Spouse Wages Down 8%"
putexcel A112:A123="Median Changes", merge vcenter
putexcel B112 = "R Earnings Change - Median"
putexcel B113 = "Spouse Earnings Change - Median"
putexcel B114 = "HH Earnings Change - Median"
putexcel B115 = "Other Earnings Change - Median"
putexcel B116 = "R Raw Earnings Change - Median"
putexcel B117 = "Spouse Raw Earnings Change - Median"
putexcel B118 = "HH Raw Earnings Change - Median"
putexcel B119 = "Other Raw Earnings Change - Median"
putexcel B120 = "R Hours Change - Median"
putexcel B121 = "Spouse Hours Change - Median"
putexcel B122 = "R Wages Change - Median"
putexcel B123 = "Spouse Wages Change - Median"
putexcel A124:A135="Alt Earnings Threshold", merge vcenter
putexcel B124 = "R Earnings Change - Average"
putexcel B125 = "Spouse Earnings Change - Average"
putexcel B126 = "HH Earnings Change - Average"
putexcel B127 = "Other Earnings Change - Average"
putexcel B128 = "R Earnings Up 8%"
putexcel B129 = "R Earnings Down 8%"
putexcel B130 = "Spouse Earnings Up 8%"
putexcel B131 = "Spouse Earnings Down 8%"
putexcel B132 = "HH Earnings Up 8%"
putexcel B133 = "HH Earnings Down 8%"
putexcel B134 = "HH Earnings Up 8%"
putexcel B135 = "HH Earnings Down 8%"
putexcel A136:A159="Comprehensive Status Changes", merge vcenter
putexcel B136 = "Mom Earnings up 8%"
putexcel B137 = "Mom Hours up 5%"
putexcel B138 = "Mom Wages up 8%"
putexcel B139 = "Mom Earnings up 8% - Alt"
putexcel B140 = "Mom Earnings Down 8%"
putexcel B141 = "Mom Hours down 5%"
putexcel B142 = "Mom Wages down 8%"
putexcel B143 = "Mom Earnings Down 8% - Alt"
putexcel B144 = "Partner Earnings up 8%"
putexcel B145 = "Partner Hours up 5%"
putexcel B146 = "Partner Wages up 8%"
putexcel B147 = "Partner Earnings up 8% - Alt"
putexcel B148 = "Partner Earnings Down 8%"
putexcel B149 = "Partner Hours down 5%"
putexcel B150 = "Partner Wages down 8%"
putexcel B151 = "Partner Earnings Down 8% - Alt"
putexcel B152 = "HH Earnings up 8%"
putexcel B153 = "HH Earnings up 8% - Alt"
putexcel B154 = "HH Earnings down 8%"
putexcel B155 = "HH Earnings down 8% - Alt"
putexcel B156 = "Other Earnings up 8%"
putexcel B157 = "Other Earnings up 8% - Alt"
putexcel B158 = "Other Earnings down 8%"
putexcel B159 = "Other Earnings down 8% - Alt"
putexcel A160:A167="Changes in Earner Status", merge vcenter
putexcel B160 = "R Became Earner"
putexcel B161 = "R Stopped Earning"
putexcel B162 = "Spouse Became Earner"
putexcel B163 = "Spouse Stopped Earning"
putexcel B164 = "HH Became Earner"
putexcel B165 = "HH Stopped Earning"
putexcel B166 = "Other Became Earner"
putexcel B167 = "Other Stopped Earning"
putexcel A168:A185="Relevant Overlaps", merge vcenter
putexcel B168 = "Mom Earnings Up, Partner Down"
putexcel B169 = "Mom Earnings Up, Someone else down"
putexcel B170 = "Mom Earnings Up, Child down"
putexcel B171 = "Mom Earnings Up, Parent down"
putexcel B172 = "Mom Earnings Up Only"
putexcel B173 = "Mom Earnings Unchanged, HH Down"
putexcel B174 = "Mom Earnings Unchanged, Partner Down"
putexcel B175 = "Mom Earnings Unchanged, Someone else Down"
putexcel B176 = "Mom Earnings Unchanged, Child down"
putexcel B176 = "Mom Earnings Unchanged, Parent down"
putexcel B177 = "Mom Earnings Up, Earner Left HH"
putexcel B178 = "Mom Earnings Unchanged, Earner Left HH"
putexcel B179 = "Mom Earnings Up, Relationship Ended"
putexcel B181 = "Mom Earnings Unchanged, Relationship Ended"
putexcel B182 = "Mom Earnings Up, Partner Up"
putexcel B183 = "Mom Earnings Up, Someone else Up"
putexcel B184 = "Mom Earnings Down, Partner Down"
putexcel B185 = "Mom Earnings Down, Someone else down"

putexcel B187 = "Total Sample"
putexcel B188 = "Breadwinners"

sort SSUID PNUM year

// Partner and HH status changes
local status_vars "sing_coh sing_mar coh_mar coh_diss marr_diss marr_wid marr_coh no_status_chg hh_lose earn_lose earn_non hh_gain earn_gain non_earn resp_earn resp_non prekid_gain prekid_lose parents_gain parents_lose birth"

local colu1 "C D E F"

forvalues w=1/21 {
	forvalues r=1/4{
		local i=`r'
		local row=`w'+2
		local col1: word `i' of `colu1'
		local var: word `w' of `status_vars'
		mean `var' if trans_bw60==1 & race==`r'
		matrix m`var'`r' = e(b)
		putexcel `col1'`row' = matrix(m`var'`r'), nformat(#.##%)
		}
}

// firthbirth - needs own code because mother had to be a BW in year prior to having a child
local colu1 "C D E F"

	forvalues r=1/4{
		local i=`r'
		local col1: word `i' of `colu1'
		mean firstbirth if bw60==1 & bw60[_n-1]==1 & race==`r' & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
		matrix mfirstbirth`r' = e(b)
		putexcel `col1'24 = matrix(mfirstbirth`r'), nformat(#.##%)
		}


// Job changes - respondent and spouse	
local job_vars "full_part full_no part_no part_full no_part no_full no_job_chg jobchange betterjob left_preg many_jobs one_job numjobs_up numjobs_down full_part_sp full_no_sp part_no_sp part_full_sp no_part_sp no_full_sp no_job_chg_sp jobchange_sp betterjob_sp many_jobs_sp one_job_sp numjobs_up_sp numjobs_down_sp"

local colu1 "C D E F"

forvalues w=1/27 {
	forvalues r=1/4{
		local i=`r'
		local row=`w'+24
		local col1: word `i' of `colu1'
		local var: word `w' of `job_vars'
		mean `var' if trans_bw60==1 & race==`r'
		matrix m`var'`r' = e(b)
		putexcel `col1'`row' = matrix(m`var'`r'), nformat(#.##%)
		}
}

// Remaining change variables - disability, welfare, child care, and education

local other_vars "efindjob_in efindjob_out edisabl_in edisabl_out rdis_alt_in rdis_alt_out efindjob_in_sp edisabl_in_sp efindjob_out_sp edisabl_out_sp rdis_alt_in_sp rdis_alt_out_sp welfare_in welfare_out ch_workmore_yes ch_workmore_no childasst_yes childasst_no ch_waitlist_yes ch_waitlist_no move_relat move_indep educ_change enrolled_yes enrolled_no educ_change_sp enrolled_yes_sp enrolled_no_sp"

local colu1 "C D E F"

forvalues w=1/28 {
	forvalues r=1/4{
		local i=`r'
		local row=`w'+51
		local col1: word `i' of `colu1'
		local var: word `w' of `other_vars'
		mean `var' if trans_bw60==1 & race==`r'
		matrix m`var'`r' = e(b)
		putexcel `col1'`row' = matrix(m`var'`r'), nformat(#.##%)
		}
}

// Earnings, hours, and wage changes

local chg_vars "earn_change earn_change_sp earn_change_hh earn_change_oth earn_change_raw earn_change_raw_oth earn_change_raw_hh earn_change_raw_sp hours_change hours_change_sp wage_chg wage_chg_sp earnup8 earndown8 earnup8_sp earndown8_sp earnup8_hh earndown8_hh earnup8_oth earndown8_oth earnup8_child earndown8_child earnup8_par earndown8_par hours_up5 hoursdown5 hours_up5_sp hoursdown5_sp wagesup8 wagesdown8 wagesup8_sp wagesdown8_sp"

local colu1 "C D E F"

forvalues w=1/32{
	forvalues r=1/4{
		local i=`r'
		local row=`w'+79
		local col1: word `i' of `colu1'
		local var: word `w' of `chg_vars'
		mean `var' if trans_bw60==1 & race==`r'
		matrix m`var'`r' = e(b)
		putexcel `col1'`row' = matrix(m`var'`r'), nformat(#.##%)
		}
}

// median changes instead of mean because of outliers

local med_chg_vars "earn_change_m earn_change_sp_m earn_change_hh_m earn_change_oth_m earn_change_raw_m earn_change_raw_oth_m earn_change_raw_hh_m earn_change_raw_sp_m hours_change_m hours_change_sp_m wage_chg_m wage_chg_sp_m"

local colu1 "C D E F"

forvalues w=1/12{
	forvalues r=1/4{
		local i=`r'
		local row=`w'+111
		local col1: word `i' of `colu1'
		local var: word `w' of `med_chg_vars'
		summarize `var' if trans_bw60==1 & race==`r', detail
		matrix m`var'`r' = r(p50)
		putexcel `col1'`row' = matrix(m`var'`r'), nformat(#.##%)
		}
}

// Testing placing a min earnings threshold to calculate changes in earnings (>$500 in a year)




// Testing placing a min earnings threshold to calculate changes in earnings (>$500 in a year)
local alt_chg_vars "earn_change_alt earn_change_alt_sp earn_change_alt_hh earn_change_alt_oth earnup_alt8 earndown_alt8 earnup_alt8_sp earndown_alt8_sp earnup_alt8_hh earndown_alt8_hh earnup_alt8_oth earndown_alt8_oth"

local colu1 "C D E F"

forvalues w=1/12 {
	forvalues r=1/4{
		local i=`r'
		local row=`w'+123
		local col1: word `i' of `colu1'
		local var: word `w' of `alt_chg_vars'
		mean `var' if trans_bw60==1  & race==`r'
		matrix m`var'`r' = e(b)
		putexcel `col1'`row' = matrix(m`var'`r'), nformat(#.##%)
		}
}


local all_vars "earnup8_all hours_up5_all wagesup8_all earnup_alt8_all earndown8_all hoursdown5_all wagesdown8_all earndown_alt8_all earnup8_sp_all hours_up5_sp_all wagesup8_sp_all earnup_alt8_sp_all earndown8_sp_all hoursdown5_sp_all wagesdown8_sp_all earndown_alt8_sp_all earnup8_hh_all earnup_alt8_hh_all earndown8_hh_all earndown_alt8_hh_all earnup8_oth_all earnup_alt8_oth_all earndown8_oth_all earndown_alt8_oth_all"

local colu1 "C D E F"

forvalues w=1/24 {
	forvalues r=1/4{
		local i=`r'
		local row=`w'+135
		local col1: word `i' of `colu1'
		local var: word `w' of `all_vars'
		mean `var' if trans_bw60==1  & race==`r'
		matrix m`var'`r' = e(b)
		putexcel `col1'`row' = matrix(m`var'`r'), nformat(#.##%)
		}
}


// Testing changes from no earnings to earnings for all (Mother, Partner, Others)

local earn_status_vars "mom_gain_earn mom_lose_earn part_gain_earn part_lose_earn hh_gain_earn hh_lose_earn oth_gain_earn oth_lose_earn"

local colu1 "C D E F"

forvalues w=1/8 {
	forvalues r=1/4{
		local i=`r'
		local row=`w'+159
		local col1: word `i' of `colu1'
		local var: word `w' of `earn_status_vars'
		mean `var' if trans_bw60==1 & race==`r'
		matrix m`var'`r' = e(b)
		putexcel `col1'`row' = matrix(m`var'`r'), nformat(#.##%)
		}
}

// relevant overlap vars

local overlap_vars "momup_partdown momup_othdown momup_childdown momup_parentdown momup_only momno_hhdown momno_partdown momno_othdown momno_childdown momno_parentdown momup_othleft momno_othleft momup_relend momno_relend momup_partup momup_othup momdown_partdown momdown_othdown"

local colu1 "C D E F"

* by year
forvalues w=1/18 {
	forvalues r=1/4{
		local i=`r'
		local row=`w'+167
		local col1: word `i' of `colu1'
		local var: word `w' of `overlap_vars'
		mean `var' if trans_bw60==1 & race==`r'
		matrix m`var'`r' = e(b)
		putexcel `col1'`row' = matrix(m`var'`r'), nformat(#.##%)
		}
}


**** adding in sample sizes

local colu1 "C D E F"


forvalues r=1/4{
	local i=`r'
	local col1: word `i' of `colu1'
	egen total_r`r' = nvals(idnum) if race==`r'
	bysort total_r`r': replace total_r`r' = total_r`r'[1] 
	local total_r`r' = total_r`r'
	egen bw_r`r' = nvals(idnum) if race==`r' & trans_bw60==1
	bysort bw_r`r': replace bw_r`r' = bw_r`r'[1] 
	local bw_r`r' = bw_r`r'
	putexcel `col1'187 = `total_r`r''
	putexcel `col1'188 = `bw_r`r''
	}

********************************************************************************
* Now breaking down by age at first birth
********************************************************************************
// first make a categorical variable

recode ageb1 (1/18=1) (19/21=2) (22/25=3) (26/29=4) (30/50=5), gen(ageb1_gp)
label define ageb1_gp 1 "Under 18" 2 "A19-21" 3 "A22-25" 4 "A26-29" 5 "Over 30"
label values ageb1_gp ageb1_gp

putexcel set "$results/Breadwinner_Characteristics", sheet(Age_Birth_Breakdown) modify
putexcel C1 = ("Under 18") D1 = ("A19-21") E1 = ("A22-25") F1 = ("A26-29") G1 = ("Over 30"), border(bottom)
putexcel C2 = ("Year") D2 = ("Year") E2 = ("Year") F2 = ("Year") G2 = ("Year"), border(bottom)
putexcel A3:A10="Marital Status", merge vcenter
putexcel B3 = "Single -> Cohabit"
putexcel B4 = "Single -> Married"
putexcel B5 = "Cohabit -> Married"
putexcel B6 = "Cohabit -> Dissolved"
putexcel B7 = "Married -> Dissolved"
putexcel B8 = "Married -> Widowed"
putexcel B9 = "Married -> Cohabit"
putexcel B10 = "No Status Change"
putexcel A11:A22="Household Status", merge vcenter
putexcel B11 = "Member Left"
putexcel B12 = "Earner Left"
putexcel B13 = "Earner -> Non-earner"
putexcel B14 = "Member Gained"
putexcel B15 = "Earner Gained"
putexcel B16 = "Non-earner -> earner"
putexcel B17 = "R became earner"
putexcel B18 = "R became non-earner"
putexcel B19 = "Gained Pre-school aged children"
putexcel B20 = "Lost pre-school aged children"
putexcel B21 = "Gained parents"
putexcel B22 = "Lost parents"
putexcel A23:A24="Births", merge vcenter
putexcel B23 = "Subsequent Birth"
putexcel B24 = "First Birth"
putexcel A25:A51="Job Changes", merge vcenter
putexcel B25 = "Full-Time->Part-Time"
putexcel B26 = "Full-Time-> No Job"
putexcel B27 = "Part-Time-> No Job"
putexcel B28 = "Part-Time->Full-Time"
putexcel B29 = "No Job->PT"
putexcel B30 = "No Job->FT"
putexcel B31 = "No Job Change"
putexcel B32 = "Employer Change"
putexcel B33 = "Better Job"
putexcel B34 = "Job exit due to pregnancy"
putexcel B35 = "One to Many Jobs"
putexcel B36 = "Many to one job"
putexcel B37 = "Added a job"
putexcel B38 = "Lost a job"
putexcel B39 = "Spouse Full-Time->Part-Time"
putexcel B40 = "Spouse Full-Time-> No Job"
putexcel B41 = "Spouse Part-Time-> No Job"
putexcel B42 = "Spouse Part-Time->Full-Time"
putexcel B43 = "Spouse No Job->PT"
putexcel B44 = "Spouse No Job->FT"
putexcel B45 = "Spouse No Job Change"
putexcel B46 = "Spouse Employer Change"
putexcel B47 = "Spouse Better Job"
putexcel B48 = "Spouse One to Many Jobs"
putexcel B49 = "Spouse Many to one job"
putexcel B50 = "Spouse Added a job"
putexcel B51 = "Spouse Lost a job"
putexcel A52:A63="Disability", merge vcenter
putexcel B52 = "Into 'difficult to find a job'"
putexcel B53 = "Out of 'difficult fo find a job'"
putexcel B54 = "Into 'condition that limits work'"
putexcel B55 = "Out of 'condition that limits work'"
putexcel B56 = "Into 'core disability'"
putexcel B57 = "Out of 'core disability'"
putexcel B58 = "Spouse Into 'difficult to find a job'"
putexcel B59 = "Spouse Out of 'difficult fo find a job'"
putexcel B60 = "Spouse Into 'condition that limits work'"
putexcel B61 = "Spouse Out of 'condition that limits work'"
putexcel B62 = "Spouse Into 'core disability'"
putexcel B63 = "Spouse Out of 'core disability'"
putexcel A64:A65="Welfare", merge vcenter
putexcel B64 = "Into welfare"
putexcel B65 = "Out of welfare"
putexcel A66:A71="Child care", merge vcenter
putexcel B66 = "Into 'Child care prevented from working more'"
putexcel B67 = "Out of 'Child care prevented from working more'"
putexcel B68 = "Received child care assistance"
putexcel B69 = "Stopped receiving child care assistance"
putexcel B70 = "Onto a child care wait list"
putexcel B71 = "Off a child care wait list"
putexcel A72:A73="Moves", merge vcenter
putexcel B72 = "Moved for relationship"
putexcel B73 = "Moved for independence"
putexcel A74:A79="Education Changes", merge vcenter
putexcel B74 = "Gained education"
putexcel B75 = "Enrolled in school"
putexcel B76 = "Stopped being enrolled in school"
putexcel B77 = "Spouse Gained education"
putexcel B78 = "Spouse Enrolled in school"
putexcel B79 = "Spouse Stopped being enrolled in school"
putexcel A80:A91="Average Changes", merge vcenter
putexcel B80 = "R Earnings Change - Average"
putexcel B81 = "Spouse Earnings Change - Average"
putexcel B82 = "HH Earnings Change - Average"
putexcel B83 = "Other Earnings Change - Average"
putexcel B84 = "R Raw Earnings Change - Average"
putexcel B85 = "Spouse Raw Earnings Change - Average"
putexcel B86 = "HH Raw Earnings Change - Average"
putexcel B87 = "Other Raw Earnings Change - Average"
putexcel B88 = "R Hours Change - Average"
putexcel B89 = "Spouse Hours Change - Average"
putexcel B90 = "R Wages Change - Average"
putexcel B91 = "Spouse Wages Change - Average"
putexcel A92:A103="Earnings Thresholds", merge vcenter
putexcel B92 = "R Earnings Up 8%"
putexcel B93 = "R Earnings Down 8%"
putexcel B94 = "Spouse Earnings Up 8%"
putexcel B95 = "Spouse Earnings Down 8%"
putexcel B96 = "HH Earnings Up 8%"
putexcel B97 = "HH Earnings Down 8%"
putexcel B98 = "Other Earnings Up 8%"
putexcel B99 = "Other Earnings Down 8%"
putexcel B100 = "Child Earnings Up 8%"
putexcel B101 = "Child Earnings Down 8%"
putexcel B102 = "Parent Earnings Up 8%"
putexcel B103 = "Parent Earnings Down 8%"
putexcel A104:A107="Hours Thresholds", merge vcenter
putexcel B104 = "R Hours Up 5%"
putexcel B105 = "R Hours Down 5%"
putexcel B106 = "Spouse Hours Up 5%"
putexcel B107 = "Spouse Hours Down 5%"
putexcel A108:A111="Wages Changes", merge vcenter
putexcel B108 = "R Wages Up 8%"
putexcel B109 = "R Wages Down 8%"
putexcel B110 = "Spouse Wages Up 8%"
putexcel B111 = "Spouse Wages Down 8%"
putexcel A112:A123="Median Changes", merge vcenter
putexcel B112 = "R Earnings Change - Median"
putexcel B113 = "Spouse Earnings Change - Median"
putexcel B114 = "HH Earnings Change - Median"
putexcel B115 = "Other Earnings Change - Median"
putexcel B116 = "R Raw Earnings Change - Median"
putexcel B117 = "Spouse Raw Earnings Change - Median"
putexcel B118 = "HH Raw Earnings Change - Median"
putexcel B119 = "Other Raw Earnings Change - Median"
putexcel B120 = "R Hours Change - Median"
putexcel B121 = "Spouse Hours Change - Median"
putexcel B122 = "R Wages Change - Median"
putexcel B123 = "Spouse Wages Change - Median"
putexcel A124:A135="Alt Earnings Threshold", merge vcenter
putexcel B124 = "R Earnings Change - Average"
putexcel B125 = "Spouse Earnings Change - Average"
putexcel B126 = "HH Earnings Change - Average"
putexcel B127 = "Other Earnings Change - Average"
putexcel B128 = "R Earnings Up 8%"
putexcel B129 = "R Earnings Down 8%"
putexcel B130 = "Spouse Earnings Up 8%"
putexcel B131 = "Spouse Earnings Down 8%"
putexcel B132 = "HH Earnings Up 8%"
putexcel B133 = "HH Earnings Down 8%"
putexcel B134 = "HH Earnings Up 8%"
putexcel B135 = "HH Earnings Down 8%"
putexcel A136:A159="Comprehensive Status Changes", merge vcenter
putexcel B136 = "Mom Earnings up 8%"
putexcel B137 = "Mom Hours up 5%"
putexcel B138 = "Mom Wages up 8%"
putexcel B139 = "Mom Earnings up 8% - Alt"
putexcel B140 = "Mom Earnings Down 8%"
putexcel B141 = "Mom Hours down 5%"
putexcel B142 = "Mom Wages down 8%"
putexcel B143 = "Mom Earnings Down 8% - Alt"
putexcel B144 = "Partner Earnings up 8%"
putexcel B145 = "Partner Hours up 5%"
putexcel B146 = "Partner Wages up 8%"
putexcel B147 = "Partner Earnings up 8% - Alt"
putexcel B148 = "Partner Earnings Down 8%"
putexcel B149 = "Partner Hours down 5%"
putexcel B150 = "Partner Wages down 8%"
putexcel B151 = "Partner Earnings Down 8% - Alt"
putexcel B152 = "HH Earnings up 8%"
putexcel B153 = "HH Earnings up 8% - Alt"
putexcel B154 = "HH Earnings down 8%"
putexcel B155 = "HH Earnings down 8% - Alt"
putexcel B156 = "Other Earnings up 8%"
putexcel B157 = "Other Earnings up 8% - Alt"
putexcel B158 = "Other Earnings down 8%"
putexcel B159 = "Other Earnings down 8% - Alt"
putexcel A160:A167="Changes in Earner Status", merge vcenter
putexcel B160 = "R Became Earner"
putexcel B161 = "R Stopped Earning"
putexcel B162 = "Spouse Became Earner"
putexcel B163 = "Spouse Stopped Earning"
putexcel B164 = "HH Became Earner"
putexcel B165 = "HH Stopped Earning"
putexcel B166 = "Other Became Earner"
putexcel B167 = "Other Stopped Earning"
putexcel A168:A185="Relevant Overlaps", merge vcenter
putexcel B168 = "Mom Earnings Up, Partner Down"
putexcel B169 = "Mom Earnings Up, Someone else down"
putexcel B170 = "Mom Earnings Up, Child down"
putexcel B171 = "Mom Earnings Up, Parent down"
putexcel B172 = "Mom Earnings Up Only"
putexcel B173 = "Mom Earnings Unchanged, HH Down"
putexcel B174 = "Mom Earnings Unchanged, Partner Down"
putexcel B175 = "Mom Earnings Unchanged, Someone else Down"
putexcel B176 = "Mom Earnings Unchanged, Child down"
putexcel B176 = "Mom Earnings Unchanged, Parent down"
putexcel B177 = "Mom Earnings Up, Earner Left HH"
putexcel B178 = "Mom Earnings Unchanged, Earner Left HH"
putexcel B179 = "Mom Earnings Up, Relationship Ended"
putexcel B181 = "Mom Earnings Unchanged, Relationship Ended"
putexcel B182 = "Mom Earnings Up, Partner Up"
putexcel B183 = "Mom Earnings Up, Someone else Up"
putexcel B184 = "Mom Earnings Down, Partner Down"
putexcel B185 = "Mom Earnings Down, Someone else down"

putexcel B187 = "Total Sample"
putexcel B188 = "Breadwinners"

sort SSUID PNUM year

// Partner and HH status changes
local status_vars "sing_coh sing_mar coh_mar coh_diss marr_diss marr_wid marr_coh no_status_chg hh_lose earn_lose earn_non hh_gain earn_gain non_earn resp_earn resp_non prekid_gain prekid_lose parents_gain parents_lose birth"

local colu1 "C D E F G"

forvalues w=1/21 {
	forvalues a=1/5{
		local i=`a'
		local row=`w'+2
		local col1: word `i' of `colu1'
		local var: word `w' of `status_vars'
		mean `var' if trans_bw60==1 & ageb1_gp==`a'
		matrix m`var'`a' = e(b)
		putexcel `col1'`row' = matrix(m`var'`a'), nformat(#.##%)
		}
}

// firthbirth - needs own code because mother had to be a BW in year prior to having a child
local colu1 "C D E F G"

	forvalues a=1/5{
		local i=`a'
		local col1: word `i' of `colu1'
		mean firstbirth if bw60==1 & bw60[_n-1]==1 & ageb1_gp==`a' & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
		matrix mfirstbirth`a' = e(b)
		putexcel `col1'24 = matrix(mfirstbirth`a'), nformat(#.##%)
		}


// Job changes - respondent and spouse	
local job_vars "full_part full_no part_no part_full no_part no_full no_job_chg jobchange betterjob left_preg many_jobs one_job numjobs_up numjobs_down full_part_sp full_no_sp part_no_sp part_full_sp no_part_sp no_full_sp no_job_chg_sp jobchange_sp betterjob_sp many_jobs_sp one_job_sp numjobs_up_sp numjobs_down_sp"

local colu1 "C D E F G"

forvalues w=1/27 {
	forvalues a=1/5{
		local i=`a'
		local row=`w'+24
		local col1: word `i' of `colu1'
		local var: word `w' of `job_vars'
		mean `var' if trans_bw60==1 & ageb1_gp==`a'
		matrix m`var'`a' = e(b)
		putexcel `col1'`row' = matrix(m`var'`a'), nformat(#.##%)
		}
}

// Remaining change variables - disability, welfare, child care, and education

local other_vars "efindjob_in efindjob_out edisabl_in edisabl_out rdis_alt_in rdis_alt_out efindjob_in_sp edisabl_in_sp efindjob_out_sp edisabl_out_sp rdis_alt_in_sp rdis_alt_out_sp welfare_in welfare_out ch_workmore_yes ch_workmore_no childasst_yes childasst_no ch_waitlist_yes ch_waitlist_no move_relat move_indep educ_change enrolled_yes enrolled_no educ_change_sp enrolled_yes_sp enrolled_no_sp"

local colu1 "C D E F G"

forvalues w=1/28 {
	forvalues a=1/5{
		local i=`a'
		local row=`w'+51
		local col1: word `i' of `colu1'
		local var: word `w' of `other_vars'
		mean `var' if trans_bw60==1 & ageb1_gp==`a'
		matrix m`var'`a' = e(b)
		putexcel `col1'`row' = matrix(m`var'`a'), nformat(#.##%)
		}
}

// Earnings, hours, and wage changes

local chg_vars "earn_change earn_change_sp earn_change_hh earn_change_oth earn_change_raw earn_change_raw_oth earn_change_raw_hh earn_change_raw_sp hours_change hours_change_sp wage_chg wage_chg_sp earnup8 earndown8 earnup8_sp earndown8_sp earnup8_hh earndown8_hh earnup8_oth earndown8_oth earnup8_child earndown8_child earnup8_par earndown8_par hours_up5 hoursdown5 hours_up5_sp hoursdown5_sp wagesup8 wagesdown8 wagesup8_sp wagesdown8_sp"

local colu1 "C D E F G"

forvalues w=1/32{
	forvalues a=1/5{
		local i=`a'
		local row=`w'+79
		local col1: word `i' of `colu1'
		local var: word `w' of `chg_vars'
		mean `var' if trans_bw60==1 & ageb1_gp==`a'
		matrix m`var'`a' = e(b)
		putexcel `col1'`row' = matrix(m`var'`a'), nformat(#.##%)
		}
}

// median changes instead of mean because of outliers

local med_chg_vars "earn_change_m earn_change_sp_m earn_change_hh_m earn_change_oth_m earn_change_raw_m earn_change_raw_oth_m earn_change_raw_hh_m earn_change_raw_sp_m hours_change_m hours_change_sp_m wage_chg_m wage_chg_sp_m"

local colu1 "C D E F G"

forvalues w=1/12{
	forvalues a=1/5{
		local i=`a'
		local row=`w'+111
		local col1: word `i' of `colu1'
		local var: word `w' of `med_chg_vars'
		summarize `var' if trans_bw60==1 & ageb1_gp==`a', detail
		matrix m`var'`a' = r(p50)
		putexcel `col1'`row' = matrix(m`var'`a'), nformat(#.##%)
		}
}

// Testing placing a min earnings threshold to calculate changes in earnings (>$500 in a year)




// Testing placing a min earnings threshold to calculate changes in earnings (>$500 in a year)
local alt_chg_vars "earn_change_alt earn_change_alt_sp earn_change_alt_hh earn_change_alt_oth earnup_alt8 earndown_alt8 earnup_alt8_sp earndown_alt8_sp earnup_alt8_hh earndown_alt8_hh earnup_alt8_oth earndown_alt8_oth"

local colu1 "C D E F G"

forvalues w=1/12 {
	forvalues a=1/5{
		local i=`a'
		local row=`w'+123
		local col1: word `i' of `colu1'
		local var: word `w' of `alt_chg_vars'
		mean `var' if trans_bw60==1  & ageb1_gp==`a'
		matrix m`var'`a' = e(b)
		putexcel `col1'`row' = matrix(m`var'`a'), nformat(#.##%)
		}
}


local all_vars "earnup8_all hours_up5_all wagesup8_all earnup_alt8_all earndown8_all hoursdown5_all wagesdown8_all earndown_alt8_all earnup8_sp_all hours_up5_sp_all wagesup8_sp_all earnup_alt8_sp_all earndown8_sp_all hoursdown5_sp_all wagesdown8_sp_all earndown_alt8_sp_all earnup8_hh_all earnup_alt8_hh_all earndown8_hh_all earndown_alt8_hh_all earnup8_oth_all earnup_alt8_oth_all earndown8_oth_all earndown_alt8_oth_all"

local colu1 "C D E F G"

forvalues w=1/24 {
	forvalues a=1/5{
		local i=`a'
		local row=`w'+135
		local col1: word `i' of `colu1'
		local var: word `w' of `all_vars'
		mean `var' if trans_bw60==1  & ageb1_gp==`a'
		matrix m`var'`a' = e(b)
		putexcel `col1'`row' = matrix(m`var'`a'), nformat(#.##%)
		}
}


// Testing changes from no earnings to earnings for all (Mother, Partner, Others)

local earn_status_vars "mom_gain_earn mom_lose_earn part_gain_earn part_lose_earn hh_gain_earn hh_lose_earn oth_gain_earn oth_lose_earn"

local colu1 "C D E F G"

forvalues w=1/8 {
	forvalues a=1/5{
		local i=`a'
		local row=`w'+159
		local col1: word `i' of `colu1'
		local var: word `w' of `earn_status_vars'
		mean `var' if trans_bw60==1 & ageb1_gp==`a'
		matrix m`var'`a' = e(b)
		putexcel `col1'`row' = matrix(m`var'`a'), nformat(#.##%)
		}
}

// relevant overlap vars

local overlap_vars "momup_partdown momup_othdown momup_childdown momup_parentdown momup_only momno_hhdown momno_partdown momno_othdown momno_childdown momno_parentdown momup_othleft momno_othleft momup_relend momno_relend momup_partup momup_othup momdown_partdown momdown_othdown"

local colu1 "C D E F G"

* by year
forvalues w=1/18 {
	forvalues a=1/5{
		local i=`a'
		local row=`w'+167
		local col1: word `i' of `colu1'
		local var: word `w' of `overlap_vars'
		mean `var' if trans_bw60==1 & ageb1_gp==`a'
		matrix m`var'`a' = e(b)
		putexcel `col1'`row' = matrix(m`var'`a'), nformat(#.##%)
		}
}


**** adding in sample sizes

local colu1 "C D E F G"


forvalues a=1/5{
	local i=`a'
	local col1: word `i' of `colu1'
	egen total_a`a' = nvals(idnum) if ageb1_gp==`a'
	bysort total_a`a': replace total_a`a' = total_a`a'[1] 
	local total_a`a' = total_a`a'
	egen bw_a`a' = nvals(idnum) if ageb1_gp==`a' & trans_bw60==1
	bysort bw_a`a': replace bw_a`a' = bw_a`a'[1] 
	local bw_a`a' = bw_a`a'
	putexcel `col1'187 = `total_a`a''
	putexcel `col1'188 = `bw_a`a''
	}

	
save "$SIPP14keep/bw_descriptives.dta", replace

