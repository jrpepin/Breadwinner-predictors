*-------------------------------------------------------------------------------
* BREADWINNER PROJECT
* extract_and_merge_files_for_HH.do
* Kelly Raley and Joanna Pepin
*-------------------------------------------------------------------------------
di "$S_DATE"

********************************************************************************
* DESCRIPTION
********************************************************************************
* Extracts key variables from all SIPP 1996 core waves and matches to
* relevant topical modules.

* these files will then be used to create a lookup file to match other HH members
* to mother

* The data files used in this script are the compressed data files that we
* created from the Census data files. 

********************************************************************************
* Read in each original, compressed, data set and extract the key variables
********************************************************************************

clear
* set maxvar 5500 //set the maxvar if not starting from a master project file.

   forvalues w=1/12{
      use "$SIPP1996/sip96l`w'.dta"
   	keep	swave rhcalyr rhcalmn srefmon wpfinwgt ssuid epppnum ehrefper errp eentaid shhadid		/// /* TECHNICAL & HH */
			eppintvw rhchange efkind epnmom epndad etypmom etypdad epnspous ehhnumpp				///
			tpearn  tpmsum* apmsum* tftotinc thtotinc thpov 										/// /* FINANCIAL   */
			erace eorigin esex tage  eeducate tfipsst  ems uentmain ulftmain						/// /* DEMOGRAPHIC */
			tjbocc* ejbind* rmhrswk ejbhrs* eawop rmesr epdjbthn ejobcntr eptwrk eptresn			/// /* EMPLOYMENT & EARNINGS */
			ersend* ersnowrk rpyper* epayhr* tpyrate* rwksperm										///
			rcutyp27 rcutyp21 rcutyp25 rcutyp20 rcutyp24 rhnbrf rhcbrf rhmtrf efsyn epatyn ewicyn	/// /* PROGRAM USAGE */
			renroll eenlevel  epatyp5 	edisabl edisprev											/// /* MISC (enrollment, child care, disability)*/
			
			
	  // gen year = 2012+`w'
      save "$tempdir/sipp96hh`w'", replace
   }

 
clear

// variables I could not find matches for: apearn rhpovt2 thincpov thincpovt2 ems_ehc ajb*_rsend ejb*_jborse tjb*_annsal* tjb*_hourly* tjb*_wkly* tjb*_bwkly* tjb*_mthly* tjb*_smthly* tjb*_other* 	tjb*_gamt* rdis rdis_alt edisany	
// variables that come from topical modules: tage_fb (ragfbirth) tceb (tmomch1 tmomchl tfrchl) tcbyr* (tlbirtyr) tyear_fb (tfbrthyr) tyrcurrmarr (tlmyear) tyrfirstmarr (tfmyear) exmar ejb*_wsmnr (ewsmnr*) ejb*_wsjob(ewsjob*)

********************************************************************************
* Stack all the extracts into a single file 
********************************************************************************

// Import first wave. 
   use "$tempdir/sipp96hh1", clear

// Append the remaining waves
   forvalues w=2/12{
      append using "$tempdir/sipp96hh`w'"
   }

save "$tempdir/sipp96hh_core", replace

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
		tlmyear tfmyear exmar emarpth												/// /* MARRIAGE */

sort ssuid eentaid epppnum swave
		
save "$tempdir/sipp96_mod2_hhmerge", replace


use "$tempdir/sipp96hh_core", clear

sort ssuid eentaid epppnum swave srefmon

merge m:1 ssuid eentaid epppnum using "$tempdir/sipp96_mod2_hhmerge.dta"


// browse ssuid epppnum rhcalyr rhcalmn eppintvw esex swave _merge if _merge==1 // what are defining characteristics of those unmatched? are there any?
tab swave if _merge==1 // okay mostly people in other waves, so probably attrition or new people - will leave in sample for now

drop _merge

********************************************************************************
* Variable recodes
********************************************************************************
// Create a panel month variable ranging from 1(01/2013) to 48 (12/2016)
	gen panelmonth = (rhcalyr-1996)*12+rhcalmn+1
	
