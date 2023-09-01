*-------------------------------------------------------------------------------
* BREADWINNER PROJECT
* measures and sample.do
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

   forvalues w=1/4{
      use "$SIPP2014/pu2014w`w'_compressed.dta"
   	keep	swave monthcode wpfinwgt ssuid pnum eresidenceid shhadid einttype thhldstatus 						/// /* TECHNICAL */
			epnpar1 epnpar2 rfamref rfamrefwt2 erelrp epar_scrnr epar1typ epar2typ 								/// /* HH MEMBERS & COMP */
			rrel* rrel_pnum* rpnpar1_ehc rpnpar2_ehc rpar1typ_ehc rpar2typ_ehc rpnchild* rchtyp* erefpar erp	///
			rhnumper rhnumperwt2 rhnumu18 rhnumu18wt2 rhnum65over rhnum65ovrt2  								///
			epnspouse epnspous_ehc epncohab epncohab_ehc														///
			rany5 rfamkind rfamkindwt2 rfamnum rfamnumwt2  tcbyr* tyear_fb rchtyp* 								///
			tpearn apearn tjb?_msum ajb?_msum tftotinc thtotinc rhpov rhpovt2 thincpov thincpovt2 				/// /* FINANCIAL   */
			tptotinc tpprpinc tpscininc tsssamt tsscamt tuc*amt tva*amt twcamt									///
			erace eorigin esex tage tage_fb eeduc tceb tcbyr* tyear_fb ems ems_ehc	empf						/// /* DEMOGRAPHIC */
			tyrcurrmarr tyrfirstmarr exmar eehc_why	?mover tehc_mvyr eehc_why									///
			tjb*_occ tjb*_ind tmwkhrs enjflag rmesr rmnumjobs ejb*_bmonth ejb*_emonth ejb*_ptresn*				/// /* EMPLOYMENT */
			ejb*_rsend ejb*_wsmnr enj_nowrk* ejb*_payhr* ejb*_wsjob ajb*_rsend ejb*_jborse rmwkwjb				///
			tjb*_annsal* tjb*_hourly* tjb*_wkly* tjb*_bwkly* tjb*_mthly* tjb*_smthly* tjb*_other* 				/// /* EARNINGS */
			tjb*_gamt* tjb*_msum tpearn																			///
			efindjob edisabl ejobcant rdis rdis_alt edisany														/// /* DISABILITY */
			eeitc eenergy_asst ehouse_any rfsyn tgayn rtanfyn rwicyn rtanfcov ttanf_amt							/// /* PROGRAM USAGE */
			ewelac_mnyn renroll eedgrade eedcred																/// /* ENROLLMENT */
			echld_mnyn epayhelp elist eworkmore																	/// /* CHILD CARE */
			tval_ast thval_ast thval_bank thval_stmf thval_bond thval_rent thval_re thval_oth thval_ret			/// /* WEALTH & ASSETS */
			thval_bus thval_home thval_veh thval_esav thnetworth tnetworth										///
			tinc_ast thinc_ast thinc_bank thinc_bond thinc_stmf thinc_rent thinc_oth							///
			ecsany ecsmnyn tcsamt esupportpay tamountpaid eanykid tnumkids etimespent ealiany ealimnyn taliamt  /// /* CHILD SUPPORT */ rptyn tpt_amt - only wave 1 2014
			rminc_any eminc_typ2yn tminc_amt tpothinc tptrninc 													/// /* MISC SUPPORT */ egnon egnonamt ernon	- 2022 only
			eothsuprt1yn eothsuprt2yn eothsuprt3yn eothsuprt4yn eothsuprt5yn eothsuprt6yn textotamt 			///
			
	  gen year = 2012+`w'
      save "$tempdir/sipp14tpearn`w'_finsupport", replace
   }

   
clear


********************************************************************************
* Stack all the extracts into a single file 
********************************************************************************

// Import first wave. 
   use "$tempdir/sipp14tpearn1_finsupport", clear

