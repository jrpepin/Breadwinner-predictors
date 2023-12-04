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
* Unlike the 2014 SIPP, when HH relationships are asked in every wave, detailed
* HH relationships are only asked in the wave 2 topical module

// Import relationship data
use "$SIPP96keep/sipp96_hhdata.dta", clear

// exploring HH roster
// browse SSUID PNUM panelmonth ehrefper errp erelat* eprlpn*


// Select only necessary variables
keep SSUID ERESIDENCEID PNUM errp panelmonth

bysort SSUID ERESIDENCEID panelmonth: egen person = rank(PNUM)
// bysort SSUID ERESIDENCEID PNUM: replace person = person[1]

// Reshape the data
reshape wide PNUM errp,i(SSUID ERESIDENCEID panelmonth) j(person) 

	// https://www.stata.com/statalist/archive/2010-08/msg00825.html - want something like this but for MULTIPLE columns

compress
save "$tempdir/sipp96_hh_rel_wide.dta", replace

use "$SIPP96keep/sipp96_hhdata.dta", clear	
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

merge m:1 SSUID ERESIDENCEID PNUM panelmonth using "$SIPP96keep/sipp96_hhdata.dta", keepusing(errp)
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

tabout RREL errp if relationship==. & _merge==1 using "$results/s96_unmatched_pairs.xls", replace

preserve
collapse (min) minrel=relationship (max) maxrel=relationship (p50) commonrel=relationship (mean) relationship, by(RREL errp)
restore

