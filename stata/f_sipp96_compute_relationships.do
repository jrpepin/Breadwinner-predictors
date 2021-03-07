*-------------------------------------------------------------------------------
* BREADWINNER PROJECT
* compute_relationships.do
* Kelly Raley and Joanna Pepin
*-------------------------------------------------------------------------------
di "$S_DATE"

********************************************************************************
* DESCRIPTION
********************************************************************************
* This script uses the core and wave 2 topical files to attempt to describe 
* each person's relationship to every other person in the household by month

// Import relationship data
use "$SIPP14keep/sipp96_hhdata.dta", clear

// exploring HH roster
// browse SSUID PNUM panelmonth ehrefper errp erelat* eprlpn*


// Select only necessary variables
keep SSUID ERESIDENCEID PNUM errp panelmonth

bysort SSUID ERESIDENCEID panelmonth: egen person = rank(PNUM)

// Reshape the data
reshape wide PNUM errp,i(SSUID ERESIDENCEID panelmonth) j(person) 

	// https://www.stata.com/statalist/archive/2010-08/msg00825.html - want something like this but for MULTIPLE columns

save "$tempdir/sipp96_hh_rel_wide.dta", replace

use "$SIPP14keep/sipp96_hhdata.dta", clear	
drop erelat* eprlpn* // removing these to avoid confusion - only accurate for wave 2

merge m:1 SSUID ERESIDENCEID panelmonth using "$tempdir/sipp96_hh_rel_wide.dta"

browse PNUM SSUID ERESIDENCEID panelmonth PNUM* errp* in 1/100

forvalues p=1/17{
	replace errp`p' = 99 if PNUM==PNUM`p'
	rename PNUM`p' RRELPNUM`p' // renaming to avoid duplicates with main var
	rename errp`p' RREL`p' // renaming to avoid duplicates with main var
}

save "$tempdir/sipp96_all_HH_rels.dta", replace

// Reshape the data back to long to get pairs
keep ehrefper RRELPNUM* RREL* SSUID ERESIDENCEID PNUM panelmonth

reshape long RRELPNUM RREL,i(SSUID ERESIDENCEID PNUM panelmonth) j(person) 

// Don't keep relationship to self or empty lines
keep if RREL !=99 & !missing(RREL) 

// Add value labels to relationship variables
#delimit ;
label define rel  	1	"Reference person w/ rel. persons"
					2	"Reference Person w/out rel."   
					3	"Spouse of reference person"       
					4	"Child of reference person"        
					5	"Grandchild of reference person"
					6	"Parent of reference person"    
					7	"Brother/sister of reference person"
					8	"Other relative of reference person"
					9	"Foster child of reference person"
					10	"Unmarried partner of reference"  
					11	"Housemate/roommate"    
					12	"Roomer/boarder"                
					13	"Other non-relative of reference"
					99 	"self" ;

#delimit cr

label values RREL  rel

// Peek at the labels and values
fre RREL

// Rename vars
rename PNUM from_num
rename RRELPNUM to_num

egen pair = concat(from_num to_num), punct("_")

save "$tempdir/s96_rel_pairs_bymonth.dta", replace

// trying to get real relationship look-ups from the wave 2 module (since right now, all relationships are to ref person)
use "$tempdir/sipp96_mod2_hhmerge", clear

destring epppnum, gen(PNUM)
rename ssuid SSUID
rename eentaid ERESIDENCEID

forvalues e=1/9{
	rename erelat0`e' erelat`e' // leading 0 causing issues with reshape
	rename eprlpn0`e' eprlpn`e'
}

// Reshape the data to long to get pairs
keep erelat* eprlpn* SSUID ERESIDENCEID PNUM

reshape long erelat eprlpn,i(SSUID ERESIDENCEID PNUM) j(person) 
rename erelat relationship
rename eprlpn RRELPNUM

keep if relationship !=99 & relationship !=-1

egen pair = concat(PNUM RRELPNUM), punct("_")

save "$tempdir/s96_rel_pairs_lookup", replace

//attemping to get true relationship
use "$tempdir/s96_rel_pairs_bymonth.dta", clear

// first need a view of "to_num's" relationship
rename from_num PNUM

