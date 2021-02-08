********************************************************************************
* DESCRIPTION
********************************************************************************
* Create a file that add to the final women file their relationships as well as
* characteristics of each person in their HH
* The data file used in this script was produced by compute_relationships.do
* and measures_and_sample.do

********************************************************************************
* Create file that retains information for those who match
* to a mother in final sample
********************************************************************************
* To get relationships / attributes

use "$tempdir/relationship_pairs_bymonth.dta", clear

drop RRELIG

// reshape wide to_num relationship to_sex to_age to_race to_educ to_employ to_TAGE_FB to_EMS to_TPEARN to_earnings to_TMWKHRS to_ft_pt to_occ_1 to_occ_2 to_occ_3 to_occ_4 to_occ_5 to_occ_6 to_occ_7,i(SSUID ERESIDENCEID from_num panelmonth) j(lno) 

reshape wide to_num relationship RREL to_sex from_age to_age pairtype from_sex from_race to_race from_educ to_educ from_employ to_employ from_TAGE_FB to_TAGE_FB from_EMS to_EMS from_TPEARN to_TPEARN from_earnings to_earnings from_TMWKHRS to_TMWKHRS from_ft_pt to_ft_pt from_occ_1 to_occ_1 from_occ_2 to_occ_2 from_occ_3 to_occ_3 from_occ_4 to_occ_4 from_occ_5 to_occ_5 from_occ_6 to_occ_6 from_occ_7 to_occ_7 from_EINTTYPE to_EINTTYPE from_whynowork to_whynowork from_leave_job1 to_leave_job1 from_leave_job2 to_leave_job2 from_leave_job3 to_leave_job3 from_leave_job4 to_leave_job4 from_leave_job5 to_leave_job5 from_leave_job6 to_leave_job6 from_leave_job7 to_leave_job7 from_jobchange_1 to_jobchange_1 from_jobchange_2 to_jobchange_2 from_jobchange_3 to_jobchange_3 from_jobchange_4 to_jobchange_4 from_jobchange_5 to_jobchange_5 from_jobchange_6 to_jobchange_6 from_jobchange_7 to_jobchange_7 from_jobtype_1 to_jobtype_1 from_jobtype_2 to_jobtype_2 from_jobtype_3 to_jobtype_3 from_jobtype_4 to_jobtype_4 from_jobtype_5 to_jobtype_5 from_jobtype_6 to_jobtype_6 from_jobtype_7 to_jobtype_7 from_pov_level to_pov_level,i(SSUID ERESIDENCEID from_num panelmonth) j(lno)

rename from_num PNUM

save "$tempdir/relationship_details_wide", replace 

* Final sample file:
use "$SIPP14keep/sipp14tpearn_all", clear

// Make the six digit identifier for residence addresses numeric to match the merge file
replace ERESIDENCEID=subinstr(ERESIDENCEID,"A","1",.)
replace ERESIDENCEID=subinstr(ERESIDENCEID,"B","2",.)
replace ERESIDENCEID=subinstr(ERESIDENCEID,"C","3",.)
replace ERESIDENCEID=subinstr(ERESIDENCEID,"D","4",.)
replace ERESIDENCEID=subinstr(ERESIDENCEID,"E","5",.)
replace ERESIDENCEID=subinstr(ERESIDENCEID,"F","6",.)
        
destring ERESIDENCEID, replace
	
merge 1:1 SSUID ERESIDENCEID panelmonth PNUM using "$tempdir/relationship_details_wide.dta"

drop if _merge==2

tab hhsize if _merge==1 // confirming that the unmatched in master are all people who live alone, so that is fine.

drop from_* // just want to use the "to" attributes aka others in HH. Will use original file for respondent's characteristics. This will help simplify

save "$SIPP14keep/sipp14tpearn_rel.dta", replace

// union status recodes - compare these to using simplistic gain or lose partner / gain or lose spouse later on

label define ems 1 "Married, spouse present" 2 "Married, spouse absent" 3 "Widowed" 4 "Divorced" 5 "Separated" 6 "Never Married"
label values ems_ehc ems
label values ems ems

tab ems_ehc spouse // some people are "married - spouse absent" - currently not in "spouse" tally, (but they are also not SEPARATED according to them), do we consider them married?. some of these women also have unmarried partner living there
tab ems_ehc partner
// browse SSUID PNUM panelmonth ems_ehc ems spouse partner relationship* if ems_ehc==2

gen marital_status=.
replace marital_status=1 if inlist(ems_ehc,1,2) // for now - considered all married as married
replace marital_status=2 if inlist(ems_ehc,3,4,5,6) & partner>=1 // for now, if married spouse absent and having a partner - considering you married and not counting here. Cohabiting will override if divorced / separated in given month
replace marital_status=3 if ems_ehc==3 & partner==0
replace marital_status=4 if inlist(ems_ehc,4,5) & partner==0
replace marital_status=5 if ems_ehc==6 & partner==0

label define marital_status 1 "Married" 2 "Cohabiting" 3 "Widowed" 4 "Dissolved-Unpartnered" 5 "Never Married- Not partnered"
label values marital_status marital_status

// earner status recodes
gen other_earner=numearner if tpearn==.
replace other_earner=(numearner-1) if tpearn!=.

// browse panelmonth numearner other_earner tpearn to_TPEARN*

// job changes
egen jobchange = rowtotal(jobchange_1-jobchange_7)
replace jobchange=1 if jobchange>=1 & jobchange!=.
replace jobchange=. if tmwkhrs==.

forvalues n=1/22{
	egen to_jobchange`n' = rowtotal(to_jobchange_1`n'-to_jobchange_7`n')
	replace to_jobchange`n'=1 if to_jobchange`n'>=1 & to_jobchange`n'!=.
	replace to_jobchange`n'=. if to_TMWKHRS`n'==.
}

save "$SIPP14keep/sipp14tpearn_rel.dta", replace