// Append the remaining waves
   forvalues w=2/4{
      append using "$tempdir/sipp14tpearn`w'_finsupport"
   }
   
   
	replace wpfinwgt=0 if wpfinwgt==. // per this user note: https://www.census.gov/programs-surveys/sipp/tech-documentation/user-notes/2014-w4-usernotes/2014w4-prob-wpfinwgt.html
	tab monthcode 
	tab monthcode [aweight=wpfinwgt]
   
// mover variable changed between waves 1 and 2 so recoding so file will append properly
gen mover=.
replace mover=tmover if inrange(swave, 2,4)
replace mover=rmover if swave==1
drop tmover rmover
   
********************************************************************************
* Create and format variables
********************************************************************************
// Create a panel month variable ranging from 1(01/2013) to 48 (12/2016)
	gen panelmonth = (swave-1)*12+monthcode
	
// Capitalize variables to be compatible with household composition indicators
	rename ssuid SSUID
	rename eresidenceid ERESIDENCEID
	rename pnum PNUM

// Create a measure of total household earnings per month (with allocated data) and program income 
	* Note that this approach omits the earnings of type 2 people.
    egen thearn = total(tpearn), 	by(SSUID ERESIDENCEID swave monthcode)
	recode tptrninc (.=0)
	egen program_income = total(tptrninc), by(SSUID ERESIDENCEID swave monthcode)
	recode ttanf_amt (.=0)
	egen tanf_amount = total(ttanf_amt), by(SSUID ERESIDENCEID swave monthcode)
	recode tpothinc (.=0)
	egen other_income = total(tpothinc), by(SSUID ERESIDENCEID swave monthcode)
	
// Creating a measure of earnings solely based on wages and not profits and losses
	egen earnings=rowtotal(tjb1_msum tjb2_msum tjb3_msum tjb4_msum tjb5_msum tjb6_msum tjb7_msum), missing
   	egen thearn_alt = total(earnings), 	by(SSUID ERESIDENCEID swave monthcode) // how different is a HH measure based on earnings v. tpearn?
	// browse tftotinc thtotinc thearn thearn_alt
	
	// browse earnings tpearn
	gen check_e=.
	replace check_e=0 if earnings!=tpearn & tpearn!=.
	replace check_e=1 if earnings==tpearn

	tab check_e 
	tab ejb1_jborse check_e, m

// Count number of earners in hh per month
    egen numearner = count(tpearn),	by(SSUID ERESIDENCEID swave monthcode)

// Create an indicator of first wave of observation for this individual

    egen first_wave = min(swave), by(SSUID PNUM)	
	
// Create an indictor of the birth year of the first child 
    gen yrfirstbirth = tcbyr_1 

	* If a birth of the second child or later is earlier than the year of the first child's birth,
	* replace the yrfirstbirth with the date of the firstborn.
	forvalues birth = 2/12 {
		replace yrfirstbirth = tcbyr_`birth' if tcbyr_`birth' < yrfirstbirth
	}
	

	// browse tyear_fb yrfirstbirth tcbyr_1
	// browse tcbyr_1 tcbyr_2 tcbyr_3 if tcbyr_1 > tcbyr_2
	
	gen bcheck=.
	replace bcheck=1 if yrfirstbirth==tyear_fb
	replace bcheck=0 if yrfirstbirth!=tyear_fb
	
// create an indicator of birth year of the last child
	egen yrlastbirth = rowmax(tcbyr_1-tcbyr_7)
	bysort SSUID PNUM (yrlastbirth): replace yrlastbirth=yrlastbirth[1] // for some reason, fertility history is inconsistently missing or filled in for mothers who seem to have babies in some years and not others

// Create an indicator of how many years have elapsed since individual's last birth
   gen durmom=year-yrlastbirth if !missing(yrlastbirth)

// Create an indicator of how many years have elapsed since individual's first birth
* Note: I want to be able to capture negatives in this case, because we want the year prior to women bcoming a mother if she did in the panel. However, if she had her first baby in 2014, all her tcbyr's will be blank in the 2013 survey (since they only ask that question to parents) -- I need to copy the value of her yr of first birth to all nulls before then to get the appropriate calculation. example browse SSUID PNUM yrfirstbirth year tcbyr_1 if SSUID == "000114552134"
bysort SSUID PNUM (yrfirstbirth): replace yrfirstbirth = yrfirstbirth[1] 