merge m:1 SSUID ERESIDENCEID PNUM panelmonth using "$SIPP14keep/sipp96_hhdata.dta", keepusing(errp)
drop _merge

rename PNUM from_num

merge m:1 SSUID ERESIDENCEID pair using "$tempdir/s96_rel_pairs_lookup", keepusing(relationship)

browse if _merge==1

// replace relationship = 99 if to_num==ehrefper & inlist(errp,1,2) & _merge==1
replace relationship = 1 if to_num==ehrefper & errp==3 & _merge==1
replace relationship = 10 if to_num==ehrefper & errp==4 & _merge==1
replace relationship = 40 if to_num==ehrefper & errp==5 & _merge==1
replace relationship = 20 if to_num==ehrefper & errp==6 & _merge==1
replace relationship = 30 if to_num==ehrefper & errp==7 & _merge==1
replace relationship = 55 if to_num==ehrefper & errp==8 & _merge==1
replace relationship = 14 if to_num==ehrefper & errp==9 & _merge==1
replace relationship = 2 if to_num==ehrefper & errp==10 & _merge==1
replace relationship = 61 if to_num==ehrefper & errp==11 & _merge==1
replace relationship = 62 if to_num==ehrefper & errp==12 & _merge==1
replace relationship = 65 if to_num==ehrefper & errp==13 & _merge==1
 
// replace relationship = 99 if from_num==ehrefper & inlist(RREL,1,2) & _merge==1
replace relationship = 1 if from_num==ehrefper & RREL==3 & _merge==1
replace relationship = 20 if from_num==ehrefper & RREL==4 & _merge==1
replace relationship = 41 if from_num==ehrefper & RREL==5 & _merge==1
replace relationship = 10 if from_num==ehrefper & RREL==6 & _merge==1
replace relationship = 30 if from_num==ehrefper & RREL==7 & _merge==1
replace relationship = 55 if from_num==ehrefper & RREL==8 & _merge==1
replace relationship = 24 if from_num==ehrefper & RREL==9 & _merge==1
replace relationship = 2 if from_num==ehrefper & RREL==10 & _merge==1
replace relationship = 61 if from_num==ehrefper & RREL==11 & _merge==1
replace relationship = 62 if from_num==ehrefper & RREL==12 & _merge==1
replace relationship = 65 if from_num==ehrefper & RREL==13 & _merge==1

drop if RREL==. // no info on relationship

tabout RREL errp if relationship==. & _merge==1 using "$results/s96_unmatched_pairs.xls"


save "$tempdir/s96_rel_pairs_full.dta", replace

