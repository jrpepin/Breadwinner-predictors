*-------------------------------------------------------------------------------
* BREADWINNER PROJECT
* sipp96_child_support.do
* Kimberly McErlean
*-------------------------------------------------------------------------------
di "$S_DATE"

********************************************************************************
* DESCRIPTION
********************************************************************************
* Extracts key variables from all SIPP 1996 core waves and matches to
* relevant topical modules.

* The data files used in this script are the compressed data files that we
* created from the Census data files. 

********************************************************************************
********************************************************************************
* Read in each original, compressed, data set and extract the key variables
********************************************************************************
********************************************************************************

clear
* set maxvar 5500 //set the maxvar if not starting from a master project file.

   forvalues w=1/12{
      use "$SIPP1996/sip96l`w'.dta"
   	keep	swave rhcalyr rhcalmn srefmon wpfinwgt ssuid epppnum ehrefper errp eentaid shhadid		/// /* TECHNICAL */
			eppintvw rhchange epnmom etypmom epndad etypdad epnspous ehhnumpp efkind rfid srotaton	///
			tpearn  tpmsum* apmsum* tftotinc thtotinc thpov tptotinc tpothinc tpprpinc tptrninc 	/// /* FINANCIAL   */
			erace eorigin esex tage  eeducate   ems uentmain ulftmain								/// /* DEMOGRAPHIC */
			rfnkids rfownkid rfoklt18 rdesgpnt														/// /* KIDS IN FAMILY */
			tjbocc* ejbind* rmhrswk ejbhrs* eawop rmesr epdjbthn ejobcntr eptwrk eptresn			/// /* EMPLOYMENT & EARNINGS */
			ersend* ersnowrk rpyper* epayhr* tpyrate* rwksperm rmwkwjb								///
			rcutyp27 rcutyp21 rcutyp25 rcutyp20 rcutyp24 rhnbrf rhcbrf rhmtrf efsyn epatyn ewicyn	/// /* PROGRAM USAGE */
			renroll eenlevel  epatyp5 	edisabl edisprev											/// /* MISC (enrollment, child care, disability)*/
			ecsyn ecsagree er28 t28amt	epssthru er26 t26amt										/// /* CHILD SUPPORT */
			t01amta t01amtk t05amt t07amt t08amt t10amt t20amt t26amt t29amt t51amt t50amt 			/// /* ALT INCOME */
			t56amt tcsagy																			///

			
			
	  // gen year = 2012+`w'
      save "$tempdir/sipp96tpearn`w'_finsupport", replace
   }

 
clear

// sinthhid


********************************************************************************
* Stack all the core extracts into a single file 
********************************************************************************

// Import first wave. 
   use "$tempdir/sipp96tpearn1_finsupport", clear

// Append the remaining waves
   forvalues w=2/12{
      append using "$tempdir/sipp96tpearn`w'_finsupport"
   }

save "$tempdir/sipp96tpearn_core_finsupport", replace

sort ssuid epppnum rhcalyr rhcalmn
// browse ssuid epppnum rhcalyr rhcalmn tpearn

********************************************************************************
********************************************************************************
**# Getting information needed from topical modules
********************************************************************************
********************************************************************************

********************************************************************************
* Topical Module 2
********************************************************************************
use "$SIPP1996tm/sip96t2.dta", clear

keep 	ssuid spanel swave wpfinwgt epppnum eentaid sinthhid shhadid eppintvw	/// /* TECHNICAL & HH */
		erelat* eprlpn* srotaton												///
		tfbrthyr efbrthmo tlbirtyr elbirtmo ragfbrth tmomchl tfrchl 			/// /* FERTILITY */
		emomlivh tfrinhh efblivnw elblivnw										///
		exmar emarpth tfmyear tsmyear tlmyear ewidiv* 							/// /* MARRIAGE */
		tfsyear tftyear tssyear tstyear	tlsyear tltyear							/// /* note: last used for last or ONLY, not first*/
		ebrstate rcitiznt														/// to try to get immigrant status

sort ssuid sinthhid eentaid epppnum swave
		
save "$tempdir/sipp96_mod2_merge_x", replace // added x to distinguish from other BW file; don't want to mess that code up