gen durmom_1st=year-yrfirstbirth if !missing(yrfirstbirth) // to get the duration 1 year prior to respondent becoming a mom
   
gen mom_panel=.
replace mom_panel=1 if inrange(yrfirstbirth, 2013, 2016) // flag if became a mom during panel to use later

sort SSUID PNUM year panelmonth
browse SSUID PNUM year panelmonth swave durmom durmom_1st first_wave yrfirstbirth yrlastbirth tcbyr_* if inlist(SSUID, "000418500162", "000418209903", "000418334944")
// durmom seems wrong - okay bc yearbirth seems missing sometimes when it shouldn't be, because tcbyr is just missing some years...

* Note that durmom=0 when child was born in this year, but some of the children born in the previous calendar
* year are still < 1. So if we want the percentage of mothers breadwinning in the year of the child's birth
* we should check to see if breadwinning is much different between durmom=0 or durmom=1. We could use durmom=1
* because many of those with durmom=0 will have spent much of the year not a mother. 

* also, some women gave birth to their first child after the reference year. In this case durmom < 0, but
* we don't have income information for this year in that wave of data. So, durmom < 0 is dropped below
 
// Create a flag if year of first birth is > respondents year of birth+9
   gen 		mybirthyear		= year-tage
   gen 		birthyear_error	= 1 			if mybirthyear+9  > yrfirstbirth & !missing(yrfirstbirth)  // too young
   replace 	birthyear_error	= 1 			if mybirthyear+50 < yrfirstbirth & !missing(yrfirstbirth)  // too old

// create an indicator of age at first birth to be able to compare to NLSY analysis
   gen ageb1=yrfirstbirth-mybirthyear
   
   gen check=.
   replace check=1 if ageb1==tage_fb & tage_fb!=.
   replace check=0 if ageb1!=tage_fb
   
  
// other parental variable recodes
recode eanykid (2=0) // want 1 to be yes and 0 to be no
recode epar_scrnr (2=0) // want 1 to be yes and 0 to be no
recode erp (2=0) // want 1 to be yes and 0 to be no

label define erelrp 1 "Householder with relatives" 2 "Householder with NO relatives" 3 "Spouse (husband/wife)" 4 "Unmarried partner" ///
5 "Child (Biological, Step, Adopted)" 6 "Grandchild" 7 "Parent (Mother/Father)" 8 "Brother/Sister" 9 "Other relative" ///
10 "Foster child" 11 "Housemate/Roommate" 12 "Roomer/Boarder" 13 "Other nonrelative"
label values erelrp erelrp
  
********************************************************************************
* Demographic Variable recodes
********************************************************************************

* age of youngest child: needs to vary with time across the household, will compute once relationships updated. for any given month, identify all children in household, use TAGE and get min TAGE (file 04)

* # of preschool age children: will update this in future code with other HH compositon calculations (file 04)

* race/ ethnicity: combo of ERACE and EORIGIN
gen race=.
replace race=1 if erace==1 & eorigin==2
replace race=2 if erace==2
replace race=3 if erace==3 & eorigin==2
replace race=4 if eorigin==1 & erace!=2
replace race=5 if erace==4 & eorigin==2

label define race 1 "NH White" 2 "NH Black" 3 "NH Asian" 4 "Hispanic" 5 "Other"
label values race race

// drop erace eorigin

* age at 1st birth: this exists as TAGE_FB

* marital status at 1st birth: computed in step 07, need to merge with SSA

* educational attainment: use EEDUC
recode eeduc (31/38=1)(39=2)(40/42=3)(43/46=4), gen(educ)
label define educ 1 "Less than HS" 2 "HS Diploma" 3 "Some College" 4 "College Plus"
label values educ educ

drop eeduc

* subsequent birth: can use TCBYR* to get year of each birth, so will get a flag if that occurs during survey waves.

