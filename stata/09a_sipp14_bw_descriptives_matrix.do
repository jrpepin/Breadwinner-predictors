*-------------------------------------------------------------------------------
* BREADWINNER PROJECT
* bw_descriptives_matrix.do
* Kelly Raley and Joanna Pepin
*-------------------------------------------------------------------------------
di "$S_DATE"

********************************************************************************
* DESCRIPTION
********************************************************************************
* Splitting the overlapping descriptives related to file 09 because it
* takes very long to run

********************************************************************************
* Import data file
********************************************************************************
use "$SIPP14keep/bw_descriptives.dta", clear

********************************************************************************
* Concurrent changes
********************************************************************************
// this is very long atm
//can't do change variables because that's a mean and has too many values

local vars1 "sing_coh sing_mar coh_mar coh_diss marr_diss marr_wid marr_coh no_status_chg hh_lose earn_lose earn_non hh_gain earn_gain non_earn resp_earn resp_non prekid_gain prekid_lose parents_gain parents_lose birth firstbirth full_part full_no part_no part_full no_part no_full no_job_chg jobchange betterjob left_preg many_jobs one_job numjobs_up numjobs_down full_part_sp full_no_sp part_no_sp part_full_sp no_part_sp no_full_sp no_job_chg_sp jobchange_sp betterjob_sp many_jobs_sp one_job_sp numjobs_up_sp numjobs_down_sp efindjob_in efindjob_out edisabl_in edisabl_out rdis_alt_in rdis_alt_out efindjob_in_sp edisabl_in_sp efindjob_out_sp edisabl_out_sp rdis_alt_in_sp rdis_alt_out_sp welfare_in welfare_out ch_workmore_yes ch_workmore_no childasst_yes childasst_no ch_waitlist_yes ch_waitlist_no move_relat move_indep educ_change enrolled_yes enrolled_no educ_change_sp enrolled_yes_sp enrolled_no_sp earnup20 earndown20 earnup20_sp earndown20_sp earnup20_hh earndown20_hh earnup20_oth earndown20_oth earnup5 earndown5 earnup5_sp earndown5_sp earnup5_hh earndown5_hh earnup5_oth earndown5_oth hours_up15 hoursdown15 hours_up15_sp hoursdown15_sp hours_up5 hoursdown5 hours_up5_sp hoursdown5_sp wagesup15 wagesdown15 wagesup15_sp wagesdown15_sp wagesup5 wagesdown5 wagesup5_sp wagesdown5_sp mom_gain_earn mom_lose_earn part_gain_earn part_lose_earn hh_gain_earn hh_lose_earn oth_gain_earn oth_lose_earn"

local vars2 "sing_coh sing_mar coh_mar coh_diss marr_diss marr_wid marr_coh no_status_chg hh_lose earn_lose earn_non hh_gain earn_gain non_earn resp_earn resp_non prekid_gain prekid_lose parents_gain parents_lose birth firstbirth full_part full_no part_no part_full no_part no_full no_job_chg jobchange betterjob left_preg many_jobs one_job numjobs_up numjobs_down full_part_sp full_no_sp part_no_sp part_full_sp no_part_sp no_full_sp no_job_chg_sp jobchange_sp betterjob_sp many_jobs_sp one_job_sp numjobs_up_sp numjobs_down_sp efindjob_in efindjob_out edisabl_in edisabl_out rdis_alt_in rdis_alt_out efindjob_in_sp edisabl_in_sp efindjob_out_sp edisabl_out_sp rdis_alt_in_sp rdis_alt_out_sp welfare_in welfare_out ch_workmore_yes ch_workmore_no childasst_yes childasst_no ch_waitlist_yes ch_waitlist_no move_relat move_indep educ_change enrolled_yes enrolled_no educ_change_sp enrolled_yes_sp enrolled_no_sp earnup20 earndown20 earnup20_sp earndown20_sp earnup20_hh earndown20_hh earnup20_oth earndown20_oth earnup5 earndown5 earnup5_sp earndown5_sp earnup5_hh earndown5_hh earnup5_oth earndown5_oth hours_up15 hoursdown15 hours_up15_sp hoursdown15_sp hours_up5 hoursdown5 hours_up5_sp hoursdown5_sp wagesup15 wagesdown15 wagesup15_sp wagesdown15_sp wagesup5 wagesdown5 wagesup5_sp wagesdown5_sp mom_gain_earn mom_lose_earn part_gain_earn part_lose_earn hh_gain_earn hh_lose_earn oth_gain_earn oth_lose_earn"