********************************************************************************
* Topical Module 3
********************************************************************************
use "$SIPP1996/sip96t3.dta", clear

keep 	ssuid spanel swave wpfinwgt epppnum eentaid sinthhid shhadid eppintvw srotaton	/// /* TECHNICAL & HH */
		epvchild epvmancd tpvchpa1 tpvchpa2 tpvchpa3 tpvchpa4 epvmosup 			/// /* CHILD SUPPORT */

sort ssuid sinthhid eentaid epppnum swave
		
save "$tempdir/sipp96_mod3_merge", replace

********************************************************************************
* Topical Module 5
********************************************************************************
use "$SIPP1996/sip96t5.dta", clear

keep 	ssuid spanel swave wpfinwgt epppnum eentaid sinthhid shhadid eppintvw srotaton	/// /* TECHNICAL & HH */
		tactrec4 tactrec3 tactrec2 tactrec1 eamtbac1 tamtsup1 tamtsup2 tsupampd	/// /* CHILD SUPPORT */
		tsupamad tsupamal esuptyp1 tsupnkid esupkdyn esupotnt tsupotam tsupotpa	///
		esupotha esupotpy esupotre esupotrl esupwoag ranyagre epayrecv tsupnagr	///

sort ssuid sinthhid eentaid epppnum swave
		
save "$tempdir/sipp96_mod5_merge", replace

// tbacrec1 tbacrec2

********************************************************************************
* Topical Module 6
********************************************************************************
use "$SIPP1996/sip96t6.dta", clear

keep 	ssuid spanel swave wpfinwgt epppnum eentaid sinthhid shhadid eppintvw srotaton	/// /* TECHNICAL & HH */
		epvchild epvmancd tpvchpa1 tpvchpa2 tpvchpa3 tpvchpa4 epvmosup 			/// /* CHILD SUPPORT */

sort ssuid sinthhid eentaid epppnum swave
		
save "$tempdir/sipp96_mod6_merge", replace

********************************************************************************
* Topical Module 9
********************************************************************************
use "$SIPP1996/sip96t9.dta", clear

keep 	ssuid spanel swave wpfinwgt epppnum eentaid sinthhid shhadid eppintvw srotaton	/// /* TECHNICAL & HH */
		epvchild epvmancd tpvchpa1 tpvchpa2 tpvchpa3 tpvchpa4 epvmosup 			/// /* CHILD SUPPORT */

sort ssuid sinthhid eentaid epppnum swave
		
save "$tempdir/sipp96_mod9_merge", replace

********************************************************************************
* Topical Module 11
********************************************************************************
use "$SIPP1996/sip96t11.dta", clear

keep 	ssuid spanel swave wpfinwgt epppnum eentaid sinthhid shhadid eppintvw srotaton	/// /* TECHNICAL & HH */
		tactrec4 tactrec3 tactrec2 tactrec1 tamtsup1 tamtsup2 tsupampd			/// /* CHILD SUPPORT */
		tsupamad tsupamal esuptyp1 tsupnkid esupkdyn esupotnt tsupotam tsupotpa	///
		esupotha esupotpy esupotre esupotrl esupwoag ranyagre epayrecv tsupnagr	///

sort ssuid sinthhid eentaid epppnum swave
		
save "$tempdir/sipp96_mod11_merge", replace

// eamtbac1

********************************************************************************
* Topical Module 12
********************************************************************************
use "$SIPP1996/sip96t12.dta", clear

keep 	ssuid spanel swave wpfinwgt epppnum eentaid sinthhid shhadid eppintvw srotaton	/// /* TECHNICAL & HH */
		epvchild epvmancd tpvchpa1 tpvchpa2 tpvchpa3 tpvchpa4 epvmosup 			/// /* CHILD SUPPORT */

sort ssuid sinthhid eentaid epppnum swave
		
save "$tempdir/sipp96_mod12_merge", replace

********************************************************************************
********************************************************************************
**# Merging records from topical modules
********************************************************************************
********************************************************************************

use "$tempdir/sipp96tpearn_core_finsupport", clear

sort ssuid eentaid epppnum swave srefmon

merge m:1 ssuid eentaid epppnum using "$tempdir/sipp96_mod2_merge_x.dta" // for tm 2, i want all records, not just that wave, bc a lot of them are fixed characteristics re: timing of first and last birth / marriage