// Capitalize variables to be compatible with 2014 and household composition indicators
	rename ssuid SSUID
	rename eentaid ERESIDENCEID
	destring epppnum, gen(PNUM)
	rename rhcalmn monthcode
	rename rhcalyr year
	gen from_num=PNUM // will need these later to match to pairs data
	gen to_num=PNUM // will need these later to match to pairs data

	
// Creating a measure of earnings solely based on wages and not profits and losses
	egen earnings=rowtotal(tpmsum1 tpmsum2), missing
	

* race/ ethnicity: combo of ERACE and EORIGIN
gen race=.
replace race=1 if erace==1 & !inrange(eorigin, 20,28)
replace race=2 if erace==2 & !inrange(eorigin, 20,28)
replace race=3 if erace==4 & !inrange(eorigin, 20,28)
replace race=4 if inrange(eorigin, 20,28)
replace race=5 if erace==3 & !inrange(eorigin, 20,28)

label define race 1 "NH White" 2 "NH Black" 3 "NH Asian" 4 "Hispanic" 5 "Other"
label values race race

drop erace eorigin


* educational attainment
recode eeducate (31/38=1)(39=2)(40/43=3)(44/47=4)(-1=.), gen(educ)
label define educ 1 "Less than HS" 2 "HS Diploma" 3 "Some College" 4 "College Plus"
label values educ educ

drop eeducate


* employment changes

recode rmesr (1=1) (2/5=2) (6/7=3) (8=4) (-1=.), gen(employ)
label define employ 1 "Full Time" 2 "Part Time" 3 "Not Working - Looking" 4 "Not Working - Not Looking" // this is probably oversimplified at the moment
label values employ employ

label define jobchange 0 "No" 1 "Yes"

recode ersend1 (-1=0) (1/15=1), gen(jobchange_1)
recode ersend2 (-1=0) (1/15=1), gen(jobchange_2)
label values jobchange_1 jobchange_2 jobchange

gen better_job = .
replace better_job = 1 if (inlist(ersend1,12,14) | inlist(ersend2,12,14))
replace better_job = 0 if (jobchange_1==1 | jobchange_2==1) & better_job==.


* wages change: revisit this - confused bc only seem to track hourly pay rates
// browse SSUID PNUM epayhr1 tpyrate1 ejbhrs1 tpmsum1
// should I either create an hourly metric for all? need the column w weeks in month...or create annual or monthly wages for those not paid hourly? - this might also be in a topical module, haven't gotten this far 
gen hourly_est1 = .
replace hourly_est1 = tpyrate1 if epayhr1==1
replace hourly_est1 = (tpmsum1 / rwksperm / ejbhrs1) if epayhr1==2
	// browse SSUID PNUM epayhr1 tpyrate1 ejbhrs1 tpmsum1 hourly_est1
	
gen hourly_est2 = .
replace hourly_est2 = tpyrate2 if epayhr2==1
replace hourly_est2 = (tpmsum2 / rwksperm / ejbhrs2) if epayhr2==2
	
egen avg_wk_rate=rowmean(hourly_est1 hourly_est2)

// browse SSUID PNUM epayhr1 tpyrate1 ejbhrs1 tpmsum1 hourly_est1 hourly_est2 avg_wk_rate
	

* hours change: need to create a view of average hours across both job options // browse SSUID ejbhrs1 ejbhrs2 rmhrswk
replace ejbhrs1=. if ejbhrs1==-1
replace ejbhrs2=. if ejbhrs2==-1

egen avg_mo_hrs=rowmean(ejbhrs1 ejbhrs2)

* also do a recode for reference of FT / PT
replace eptwrk=. if eptwrk==-1
	
/* this is from a topical module I did not pull in
	* type of schedule - Each person can have up to 7 jobs, so recoding all 7
	label define jobtype 1 "Regular Day" 2 "Regular Night" 3 "Irregular" 4 "Other"
	forvalues job=1/7{
		recode ejb`job'_wsjob (1=1) (2/3=2) (4/6=3) (7=4), gen(jobtype_`job')
		label values jobtype_`job' jobtype
		drop ejb`job'_wsjob
	}
*/

