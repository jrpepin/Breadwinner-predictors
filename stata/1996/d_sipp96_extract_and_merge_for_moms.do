*-------------------------------------------------------------------------------
* BREADWINNER PROJECT
* extract_and_merge_files.do
* Kelly Raley and Joanna Pepin
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
* Read in each original, compressed, data set and extract the key variables
********************************************************************************
clear
* set maxvar 5500 //set the maxvar if not starting from a master project file.

   forvalues w=1/12{
      use "$SIPP1996/sip96l`w'.dta"
   	keep	swave rhcalyr rhcalmn srefmon wpfinwgt ssuid epppnum ehrefper errp eentaid shhadid		/// /* TECHNICAL */
			eppintvw rhchange epnmom etypmom epndad etypdad epnspous ehhnumpp						///
			tpearn  tpmsum* tbmsum* apmsum* tftotinc thtotinc thpov tprftb*							/// /* FINANCIAL   */
			erace eorigin esex tage  eeducate   ems uentmain ulftmain								/// /* DEMOGRAPHIC */
			rfnkids rfownkid rfoklt18																/// /* KIDS IN FAMILY */
			tjbocc* ejbind* rmhrswk ejbhrs* eawop rmesr epdjbthn ejobcntr eptwrk eptresn			/// /* EMPLOYMENT & EARNINGS */
			ersend* ersnowrk rpyper* epayhr* tpyrate* rwksperm rmwkwjb eclwrk* ebuscntr  egrssb*	///
			rcutyp27 rcutyp21 rcutyp25 rcutyp20 rcutyp24 rhnbrf rhcbrf rhmtrf efsyn epatyn ewicyn	/// /* PROGRAM USAGE */
			renroll eenlevel  epatyp5 	edisabl edisprev											/// /* MISC (enrollment, child care, disability)*/
			
			
	  // gen year = 2012+`w'
      save "$tempdir/sipp96tpearn`w'", replace
   }

 
clear

// variables I could not find matches for: apearn rhpovt2 thincpov thincpovt2 ems_ehc ajb*_rsend ejb*_jborse tjb*_annsal* tjb*_hourly* tjb*_wkly* tjb*_bwkly* tjb*_mthly* tjb*_smthly* tjb*_other* 	tjb*_gamt* rdis rdis_alt edisany	
// variables that come from topical modules: tage_fb (ragfbirth) tceb (tmomch1 tmomchl tfrchl) tcbyr* (tlbirtyr) tyear_fb (tfbrthyr) tyrcurrmarr (tlmyear) tyrfirstmarr (tfmyear) exmar ejb*_wsmnr (ewsmnr*) ejb*_wsjob(ewsjob*)

********************************************************************************
* Stack all the extracts into a single file 
********************************************************************************

// Import first wave. 
   use "$tempdir/sipp96tpearn1", clear

// Append the remaining waves
   forvalues w=2/12{
      append using "$tempdir/sipp96tpearn`w'"
   }

save "$tempdir/sipp96tpearn_core", replace

sort ssuid epppnum rhcalyr rhcalmn
// browse ssuid epppnum rhcalyr rhcalmn tpearn

********************************************************************************
* Merging records from topical module 2 (fertility, marriage, relationships) 
* for variables needed in anaylsis
********************************************************************************
use "$SIPP1996tm/sip96t2.dta", clear

keep 	swave wpfinwgt ssuid epppnum eentaid shhadid eppintvw erelat* eprlpn*		/// /* TECHNICAL & HH */
		tfbrthyr efbrthmo tlbirtyr elbirtmo ragfbrth tmomchl tfrchl 				/// /* FERTILITY */
		emomlivh tfrinhh efblivnw elblivnw											///
		exmar emarpth tfmyear tsmyear tlmyear ewidiv* 								/// /* MARRIAGE */
		tfsyear tftyear tssyear tstyear	tlsyear tltyear								/// /* note: last used for last or ONLY, not first*/

sort ssuid eentaid epppnum swave
		
save "$tempdir/sipp96_mod2_merge", replace


use "$tempdir/sipp96tpearn_core", clear

sort ssuid eentaid epppnum swave srefmon

merge m:1 ssuid eentaid epppnum using "$tempdir/sipp96_mod2_merge.dta"

browse ssuid epppnum rhcalyr rhcalmn eppintvw tfbrthyr tlbirtyr