tab swave if _merge==1 // okay mostly people in other waves, so probably attrition or new people - will leave in sample for now
drop _merge

merge m:1 ssuid eentaid epppnum swave using "$tempdir/sipp96_mod3_merge.dta"
drop _merge

merge m:1 ssuid eentaid epppnum swave using "$tempdir/sipp96_mod5_merge.dta"
drop _merge

merge m:1 ssuid eentaid epppnum swave using "$tempdir/sipp96_mod6_merge.dta"
drop if _merge==2
drop _merge

merge m:1 ssuid eentaid epppnum swave using "$tempdir/sipp96_mod9_merge.dta"
drop _merge

merge m:1 ssuid eentaid epppnum swave using "$tempdir/sipp96_mod11_merge.dta"
drop _merge

merge m:1 ssuid eentaid epppnum swave using "$tempdir/sipp96_mod12_merge.dta"
drop _merge

// Create a panel month variable ranging from 1(01/2013) to 48 (12/2016)
	gen panelmonth = (rhcalyr-1996)*12+rhcalmn+1
	
save "$tempdir/sipp96_combined_finsupport.dta", replace

********************************************************************************
** Variable recodes
********************************************************************************

// Capitalize variables to be compatible with 2014 and household composition indicators
	rename ssuid SSUID
	rename eentaid ERESIDENCEID
	rename rhcalmn monthcode
	rename rhcalyr year
	destring epppnum, gen(PNUM)
	
// Create a measure of total household earnings per month (with allocated data)
    egen thearn = total(tpearn), 	by(SSUID ERESIDENCEID swave monthcode)
	
// Creating a measure of earnings solely based on wages and not profits and losses
	egen earnings=rowtotal(tpmsum1 tpmsum2), missing

	// browse earnings tpearn
	gen check_e=.
	replace check_e=0 if earnings!=tpearn & tpearn!=.
	replace check_e=1 if earnings==tpearn

	tab check_e 
	
	egen thearn_alt = total(earnings), 	by(SSUID ERESIDENCEID swave monthcode) // how different is a HH measure based on earnings v. tpearn?
	// browse SSUID thearn thearn_alt

// Count number of earners in hh per month
    egen numearner = count(earnings) if earnings>0,	by(SSUID ERESIDENCEID swave monthcode)

// Create an indicator of first wave of observation for this individual

    egen first_wave = min(swave), by(SSUID PNUM)	
	
// Create an indictor of the birth year of the first child - using the variables that already exist, but leaving names to be consistent with 2014, for when we merge
    gen yrfirstbirth = tfbrthyr 

// create an indicator of birth year of the last child
	gen yrlastbirth = tlbirtyr
	replace yrlastbirth = tfbrthyr if tlbirtyr==-1 // tfbrthyr records first or ONLY birth, so for some, this is blank if only 1 child
	
	browse yrfirstbirth tfbrthyr yrlastbirth tlbirtyr
	replace yrfirstbirth=. if yrfirstbirth == -1
	replace yrlastbirth=. if yrlastbirth == -1

// Create an indicator of how many years have elapsed since individual's last birth
   gen durmom=year-yrlastbirth if !missing(yrlastbirth)
   
   //browse SSUID PNUM year panelmonth yrlastbirth yrfirstbirth tfbrthyr tlbirtyr durmom

// Create an indicator of how many years have elapsed since individual's first birth
gen durmom_1st=year-yrfirstbirth if !missing(yrfirstbirth) // to get the duration 1 year prior to respondent becoming a mom
   
gen mom_panel=.
replace mom_panel=1 if inrange(yrfirstbirth, 1995, 2000) // flag if became a mom during panel to use later - note, since the topical module was in 1996, anyone with a birth during the panel not captured here - I handle this below with the counts of children

* Note that durmom=0 when child was born in this year, but some of the children born in the previous calendar
* year are still < 1. So if we want the percentage of mothers breadwinning in the year of the child's birth
* we should check to see if breadwinning is much different between durmom=0 or durmom=1. We could use durmom=1
* because many of those with durmom=0 will have spent much of the year not a mother. 
 
