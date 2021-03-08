*-------------------------------------------------------------------------------
* BREADWINNER PROJECT
* create_hhcomp.do
* Kelly Raley and Joanna Pepin
*-------------------------------------------------------------------------------
di "$S_DATE"

********************************************************************************
* DESCRIPTION
********************************************************************************
* Create a monthly file with just household composition, including type2 people

* The data file used in this script was produced by compute_relationships.do

********************************************************************************
* Create database with household composition information.
********************************************************************************
* Generating variables that indicate 1 if match person type and missing otherwise.
* This sets up to count the number of people of relationship type that are in ego's household.

// Load the data
use "$tempdir/s96_relationship_pairs_bymonth.dta", clear

rename from_num PNUM

// Identify relationship codes
fre relationship

label define erelat1p 70 "Parent OR Aunt / Uncle", add // need to revisit this coding. coding is around child / ref person / and brother-sister. need to use mom / dad number vars
label values relationship erelat1p

// Identify children
gen allchildren		=1		if inrange(relationship, 20,24)
gen biochildren		=1 		if relationship==20
gen minorchildren	=1 		if inrange(relationship, 20,24) & to_age < 18
gen minorbiochildren=1 		if relationship==20 & to_age < 18
gen preschoolchildren = 1 	if inrange(relationship, 20,24) & to_age<=5
gen prebiochildren	=1		if relationship==20 & to_age<=5

// Create children's age variable
gen childage		=to_age if allchildren==1 

// Identify partners
gen spouse			=1 		if relationship==1 // married partner
gen partner			=1 		if relationship==2 // unmarried partner

// Identify other household members
gen parents 		=1		if inrange(relationship, 10,14) // including bio, step, adoptive, and in-laws
gen grandparents	=1		if relationship==40
gen grandchildren	=1		if relationship==41
gen siblings		=1		if inrange(relationship, 30, 34)

********************************************************************************
* Create household composition vars
********************************************************************************

// Every person gets a 1 to prep for collapse.
gen hhsize			=1

collapse (count) minorchildren minorbiochildren preschoolchildren prebiochildren spouse partner hhsize parents grandparents grandchildren siblings (min) youngest_age=childage (max) oldest_age=childage, by(SSUID PNUM panelmonth)

* this file has one record per person living with PNUM. Need to add add one to hhsize for PNUM
replace hhsize=hhsize+1

save "$tempdir/s96_hhcomp.dta", replace

sum youngest_age
sum oldest_age