* partner status: can use ems for marriage. for cohabiting unions, need to use relationship codes. will recode this in a later step (may already happen in step 4)

* employment
recode rmesr (1=1) (2/5=2) (6/7=3) (8=4), gen(employ)
label define employ 1 "Full Time" 2 "Part Time" 3 "Not Working - Looking" 4 "Not Working - Not Looking" // this is probably oversimplified at the moment
label values employ employ

// drop rmesr

* Welfare use
foreach var in eeitc eenergy_asst ehouse_any rfsyn tgayn rtanfyn rwicyn rtanfcov{
replace `var' =0 if `var'==2 | `var'==3
}

egen programs = rowtotal ( rfsyn tgayn rtanfyn rwicyn)

label define sex 1 "Male" 2 "Female"
label values esex sex

save "$tempdir/sipp14tpearn_finsupport_fullsamp", replace


********************************************************************************
**# Create the analytic sample
********************************************************************************
* ALL parental households with minor children (including single moms, single dads, dual earner and single earner two parent families with kids, but EXCLUDING kids who do not live with either parent)
* Remove women who had a birth within last year

// need to wrap my head around information
browse SSUID ERESIDENCEID PNUM year panelmonth epar_scrnr erp rhnumper rhnumu18 erefpar epnpar1 rpnpar1_ehc epnpar2 rpnpar2_ehc epar1typ rpar1typ_ehc epar2typ rpar2typ_ehc erelrp rpnchild* rchtyp* tyear_fb eanykid tnumkids // rrel* rrel_pnum*

browse SSUID ERESIDENCEID PNUM year panelmonth epar_scrnr erp eanykid ecsany tcsamt esupportpay tamountpaid tpearn

browse SSUID ERESIDENCEID PNUM year panelmonth epar_scrnr esex erp rhnumu18 eanykid epnpar1 epnpar2 epar1typ epar2typ erelrp rpnchild1 rpnchild2 rpnchild3 rchtyp1 rchtyp2 rchtyp3 eanykid tnumkids tpearn tcsamt tamountpaid taliamt if inlist(SSUID, "000114285134","000114285765", "000114552134", "000114552343", "398860929258", "398860929473", "332860172149")

// browse SSUID PNUM year panelmonth tpearn earnings tptotinc tptrninc tpothinc tpprpinc tpscininc tminc_amt thearn thtotinc
// browse SSUID PNUM year panelmonth tpearn earnings tptotinc tpscininc tsssamt tsscamt tuc*amt tva*amt twcamt	

// epar_scrnr==1 = first filter
keep if epar_scrnr==1