// Create a flag if year of first birth is > respondents year of birth+9
   gen 		mybirthyear		= year-tage
   gen 		birthyear_error	= 1 			if mybirthyear+9  > yrfirstbirth & !missing(yrfirstbirth)  // too young
   replace 	birthyear_error	= 1 			if mybirthyear+50 < yrfirstbirth & !missing(yrfirstbirth)  // too old

// create an indicator of age at first birth to be able to compare to NLSY analysis
   gen ageb1=yrfirstbirth-mybirthyear
   replace ragfbrth=. if ragfbrth==-1
   gen ageb1_mon=(ragfbrth/12) // ragfbrth is given in months not years

   gen check=.
   replace check=1 if ageb1==round(ageb1_mon) & ageb1_mon!=.
   replace check=0 if ageb1!=round(ageb1_mon) 
   browse mybirthyear yrfirstbirth ageb1 ageb1_mon
   
* race/ ethnicity: combo of ERACE and EORIGIN
gen race=.
replace race=1 if erace==1 & !inrange(eorigin, 20,28)
replace race=2 if erace==2
replace race=3 if erace==4 & !inrange(eorigin, 20,28)
replace race=4 if inrange(eorigin, 20,28) & erace!=2
replace race=5 if erace==3 & !inrange(eorigin, 20,28)

label define race 1 "NH White" 2 "Black" 3 "NH Asian" 4 "Hispanic" 5 "Other"
label values race race
// drop erace eorigin

* whether native- or foreign-born
recode ebrstate (1/56=1)(60/555=2), gen(where_born)
label define where_born 1 "US" 2 "Other Country"
label values where_born where_born

tab where_born rcitiznt, m

* educational attainment: use EEDUC
recode eeducate (31/38=1)(39=2)(40/43=3)(44/47=4)(-1=.), gen(educ)
label define educ 1 "Less than HS" 2 "HS Diploma" 3 "Some College" 4 "College Plus"
label values educ educ
// drop eeducate

* employment
recode rmesr (1=1) (2/5=2) (6/7=3) (8=4) (-1=.), gen(employ)
label define employ 1 "Full Time" 2 "Part Time" 3 "Not Working - Looking" 4 "Not Working - Not Looking" // this is probably oversimplified at the moment
label values employ employ

save "$tempdir/sipp96_combined_finsupport.dta", replace

********************************************************************************
**# Create the analytic sample
********************************************************************************
* ALL parental households with minor children (including single moms, single dads, dual earner and single earner two parent families with kids, but EXCLUDING kids who do not live with either parent)
* Remove women who had a birth within last year

// need to wrap my head around information
browse SSUID PNUM year panelmonth tage esex rdesgpnt epnmom epndad etypmom etypdad errp rfnkids rfownkid rfoklt18

replace epnmom=. if epnmom==9999
replace epndad=. if epndad==9999

bysort SSUID panelmonth (epnmom): egen hhmom1 = min(epnmom)  // this doesn't work if there are 2 moms in the HH, which there could be if multi-generational
bysort SSUID panelmonth (epnmom): egen hhmom2 = max(epnmom) // if there are MORE than 2 moms, then idk. this HH has three moms: 697648074919, so only capturing 2
bysort SSUID panelmonth (epndad): egen hhdad1 = min(epndad)
bysort SSUID panelmonth (epndad): egen hhdad2 = max(epndad)

// browse SSUID PNUM year panelmonth tage esex rdesgpnt hhmom1 hhmom2 epnmom hhdad1 hhdad2 epndad etypmom etypdad errp rfnkids rfownkid rfoklt18

// how to get TYPE 
gen hhmom1_type = etypmom if hhmom1 == epnmom
bysort SSUID panelmonth (hhmom1_type): replace hhmom1_type=hhmom1_type[1]
// browse SSUID PNUM year panelmonth tage esex rdesgpnt hhmom1 hhmom2 epnmom etypmom hhmom1_type
gen hhmom2_type = etypmom if hhmom2 == epnmom
bysort SSUID panelmonth (hhmom2_type): replace hhmom2_type=hhmom2_type[1]
gen hhdad1_type = etypdad if hhdad1 == epndad
bysort SSUID panelmonth (hhdad1_type): replace hhdad1_type=hhdad1_type[1]
gen hhdad2_type = etypdad if hhdad2 == epndad
bysort SSUID panelmonth (hhdad2_type): replace hhdad2_type=hhdad2_type[1]

