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

// temp recode - but fixed in source file, but will take awhile to run recode educ (1=1) (2=2) (3=3) (4/5=4)
label define educ 1 "Less than HS" 2 "HS Diploma" 3 "Some College" 4 "College Plus"
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
putexcel A80:A87="Average Changes", merge vcenter
putexcel B80 = "R Earnings Change - Average"
putexcel B81 = "Spouse Earnings Change - Average"
putexcel B82 = "HH Earnings Change - Average"
putexcel B83 = "Other Earnings Change - Average"
putexcel B84 = "R Hours Change - Average"
putexcel B85 = "Spouse Hours Change - Average"
putexcel B86 = "R Wages Change - Average"
putexcel B87 = "Spouse Wages Change - Average"
putexcel A88:A103="Earnings Thresholds", merge vcenter
putexcel B88 = "R Earnings Up 20%"
putexcel B89 = "R Earnings Down 20%"
putexcel B90 = "Spouse Earnings Up 20%"
putexcel B91 = "Spouse Earnings Down 20%"
putexcel B92 = "HH Earnings Up 20%"
putexcel B93 = "HH Earnings Down 20%"
putexcel B94 = "Other Earnings Up 20%"
putexcel B95 = "Other Earnings Down 20%"
putexcel B96 = "R Earnings Up 5%"
putexcel B97 = "R Earnings Down 5%"
putexcel B98 = "Spouse Earnings Up 5%"
putexcel B99 = "Spouse Earnings Down 5%"
putexcel B100 = "HH Earnings Up 5%"
putexcel B101 = "HH Earnings Down 5%"
putexcel B102 = "Other Earnings Up 5%"
putexcel B103 = "Other Earnings Down 5%"
putexcel A104:A111="Hours Thresholds", merge vcenter
putexcel B104 = "R Hours Up 15%"
putexcel B105 = "R Hours Down 15%"
putexcel B106 = "Spouse Hours Up 15%"
putexcel B107 = "Spouse Hours Down 15%"
putexcel B108 = "R Hours Up 5%"
putexcel B109 = "R Hours Down 5%"
putexcel B110 = "Spouse Hours Up 5%"
putexcel B111 = "Spouse Hours Down 5%"
putexcel A112:A119="Wages Changes", merge vcenter
putexcel B112 = "R Wages Up 15%"
putexcel B113 = "R Wages Down 15%"
putexcel B114 = "Spouse Wages Up 15%"
putexcel B115 = "Spouse Wages Down 15%"
putexcel B116 = "R Wages Up 5%"
putexcel B117 = "R Wages Down 5%"
putexcel B118 = "Spouse Wages Up 5%"
putexcel B119 = "Spouse Wages Down 5%"
putexcel A120:A139="Alt Earnings Threshold", merge vcenter
putexcel B120 = "R Earnings Change - Average"
putexcel B121 = "Spouse Earnings Change - Average"
putexcel B122 = "HH Earnings Change - Average"
putexcel B123 = "Other Earnings Change - Average"
putexcel B124 = "R Earnings Up 20%"
putexcel B125 = "R Earnings Down 20%"
putexcel B126 = "Spouse Earnings Up 20%"
putexcel B127 = "Spouse Earnings Down 20%"
putexcel B128 = "HH Earnings Up 20%"
putexcel B129 = "HH Earnings Down 20%"
putexcel B130 = "Other Earnings Up 20%"
putexcel B131 = "Other Earnings Down 20%"
putexcel B132 = "R Earnings Up 5%"
putexcel B133 = "R Earnings Down 5%"
putexcel B134 = "Spouse Earnings Up 5%"
putexcel B135 = "Spouse Earnings Down 5%"
putexcel B136 = "HH Earnings Up 5%"
putexcel B137 = "HH Earnings Down 5%"
putexcel B138 = "Other Earnings Up 5%"
putexcel B139 = "Other Earnings Down 5%"
putexcel A140:A147="Changes in Earner Status", merge vcenter
putexcel B140 = "R Became Earner"
putexcel B141 = "R Stopped Earning"
putexcel B142 = "Spouse Became Earner"
putexcel B143 = "Spouse Stopped Earning"
putexcel B144 = "HH Became Earner"
putexcel B145 = "HH Stopped Earning"
putexcel B146 = "Other Became Earner"
putexcel B147 = "Other Stopped Earning"
putexcel A148:A155="Median Changes", merge vcenter
putexcel B148 = "R Earnings Change - Median"
putexcel B149 = "Spouse Earnings Change - Median"
putexcel B150 = "HH Earnings Change - Median"
putexcel B151 = "Other Earnings Change - Median"
putexcel B152 = "R Hours Change - Median"
putexcel B153 = "Spouse Hours Change - Median"
putexcel B154 = "R Wages Change - Median"
putexcel B155 = "Spouse Wages Change - Median"
putexcel B156 = "First Birth - year of BW"
putexcel B157 = "First Birth - prior year BW"
putexcel B159 = "Total Sample / Just BWs"


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

