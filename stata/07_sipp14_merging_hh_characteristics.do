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

reshape wide to_num relationship RREL to_sex from_age to_age pairtype from_sex from_race to_race from_educ to_educ from_employ to_employ from_TAGE_FB to_TAGE_FB from_EMS to_EMS from_TPEARN to_TPEARN from_earnings to_earnings from_TMWKHRS to_TMWKHRS from_ft_pt to_ft_pt from_occ_1 to_occ_1 from_occ_2 to_occ_2 from_occ_3 to_occ_3 from_occ_4 to_occ_4 from_occ_5 to_occ_5 from_occ_6 to_occ_6 from_occ_7 to_occ_7 from_EINTTYPE to_EINTTYPE from_whynowork to_whynowork from_leave_job1 to_leave_job1 from_leave_job2 to_leave_job2 from_leave_job3 to_leave_job3 from_leave_job4 to_leave_job4 from_leave_job5 to_leave_job5 from_leave_job6 to_leave_job6 from_leave_job7 to_leave_job7,i(SSUID ERESIDENCEID from_num panelmonth) j(lno)

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