label values hhmom1_type hhmom2_type etypmom
label values hhdad1_type hhdad2_type etypdad

gen is_mom=0
replace is_mom=1 if PNUM == hhmom1 | PNUM == hhmom2

gen is_dad=0
replace is_dad=1 if PNUM == hhdad1 | PNUM == hhdad2

gen is_bio_mom=0
replace is_bio_mom=1 if ((PNUM == hhmom1) & inlist(hhmom1_type,1,3)) | ((PNUM == hhmom2) & inlist(hhmom2_type,1,3))

gen is_bio_dad=0
replace is_bio_dad=1 if ((PNUM == hhdad1) & inlist(hhdad1_type,1,3)) | ((PNUM == hhdad2) & inlist(hhdad2_type,1,3))

gen parent=0
replace parent=1 if is_mom==1 | is_dad==1

gen bio_parent=0
replace bio_parent=1 if is_bio_mom==1 | is_bio_dad==1

browse SSUID PNUM year panelmonth tage esex rdesgpnt parent bio_parent hhmom1 hhmom2 epnmom hhdad1 hhdad2 epndad etypmom etypdad errp rfnkids rfownkid rfoklt18

// how to figure out if have children OUTSIDE of HH. only in some TMs? also some CS in core, others just in TM? which are right variables
browse SSUID PNUM year swave panelmonth parent bio_parent ecsyn ecsagree er28 t28amt // in core - RECEIVED
	// ecsyn = ever received payment during ref period
	// er28 = in this month - so subset of above
	// ecsagree = support payments ever court ordered or informally agreed to? (so doesn't mean PAID - is what I gather)

egen cs_received_tm = rowtotal(tactrec4 tactrec3 tactrec2 tactrec1) // from TM, also child support received. Not sure if these are meant to match?!
replace cs_received_tm=. if tactrec1==. & tactrec2==. & tactrec3==. & tactrec4==.

browse SSUID PNUM year swave panelmonth parent bio_parent er28 t28amt cs_received_tm tactrec4 tactrec3 tactrec2 tactrec1
	// has both t28 and cs_received: 265860000932 (don't match, even if I aggregate across whole wave)
	// seems like annual number based on this: 283052651691. they have t28amt of 260 each month and cs=3120. 260*12 = 3120. so think I can rely on the core monthly ones.
	// okay duh in question it says: "durign that period (last 12 months)"

browse SSUID PNUM year swave panelmonth parent bio_parent er28 t28amt epvchild epvmancd tpvchpa1 tpvchpa2 tpvchpa3 tpvchpa4 epvmosup tsupnkid esupkdyn tsupampd tsupamad tsupamal  ranyagre tsupnagr  esupotha // not all in same module but similar questions. Think these are actually also annual
	// 019033358630 - has some of these filled in AND not flagged as parent in existing HH. so helpful to know that is NOT comprehensive
	// epvmosup==1, and just ignore for missing months (when no TM?)
	// need to figure out if 5 and 6 are same even though diff questions
	// 019052123373, 019052754174 - good example because has things in both sets of questions - think summing across tpvchpa1-4 gets me close to one of tsupampd/ad/al (honestly not clear the difference) - again think the tpvchpa1-4 is monthly, then the other is annual
	// let's create a new variable to flag in the topical modules that have, but aggregated into 1 variable
	// esupkdyn==1 is for the other months?
	
egen outside_amount_wave = rowtotal(tpvchpa1 tpvchpa2 tpvchpa3 tpvchpa4)
egen outside_amount_annual = rowtotal(tsupampd tsupamad tsupamal)
	
gen support_outside_child=0
replace support_outside_child=1 if epvmosup==1 | esupkdyn==1

gen num_outside_child=0
replace num_outside_child= epvmancd if epvmancd > 0 & epvmancd !=.
replace num_outside_child= tsupnkid if tsupnkid > 0 & tsupnkid !=.

