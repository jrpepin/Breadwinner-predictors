*-------------------------------------------------------------------------------
* BREADWINNER PROJECT
* extract_and_merge_files.do
* Kelly Raley and Joanna Pepin
*-------------------------------------------------------------------------------
di "$S_DATE"

********************************************************************************
* DESCRIPTION
********************************************************************************
* Extracts key variables from all SIPP 2014 waves and creates the analytic sample.

* The data files used in this script are the compressed data files that we
* created from the Census data files. 

********************************************************************************
* Read in each original, compressed, data set and extract the key variables
********************************************************************************
clear
* set maxvar 5500 //set the maxvar if not starting from a master project file.

   forvalues w=1/12{
      use "$SIPP1996/sip96l`w'.dta"
   	keep	swave rhcalyr rhcalmn srefmon wpfinwgt ssuid epppnum eentaid shhadid eppintvw rhchange	/// /* TECHNICAL */
			tpearn  tpmsum* apmsum* tftotinc thtotinc thpov 										/// /* FINANCIAL   */
			erace eorigin esex tage  eeducate   ems uentmain ulftmain								/// /* DEMOGRAPHIC */
			tjbocc* ejbind* rmhrswk ejbhrs* eawop rmesr epdjbthn ejobcntr eptwrk eptresn			/// /* EMPLOYMENT & EARNINGS */
			ersend* ersnowrk rpyper* epayhr* tpyrate* rwksperm										///
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
use "$SIPP1996/sip96t2.dta", clear

keep 	swave wpfinwgt ssuid epppnum eentaid shhadid eppintvw erelat* eprlpn*		/// /* TECHNICAL & HH */
		tfbrthyr efbrthmo tlbirtyr elbirtmo ragfbrth tmomchl tfrchl 				/// /* FERTILITY */
		emomlivh tfrinhh efblivnw elblivnw											///
		tlmyear tfmyear exmar emarpth												/// /* MARRIAGE */

sort ssuid eentaid epppnum swave
		
save "$tempdir/sipp96_mod2_merge", replace


use "$tempdir/sipp96tpearn_core", clear

sort ssuid eentaid epppnum swave srefmon

merge m:1 ssuid eentaid epppnum using "$tempdir/sipp96_mod2_merge.dta"

browse ssuid epppnum rhcalyr rhcalmn eppintvw tfbrthyr tlbirtyr

browse ssuid epppnum rhcalyr rhcalmn eppintvw esex swave _merge if _merge==1 // what are defining characteristics of those unmatched? are there any?
tab swave if _merge==1 // okay mostly people in other waves, so probably attrition or new people - will leave in sample for now


save "$SIPP14keep/sipp96_data.dta", replace