local colu "B C D E F G H I J K L M N O P Q R S T U V W X Y Z AA AB AC AD AE AF AG AH AI AJ AK AL AM AN AO AP AQ AR AS AT AU AV AW AX AY AZ BA BB BC BD BE BF BG BH BI BJ BK BL BM BN BO BP BQ BR BS BT BU BV BW BX BY BZ CA CB CC CD CE CF CG CH CI CJ CK CL CM CN CO CP CQ CR CS CT CU CV CW CX CY CZ DA DB DC DD DE DF DG DH DI DJ DK DL DM DN"

putexcel set "$results/Breadwinner_Characteristics", sheet(matrix) modify

putexcel A2="Single -> Cohabit" B1="Single -> Cohabit"
putexcel A3="Single -> Married" C1="Single -> Married"
putexcel A4="Cohabit -> Married" D1="Cohabit -> Married"
putexcel A5="Cohabit -> Dissolved" E1="Cohabit -> Dissolved"
putexcel A6="Married -> Dissolved" F1="Married -> Dissolved"
putexcel A7="Married -> Widowed" G1="Married -> Widowed"
putexcel A8="Married -> Cohabit" H1="Married -> Cohabit"
putexcel A9="No Status Change" I1="No Status Change"
putexcel A10="Member Left" J1="Member Left"
putexcel A11="Earner Left" K1="Earner Left"
putexcel A12="Earner -> Non-earner" L1="Earner -> Non-earner"
putexcel A13="Member Gained" M1="Member Gained"
putexcel A14="Earner Gained" N1="Earner Gained"
putexcel A15="Non-earner -> earner" O1="Non-earner -> earner"
putexcel A16="R became earner" P1="R became earner"
putexcel A17="R became non-earner" Q1="R became non-earner"
putexcel A18="Gained Pre-school aged children" R1="Gained Pre-school aged children"
putexcel A19="Lost pre-school aged children" S1="Lost pre-school aged children"
putexcel A20="Gained parents" T1="Gained parents"
putexcel A21="Lost parents" U1="Lost parents"
putexcel A22="Subsequent Birth" V1="Subsequent Birth"
putexcel A23="First Birth" W1="First Birth"
putexcel A24="Full-Time->Part-Time" X1="Full-Time->Part-Time"
putexcel A25="Full-Time-> No Job" Y1="Full-Time-> No Job"
putexcel A26="Part-Time-> No Job" Z1="Part-Time-> No Job"
putexcel A27="Part-Time->Full-Time" AA1="Part-Time->Full-Time"
putexcel A28="No Job->PT" AB1="No Job->PT"
putexcel A29="No Job->FT" AC1="No Job->FT"
putexcel A30="No Job Change" AD1="No Job Change"
putexcel A31="Employer Change" AE1="Employer Change"
putexcel A32="Better Job" AF1="Better Job"
putexcel A33="Job exit due to pregnancy" AG1="Job exit due to pregnancy"
putexcel A34="One to Many Jobs" AH1="One to Many Jobs"
putexcel A35="Many to one job" AI1="Many to one job"
putexcel A36="Added a job" AJ1="Added a job"
putexcel A37="Lost a job" AK1="Lost a job"
putexcel A38="Spouse Full-Time->Part-Time" AL1="Spouse Full-Time->Part-Time"
putexcel A39="Spouse Full-Time-> No Job" AM1="Spouse Full-Time-> No Job"
putexcel A40="Spouse Part-Time-> No Job" AN1="Spouse Part-Time-> No Job"
putexcel A41="Spouse Part-Time->Full-Time" AO1="Spouse Part-Time->Full-Time"
putexcel A42="Spouse No Job->PT" AP1="Spouse No Job->PT"
putexcel A43="Spouse No Job->FT" AQ1="Spouse No Job->FT"
putexcel A44="Spouse No Job Change" AR1="Spouse No Job Change"
putexcel A45="Spouse Employer Change" AS1="Spouse Employer Change"
putexcel A46="Spouse Better Job" AT1="Spouse Better Job"
putexcel A47="Spouse One to Many Jobs" AU1="Spouse One to Many Jobs"
putexcel A48="Spouse Many to one job" AV1="Spouse Many to one job"
putexcel A49="Spouse Added a job" AW1="Spouse Added a job"
putexcel A50="Spouse Lost a job" AX1="Spouse Lost a job"
putexcel A51="Into 'difficult to find a job'" AY1="Into 'difficult to find a job'"
putexcel A52="Out of 'difficult fo find a job'" AZ1="Out of 'difficult fo find a job'"
putexcel A53="Into 'condition that limits work'" BA1="Into 'condition that limits work'"
putexcel A54="Out of 'condition that limits work'" BB1="Out of 'condition that limits work'"
putexcel A55="Into 'core disability'" BC1="Into 'core disability'"
putexcel A56="Out of 'core disability'" BD1="Out of 'core disability'"
putexcel A57="Spouse Into 'difficult to find a job'" BE1="Spouse Into 'difficult to find a job'"
putexcel A58="Spouse Out of 'difficult fo find a job'" BF1="Spouse Out of 'difficult fo find a job'"
putexcel A59="Spouse Into 'condition that limits work'" BG1="Spouse Into 'condition that limits work'"
putexcel A60="Spouse Out of 'condition that limits work'" BH1="Spouse Out of 'condition that limits work'"
putexcel A61="Spouse Into 'core disability'" BI1="Spouse Into 'core disability'"
putexcel A62="Spouse Out of 'core disability'" BJ1="Spouse Out of 'core disability'"
putexcel A63="Into welfare" BK1="Into welfare"
putexcel A64="Out of welfare" BL1="Out of welfare"
putexcel A65="Into 'Child care prevented from working more'" BM1="Into 'Child care prevented from working more'"
putexcel A66="Out of 'Child care prevented from working more'" BN1="Out of 'Child care prevented from working more'"
putexcel A67="Received child care assistance" BO1="Received child care assistance"
putexcel A68="Stopped receiving child care assistance" BP1="Stopped receiving child care assistance"
putexcel A69="Onto a child care wait list" BQ1="Onto a child care wait list"
putexcel A70="Off a child care wait list" BR1="Off a child care wait list"
putexcel A71="Moved for relationship" BS1="Moved for relationship"
putexcel A72="Moved for independence" BT1="Moved for independence"
putexcel A73="Gained education" BU1="Gained education"
putexcel A74="Enrolled in school" BV1="Enrolled in school"
putexcel A75="Stopped being enrolled in school" BW1="Stopped being enrolled in school"
putexcel A76="Spouse Gained education" BX1="Spouse Gained education"
putexcel A77="Spouse Enrolled in school" BY1="Spouse Enrolled in school"
putexcel A78="Spouse Stopped being enrolled in school" BZ1="Spouse Stopped being enrolled in school"
putexcel A79="R Earnings Up 20%" CA1="R Earnings Up 20%"
putexcel A80="R Earnings Down 20%" CB1="R Earnings Down 20%"
putexcel A81="Spouse Earnings Up 20%" CC1="Spouse Earnings Up 20%"
putexcel A82="Spouse Earnings Down 20%" CD1="Spouse Earnings Down 20%"
putexcel A83="HH Earnings Up 20%" CE1="HH Earnings Up 20%"
putexcel A84="HH Earnings Down 20%" CF1="HH Earnings Down 20%"
putexcel A85="Other Earnings Up 20%" CG1="Other Earnings Up 20%"
putexcel A86="Other Earnings Down 20%" CH1="Other Earnings Down 20%"
putexcel A87="R Earnings Up 5%" CI1="R Earnings Up 5%"
putexcel A88="R Earnings Down 5%" CJ1="R Earnings Down 5%"
putexcel A89="Spouse Earnings Up 5%" CK1="Spouse Earnings Up 5%"
putexcel A90="Spouse Earnings Down 5%" CL1="Spouse Earnings Down 5%"
putexcel A91="HH Earnings Up 5%" CM1="HH Earnings Up 5%"
putexcel A92="HH Earnings Down 5%" CN1="HH Earnings Down 5%"
putexcel A93="Other Earnings Up 5%" CO1="Other Earnings Up 5%"
putexcel A94="Other Earnings Down 5%" CP1="Other Earnings Down 5%"
putexcel A95="R Hours Up 15%" CQ1="R Hours Up 15%"
putexcel A96="R Hours Down 15%" CR1="R Hours Down 15%"
putexcel A97="Spouse Hours Up 15%" CS1="Spouse Hours Up 15%"
putexcel A98="Spouse Hours Down 15%" CT1="Spouse Hours Down 15%"
putexcel A99="R Hours Up 5%" CU1="R Hours Up 5%"
putexcel A100="R Hours Down 5%" CV1="R Hours Down 5%"
putexcel A101="Spouse Hours Up 5%" CW1="Spouse Hours Up 5%"
putexcel A102="Spouse Hours Down 5%" CX1="Spouse Hours Down 5%"
putexcel A103="R Wages Up 15%" CY1="R Wages Up 15%"
putexcel A104="R Wages Down 15%" CZ1="R Wages Down 15%"
putexcel A105="Spouse Wages Up 15%" DA1="Spouse Wages Up 15%"
putexcel A106="Spouse Wages Down 15%" DB1="Spouse Wages Down 15%"
putexcel A107="R Wages Up 5%" DC1="R Wages Up 5%"
putexcel A108="R Wages Down 5%" DD1="R Wages Down 5%"
putexcel A109="Spouse Wages Up 5%" DE1="Spouse Wages Up 5%"
putexcel A110="Spouse Wages Down 5%" DF1="Spouse Wages Down 5%"
putexcel A111="R Became Earner" DG1="R Became Earner"
putexcel A112="R Stopped Earning" DH1="R Stopped Earning"
putexcel A113="Spouse Became Earner" DI1="Spouse Became Earner"
putexcel A114="Spouse Stopped Earning" DJ1="Spouse Stopped Earning"
putexcel A115="HH Became Earner" DK1="HH Became Earner"
putexcel A116="HH Stopped Earning" DL1="HH Stopped Earning"
putexcel A117="Other Became Earner" DM1="Other Became Earner"
putexcel A118="Other Stopped Earning" DN1="Other Stopped Earning"


forvalues v=1/117{
local var1: word `v' of `vars1'
local row =`v'+1
	forvalues x=1/117{
	local col: word `x' of `colu'
	local var2: word `x' of `vars2'
	quietly tab `var1' `var2' if trans_bw60==1, matcell(`var1'_`var2')
	mata: st_matrix("`var1'_`var2'", (st_matrix("`var1'_`var2'")  :/ sum(st_matrix("`var1'_`var2'"))))
	mat `var1'_`var2' = `var1'_`var2'[2,2]
	quietly putexcel `col'`row' = matrix(`var1'_`var2'), nformat(#.##%) 
	}
}

/* logic to follow
tab sing_coh hh_lose if trans_bw60==1 & year==2014, matcell(test)
mata: st_matrix("test", (st_matrix("test")  :/ sum(st_matrix("test"))))
mat B = test[2,2]
matrix list B = has just the value I want
*/