browse SSUID PNUM year swave panelmonth parent bio_parent support_outside_child epvmosup esupkdyn outside_amount_wave outside_amount_annual tpvchpa1 tpvchpa2 tpvchpa3 tpvchpa4 tsupampd tsupamad tsupamal

keep if bio_parent==1 | support_outside_child==1 // so have any bio kid in hh or any kid outside of HH. removing if JUST stepparent

// also remove if had birth that year
gen birth_in_year=0
replace birth_in_year=1 if yrfirstbirth == year | yrlastbirth == year // need to update this also if number of kids in HH goes up? (bc these years are catpured in module 2)
drop if birth_in_year==1

browse SSUID PNUM year swave panelmonth parent bio_parent rfownkid
gen had_birth=0
replace had_birth=1 if rfownkid==rfownkid[_n-1]+1 & SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1]

browse SSUID PNUM year swave panelmonth parent bio_parent rfownkid had_birth
gen had_birth_year = year if had_birth==1
bysort SSUID PNUM year (had_birth_year): replace had_birth_year=had_birth_year[1]

drop if year==had_birth_year

save "$tempdir/sipp96_finsupport_parents", replace

browse SSUID PNUM year monthcode thearn thearn_alt thpov
// create vars to match 2014
gen rhpov = thpov / 12 // currently annual
gen thincpov = thearn / rhpov
browse SSUID PNUM year monthcode thearn thearn_alt thpov rhpov thincpov

********************************************************************************
* Annualize because some topical modules are at YEAR level, others are at wave, then actual data is by month
********************************************************************************
// some variables need to be created / updated first
browse SSUID PNUM year swave panelmonth bio_parent support_outside_child tpearn earnings t28amt outside_amount_wave outside_amount_annual
replace outside_amount_annual = outside_amount_wave * 3 if outside_amount_wave > 0 & outside_amount_wave!=.
replace outside_amount_annual=. if outside_amount_annual <=0
replace outside_amount_wave=. if outside_amount_wave <=0
replace t28amt=. if t28amt <=0

egen tpscininc = rowtotal(t01amta t01amtk t05amt t07amt t08amt t10amt) // attempting to use the information to create this variable that exists in 2014 wave

gen st_ems = ems
gen end_ems = ems

// Collapse the data by year to create annual measures
collapse 	(sum) 	tpearn earnings thearn thearn_alt t28amt thtotinc		///
					tptotinc tptrninc tpothinc tpprpinc tpscininc			///
					t01amta t01amtk t05amt t07amt t08amt t10amt	t51amt		///
					t50amt t56amt rhpov										///
			(mean) 	outside_amount_annual esex 	thpov	thincpov			///
			(max) 	rfnkids rfownkid rfoklt18 num_outside_child				///
					tage race educ employ bio_parent support_outside_child	///
					where_born rcitiznt										///
			(firstnm) 	st_ems												///
			(lastnm) 	end_ems,											///
			by(SSUID PNUM year)
				
gen mom_earnings=0
replace mom_earnings=earnings if esex==2 & bio_parent==1

gen mom_cs_paid=0
replace mom_cs_paid = outside_amount_annual if esex==2 & outside_amount_annual!=.
replace mom_cs_paid = t28amt if esex==1

gen dad_earnings=0
replace dad_earnings=earnings if esex==1 & bio_parent==1

gen dad_cs_paid=0
replace dad_cs_paid = outside_amount_annual if esex==1 & outside_amount_annual!=.
replace dad_cs_paid = t28amt if esex==2

recode rcitiznt (1/2=1)(3=2), gen(citizen)

gen mom_educ=educ if esex==2 & bio_parent==1 // only consider "mom" if has bio kid in HH
gen mom_race=race if esex==2 & bio_parent==1 // only consider "mom" if has bio kid in HH
gen mom_born=where_born if esex==2 & bio_parent==1 // only consider "mom" if has bio kid in HH
gen mom_citizen=citizen if esex==2 & bio_parent==1 // only consider "mom" if has bio kid in HH

gen dad_educ=educ if esex==1 & bio_parent==1
gen dad_race=race if esex==1 & bio_parent==1
gen dad_born=where_born if esex==1 & bio_parent==1
gen dad_citizen=citizen if esex==1 & bio_parent==1 

