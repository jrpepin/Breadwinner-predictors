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

use "$tempdir/s96_relationship_pairs_bymonth.dta", clear // created in "compute relationships"

drop _merge pair

rename errp from_rel
rename RREL to_rel

// bysort SSUID ERESIDENCEID (from_num): gen person2 = _n
// bysort SSUID ERESIDENCEID (from_num): egen person2 = rank(from_num), unique
// bysort SSUID ERESIDENCEID from_num to_num panelmonth: replace person = person[1] 
// browse SSUID ERESIDENCEID from_num to_num panelmonth person
// browse SSUID ERESIDENCEID from_num to_num panelmonth person person2 if SSUID == "489226451420"

// browse SSUID ERESIDENCEID from_num to_num panelmonth person

reshape wide to_num relationship from_rel to_rel from_sex to_sex from_age to_age from_thtotinc from_thpov from_efkind from_tftotinc from_wpfinwgt from_ems from_epnspous from_epnmom from_epndad from_etypmom from_etypdad from_ulftmain from_uentmain from_tpearn from_renroll from_eenlevel from_epdjbthn from_ejobcntr from_edisabl from_edisprev from_ersnowrk from_eawop from_eptwrk from_eptresn from_rmesr from_rwksperm from_ersend1 from_ejbhrs1 from_tpmsum1 from_epayhr1 from_tpyrate1 from_rpyper1 from_ejbind1 from_tjbocc1 from_ersend2 from_ejbhrs2 from_tpmsum2 from_epayhr2 from_tpyrate2 from_rpyper2 from_ejbind2 from_tjbocc2 from_epatyp5 from_emarpth from_exmar from_tfmyear from_tlmyear from_tfrchl from_tfrinhh from_tmomchl from_emomlivh from_efbrthmo from_tfbrthyr from_ragfbrth from_elbirtmo from_tlbirtyr from_efblivnw from_elblivnw from_earnings from_race from_educ from_employ from_jobchange_1 from_jobchange_2 from_better_job from_hourly_est1 from_hourly_est2 from_avg_wk_rate from_avg_mo_hrs from_programs from_benefits to_thtotinc to_thpov to_efkind to_tftotinc to_wpfinwgt to_ems to_epnspous to_epnmom to_epndad to_etypmom to_etypdad to_ulftmain to_uentmain to_tpearn to_renroll to_eenlevel to_epdjbthn to_ejobcntr to_edisabl to_edisprev to_ersnowrk to_eawop to_eptwrk to_eptresn to_rmesr to_rwksperm to_ersend1 to_ejbhrs1 to_tpmsum1 to_epayhr1 to_tpyrate1 to_rpyper1 to_ejbind1 to_tjbocc1 to_ersend2 to_ejbhrs2 to_tpmsum2 to_epayhr2 to_tpyrate2 to_rpyper2 to_ejbind2 to_tjbocc2 to_epatyp5 to_emarpth to_exmar to_tfmyear to_tlmyear to_tfrchl to_tfrinhh to_tmomchl to_emomlivh to_efbrthmo to_tfbrthyr to_ragfbrth to_elbirtmo to_tlbirtyr to_efblivnw to_elblivnw to_earnings to_race to_educ to_employ to_jobchange_1 to_jobchange_2 to_better_job to_hourly_est1 to_hourly_est2 to_avg_wk_rate to_avg_mo_hrs to_programs to_benefits,i(SSUID ERESIDENCEID from_num panelmonth) j(person)

rename from_num PNUM

save "$tempdir/s96_relationship_details_wide", replace 

* Final sample file:
use "$SIPP14keep/sipp96tpearn_all", clear // created in measures and sample

merge 1:1 SSUID ERESIDENCEID panelmonth PNUM using "$tempdir/s96_relationship_details_wide.dta"

drop if _merge==2 // those not in sample

tab hhsize if _merge==1 // confirming that the unmatched in master (_merge==1) are all people who live alone, so that is fine. except confused how they ended up here, because needed children to stay in sample. will revisit this.

drop from_* eprlpn* erelat* // just want to use the "to" attributes aka others in HH. Will use original file for respondent's characteristics. This will help simplify. also removing old person level variables; will use ones I added

save "$SIPP14keep/sipp96tpearn_rel.dta", replace

// union status recodes - compare these to using simplistic gain or lose partner / gain or lose spouse later on - also concerned here, on matching of spouse and marital status

tab ems spouse // some people are "married - spouse absent" - currently not in "spouse" tally, (but they are also not SEPARATED according to them), do we consider them married?. some of these women also have unmarried partner living there
tab ems partner
// browse SSUID PNUM panelmonth ems_ehc ems spouse partner relationship* if ems_ehc==2

gen marital_status=.
replace marital_status=1 if inlist(ems,1,2) // for now - considered all married as married
replace marital_status=2 if inlist(ems,3,4,5,6) & partner>=1 // for now, if married spouse absent and having a partner - considering you married and not counting here. Cohabiting will override if divorced / separated in given month
replace marital_status=3 if ems==3 & partner==0
replace marital_status=4 if inlist(ems,4,5) & partner==0
replace marital_status=5 if ems==6 & partner==0

label define marital_status 1 "Married" 2 "Cohabiting" 3 "Widowed" 4 "Dissolved-Unpartnered" 5 "Never Married- Not partnered"
label values marital_status marital_status

// earner status recodes
browse tpearn epdjbthn
replace tpearn=. if epdjbthn==2

forvalues p=1/17{
replace to_tpearn`p'=. if to_epdjbthn`p'==2
}

drop numearner
egen numearner = rownonmiss(tpearn to_tpearn*)

gen other_earner=numearner if tpearn==.
replace other_earner=(numearner-1) if tpearn!=.

// browse panelmonth numearner other_earner tpearn to_tpearn*

save "$SIPP14keep/sipp96tpearn_rel.dta", replace