// recoding remaining missing - this was all done based on a manual assessment of relationships
replace relationship = 99 if errp == 1 & RREL == 1 & _merge==1 & relationship==.
replace relationship = 99 if errp == 1 & RREL == 2 & _merge==1 & relationship==.
replace relationship = 1 if errp == 1 & RREL == 3 & _merge==1 & relationship==.
replace relationship = 20 if errp == 1 & RREL == 4 & _merge==1 & relationship==.
replace relationship = 41 if errp == 1 & RREL == 5 & _merge==1 & relationship==.
replace relationship = 10 if errp == 1 & RREL == 6 & _merge==1 & relationship==.
replace relationship = 30 if errp == 1 & RREL == 7 & _merge==1 & relationship==.
replace relationship = 55 if errp == 1 & RREL == 8 & _merge==1 & relationship==.
replace relationship = 24 if errp == 1 & RREL == 9 & _merge==1 & relationship==.
replace relationship = 2 if errp == 1 & RREL == 10 & _merge==1 & relationship==.
replace relationship = 61 if errp == 1 & RREL == 11 & _merge==1 & relationship==.
replace relationship = 62 if errp == 1 & RREL == 12 & _merge==1 & relationship==.
replace relationship = 65 if errp == 1 & RREL == 13 & _merge==1 & relationship==.
replace relationship = 99 if errp == 2 & RREL == 1 & _merge==1 & relationship==.
replace relationship = 99 if errp == 2 & RREL == 2 & _merge==1 & relationship==.
replace relationship = 1 if errp == 2 & RREL == 3 & _merge==1 & relationship==.
replace relationship = 10 if errp == 2 & RREL == 4 & _merge==1 & relationship==.
replace relationship = 41 if errp == 2 & RREL == 5 & _merge==1 & relationship==.
replace relationship = 10 if errp == 2 & RREL == 6 & _merge==1 & relationship==.
replace relationship = 30 if errp == 2 & RREL == 7 & _merge==1 & relationship==.
replace relationship = 55 if errp == 2 & RREL == 8 & _merge==1 & relationship==.
replace relationship = 24 if errp == 2 & RREL == 9 & _merge==1 & relationship==.
replace relationship = 2 if errp == 2 & RREL == 10 & _merge==1 & relationship==.
replace relationship = 61 if errp == 2 & RREL == 11 & _merge==1 & relationship==.
replace relationship = 52 if errp == 2 & RREL == 12 & _merge==1 & relationship==.
replace relationship = 65 if errp == 2 & RREL == 13 & _merge==1 & relationship==.
replace relationship = 1 if errp == 3 & RREL == 1 & _merge==1 & relationship==.
replace relationship = 1 if errp == 3 & RREL == 2 & _merge==1 & relationship==.
replace relationship = 99 if errp == 3 & RREL == 3 & _merge==1 & relationship==.
replace relationship = 20 if errp == 3 & RREL == 4 & _merge==1 & relationship==.
replace relationship = 41 if errp == 3 & RREL == 5 & _merge==1 & relationship==.
replace relationship = 50 if errp == 3 & RREL == 6 & _merge==1 & relationship==.
replace relationship = 52 if errp == 3 & RREL == 7 & _merge==1 & relationship==.
replace relationship = 55 if errp == 3 & RREL == 8 & _merge==1 & relationship==.
replace relationship = 24 if errp == 3 & RREL == 9 & _merge==1 & relationship==.
replace relationship = 65 if errp == 3 & RREL == 10 & _merge==1 & relationship==.
replace relationship = 61 if errp == 3 & RREL == 11 & _merge==1 & relationship==.
replace relationship = 62 if errp == 3 & RREL == 12 & _merge==1 & relationship==.
replace relationship = 65 if errp == 3 & RREL == 13 & _merge==1 & relationship==.
replace relationship = 10 if errp == 4 & RREL == 1 & _merge==1 & relationship==.
replace relationship = 10 if errp == 4 & RREL == 2 & _merge==1 & relationship==.
replace relationship = 20 if errp == 4 & RREL == 3 & _merge==1 & relationship==.
replace relationship = 30 if errp == 4 & RREL == 4 & _merge==1 & relationship==.
replace relationship = 70 if errp == 4 & RREL == 5 & _merge==1 & relationship==. // could be parent OR aunt/uncle
replace relationship = 40 if errp == 4 & RREL == 6 & _merge==1 & relationship==.
replace relationship = 43 if errp == 4 & RREL == 7 & _merge==1 & relationship==.
replace relationship = 55 if errp == 4 & RREL == 8 & _merge==1 & relationship==.
replace relationship = 32 if errp == 4 & RREL == 9 & _merge==1 & relationship==.
replace relationship = 21 if errp == 4 & RREL == 10 & _merge==1 & relationship==.
replace relationship = 61 if errp == 4 & RREL == 11 & _merge==1 & relationship==.
replace relationship = 62 if errp == 4 & RREL == 12 & _merge==1 & relationship==.
replace relationship = 65 if errp == 4 & RREL == 13 & _merge==1 & relationship==.
replace relationship = 41 if errp == 5 & RREL == 1 & _merge==1 & relationship==.
replace relationship = 41 if errp == 5 & RREL == 2 & _merge==1 & relationship==.
replace relationship = 41 if errp == 5 & RREL == 3 & _merge==1 & relationship==.
replace relationship = 70 if errp == 5 & RREL == 4 & _merge==1 & relationship==. // could be parent OR aunt/uncle
replace relationship = 99 if errp == 5 & RREL == 5 & _merge==1 & relationship==.
replace relationship = 55 if errp == 5 & RREL == 6 & _merge==1 & relationship==.
replace relationship = 55 if errp == 5 & RREL == 7 & _merge==1 & relationship==.
replace relationship = 55 if errp == 5 & RREL == 8 & _merge==1 & relationship==.
replace relationship = 55 if errp == 5 & RREL == 9 & _merge==1 & relationship==.
replace relationship = 41 if errp == 5 & RREL == 10 & _merge==1 & relationship==.
replace relationship = 61 if errp == 5 & RREL == 11 & _merge==1 & relationship==.
replace relationship = 62 if errp == 5 & RREL == 12 & _merge==1 & relationship==.
replace relationship = 65 if errp == 5 & RREL == 13 & _merge==1 & relationship==.
replace relationship = 10 if errp == 6 & RREL == 1 & _merge==1 & relationship==.
replace relationship = 10 if errp == 6 & RREL == 2 & _merge==1 & relationship==.
replace relationship = 50 if errp == 6 & RREL == 3 & _merge==1 & relationship==.
replace relationship = 40 if errp == 6 & RREL == 4 & _merge==1 & relationship==.
replace relationship = 55 if errp == 6 & RREL == 5 & _merge==1 & relationship==.
replace relationship = 99 if errp == 6 & RREL == 6 & _merge==1 & relationship==.
replace relationship = 10 if errp == 6 & RREL == 7 & _merge==1 & relationship==.
replace relationship = 55 if errp == 6 & RREL == 8 & _merge==1 & relationship==.
replace relationship = 55 if errp == 6 & RREL == 9 & _merge==1 & relationship==.
replace relationship = 65 if errp == 6 & RREL == 10 & _merge==1 & relationship==.
replace relationship = 61 if errp == 6 & RREL == 11 & _merge==1 & relationship==.
replace relationship = 62 if errp == 6 & RREL == 12 & _merge==1 & relationship==.
replace relationship = 65 if errp == 6 & RREL == 13 & _merge==1 & relationship==.
replace relationship = 30 if errp == 7 & RREL == 1 & _merge==1 & relationship==.
replace relationship = 30 if errp == 7 & RREL == 2 & _merge==1 & relationship==.
replace relationship = 52 if errp == 7 & RREL == 3 & _merge==1 & relationship==.
replace relationship = 42 if errp == 7 & RREL == 4 & _merge==1 & relationship==.
replace relationship = 55 if errp == 7 & RREL == 5 & _merge==1 & relationship==.
replace relationship = 10 if errp == 7 & RREL == 6 & _merge==1 & relationship==.
replace relationship = 99 if errp == 7 & RREL == 7 & _merge==1 & relationship==.
replace relationship = 55 if errp == 7 & RREL == 8 & _merge==1 & relationship==.
replace relationship = 42 if errp == 7 & RREL == 9 & _merge==1 & relationship==.
replace relationship = 65 if errp == 7 & RREL == 10 & _merge==1 & relationship==.
replace relationship = 61 if errp == 7 & RREL == 11 & _merge==1 & relationship==.
replace relationship = 62 if errp == 7 & RREL == 12 & _merge==1 & relationship==.
replace relationship = 65 if errp == 7 & RREL == 13 & _merge==1 & relationship==.
replace relationship = 24 if errp == 9 & RREL == 1 & _merge==1 & relationship==.
replace relationship = 24 if errp == 9 & RREL == 2 & _merge==1 & relationship==.
replace relationship = 24 if errp == 9 & RREL == 3 & _merge==1 & relationship==.
replace relationship = 32 if errp == 9 & RREL == 4 & _merge==1 & relationship==.
replace relationship = 42 if errp == 9 & RREL == 5 & _merge==1 & relationship==.
replace relationship = 40 if errp == 9 & RREL == 6 & _merge==1 & relationship==.
replace relationship = 42 if errp == 9 & RREL == 7 & _merge==1 & relationship==.
replace relationship = 55 if errp == 9 & RREL == 8 & _merge==1 & relationship==.
replace relationship = 99 if errp == 9 & RREL == 9 & _merge==1 & relationship==.
replace relationship = 24 if errp == 9 & RREL == 10 & _merge==1 & relationship==.
replace relationship = 61 if errp == 9 & RREL == 11 & _merge==1 & relationship==.
replace relationship = 62 if errp == 9 & RREL == 12 & _merge==1 & relationship==.
replace relationship = 65 if errp == 9 & RREL == 13 & _merge==1 & relationship==.
replace relationship = 2 if errp == 10 & RREL == 1 & _merge==1 & relationship==.
replace relationship = 2 if errp == 10 & RREL == 2 & _merge==1 & relationship==.
replace relationship = 65 if errp == 10 & RREL == 3 & _merge==1 & relationship==.
replace relationship = 21 if errp == 10 & RREL == 4 & _merge==1 & relationship==.
replace relationship = 41 if errp == 10 & RREL == 5 & _merge==1 & relationship==.
replace relationship = 65 if errp == 10 & RREL == 6 & _merge==1 & relationship==.
replace relationship = 65 if errp == 10 & RREL == 7 & _merge==1 & relationship==.
replace relationship = 55 if errp == 10 & RREL == 8 & _merge==1 & relationship==.
replace relationship = 24 if errp == 10 & RREL == 9 & _merge==1 & relationship==.
replace relationship = 99 if errp == 10 & RREL == 10 & _merge==1 & relationship==.
replace relationship = 61 if errp == 10 & RREL == 11 & _merge==1 & relationship==.
replace relationship = 62 if errp == 10 & RREL == 12 & _merge==1 & relationship==.
replace relationship = 65 if errp == 10 & RREL == 13 & _merge==1 & relationship==.
replace relationship = 61 if RREL == 11 & _merge==1 & relationship==.
replace relationship = 62 if RREL == 12 & _merge==1 & relationship==.
replace relationship = 65 if RREL == 13 & _merge==1 & relationship==.
replace relationship = 55 if errp == 8 & _merge==1 & relationship==.
replace relationship = 61 if errp == 11 & _merge==1 & relationship==.
replace relationship = 62 if errp == 12 & _merge==1 & relationship==.
replace relationship = 65 if errp == 13 & _merge==1 & relationship==.