/*

********************************************************************************
* Reshape data on type 1 individuals,
* creating two records for each pair of coresident
* type 1 people using joinby
********************************************************************************

// Import relationship data, a file with one record per type 1 individual 
use "$SIPP14keep/allmonths14_rec.dta", clear

// Select only necessary variables
keep SSUID ERESIDENCEID PNUM panelmonth TAGE ESEX race educ employ TAGE_FB EMS TPEARN earnings TMWKHRS ft_pt occ* EINTTYPE whynowork leave_job* jobchange_* jobtype_* better_job RMNUMJOBS EFINDJOB EDISABL RDIS_ALT programs ECHLD_MNYN ELIST EWORKMORE hh_move RENROLL ENJ_NOWRK5 EJB*_PAYHR1 TJB*_ANNSAL1 TJB*_HOURLY*1 TJB*_WKLY1 TJB*_BWKLY1 TJB*_MTHLY1 TJB*_SMTHLY1 TJB*_OTHER1 TJB*_GAMT1

save "$tempdir/onehalf.dta", replace

foreach var in PNUM TAGE ESEX race educ employ TAGE_FB EMS TPEARN earnings TMWKHRS ft_pt occ_1 occ_2 occ_3 occ_4 occ_5 occ_6 occ_7 EINTTYPE whynowork leave_job1 leave_job2 leave_job3 leave_job4 leave_job5 leave_job6 leave_job7 jobchange_1 jobchange_2 jobchange_3 jobchange_4 jobchange_5 jobchange_6 jobchange_7 jobtype_1 jobtype_2 jobtype_3 jobtype_4 jobtype_5 jobtype_6 jobtype_7  better_job RMNUMJOBS EFINDJOB EDISABL RDIS_ALT programs ECHLD_MNYN ELIST EWORKMORE hh_move RENROLL ENJ_NOWRK5 EJB1_PAYHR1 TJB1_ANNSAL1 TJB1_HOURLY1 TJB1_WKLY1 TJB1_BWKLY1 TJB1_MTHLY1 TJB1_SMTHLY1 TJB1_OTHER1 TJB1_GAMT1 EJB2_PAYHR1 TJB2_ANNSAL1 TJB2_HOURLY1 TJB2_WKLY1 TJB2_BWKLY1 TJB2_MTHLY1 TJB2_SMTHLY1 TJB2_OTHER1 TJB2_GAMT1 EJB3_PAYHR1 TJB3_ANNSAL1 TJB3_HOURLY1 TJB3_WKLY1 TJB3_BWKLY1 TJB3_MTHLY1 TJB3_SMTHLY1 TJB3_OTHER1 TJB3_GAMT1 EJB4_PAYHR1 TJB4_ANNSAL1 TJB4_HOURLY1 TJB4_WKLY1 TJB4_BWKLY1 TJB4_MTHLY1 TJB4_SMTHLY1 TJB4_OTHER1 TJB4_GAMT1 EJB5_PAYHR1 TJB5_ANNSAL1 TJB5_HOURLY1 TJB5_WKLY1 TJB5_BWKLY1 TJB5_MTHLY1 TJB5_SMTHLY1 TJB5_OTHER1 TJB5_GAMT1{
rename `var' from_`var'
}

// Reshape the data
joinby SSUID ERESIDENCEID panelmonth using "$tempdir/onehalf.dta" 

foreach var in PNUM TAGE ESEX race educ employ TAGE_FB EMS TPEARN earnings TMWKHRS ft_pt occ_1 occ_2 occ_3 occ_4 occ_5 occ_6 occ_7 EINTTYPE whynowork leave_job1 leave_job2 leave_job3 leave_job4 leave_job5 leave_job6 leave_job7 jobchange_1 jobchange_2 jobchange_3 jobchange_4 jobchange_5 jobchange_6 jobchange_7 jobtype_1 jobtype_2 jobtype_3 jobtype_4 jobtype_5 jobtype_6 jobtype_7 better_job RMNUMJOBS EFINDJOB EDISABL RDIS_ALT programs ECHLD_MNYN ELIST EWORKMORE hh_move RENROLL ENJ_NOWRK5 EJB1_PAYHR1 TJB1_ANNSAL1 TJB1_HOURLY1 TJB1_WKLY1 TJB1_BWKLY1 TJB1_MTHLY1 TJB1_SMTHLY1 TJB1_OTHER1 TJB1_GAMT1 EJB2_PAYHR1 TJB2_ANNSAL1 TJB2_HOURLY1 TJB2_WKLY1 TJB2_BWKLY1 TJB2_MTHLY1 TJB2_SMTHLY1 TJB2_OTHER1 TJB2_GAMT1 EJB3_PAYHR1 TJB3_ANNSAL1 TJB3_HOURLY1 TJB3_WKLY1 TJB3_BWKLY1 TJB3_MTHLY1 TJB3_SMTHLY1 TJB3_OTHER1 TJB3_GAMT1 EJB4_PAYHR1 TJB4_ANNSAL1 TJB4_HOURLY1 TJB4_WKLY1 TJB4_BWKLY1 TJB4_MTHLY1 TJB4_SMTHLY1 TJB4_OTHER1 TJB4_GAMT1 EJB5_PAYHR1 TJB5_ANNSAL1 TJB5_HOURLY1 TJB5_WKLY1 TJB5_BWKLY1 TJB5_MTHLY1 TJB5_SMTHLY1 TJB5_OTHER1 TJB5_GAMT1{
rename `var' to_`var'
}

rename from_PNUM from_num
rename to_PNUM to_num

rename from_TAGE from_age
rename to_TAGE to_age

rename from_ESEX from_sex
rename to_ESEX to_sex

// Organize the data to make it easier to see the merged results
sort SSUID ERESIDENCEID panelmonth from_num to_num
order  SSUID ERESIDENCEID panelmonth from_num to_num from_age to_age from_sex to_sex from_race to_race from_educ to_educ from_employ to_employ from_TAGE_FB to_TAGE_FB from_EMS to_EMS from_TPEARN to_TPEARN from_earnings to_earnings from_TMWKHRS to_TMWKHRS from_ft_pt to_ft_pt from_occ_1 to_occ_1 from_occ_2 to_occ_2 from_occ_3 to_occ_3 from_occ_4 to_occ_4 from_occ_5 to_occ_5 from_occ_6 to_occ_6 from_occ_7 to_occ_7 from_EINTTYPE to_EINTTYPE from_whynowork to_whynowork from_leave_job1 to_leave_job1 from_leave_job2 to_leave_job2 from_leave_job3 to_leave_job3 from_leave_job4 to_leave_job4 from_leave_job5 to_leave_job5 from_leave_job6 to_leave_job6 from_leave_job7 to_leave_job7 from_jobchange_1 to_jobchange_1 from_jobchange_2 to_jobchange_2 from_jobchange_3 to_jobchange_3 from_jobchange_4 to_jobchange_4 from_jobchange_5 to_jobchange_5 from_jobchange_6 to_jobchange_6 from_jobchange_7 to_jobchange_7 from_jobtype_1 to_jobtype_1 from_jobtype_2 to_jobtype_2 from_jobtype_3 to_jobtype_3 from_jobtype_4 to_jobtype_4 from_jobtype_5 to_jobtype_5 from_jobtype_6 to_jobtype_6 from_jobtype_7 to_jobtype_7 from_better_job to_better_job from_RMNUMJOBS to_RMNUMJOBS from_EFINDJOB to_EFINDJOB from_EDISABL to_EDISABL from_RDIS_ALT to_RDIS_ALT from_programs to_programs from_ECHLD_MNYN to_ECHLD_MNYN from_ELIST to_ELIST from_EWORKMORE to_EWORKMORE from_hh_move to_hh_move from_RENROLL to_RENROLL from_ENJ_NOWRK5 to_ENJ_NOWRK5 from_EJB1_PAYHR1 to_EJB1_PAYHR1 from_TJB1_ANNSAL1 to_TJB1_ANNSAL1 from_TJB1_HOURLY1 to_TJB1_HOURLY1 from_TJB1_WKLY1 to_TJB1_WKLY1 from_TJB1_BWKLY1 to_TJB1_BWKLY1 from_TJB1_MTHLY1 to_TJB1_MTHLY1 from_TJB1_SMTHLY1 to_TJB1_SMTHLY1 from_TJB1_OTHER1 to_TJB1_OTHER1 from_TJB1_GAMT1 to_TJB1_GAMT1 from_EJB2_PAYHR1 to_EJB2_PAYHR1 from_TJB2_ANNSAL1 to_TJB2_ANNSAL1 from_TJB2_HOURLY1 to_TJB2_HOURLY1 from_TJB2_WKLY1 to_TJB2_WKLY1 from_TJB2_BWKLY1 to_TJB2_BWKLY1 from_TJB2_MTHLY1 to_TJB2_MTHLY1 from_TJB2_SMTHLY1 to_TJB2_SMTHLY1 from_TJB2_OTHER1 to_TJB2_OTHER1 from_TJB2_GAMT1 to_TJB2_GAMT1 from_EJB3_PAYHR1 to_EJB3_PAYHR1 from_TJB3_ANNSAL1 to_TJB3_ANNSAL1 from_TJB3_HOURLY1 to_TJB3_HOURLY1 from_TJB3_WKLY1 to_TJB3_WKLY1 from_TJB3_BWKLY1 to_TJB3_BWKLY1 from_TJB3_MTHLY1 to_TJB3_MTHLY1 from_TJB3_SMTHLY1 to_TJB3_SMTHLY1 from_TJB3_OTHER1 to_TJB3_OTHER1 from_TJB3_GAMT1 to_TJB3_GAMT1 from_EJB4_PAYHR1 to_EJB4_PAYHR1 from_TJB4_ANNSAL1 to_TJB4_ANNSAL1 from_TJB4_HOURLY1 to_TJB4_HOURLY1 from_TJB4_WKLY1 to_TJB4_WKLY1 from_TJB4_BWKLY1 to_TJB4_BWKLY1 from_TJB4_MTHLY1 to_TJB4_MTHLY1 from_TJB4_SMTHLY1 to_TJB4_SMTHLY1 from_TJB4_OTHER1 to_TJB4_OTHER1 from_TJB4_GAMT1 to_TJB4_GAMT1 from_EJB5_PAYHR1 to_EJB5_PAYHR1 from_TJB5_ANNSAL1 to_TJB5_ANNSAL1 from_TJB5_HOURLY1 to_TJB5_HOURLY1 from_TJB5_WKLY1 to_TJB5_WKLY1 from_TJB5_BWKLY1 to_TJB5_BWKLY1 from_TJB5_MTHLY1 to_TJB5_MTHLY1 from_TJB5_SMTHLY1 to_TJB5_SMTHLY1 from_TJB5_OTHER1 to_TJB5_OTHER1 from_TJB5_GAMT1 to_TJB5_GAMT1

* browse // look at the results

// Delete record of individual living with herself
drop if from_num==to_num 

save "$tempdir/allt1pairs.dta", replace

********************************************************************************
* Identify Type 1 people
********************************************************************************
* all in rel_pairs_bymonth are matched in allt1pairs, but not vice versa.
* This is because type 2 people don't have observations in allt1pairs

use "$tempdir/rel_pairs_bymonth.dta", clear

// Combine relationship data with Type 1 data
merge 1:1 SSUID ERESIDENCEID panelmonth from_num to_num using "$tempdir/allt1pairs.dta"

keep if _merge==3
drop 	_merge

// Create a variable identifying these individuals as Type 1
gen pairtype =1

save "$tempdir/t1.dta", replace

********************************************************************************
* Reshape Type 2 data
********************************************************************************

** Import data on type 2 people
use "$SIPP14keep/allmonths14_type2.dta", clear

** Select only necessary variables
keep SSUID ERESIDENCEID panelmonth PNUM ET2_LNO* ET2_SEX* TT2_AGE* TAGE

** reshape the data to have one record for each type 2 person living in a type 1 person's household
reshape long ET2_LNO ET2_SEX TT2_AGE, i(SSUID ERESIDENCEID panelmonth PNUM) j(lno)

rename PNUM from_num
rename TAGE from_age
rename ET2_LNO to_num
rename ET2_SEX to_sex
rename TT2_AGE to_age

** delete variables no longer needed
drop if missing(to_num)

save "$tempdir/type2_pairs.dta", replace

********************************************************************************
* Add type 2 people's demographic information
********************************************************************************

use "$tempdir/rel_pairs_bymonth.dta", clear

// Combine datasets
merge 1:1 SSUID ERESIDENCEID panelmonth from_num to_num using "$tempdir/type2_pairs.dta"

keep if _merge	==3
drop 	_merge

// Create a variable identifying these individuals at Type 1
gen pairtype=2

// Merge type 2 people's data with type 1 people
append using "$tempdir/t1.dta"

label variable pairtype "Is the person a type 1 or type 2 individual?"

tab from_age pairtype

// Recode relationship variable
recode RREL (1=1)(2=2)(3=1)(4=2)(5/19=.), gen(relationship) 
replace relationship=RREL+2 if RREL >=9 & RREL <=13 		// bump rarer codes up to make room for common ones
replace relationship=16 	if RREL==14 | RREL==15 			// combine in-law categories
replace relationship=RREL+1 if RREL >=16 & RREL <=19 		// bump rarer codes up to make room for common ones
replace relationship=3  	if RREL==5 & to_age > from_age 	// parents must be older than children
replace relationship=4  	if RREL==5 & to_age < from_age	// bio child
replace relationship=5  	if RREL==6 & to_age > from_age 	// Step
replace relationship=6  	if RREL==6 & to_age < from_age 	// There are a small number of cases where ages are equal
replace relationship=7  	if RREL==7 & to_age > from_age 	// Adoptive
replace relationship=8  	if RREL==7 & to_age < from_age 	// There are a small number of cases where ages are equal
replace relationship=9  	if RREL==8 & to_age > from_age 	// Grandparent
replace relationship=10 	if RREL==8 & to_age < from_age	// Grandchild

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

label values relationship arel

// Peek at the labels and values
fre relationship
fre relationship if to_num < 100

save "$tempdir/relationship_pairs_bymonth.dta", replace

*/