local hh_vars "hh_lose earn_lose earn_non hh_gain earn_gain non_earn resp_earn resp_non prekid_gain prekid_lose parents_gain parents_lose birth firstbirth"
local colu1 "C E G"
local colu2 "D F H"
	
* by year
forvalues w=1/14 {
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
forvalues w=1/14 {
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
forvalues w=1/14 {
		local row=`w'+10
		local var: word `w' of `hh_vars'
		mean `var' if trans_bw60==0
		matrix m`var'= e(b)
		mean `var' if trans_bw60[_n+1]==0 & SSUID==SSUID[_n+1] & PNUM==PNUM[_n+1]
		matrix pr`var' = e(b)
		putexcel K`row' = matrix(m`var'), nformat(#.##%)
		putexcel L`row' = matrix(pr`var'), nformat(#.##%)

}


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
	// Do we care who else’s earnings changed up or down? Or just that they did. Maybe do any change up or down, then spouse up or down (see code in descriptives file), then anyone NOT spouse -do as TOTAL CHANGE? or by person?

* Using earnings not tpearn which is the sum of all earnings and won't be negative
* First create a variable that indicates percent change YoY
by SSUID PNUM (year), sort: gen earn_change = ((earnings-earnings[_n-1])/earnings[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]

// plots to determine thresholds
histogram earn_change if earn_change < .5 & earn_change > -.5, width(.01) xlab(-.5(.05).5, labsize(small)) percent
histogram earn_change if earn_change < .25 & earn_change > -.25, width(.01) xlab(-.25(.01).25, labsize(tiny)) percent
histogram earn_change_sp if earn_change_sp < .25 & earn_change_sp > -.25, width(.01) xlab(-.25(.01).25, labsize(tiny)) percent
histogram earn_change_hh if earn_change_hh < .25 & earn_change_hh > -.25, width(.01) xlab(-.25(.01).25, labsize(tiny)) percent

histogram earn_change if earn_change < .5 & earn_change > -.5 & trans_bw60==1, width(.01) xlab(-.5(.05).5, labsize(tiny)) percent
histogram earn_change_sp if earn_change_sp < .5 & earn_change_sp > -.5 & trans_bw60==1, width(.01) xlab(-.5(.05).5, labsize(tiny)) percent
histogram earn_change_hh if earn_change_hh < .5 & earn_change_hh > -.5 & trans_bw60==1, width(.01) xlab(-.5(.05).5, labsize(tiny)) percent

browse SSUID PNUM year earnings earn_change if trans_bw60==1 & earn_change >1
browse SSUID PNUM year earnings earn_change if earn_change >10 & earn_change!=. // trying to understand big jumps in earnings

	// testing a mean, then up over 5% and 20% thresholds
	gen earnup20=0
	replace earnup20 = 1 if earn_change >=.2000000
	replace earnup20=. if earn_change==.
	gen earndown20=0
	replace earndown20 = 1 if earn_change <=-.2000000
	replace earndown20=. if earn_change==.
	gen earnup5=0
	replace earnup5 = 1 if earn_change >=.05000000
	replace earnup5=. if earn_change==.
	gen earndown5=0
	replace earndown5 = 1 if earn_change <=-.05000000
	replace earndown5=. if earn_change==.
	// browse SSUID PNUM year tpearn earn_change earnup earndown

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
	// testing a mean, then up over a threshold, down over a threshold
	gen earnup20_sp=0
	replace earnup20_sp = 1 if earn_change_sp >=.2000000
	replace earnup20_sp=. if earn_change_sp==.
	gen earndown20_sp=0
	replace earndown20_sp = 1 if earn_change_sp <=-.2000000
	replace earndown20_sp=. if earn_change_sp==.
	gen earnup5_sp=0
	replace earnup5_sp = 1 if earn_change_sp >=.05000000
	replace earnup5_sp=. if earn_change_sp==.
	gen earndown5_sp=0
	replace earndown5_sp = 1 if earn_change_sp <=-.05000000
	replace earndown5_sp=. if earn_change_sp==.
	
* Variable for all earnings in HH besides R
gen hh_earn=thearn-earnings // might need a better HH earn variable that isn't negative
by SSUID PNUM (year), sort: gen earn_change_hh = ((hh_earn-hh_earn[_n-1])/hh_earn[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	// testing a mean, then up over a threshold, down over a threshold
	gen earnup20_hh=0
	replace earnup20_hh = 1 if earn_change_hh >=.2000000
	replace earnup20_hh=. if earn_change_hh==.
	gen earndown20_hh=0
	replace earndown20_hh = 1 if earn_change_hh <=-.2000000
	replace earndown20_hh=. if earn_change_hh==.
	gen earnup5_hh=0
	replace earnup5_hh = 1 if earn_change_hh >=.05000000
	replace earnup5_hh=. if earn_change_hh==.
	gen earndown5_hh=0
	replace earndown5_hh = 1 if earn_change_hh <=-.05000000
	replace earndown5_hh=. if earn_change_hh==.
	
* Variable for all earnings in HH besides R + partner
gen other_earn=thearn-earnings-earnings_a_sp // might need a better HH earn variable that isn't negative
by SSUID PNUM (year), sort: gen earn_change_oth = ((other_earn-other_earn[_n-1])/other_earn[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	// testing a mean, then up over a threshold, down over a threshold
	gen earnup20_oth=0
	replace earnup20_oth = 1 if earn_change_oth >=.2000000
	replace earnup20_oth=. if earn_change_oth==.
	gen earndown20_oth=0
	replace earndown20_oth = 1 if earn_change_oth <=-.2000000
	replace earndown20_oth=. if earn_change_oth==.
	gen earnup5_oth=0
	replace earnup5_oth = 1 if earn_change_oth >=.05000000
	replace earnup5_oth=. if earn_change_oth==.
	gen earndown5_oth=0
	replace earndown5_oth = 1 if earn_change_oth <=-.05000000
	replace earndown5_oth=. if earn_change_oth==.
	
//browse thearn tpearn earnings_sp hh_earn other_earn

// Raw hours changes

* First create a variable that indicates percent change YoY
by SSUID PNUM (year), sort: gen hours_change = ((avg_hrs-avg_hrs[_n-1])/avg_hrs[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
browse SSUID PNUM year avg_hrs hours_change

	// testing a mean, then up over a threshold, down over a threshold
	gen hours_up15=0
	replace hours_up15 = 1 if hours_change >=.1500000
	replace hours_up15=. if hours_change==.
	gen hoursdown15=0
	replace hoursdown15 = 1 if hours_change <=-.1500000
	replace hoursdown15=. if hours_change==.
	gen hours_up5=0
	replace hours_up5 = 1 if hours_change >=.0500000
	replace hours_up5=. if hours_change==.
	gen hoursdown5=0
	replace hoursdown5 = 1 if hours_change <=-.0500000
	replace hoursdown5=. if hours_change==.
	// browse SSUID PNUM year avg_hrs hours_change hours_up hoursdown

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
	gen hours_up15_sp=0
	replace hours_up15_sp = 1 if hours_change_sp >=.1500000
	replace hours_up15_sp=. if hours_change_sp==.
	gen hoursdown15_sp=0
	replace hoursdown15_sp = 1 if hours_change_sp <=-.1500000
	replace hoursdown15_sp=. if hours_change_sp==.
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

	// testing a mean, then up over a threshold, down over a threshold
	gen wagesup15=0
	replace wagesup15 = 1 if wage_chg >=.1500000
	replace wagesup15=. if wage_chg==.
	gen wagesdown15=0
	replace wagesdown15 = 1 if wage_chg <=-.1500000
	replace wagesdown15=. if wage_chg==.
	gen wagesup5=0
	replace wagesup5 = 1 if wage_chg >=.0500000
	replace wagesup5=. if wage_chg==.
	gen wagesdown5=0
	replace wagesdown5 = 1 if wage_chg <=-.0500000
	replace wagesdown5=. if wage_chg==.
	// browse SSUID PNUM year avg_hrs hours_change hours_up hoursdown

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

* then create variables
	// testing a mean, then up over a threshold, down over a threshold
	gen wagesup15_sp=0
	replace wagesup15_sp = 1 if wage_chg_sp >=.1500000
	replace wagesup15_sp=. if wage_chg_sp==.
	gen wagesdown15_sp=0
	replace wagesdown15_sp = 1 if wage_chg_sp <=-.1500000
	replace wagesdown15_sp=. if wage_chg_sp==.
	gen wagesup5_sp=0
	replace wagesup5_sp = 1 if wage_chg_sp >=.0500000
	replace wagesup5_sp=. if wage_chg_sp==.
	gen wagesdown5_sp=0
	replace wagesdown5_sp = 1 if wage_chg_sp <=-.0500000
	replace wagesdown5_sp=. if wage_chg_sp==.

// plots to determine thresholds
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


* then calculate changes
local chg_vars "earn_change earn_change_sp earn_change_hh earn_change_oth hours_change hours_change_sp wage_chg wage_chg_sp earnup20 earndown20 earnup20_sp earndown20_sp earnup20_hh earndown20_hh earnup20_oth earndown20_oth earnup5 earndown5 earnup5_sp earndown5_sp earnup5_hh earndown5_hh earnup5_oth earndown5_oth hours_up15 hoursdown15 hours_up15_sp hoursdown15_sp hours_up5 hoursdown5 hours_up5_sp hoursdown5_sp wagesup15 wagesdown15 wagesup15_sp wagesdown15_sp wagesup5 wagesdown5 wagesup5_sp wagesdown5_sp"

local colu1 "C E G"

* by year
forvalues w=1/40 {
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
forvalues w=1/40 {
		local row=`w'+79
		local var: word `w' of `chg_vars'
		mean `var' if trans_bw60==1
		matrix m`var' = e(b)
		putexcel I`row' = matrix(m`var'), nformat(#.##%)
}

* compare to non-BW
forvalues w=1/40 {
		local row=`w'+79
		local var: word `w' of `chg_vars'
		mean `var' if trans_bw60==0
		matrix m`var' = e(b)
		putexcel K`row' = matrix(m`var'), nformat(#.##%)
}

// Testing placing a min earnings threshold to calculate changes in earnings (>$100 in a year)
* Respondent
	by SSUID PNUM (year), sort: gen earn_change_alt = ((earnings-earnings[_n-1])/earnings[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & earnings[_n-1] > 100
	gen earnup_alt20=0
	replace earnup_alt20 = 1 if earn_change_alt >=.2000000
	replace earnup_alt20=. if earn_change_alt==.
	gen earndown_alt20=0
	replace earndown_alt20 = 1 if earn_change_alt <=-.2000000
	replace earndown_alt20=. if earn_change_alt==.
	gen earnup_alt5=0
	replace earnup_alt5 = 1 if earn_change_alt >=.05000000
	replace earnup_alt5=. if earn_change_alt==.
	gen earndown_alt5=0
	replace earndown_alt5 = 1 if earn_change_alt <=-.05000000
	replace earndown_alt5=. if earn_change_alt==.

*Partner
	by SSUID PNUM (year), sort: gen earn_change_alt_sp = ((earnings_a_sp-earnings_a_sp[_n-1])/earnings_a_sp[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & earnings_a_sp[_n-1] > 100
	gen earnup_alt20_sp=0
	replace earnup_alt20_sp = 1 if earn_change_alt_sp >=.2000000
	replace earnup_alt20_sp=. if earn_change_alt_sp==.
	gen earndown_alt20_sp=0
	replace earndown_alt20_sp = 1 if earn_change_alt_sp <=-.2000000
	replace earndown_alt20_sp=. if earn_change_alt_sp==.
	gen earnup_alt5_sp=0
	replace earnup_alt5_sp = 1 if earn_change_alt_sp >=.05000000
	replace earnup_alt5_sp=. if earn_change_alt_sp==.
	gen earndown_alt5_sp=0
	replace earndown_alt5_sp = 1 if earn_change_alt_sp <=-.05000000
	replace earndown_alt5_sp=. if earn_change_alt_sp==.
	
* All earnings in HH besides R
	by SSUID PNUM (year), sort: gen earn_change_alt_hh = ((hh_earn-hh_earn[_n-1])/hh_earn[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & hh_earn[_n-1] > 100
	// testing a mean, then up over a threshold, down over a threshold
	gen earnup_alt20_hh=0
	replace earnup_alt20_hh = 1 if earn_change_alt_hh >=.2000000
	replace earnup_alt20_hh=. if earn_change_alt_hh==.
	gen earndown_alt20_hh=0
	replace earndown_alt20_hh = 1 if earn_change_alt_hh <=-.2000000
	replace earndown_alt20_hh=. if earn_change_alt_hh==.
	gen earnup_alt5_hh=0
	replace earnup_alt5_hh = 1 if earn_change_alt_hh >=.05000000
	replace earnup_alt5_hh=. if earn_change_alt_hh==.
	gen earndown_alt5_hh=0
	replace earndown_alt5_hh = 1 if earn_change_alt_hh <=-.05000000
	replace earndown_alt5_hh=. if earn_change_alt_hh==.
	
* All earnings in HH besides R + partner
	by SSUID PNUM (year), sort: gen earn_change_alt_oth = ((other_earn-other_earn[_n-1])/other_earn[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & other_earn[_n-1] > 100
	// testing a mean, then up over a threshold, down over a threshold
	gen earnup_alt20_oth=0
	replace earnup_alt20_oth = 1 if earn_change_alt_oth >=.2000000
	replace earnup_alt20_oth=. if earn_change_alt_oth==.
	gen earndown_alt20_oth=0
	replace earndown_alt20_oth = 1 if earn_change_alt_oth <=-.2000000
	replace earndown_alt20_oth=. if earn_change_alt_oth==.
	gen earnup_alt5_oth=0
	replace earnup_alt5_oth = 1 if earn_change_alt_oth >=.05000000
	replace earnup_alt5_oth=. if earn_change_alt_oth==.
	gen earndown_alt5_oth=0
	replace earndown_alt5_oth = 1 if earn_change_alt_oth <=-.05000000
	replace earndown_alt5_oth=. if earn_change_alt_oth==.

* then calculate changes
local alt_chg_vars "earn_change_alt earn_change_alt_sp earn_change_alt_hh earn_change_alt_oth earnup_alt20 earndown_alt20 earnup_alt20_sp earndown_alt20_sp earnup_alt20_hh earndown_alt20_hh earnup_alt20_oth earndown_alt20_oth earnup_alt5 earndown_alt5 earnup_alt5_sp earndown_alt5_sp earnup_alt5_hh earndown_alt5_hh earnup_alt5_oth earndown_alt5_oth"

local colu1 "C E G"

* by year
forvalues w=1/20 {
	forvalues y=14/16{
		local i=`y'-13
		local row=`w'+119
		local col1: word `i' of `colu1'
		local var: word `w' of `alt_chg_vars'
		mean `var' if trans_bw60==1 & year==20`y'
		matrix m`var'`y' = e(b)
		putexcel `col1'`row' = matrix(m`var'`y'), nformat(#.##%)
		}
}

* total
forvalues w=1/20 {
		local row=`w'+119
		local var: word `w' of `alt_chg_vars'
		mean `var' if trans_bw60==1
		matrix m`var' = e(b)
		putexcel I`row' = matrix(m`var'), nformat(#.##%)
}

* compare to  non-BW
forvalues w=1/20 {
		local row=`w'+119
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
	
local earn_status_vars "mom_gain_earn mom_lose_earn part_gain_earn part_lose_earn hh_gain_earn hh_lose_earn oth_gain_earn oth_lose_earn"

local colu1 "C E G"

* by year
forvalues w=1/8 {
	forvalues y=14/16{
		local i=`y'-13
		local row=`w'+139
		local col1: word `i' of `colu1'
		local var: word `w' of `earn_status_vars'
		mean `var' if trans_bw60==1 & year==20`y'
		matrix m`var'`y' = e(b)
		putexcel `col1'`row' = matrix(m`var'`y'), nformat(#.##%)
		}
}

* total
forvalues w=1/8 {
		local row=`w'+139
		local var: word `w' of `earn_status_vars'
		mean `var' if trans_bw60==1
		matrix m`var' = e(b)
		putexcel I`row' = matrix(m`var'), nformat(#.##%)
}

* compare to non-BW
forvalues w=1/8 {
		local row=`w'+139
		local var: word `w' of `earn_status_vars'
		mean `var' if trans_bw60==0
		matrix m`var' = e(b)
		putexcel K`row' = matrix(m`var'), nformat(#.##%)
}

// median changes instead of mean because of outliers
* then calculate changes
local chg_vars "earn_change earn_change_sp earn_change_hh earn_change_oth hours_change hours_change_sp wage_chg wage_chg_sp"

local colu1 "C E G"

* by year
forvalues w=1/8 {
	forvalues y=14/16{
		local i=`y'-13
		local row=`w'+147
		local col1: word `i' of `colu1'
		local var: word `w' of `chg_vars'
		summarize `var' if trans_bw60==1 & year==20`y', detail
		matrix m`var'`y' = r(p50)
		putexcel `col1'`row' = matrix(m`var'`y'), nformat(#.##%)
		}
}

* total
forvalues w=1/8 {
		local row=`w'+147
		local var: word `w' of `chg_vars'
		summarize `var' if trans_bw60==1, detail
		matrix m`var' = r(p50)
		putexcel I`row' = matrix(m`var'), nformat(#.##%)
}

* compare to non-BW
forvalues w=1/8 {
		local row=`w'+147
		local var: word `w' of `chg_vars'
		summarize `var' if trans_bw60==0, detail
		matrix m`var' = r(p50)
		putexcel K`row' = matrix(m`var'), nformat(#.##%)
}

// alternate firthbirth specifications
local colu1 "C E G"

// using bw in year, not transition	
* by year
	forvalues y=14/16{
		local i=`y'-13
		local col1: word `i' of `colu1'
		mean firstbirth if bw60==1 & year==20`y'
		matrix mfirstbirth`y' = e(b)
		putexcel `col1'156 = matrix(mfirstbirth`y'), nformat(#.##%)
		}

* total
	mean firstbirth if bw60==1
	matrix mfirstbirth = e(b)
	putexcel I156 = matrix(mfirstbirth), nformat(#.##%)

* compare to non-BW
	mean firstbirth if bw60==0
	matrix mfirstbirth = e(b)
	putexcel K156 = matrix(mfirstbirth), nformat(#.##%)

// adding spec that you also had to be BW in year prior
* by year
	forvalues y=14/16{
		local i=`y'-13
		local col1: word `i' of `colu1'
		mean firstbirth if bw60==1 & year==20`y' & bw60[_n-1]==1 & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
		matrix mfirstbirth`y' = e(b)
		putexcel `col1'157 = matrix(mfirstbirth`y'), nformat(#.##%)
		}

* total
	mean firstbirth if bw60==1 & bw60[_n-1]==1 & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	matrix mfirstbirth = e(b)
	putexcel I157 = matrix(mfirstbirth), nformat(#.##%)

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
	putexcel `col1'159 = `total_`y''
	egen bw_`y' = nvals(idnum) if year==20`y' & trans_bw60==1
	bysort bw_`y': replace bw_`y' = bw_`y'[1] 
	local bw_`y' = bw_`y'
	putexcel `col2'159 = `bw_`y''
}

egen total_samp = nvals(idnum)
egen bw_samp = nvals(idnum) if trans_bw60==1
local total_samp = total_samp
local bw_samp = bw_samp

putexcel I159 = `total_samp'
putexcel J159 = `bw_samp'

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
putexcel A80:A87="Average Changes", merge vcenter
putexcel B80 = "R Earnings Change - Average"
putexcel B81 = "Spouse Earnings Change - Average"
putexcel B82 = "HH Earnings Change - Average"
putexcel B83 = "Other Earnings Change - Average"
putexcel B84 = "R Hours Change - Average"
putexcel B85 = "Spouse Hours Change - Average"
putexcel B86 = "R Wages Change - Average"
putexcel B87 = "Spouse Wages Change - Average"
putexcel A88:A103="Earnings Thresholds", merge vcenter
putexcel B88 = "R Earnings Up 20%"
putexcel B89 = "R Earnings Down 20%"
putexcel B90 = "Spouse Earnings Up 20%"
putexcel B91 = "Spouse Earnings Down 20%"
putexcel B92 = "HH Earnings Up 20%"
putexcel B93 = "HH Earnings Down 20%"
putexcel B94 = "Other Earnings Up 20%"
putexcel B95 = "Other Earnings Down 20%"
putexcel B96 = "R Earnings Up 5%"
putexcel B97 = "R Earnings Down 5%"
putexcel B98 = "Spouse Earnings Up 5%"
putexcel B99 = "Spouse Earnings Down 5%"
putexcel B100 = "HH Earnings Up 5%"
putexcel B101 = "HH Earnings Down 5%"
putexcel B102 = "Other Earnings Up 5%"
putexcel B103 = "Other Earnings Down 5%"
putexcel A104:A111="Hours Thresholds", merge vcenter
putexcel B104 = "R Hours Up 15%"
putexcel B105 = "R Hours Down 15%"
putexcel B106 = "Spouse Hours Up 15%"
putexcel B107 = "Spouse Hours Down 15%"
putexcel B108 = "R Hours Up 5%"
putexcel B109 = "R Hours Down 5%"
putexcel B110 = "Spouse Hours Up 5%"
putexcel B111 = "Spouse Hours Down 5%"
putexcel A112:A119="Wages Changes", merge vcenter
putexcel B112 = "R Wages Up 15%"
putexcel B113 = "R Wages Down 15%"
putexcel B114 = "Spouse Wages Up 15%"
putexcel B115 = "Spouse Wages Down 15%"
putexcel B116 = "R Wages Up 5%"
putexcel B117 = "R Wages Down 5%"
putexcel B118 = "Spouse Wages Up 5%"
putexcel B119 = "Spouse Wages Down 5%"
putexcel A120:A139="Alt Earnings Threshold", merge vcenter
putexcel B120 = "R Earnings Change - Average"
putexcel B121 = "Spouse Earnings Change - Average"
putexcel B122 = "HH Earnings Change - Average"
putexcel B123 = "Other Earnings Change - Average"
putexcel B124 = "R Earnings Up 20%"
putexcel B125 = "R Earnings Down 20%"
putexcel B126 = "Spouse Earnings Up 20%"
putexcel B127 = "Spouse Earnings Down 20%"
putexcel B128 = "HH Earnings Up 20%"
putexcel B129 = "HH Earnings Down 20%"
putexcel B130 = "Other Earnings Up 20%"
putexcel B131 = "Other Earnings Down 20%"
putexcel B132 = "R Earnings Up 5%"
putexcel B133 = "R Earnings Down 5%"
putexcel B134 = "Spouse Earnings Up 5%"
putexcel B135 = "Spouse Earnings Down 5%"
putexcel B136 = "HH Earnings Up 5%"
putexcel B137 = "HH Earnings Down 5%"
putexcel B138 = "Other Earnings Up 5%"
putexcel B139 = "Other Earnings Down 5%"
putexcel A140:A147="Changes in Earner Status", merge vcenter
putexcel B140 = "R Became Earner"
putexcel B141 = "R Stopped Earning"
putexcel B142 = "Spouse Became Earner"
putexcel B143 = "Spouse Stopped Earning"
putexcel B144 = "HH Became Earner"
putexcel B145 = "HH Stopped Earning"
putexcel B146 = "Other Became Earner"
putexcel B147 = "Other Stopped Earning"
putexcel B149 = "Total Sample"
putexcel B150 = "Breadwinners"

// Partner and HH status changes
local status_vars "sing_coh sing_mar coh_mar coh_diss marr_diss marr_wid marr_coh no_status_chg hh_lose earn_lose earn_non hh_gain earn_gain non_earn resp_earn resp_non prekid_gain prekid_lose parents_gain parents_lose birth firstbirth"

local colu1 "C D E F"

forvalues w=1/22 {
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

local chg_vars "earn_change earn_change_sp earn_change_hh earn_change_oth hours_change hours_change_sp wage_chg wage_chg_sp earnup20 earndown20 earnup20_sp earndown20_sp earnup20_hh earndown20_hh earnup20_oth earndown20_oth earnup5 earndown5 earnup5_sp earndown5_sp earnup5_hh earndown5_hh earnup5_oth earndown5_oth hours_up15 hoursdown15 hours_up15_sp hoursdown15_sp hours_up5 hoursdown5 hours_up5_sp hoursdown5_sp wagesup15 wagesdown15 wagesup15_sp wagesdown15_sp wagesup5 wagesdown5 wagesup5_sp wagesdown5_sp"

local colu1 "C D E F"

forvalues w=1/40 {
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


// Testing placing a min earnings threshold to calculate changes in earnings (>$10 in a year)

local alt_chg_vars "earn_change_alt earn_change_alt_sp earn_change_alt_hh earn_change_alt_oth earnup_alt20 earndown_alt20 earnup_alt20_sp earndown_alt20_sp earnup_alt20_hh earndown_alt20_hh earnup_alt20_oth earndown_alt20_oth earnup_alt5 earndown_alt5 earnup_alt5_sp earndown_alt5_sp earnup_alt5_hh earndown_alt5_hh earnup_alt5_oth earndown_alt5_oth"

local colu1 "C D E F"

forvalues w=1/20 {
	forvalues e=1/4{
		local i=`e'
		local row=`w'+119
		local col1: word `i' of `colu1'
		local var: word `w' of `alt_chg_vars'
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
		local row=`w'+139
		local col1: word `i' of `colu1'
		local var: word `w' of `earn_status_vars'
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
	putexcel `col1'149 = `total_`e''
	putexcel `col1'150 = `bw_`e''
	}


save "$SIPP14keep/bw_descriptives.dta", replace
