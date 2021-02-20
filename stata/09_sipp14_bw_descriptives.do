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
	* quick recode so 1 signals any transition not number of transitions
	foreach var in full_part full_no part_no part_full no_part no_full no_job_chg jobchange betterjob left_preg many_jobs one_job num_jobs_up num_jobs_down full_part_sp full_no_sp part_no_sp part_full_sp no_part_sp no_full_sp no_job_chg_sp jobchange_sp betterjob_sp many_jobs_sp one_job_sp num_jobs_up_sp num_jobs_down_sp{
	replace `var' = 1 if `var' > 1
	}
	
local job_vars "full_part full_no part_no part_full no_part no_full no_job_chg jobchange betterjob left_preg many_jobs one_job num_jobs_up num_jobs_down full_part_sp full_no_sp part_no_sp part_full_sp no_part_sp no_full_sp no_job_chg_sp jobchange_sp betterjob_sp many_jobs_sp one_job_sp num_jobs_up_sp num_jobs_down_sp"
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

browse SSUID PNUM year earnings earn_change if trans_bw60==1 & earn_change >1
browse SSUID PNUM year earnings earn_change if earn_change >10 & earn_change!=. // trying to understand big jumps in earnings

	// testing a mean, then up over 5% and 20% thresholds
	gen earn_up_20=0
	replace earn_up_20 = 1 if earn_change >=.2000000
	replace earn_up_20=. if earn_change==.
	gen earn_down_20=0
	replace earn_down_20 = 1 if earn_change <=-.2000000
	replace earn_down_20=. if earn_change==.
	gen earn_up_5=0
	replace earn_up_5 = 1 if earn_change >=.05000000
	replace earn_up_5=. if earn_change==.
	gen earn_down_5=0
	replace earn_down_5 = 1 if earn_change <=-.05000000
	replace earn_down_5=. if earn_change==.
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
by SSUID PNUM (year), sort: gen earn_change_sp = ((earnings_a_sp-earnings_a_sp[_n-1])/earnings_a_sp[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	// testing a mean, then up over a threshold, down over a threshold
	gen earn_up_20_sp=0
	replace earn_up_20_sp = 1 if earn_change_sp >=.2000000
	replace earn_up_20_sp=. if earn_change_sp==.
	gen earn_down_20_sp=0
	replace earn_down_20_sp = 1 if earn_change_sp <=-.2000000
	replace earn_down_20_sp=. if earn_change_sp==.
	gen earn_up_5_sp=0
	replace earn_up_5_sp = 1 if earn_change_sp >=.05000000
	replace earn_up_5_sp=. if earn_change_sp==.
	gen earn_down_5_sp=0
	replace earn_down_5_sp = 1 if earn_change_sp <=-.05000000
	replace earn_down_5_sp=. if earn_change_sp==.
	
* Variable for all earnings in HH besides R
gen hh_earn=thearn-earnings // might need a better HH earn variable that isn't negative
by SSUID PNUM (year), sort: gen earn_change_hh = ((hh_earn-hh_earn[_n-1])/hh_earn[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	// testing a mean, then up over a threshold, down over a threshold
	gen earn_up_20_hh=0
	replace earn_up_20_hh = 1 if earn_change_hh >=.2000000
	replace earn_up_20_hh=. if earn_change_hh==.
	gen earn_down_20_hh=0
	replace earn_down_20_hh = 1 if earn_change_hh <=-.2000000
	replace earn_down_20_hh=. if earn_change_hh==.
	gen earn_up_5_hh=0
	replace earn_up_5_hh = 1 if earn_change_hh >=.05000000
	replace earn_up_5_hh=. if earn_change_hh==.
	gen earn_down_5_hh=0
	replace earn_down_5_hh = 1 if earn_change_hh <=-.05000000
	replace earn_down_5_hh=. if earn_change_hh==.
	
* Variable for all earnings in HH besides R + partner
gen other_earn=thearn-earnings-earnings_a_sp // might need a better HH earn variable that isn't negative
by SSUID PNUM (year), sort: gen earn_change_oth = ((other_earn-other_earn[_n-1])/other_earn[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
	// testing a mean, then up over a threshold, down over a threshold
	gen earn_up_20_oth=0
	replace earn_up_20_oth = 1 if earn_change_oth >=.2000000
	replace earn_up_20_oth=. if earn_change_oth==.
	gen earn_down_20_oth=0
	replace earn_down_20_oth = 1 if earn_change_oth <=-.2000000
	replace earn_down_20_oth=. if earn_change_oth==.
	gen earn_up_5_oth=0
	replace earn_up_5_oth = 1 if earn_change_oth >=.05000000
	replace earn_up_5_oth=. if earn_change_oth==.
	gen earn_down_5_oth=0
	replace earn_down_5_oth = 1 if earn_change_oth <=-.05000000
	replace earn_down_5_oth=. if earn_change_oth==.
	
//browse thearn tpearn earnings_sp hh_earn other_earn

// Raw hours changes

* First create a variable that indicates percent change YoY
by SSUID PNUM (year), sort: gen hours_change = ((avg_hrs-avg_hrs[_n-1])/avg_hrs[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]
browse SSUID PNUM year avg_hrs hours_change

	// testing a mean, then up over a threshold, down over a threshold
	gen hours_up_15=0
	replace hours_up_15 = 1 if hours_change >=.1500000
	replace hours_up_15=. if hours_change==.
	gen hours_down_15=0
	replace hours_down_15 = 1 if hours_change <=-.1500000
	replace hours_down_15=. if hours_change==.
	gen hours_up_5=0
	replace hours_up_5 = 1 if hours_change >=.0500000
	replace hours_up_5=. if hours_change==.
	gen hours_down_5=0
	replace hours_down_5 = 1 if hours_change <=-.0500000
	replace hours_down_5=. if hours_change==.
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
	gen hours_up_15_sp=0
	replace hours_up_15_sp = 1 if hours_change_sp >=.1500000
	replace hours_up_15_sp=. if hours_change_sp==.
	gen hours_down_15_sp=0
	replace hours_down_15_sp = 1 if hours_change_sp <=-.1500000
	replace hours_down_15_sp=. if hours_change_sp==.
	gen hours_up_5_sp=0
	replace hours_up_5_sp = 1 if hours_change_sp >=.0500000
	replace hours_up_5_sp=. if hours_change_sp==.
	gen hours_down_5_sp=0
	replace hours_down_5_sp = 1 if hours_change_sp <=-.0500000
	replace hours_down_5_sp=. if hours_change_sp==.

// Wage variables

* First create a variable that indicates percent change YoY - using just job 1 for now, as that's already a lot of variables
foreach var in ejb1_payhr1 tjb1_annsal1 tjb1_hourly1 tjb1_wkly1 tjb1_bwkly1 tjb1_mthly1 tjb1_smthly1 tjb1_other1 tjb1_gamt1{
by SSUID PNUM (year), sort: gen `var'_chg = ((`var'-`var'[_n-1])/`var'[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]  
}

egen wage_chg = rowmin (tjb1_annsal1_chg tjb1_hourly1_chg tjb1_wkly1_chg tjb1_bwkly1_chg tjb1_mthly1_chg tjb1_smthly1_chg tjb1_other1_chg tjb1_gamt1_chg)
browse SSUID PNUM year wage_chg tjb1_annsal1_chg tjb1_hourly1_chg tjb1_wkly1_chg tjb1_bwkly1_chg tjb1_mthly1_chg tjb1_smthly1_chg tjb1_other1_chg tjb1_gamt1_chg // need to go back to annual file and fix ejb1_payhr1 to not be a mean

	// testing a mean, then up over a threshold, down over a threshold
	gen wages_up_15=0
	replace wages_up_15 = 1 if wage_chg >=.1500000
	replace wages_up_15=. if wage_chg==.
	gen wages_down_15=0
	replace wages_down_15 = 1 if wage_chg <=-.1500000
	replace wages_down_15=. if wage_chg==.
	gen wages_up_5=0
	replace wages_up_5 = 1 if wage_chg >=.0500000
	replace wages_up_5=. if wage_chg==.
	gen wages_down_5=0
	replace wages_down_5 = 1 if wage_chg <=-.0500000
	replace wages_down_5=. if wage_chg==.
	// browse SSUID PNUM year avg_hrs hours_change hours_up hours_down

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
	gen wages_up_15_sp=0
	replace wages_up_15_sp = 1 if wage_chg_sp >=.1500000
	replace wages_up_15_sp=. if wage_chg_sp==.
	gen wages_down_15_sp=0
	replace wages_down_15_sp = 1 if wage_chg_sp <=-.1500000
	replace wages_down_15_sp=. if wage_chg_sp==.
	gen wages_up_5_sp=0
	replace wages_up_5_sp = 1 if wage_chg_sp >=.0500000
	replace wages_up_5_sp=. if wage_chg_sp==.
	gen wages_down_5_sp=0
	replace wages_down_5_sp = 1 if wage_chg_sp <=-.0500000
	replace wages_down_5_sp=. if wage_chg_sp==.

* then calculate changes
local chg_vars "earn_change earn_change_sp earn_change_hh earn_change_oth hours_change hours_change_sp wage_chg wage_chg_sp earn_up_20 earn_down_20 earn_up_20_sp earn_down_20_sp earn_up_20_hh earn_down_20_hh earn_up_20_oth earn_down_20_oth earn_up_5 earn_down_5 earn_up_5_sp earn_down_5_sp earn_up_5_hh earn_down_5_hh earn_up_5_oth earn_down_5_oth hours_up_15 hours_down_15 hours_up_15_sp hours_down_15_sp hours_up_5 hours_down_5 hours_up_5_sp hours_down_5_sp wages_up_15 wages_down_15 wages_up_15_sp wages_down_15_sp wages_up_5 wages_down_5 wages_up_5_sp wages_down_5_sp"

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

// Testing placing a min earnings threshold to calculate changes in earnings (>$10 in a year)
* Respondent
	by SSUID PNUM (year), sort: gen earn_change_alt = ((earnings-earnings[_n-1])/earnings[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & earnings[_n-1] > 100
	gen earn_up_alt_20=0
	replace earn_up_alt_20 = 1 if earn_change_alt >=.2000000
	replace earn_up_alt_20=. if earn_change_alt==.
	gen earn_down_alt_20=0
	replace earn_down_alt_20 = 1 if earn_change_alt <=-.2000000
	replace earn_down_alt_20=. if earn_change_alt==.
	gen earn_up_alt_5=0
	replace earn_up_alt_5 = 1 if earn_change_alt >=.05000000
	replace earn_up_alt_5=. if earn_change_alt==.
	gen earn_down_alt_5=0
	replace earn_down_alt_5 = 1 if earn_change_alt <=-.05000000
	replace earn_down_alt_5=. if earn_change_alt==.

*Partner
	by SSUID PNUM (year), sort: gen earn_change_alt_sp = ((earnings_a_sp-earnings_a_sp[_n-1])/earnings_a_sp[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & earnings_a_sp[_n-1] > 100
	gen earn_up_alt_20_sp=0
	replace earn_up_alt_20_sp = 1 if earn_change_alt_sp >=.2000000
	replace earn_up_alt_20_sp=. if earn_change_alt_sp==.
	gen earn_down_alt_20_sp=0
	replace earn_down_alt_20_sp = 1 if earn_change_alt_sp <=-.2000000
	replace earn_down_alt_20_sp=. if earn_change_alt_sp==.
	gen earn_up_alt_5_sp=0
	replace earn_up_alt_5_sp = 1 if earn_change_alt_sp >=.05000000
	replace earn_up_alt_5_sp=. if earn_change_alt_sp==.
	gen earn_down_alt_5_sp=0
	replace earn_down_alt_5_sp = 1 if earn_change_alt_sp <=-.05000000
	replace earn_down_alt_5_sp=. if earn_change_alt_sp==.
	
* All earnings in HH besides R
	by SSUID PNUM (year), sort: gen earn_change_alt_hh = ((hh_earn-hh_earn[_n-1])/hh_earn[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & hh_earn[_n-1] > 100
	// testing a mean, then up over a threshold, down over a threshold
	gen earn_up_alt_20_hh=0
	replace earn_up_alt_20_hh = 1 if earn_change_alt_hh >=.2000000
	replace earn_up_alt_20_hh=. if earn_change_alt_hh==.
	gen earn_down_alt_20_hh=0
	replace earn_down_alt_20_hh = 1 if earn_change_alt_hh <=-.2000000
	replace earn_down_alt_20_hh=. if earn_change_alt_hh==.
	gen earn_up_alt_5_hh=0
	replace earn_up_alt_5_hh = 1 if earn_change_alt_hh >=.05000000
	replace earn_up_alt_5_hh=. if earn_change_alt_hh==.
	gen earn_down_alt_5_hh=0
	replace earn_down_alt_5_hh = 1 if earn_change_alt_hh <=-.05000000
	replace earn_down_alt_5_hh=. if earn_change_alt_hh==.
	
* All earnings in HH besides R + partner
	by SSUID PNUM (year), sort: gen earn_change_alt_oth = ((other_earn-other_earn[_n-1])/other_earn[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & other_earn[_n-1] > 100
	// testing a mean, then up over a threshold, down over a threshold
	gen earn_up_alt_20_oth=0
	replace earn_up_alt_20_oth = 1 if earn_change_alt_oth >=.2000000
	replace earn_up_alt_20_oth=. if earn_change_alt_oth==.
	gen earn_down_alt_20_oth=0
	replace earn_down_alt_20_oth = 1 if earn_change_alt_oth <=-.2000000
	replace earn_down_alt_20_oth=. if earn_change_alt_oth==.
	gen earn_up_alt_5_oth=0
	replace earn_up_alt_5_oth = 1 if earn_change_alt_oth >=.05000000
	replace earn_up_alt_5_oth=. if earn_change_alt_oth==.
	gen earn_down_alt_5_oth=0
	replace earn_down_alt_5_oth = 1 if earn_change_alt_oth <=-.05000000
	replace earn_down_alt_5_oth=. if earn_change_alt_oth==.

* then calculate changes
local alt_chg_vars "earn_change_alt earn_change_alt_sp earn_change_alt_hh earn_change_alt_oth earn_up_alt_20 earn_down_alt_20 earn_up_alt_20_sp earn_down_alt_20_sp earn_up_alt_20_hh earn_down_alt_20_hh earn_up_alt_20_oth earn_down_alt_20_oth earn_up_alt_5 earn_down_alt_5 earn_up_alt_5_sp earn_down_alt_5_sp earn_up_alt_5_hh earn_down_alt_5_hh earn_up_alt_5_oth earn_down_alt_5_oth"

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
local job_vars "full_part full_no part_no part_full no_part no_full no_job_chg jobchange betterjob left_preg many_jobs one_job num_jobs_up num_jobs_down full_part_sp full_no_sp part_no_sp part_full_sp no_part_sp no_full_sp no_job_chg_sp jobchange_sp betterjob_sp many_jobs_sp one_job_sp num_jobs_up_sp num_jobs_down_sp"

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

local chg_vars "earn_change earn_change_sp earn_change_hh earn_change_oth hours_change hours_change_sp wage_chg wage_chg_sp earn_up_20 earn_down_20 earn_up_20_sp earn_down_20_sp earn_up_20_hh earn_down_20_hh earn_up_20_oth earn_down_20_oth earn_up_5 earn_down_5 earn_up_5_sp earn_down_5_sp earn_up_5_hh earn_down_5_hh earn_up_5_oth earn_down_5_oth hours_up_15 hours_down_15 hours_up_15_sp hours_down_15_sp hours_up_5 hours_down_5 hours_up_5_sp hours_down_5_sp wages_up_15 wages_down_15 wages_up_15_sp wages_down_15_sp wages_up_5 wages_down_5 wages_up_5_sp wages_down_5_sp"

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

local alt_chg_vars "earn_change_alt earn_change_alt_sp earn_change_alt_hh earn_change_alt_oth earn_up_alt_20 earn_down_alt_20 earn_up_alt_20_sp earn_down_alt_20_sp earn_up_alt_20_hh earn_down_alt_20_hh earn_up_alt_20_oth earn_down_alt_20_oth earn_up_alt_5 earn_down_alt_5 earn_up_alt_5_sp earn_down_alt_5_sp earn_up_alt_5_hh earn_down_alt_5_hh earn_up_alt_5_oth earn_down_alt_5_oth"

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


/*

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
putexcel A18 = "R became earner" R1= "R became earner"
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
*/

save "$SIPP14keep/bw_descriptives.dta", replace