// some sort of loop through child type, so flagged if any child is either bio or adopted. then use that as a filter + if any kids outside the hh (because might not have bio kids in HH but do have them outside the HH), okay so also need rhnumu18 to know if kids in the HH?
gen any_kid_hh=0
forvalues k=1/19{
	replace any_kid_hh=1 if inrange(rchtyp`k',1,3)
}

gen any_bio_kid=0
forvalues k=1/19{
	replace any_bio_kid=1 if inlist(rchtyp`k',1,3)
}

gen num_kid=0
replace num_kid=1 if inlist(rchtyp1,1,3)
forvalues k=2/19{
	replace num_kid= num_kid + 1 if inlist(rchtyp`k',1,3)
}

gen total_kids=0
replace total_kids=1 if inrange(rchtyp1,1,3)
forvalues k=2/19{
	replace total_kids= total_kids + 1 if inrange(rchtyp`k',1,3)
}

// some also are parents but kid not in HH nor are they supporting outside (prob bc age?) - e.g. 114285765
keep if any_kid_hh==1 | eanykid==1 // so have any kid in hh or any kid outside of HH

// per Jennifer - also remove if had birth that year
gen birth_in_year=0
forvalues y=1/7{
	replace birth_in_year=1 if tcbyr_`y' == year
}

drop if birth_in_year==1

browse SSUID ERESIDENCEID PNUM year panelmonth epar_scrnr esex erp rhnumu18 eanykid epnpar1 epnpar2 epar1typ epar2typ erelrp rpnchild1 rpnchild2 rpnchild3 rchtyp1 rchtyp2 rchtyp3 any_bio_kid eanykid tnumkids tpearn tcsamt tamountpaid taliamt if inlist(SSUID, "000114285134","000114285765", "000114552134", "000114552343", "398860929258", "398860929473", "332860172149")

// problem is I think tamountpaid is annual but tpearn is monthly. so also need to annualize?! yes, child support and earnings are person-month, amount paid is not.

save "$tempdir/sipp14tpearn_finsupport_parents", replace
// browse SSUID PNUM year panelmonth tpearn earnings tptotinc tptrninc tpothinc tpprpinc tpscininc tminc_amt thearn thtotinc
// browse SSUID PNUM year panelmonth tpearn earnings tptotinc tpscininc tsssamt tsscamt tuc*amt tva*amt twcamt	

********************************************************************************
**# Need to annualize before I can do calculations because some measures at different time units
********************************************************************************
gen st_ems = ems
gen end_ems = ems

// Collapse the data by year to create annual measures
collapse 	(sum) 	tpearn tcsamt taliamt earnings thearn thearn_alt thtotinc	///
					tptotinc tptrninc tpothinc tpprpinc tpscininc				///
					tsssamt tsscamt tuc*amt tva*amt twcamt						///
			(mean) 	tamountpaid esex tage_fb tminc_amt							///
			(max) 	any_kid_hh any_bio_kid num_kid eanykid tnumkids total_kids	///
					tage race educ employ							 			///
			(firstnm) 	st_ems													///
			(lastnm) 	end_ems,												///
			by(SSUID PNUM year)
			
gen mom_earnings=0
replace mom_earnings=earnings if esex==2 & any_bio_kid==1

gen mom_cs_paid=0
replace mom_cs_paid = tamountpaid if esex==2 & tamountpaid!=.
replace mom_cs_paid = tcsamt if esex==1

gen dad_earnings=0
replace dad_earnings=earnings if esex==1 & any_bio_kid==1

gen dad_cs_paid=0
replace dad_cs_paid = tamountpaid if esex==1 & tamountpaid!=.
replace dad_cs_paid = tcsamt if esex==2

gen mom_educ=educ if esex==2 & any_bio_kid==1 // only consider "mom" if has bio kid in HH
gen mom_race=race if esex==2 & any_bio_kid==1 // only consider "mom" if has bio kid in HH

gen dad_educ=educ if esex==1 & any_bio_kid==1
gen dad_race=race if esex==1 & any_bio_kid==1

gen mom_bio=0
replace mom_bio=1 if esex==2  & any_bio_kid==1
tab mom_bio if esex==2

gen dad_bio=0
replace dad_bio=1 if esex==1  & any_bio_kid==1
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

egen unemployment = rowtotal(tuc1amt tuc2amt tuc3amt)
egen veterans = rowtotal(tva2amt tva3amt tva4amt tva5amt tva1amt)
egen ssincome = rowtotal(tsssamt tsscamt)

// how are they affording CS?
browse SSUID PNUM year esex earnings thearn tptotinc tptrninc tpothinc tpprpinc tpscininc tamountpaid if tamountpaid > 0 & tamountpaid!=. // income sources for those who paid out child support
browse SSUID PNUM year esex earnings thearn tptotinc tpscininc  tsssamt tsscamt unemployment veterans twcamt tamountpaid if tamountpaid > 0 & tamountpaid!=.

gen paid_out_cs=0
replace paid_out_cs=1 if tamountpaid > 0 & tamountpaid!=.

gen cs_in=0
replace cs_in=1 if tcsamt > 0 & tcsamt !=. 

tab paid_out_cs
tab cs_in // so these are roughly equal amounts

gen earnings_deficit=0
replace earnings_deficit=1 if earnings < tamountpaid & paid_out_cs==1 & tamountpaid!=.

gen totinc_deficit=0
replace totinc_deficit=1 if tptotinc < tamountpaid & paid_out_cs==1 & tamountpaid!=.

gen hh_earn_deficit=0
replace hh_earn_deficit=1 if thearn < tamountpaid & paid_out_cs==1 & tamountpaid!=.

// browse SSUID PNUM year esex earnings thearn tptotinc tptrninc tpothinc tpprpinc tpscininc tamountpaid earnings_deficit  totinc_deficit if tamountpaid > 0 & tamountpaid!=.

gen inc_pct_earnings = earnings / tptotinc
gen inc_pct_other = tpothinc / tptotinc
gen inc_pct_program = tptrninc / tptotinc
gen inc_pct_invest = tpprpinc / tptotinc
gen inc_pct_benefit = tpscininc / tptotinc

gen ssincome_pct= ssincome / tpscininc
gen unemployment_pct= unemployment  / tpscininc
gen veterans_pct= veterans  / tpscininc
gen workerscomp_pct= twcamt  / tpscininc

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

tabstat inc_pct_earnings inc_pct_program inc_pct_other inc_pct_invest inc_pct_benefit if earnings_deficit==1 & esex==2, stats(mean p50) varwidth(30) column(statistics)
tabstat inc_pct_benefit ssincome_pct unemployment_pct veterans_pct workerscomp_pct if earnings_deficit==1 & esex==2, stats(mean p50) varwidth(30) column(statistics)

* Dad
tab paid_out_cs if esex==1
tab earnings_deficit if paid_out_cs==1 &  esex==1
tab totinc_deficit if paid_out_cs==1 &  esex==1
tab hh_earn_deficit if paid_out_cs==1 &  esex==1

tabstat inc_pct_earnings inc_pct_program inc_pct_other inc_pct_invest inc_pct_benefit if earnings_deficit==1 & esex==1, stats(mean p50) varwidth(30) column(statistics)
tabstat inc_pct_benefit ssincome_pct unemployment_pct veterans_pct workerscomp_pct if earnings_deficit==1 & esex==1, stats(mean p50) varwidth(30) column(statistics)


save "$SIPP14keep/annual_finsupport.dta", replace

// okay now need to aggregate at HH level, because this is currently PERSON-level. HH and year? or JUST HH?

collapse	(sum) 	mom_earnings mom_cs_paid dad_earnings dad_cs_paid 		///
					mom_tot_inc mom_prog_inc mom_other_inc mom_invest_inc	///
					mom_benef_inc dad_tot_inc dad_prog_inc dad_other_inc 	///
					dad_invest_inc dad_benef_inc							///
			(max) 	mom_educ mom_race dad_educ dad_race mom_bio dad_bio,	///
			by(SSUID year)

label values mom_race dad_race race
label values mom_educ dad_educ educ

gen two_parent_hh=0
replace two_parent_hh=1 if mom_bio==1 & dad_bio==1
tab two_parent_hh // ~54% does that make sense? -  here was 66% https://www.americanprogress.org/article/breadwinning-mothers-continue-u-s-norm/

egen mom_total = rowtotal(mom_earnings mom_cs_paid)
egen dad_total = rowtotal(dad_earnings dad_cs_paid)
egen total = rowtotal(mom_total dad_total)

gen mom_pct = mom_total / total
gen dad_pct = dad_total / total
gen mom_earn_pct = mom_earnings / total
gen mom_cs_pct = mom_cs_paid / total
gen dad_earn_pct = dad_earnings / total
gen dad_cs_pct = dad_cs_paid / total

tabstat mom_pct dad_pct mom_earn_pct mom_cs_pct dad_earn_pct dad_cs_pct, stats(mean p50)
tabstat mom_pct dad_pct mom_earn_pct mom_cs_pct dad_earn_pct dad_cs_pct if two_parent_hh==1, stats(mean p50)

tabstat mom_pct dad_pct mom_earn_pct mom_cs_pct dad_earn_pct dad_cs_pct, by(mom_educ)
tabstat mom_pct dad_pct mom_earn_pct mom_cs_pct dad_earn_pct dad_cs_pct, by(dad_educ)