* Welfare use
foreach var in rcutyp20 rcutyp21 rcutyp24 rcutyp25 rcutyp27 rhnbrf rhcbrf rhmtrf{
replace `var' =0 if `var'==2
}

egen programs = rowtotal ( rcutyp20 rcutyp21 rcutyp24 rcutyp25 rcutyp27 )
egen benefits = rowtotal ( rhnbrf rhcbrf rhmtrf )


//misc variables
* Disability status
// EFINDJOB (seems more restrictive than EDISABL, which is about limits, find job is about difficult finding ANY job) EDISABL RDIS_ALT (alt includes job rrlated disability measures whereas RDIS doesn't, but theeir differences are very neglible so relying on the more comprehensive one)
// relabeling so the Nos are 0 not 2
foreach var in efindjob edisabl rdis_alt{
replace `var' =0 if `var'==2
}


* Child care ease of use
foreach var in echld_mnyn elist eworkmore{
replace `var'=0 if `var'==2
}


* reasons for moving

recode eehc_why (1/3=1) (4/7=2) (8/12=3) (13=4) (14=5) (15=7) (16=6), gen(moves)
label define moves 1 "Family reason" 2 "Job reason" 3 "House/Neighborhood" 4 "Disaster" 5 "Evicted" 6 "Other" 7 "Did not Move"
label values moves moves

recode eehc_why (1=1) (2=2) (3/14=3) (15=4) (16=3), gen(hh_move)
label define hh_move 1 "Relationship Change" 2 "Independence" 3 "Other" 4 "Did not Move"
label values hh_move hh_move


* Reasons for leaving employer
label define leave_job 1 "Fired" 2 "Other Involuntary Reason" 3 "Quit Voluntarily" 4 "Retired" 5 "Childcare-related" 6 "Other personal reason" 7 "Illness" 8 "In School"

forvalues job=1/7{ 
recode ejb`job'_rsend (5=1)(1/4=2)(6=2)(7/9=3)(10=4)(11=5)(12=6)(16=6)(13/14=7)(15=8), gen(leave_job`job')
label values leave_job`job' leave_job
drop ejb`job'_rsend
}

* Reasons for work schedule
label define schedule 1 "Involuntary" 2 "Pay" 3 "Childcare" 4 "Other Voluntary"

forvalues job=1/7{
recode ejb`job'_wsmnr (1/3=1) (4=2) (5=3) (6/8=4), gen(why_schedule`job') 
label values why_schedule`job' schedule
drop ejb`job'_wsmnr
}

* Why not working - this is a series of variables not one variable, so first checking for how many people gave more than one reason, then recoding
forvalues n=1/12{
replace enj_nowrk`n'=0 if enj_nowrk`n'==2
} // recoding nos to 0 instead of 2

egen count_nowork = rowtotal(enj_nowrk1-enj_nowrk12)
//browse count_nowork ENJ_NO*
tab count_nowork

gen why_nowork=.
forvalues n=1/12{
replace why_nowork = `n' if enj_nowrk`n'==1 & count_nowork==1
}

replace why_nowork=13 if count_nowork>=2 & !missing(count_nowork)

recode why_nowork (1/3=1) (4=2) (5/6=3) (7=4) (8/9=5) (10=6) (11/12=7) (13=8), gen(whynowork)
label define whynowork 1 "Illness" 2 "Retired" 3 "Child related" 4 "In School" 5 "Involuntary" 6 "Voluntary" 7 "Other" 8 "Multiple reasons"
label values whynowork whynowork

*poverty - think I did this too early // revisit
recode thincpov (0/0.499=1) (.500/1.249=2) (1.250/1.499=3) (1.500/1.849=4) (1.850/1.999=5) (2.000/3.999=6) (4.000/1000=7), gen(pov_level)
label define pov_level 1 "< 50%" 2 "50-125%" 3 "125-150%" 4 "150-185%" 5 "185-200%" 6 "200-400%" 7 "400%+" // http://neocando.case.edu/cando/pdf/CensusPovertyandIncomeIndicators.pdf - to determine thresholds
label values pov_level pov_level
// drop thincpov
*/

save "$SIPP96keep/sipp96_hhdata.dta", replace