gen mom_bio=0
replace mom_bio=1 if esex==2  & bio_parent==1
tab mom_bio if esex==2

gen dad_bio=0
replace dad_bio=1 if esex==1  & bio_parent==1
tab dad_bio if esex==1

// other income sources
gen mom_tot_inc=0
replace mom_tot_inc = tptotinc if esex==2
gen mom_prog_inc=0
replace mom_prog_inc = tptrninc if esex==2
gen mom_other_inc=0
replace mom_other_inc = tpothinc if esex==2
gen mom_invest_inc=0
replace mom_invest_inc = tpprpinc if esex==2
gen mom_benef_inc=0
replace mom_benef_inc = tpscininc if esex==2 

gen dad_tot_inc=0
replace dad_tot_inc = tptotinc if esex==1
gen dad_prog_inc=0
replace dad_prog_inc = tptrninc if esex==1
gen dad_other_inc=0
replace dad_other_inc = tpothinc if esex==1
gen dad_invest_inc=0
replace dad_invest_inc = tpprpinc if esex==1
gen dad_benef_inc=0
replace dad_benef_inc = tpscininc if esex==1

egen unemployment = rowtotal(t05amt t07amt)
egen veterans_workers = rowtotal(t08amt t10amt)
egen ssincome = rowtotal(t01amta t01amtk)

rename outside_amount_annual tamountpaid // consistent with 2014

// how are they affording CS?
browse SSUID PNUM year esex earnings thearn tptotinc tptrninc tpothinc tpprpinc tpscininc tamountpaid if tamountpaid > 0 & tamountpaid!=. // income sources for those who paid out child support

gen paid_out_cs=0
replace paid_out_cs=1 if tamountpaid > 0 & tamountpaid!=.

gen cs_in=0
replace cs_in=1 if t28amt > 0 & t28amt !=. 

tab paid_out_cs
tab cs_in // more cs in bc paid out only asked some waves

gen earnings_deficit=0
replace earnings_deficit=1 if earnings < tamountpaid & paid_out_cs==1 & tamountpaid!=. // feels like less of a problem in 1996?

gen totinc_deficit=0
replace totinc_deficit=1 if tptotinc < tamountpaid & paid_out_cs==1 & tamountpaid!=.

gen hh_earn_deficit=0
replace hh_earn_deficit=1 if thearn < tamountpaid & paid_out_cs==1 & tamountpaid!=.

gen inc_pct_earnings = earnings / tptotinc
gen inc_pct_other = tpothinc / tptotinc
gen inc_pct_program = tptrninc / tptotinc
gen inc_pct_invest = tpprpinc / tptotinc
gen inc_pct_benefit = tpscininc / tptotinc

gen ssincome_pct= ssincome / tpscininc
gen unemployment_pct= unemployment  / tpscininc
gen veterans_pct= t08amt  / tpscininc
gen workerscomp_pct= t10amt  / tpscininc

browse tptotinc earnings tpothinc tptrninc tpprpinc tpscininc inc_pct_earnings inc_pct_other inc_pct_program inc_pct_invest inc_pct_benefit

// summaries
* Total
tab paid_out_cs
tab earnings_deficit if paid_out_cs==1
tab totinc_deficit if paid_out_cs==1
tab hh_earn_deficit if paid_out_cs==1

tabstat inc_pct_earnings inc_pct_program inc_pct_other inc_pct_invest inc_pct_benefit if earnings_deficit==1, stats(mean p50) varwidth(30) column(statistics)
tabstat inc_pct_benefit ssincome_pct unemployment_pct veterans_pct workerscomp_pct if earnings_deficit==1, stats(mean p50) varwidth(30) column(statistics)

* Mom
tab paid_out_cs if esex==2
tab earnings_deficit if paid_out_cs==1 &  esex==2
tab totinc_deficit if paid_out_cs==1 &  esex==2
tab hh_earn_deficit if paid_out_cs==1 &  esex==2

tabstat inc_pct_earnings inc_pct_program inc_pct_other inc_pct_invest inc_pct_benefit if earnings_deficit==1 & esex==2, stats(mean p50) varwidth(30) column(statistics) // alt sources of earnings
tabstat inc_pct_benefit ssincome_pct unemployment_pct veterans_pct workerscomp_pct if earnings_deficit==1 & esex==2, stats(mean p50) varwidth(30) column(statistics)