browse if relationship==.

save "$tempdir/s96_rel_pairs_full.dta", replace

// now merging demographic info / rest of variables back in

drop _merge

local keepvars "thtotinc thpov efkind tftotinc esex wpfinwgt tage ems epnspous epnmom epndad etypmom etypdad ulftmain uentmain tpearn programs benefits renroll eenlevel epdjbthn ejobcntr edisabl edisprev ersnowrk eawop eptwrk eptresn rmesr rwksperm ersend1 ejbhrs1 tpmsum1 epayhr1 tpyrate1 rpyper1 ejbind1 tjbocc1 ersend2 ejbhrs2 tpmsum2 epayhr2 tpyrate2 rpyper2 ejbind2 tjbocc2 epatyp5 emarpth exmar tfmyear tlmyear tfrchl tfrinhh tmomchl emomlivh efbrthmo tfbrthyr ragfbrth elbirtmo tlbirtyr efblivnw elblivnw earnings race educ employ jobchange_1 jobchange_2 better_job hourly_est1 hourly_est2 avg_wk_rate avg_mo_hrs rmwkwjb"

merge m:1 SSUID ERESIDENCEID from_num panelmonth using "$SIPP96keep/sipp96_hhdata.dta", keepusing(`keepvars')

foreach var in `keepvars'{
    rename `var' from_`var'
}

drop _merge // assuming using only are people who live by themselves

merge m:1 SSUID ERESIDENCEID to_num panelmonth using "$SIPP96keep/sipp96_hhdata.dta", keepusing(`keepvars')

foreach var in `keepvars'{
    rename `var' to_`var'
}

rename from_tage from_age
rename to_tage to_age

rename from_esex from_sex
rename to_esex to_sex

// Organize the data to make it easier to see the merged results
sort SSUID ERESIDENCEID panelmonth from_num to_num

keep if _merge==3 // rest are people who live alone

compress
save "$tempdir/s96_relationship_pairs_bymonth.dta", replace