browse ssuid epppnum rhcalyr rhcalmn eppintvw esex swave _merge if _merge==1 // what are defining characteristics of those unmatched? are there any?
tab swave if _merge==1 // okay mostly people in other waves, so probably attrition or new people - will leave in sample for now

// Create a panel month variable ranging from 1(01/2013) to 48 (12/2016)
	gen panelmonth = (rhcalyr-1996)*12+rhcalmn+1

********************************************************************************
* Trying to use ID numbers to start to identify moms - very crude initial
* pass to HH members - not full relationships, but general presence in HH
********************************************************************************
browse ssuid epppnum epnmom ehrefper epnspous ehhnumpp rhcalmn tfbrthyr tmomchl emomlivh esex tage

destring epppnum, gen(PNUM)

replace epnmom=. if epnmom==9999
replace epndad=. if epndad==9999

bysort ssuid panelmonth (epnmom): egen hhmom1 = min(epnmom)  // this doesn't work if there are 2 moms in the HH, which there could be if multi-generational
bysort ssuid panelmonth (epnmom): egen hhmom2 = max(epnmom) 
bysort ssuid panelmonth (epndad): egen hhdad1 = min(epndad)
bysort ssuid panelmonth (epndad): egen hhdad2 = max(epndad) 
//browse ssuid panelmonth epnmom hhmom1 hhmom2 if ssuid == "019228369159"

gen epnpart =.
replace epnpart = ehrefper if errp==10 // this only captures if you are unmarried partner OF reference person, I need to know, if you are the reference person, do you have an unmarried partner
bysort ssuid panelmonth (epnpart): replace epnpart = epnpart[1]
gen epngrandparent=.
replace epngrandparent = ehrefper if errp==5
bysort ssuid panelmonth (epngrandparent): replace epngrandparent = epngrandparent[1]

// browse ssuid PNUM errp ehrefper epnpart

gen person=.
replace person=1 if PNUM==hhmom1 | PNUM==hhmom2
replace person=2 if PNUM==hhdad1 | PNUM==hhdad2
replace person=3 if (epnmom !=. | epndad!=.) & (PNUM!=hhmom1 & PNUM!=hhdad1 & PNUM!=hhmom2 & PNUM!=hhdad2) // so, struggling here, do I only want to call them a "child" if not parent at all? but what if they are a child and ALSO a parent? will this work BEFORE they have grandkids? let's see
replace person=4 if errp==10 & person==.
replace person=4 if PNUM==epnpart & person==.
replace person=5 if epnspous!=9999 & esex==2 & (PNUM!=hhmom1 & PNUM!=hhdad1 & PNUM!=hhmom2 & PNUM!=hhdad2) & person==. //could ALSO be a child, want to know that first I *think*?
replace person=6 if epnspous!=9999 & esex==1 & (PNUM!=hhmom1 & PNUM!=hhdad1 & PNUM!=hhmom2 & PNUM!=hhdad2) & person==. //could ALSO be a child, want to know that first I *think*?
replace person=7 if PNUM==ehrefper & ehhnumpp==1  & esex==1
replace person=8 if PNUM==ehrefper & ehhnumpp==1  & esex==2
replace person=9 if PNUM==epngrandparent & person==.
replace person=10 if errp==5 & person==.

label define person 1 "Mom" 2 "Dad" 3 "Child" 4 "Unmarried Partner" 5 "Married - Wife" 6 "Married - Husband" 7 "Solo - Male" 8 "Solo - Female" 9 "Grandparent" 10 "Grandchild"
label values person person

browse ssuid epppnum epnmom hhmom1 hhmom2 person esex tage errp ehrefper epnspous ehhnumpp rhcalmn if ssuid == "019228369159"

// okay like 019003754630, 201 has kids, but she is not identified as a mother... (says no mother in HH - is it because her kids don't live with her?) but there are FIVE people in the HH, so who are they?! okay then 202 is one of her children I PRESUME, bc she is 9/10, and identifies 201 AS the mother in the HH...so only get a mom ID if you're a kid?

* those above not capturing unmarried partners 955052123497
* good example of grandparent / child HH: 955052123318
* browse ssuid epppnum ehhnumpp errp esex tage if errp==2 & ehhnumpp > 1
* browse ssuid epppnum ehhnumpp errp esex tage if ssuid == "019052123067" // unmarried partners considered "not relatives", so 2 people in HH, 1 could be ref w/ no relatives, other then unmarried parner

save "$SIPP96keep/sipp96_data.dta", replace

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

restore