* Dad
tab paid_out_cs if esex==1
tab earnings_deficit if paid_out_cs==1 &  esex==1
tab totinc_deficit if paid_out_cs==1 &  esex==1
tab hh_earn_deficit if paid_out_cs==1 &  esex==1

tabstat inc_pct_earnings inc_pct_program inc_pct_other inc_pct_invest inc_pct_benefit if earnings_deficit==1 & esex==1, stats(mean p50) varwidth(30) column(statistics)
tabstat inc_pct_benefit ssincome_pct unemployment_pct veterans_pct workerscomp_pct if earnings_deficit==1 & esex==1, stats(mean p50) varwidth(30) column(statistics)

gen pov_ratio_alt = thearn / rhpov // takes annualized num and denominator - compare to mean of ratio from months
browse SSUID PNUM year thearn thearn_alt thpov rhpov thincpov pov_ratio_alt // figure out poverty thresholds

save "$SIPP96keep/annual_finsupport1996.dta", replace
**# Bookmark #1
use "$SIPP96keep/annual_finsupport1996.dta", clear

// okay now need to aggregate at HH level, because this is currently PERSON-level. HH and year? or JUST HH?

collapse	(sum) 	mom_earnings mom_cs_paid dad_earnings dad_cs_paid 		///
					mom_tot_inc mom_prog_inc mom_other_inc mom_invest_inc	///
					mom_benef_inc dad_tot_inc dad_prog_inc dad_other_inc 	///
					dad_invest_inc dad_benef_inc							///
			(mean)	pov_ratio_alt thincpov thearn rhpov						///
			(max) 	mom_educ mom_race dad_educ dad_race mom_bio dad_bio		///
					mom_born mom_citizen dad_born dad_citizen,				///
			by(SSUID year)

label values mom_race dad_race race
label values mom_educ dad_educ educ
label values mom_born dad_born where_born

gen two_parent_hh=0
replace two_parent_hh=1 if mom_bio==1 & dad_bio==1
tab two_parent_hh // ~64% is that low for 1996?

egen mom_total = rowtotal(mom_earnings mom_cs_paid)
egen dad_total = rowtotal(dad_earnings dad_cs_paid)
egen total = rowtotal(mom_total dad_total)

gen mom_pct = mom_total / total
gen dad_pct = dad_total / total
gen mom_earn_pct = mom_earnings / total
gen mom_cs_pct = mom_cs_paid / total
gen dad_earn_pct = dad_earnings / total
gen dad_cs_pct = dad_cs_paid / total

tabstat mom_pct dad_pct mom_earn_pct mom_cs_pct dad_earn_pct dad_cs_pct, stats(mean p50) // this is what I used - mean
tabstat mom_pct dad_pct mom_earn_pct mom_cs_pct dad_earn_pct dad_cs_pct if two_parent_hh==1, stats(mean p50)

tabstat mom_pct dad_pct mom_earn_pct mom_cs_pct dad_earn_pct dad_cs_pct, by(mom_educ)
tabstat mom_pct dad_pct mom_earn_pct mom_cs_pct dad_earn_pct dad_cs_pct, by(dad_educ)

save "$SIPP96keep/hh_finsupport1996.dta", replace


********************************************************************************
/* from other paper but may need?
// trying to identify births

// bysort SSUID panelmonth epnmom: distinct PNUM
bysort ssuid panelmonth epnmom: egen mom_children=nvals(PNUM) if epnmom!=.
bysort ssuid panelmonth epnmom: egen mom_bio_children=nvals(PNUM) if etypmom==1

browse ssuid PNUM panelmonth mom_children mom_bio_children rfnkids rfownkid rfoklt18 epnmom epndad etypmom etypdad

preserve
collapse 	(max) mom_children mom_bio_children ///
			(mean) rfnkids rfownkid rfoklt18, by(ssuid shhadid panelmonth epnmom)
			
drop if epnmom==.
gen PNUM = epnmom
rename ssuid SSUID

save "$tempdir/mom_children_lookup96.dta", replace

// then do this and see if births accrue?! so if number of kids go up??

restore
*/