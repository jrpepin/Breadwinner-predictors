*-------------------------------------------------------------------------------
* BREADWINNER PROJECT
* economic_consequences.do
* Kim McErlean
*-------------------------------------------------------------------------------
di "$S_DATE"

********************************************************************************
* DESCRIPTION
********************************************************************************
* File used was created in ab_decomposition_equation.do
* Note: this relies on macros created in step ab, so cannot run this in isolation

use "$tempdir/combined_bw_equation.dta", clear // created in step ab

// some sample restrictions
* restrict to just 2014
keep if survey_yr==2

* restrict to just eligible mothers - not breadwinner in year and have a second year of data to track them. need to retain prior year income first
by SSUID PNUM (year), sort: gen hh_income_raw_all = ((thearn_adj-thearn_adj[_n-1])) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1) & bw60lag==0
gen thearn_adj_lag = thearn_adj[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)
	
browse SSUID PNUM year bw60 bw60lag trans_bw60_alt2 thearn_adj thearn_adj_lag hh_income_raw_all
keep if bw60lag==0

// tab bw60 - that makes sense with our final transition rate
 
// reclassify pathways
* mom change: earn_change mom_gain_earn == specifically BECAME an earner
* other change: earn_change_hh earn_lose earn_change_sp partner_lose
browse SSUID PNUM year mom_gain_earn earn_change_hh earn_lose earn_change_sp partner_lose mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes
browse SSUID PNUM year mom_gain_earn  earn_change partner_lose ft_partner_leave

* mt_mom // can stay

gen partner_loss_only = ft_partner_down_only
replace partner_loss_only = 1 if partner_lose==1 & mom_gain_earn==0 & earn_change <=0
// then also replace if JUST partner left

gen partner_mom_change = ft_partner_down_mom
replace partner_mom_change = 1 if ft_partner_leave & (mom_gain_earn==1 | earn_change > 0)
// then also replace if partner left and mom changed

browse SSUID PNUM year mom_gain_earn  earn_change partner_lose ft_partner_leave partner_loss_only partner_mom_change

gen other_change_only = 0
replace other_change_only=1 if lt_other_changes & mom_gain_earn==0 & earn_change <=0

gen other_mom_change = 0
replace other_mom_change=1 if lt_other_changes & (mom_gain_earn==1 | earn_change > 0)


// math
// Table 4: Median Income Change
sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2, detail  // pre 2014
sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2, detail // post 2014

sum thearn_adj if bw60==0 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2, detail  // pre 2014 - all
sum thearn_adj if bw60==0, detail // & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2, detail  // or is this all? but want to know we can track them into next year, which is what above does?
sum thearn_adj if bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2, detail // post 2014 - all
sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2, detail // post 2014 - bw
sum thearn_adj if bw60==0 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2, detail // post 2014 - not bw

sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & mt_mom[_n+1]==1, detail  // pre 2014
sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & mt_mom==1, detail // post 2014
sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ft_partner_down_mom[_n+1]==1, detail  // pre 2014
sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & ft_partner_down_mom==1, detail // post 2014
sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ft_partner_down_only[_n+1]==1, detail  // pre 2014
sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & ft_partner_down_only==1, detail // post 2014
sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ft_partner_leave[_n+1]==1, detail  // pre 2014
sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & ft_partner_leave==1, detail // post 2014
sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & lt_other_changes[_n+1]==1, detail  // pre 2014
sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & lt_other_changes==1, detail // post 2014

sum thearn_adj if bw60==0 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ft_partner_leave[_n+1]==1, detail  // pre 2014 all HHs
sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ft_partner_leave[_n+1]==1, detail  // pre 2014 -- HHs that become BW
sum thearn_adj if bw60==0 & bw60[_n+1]==0 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ft_partner_leave[_n+1]==1, detail  // pre 2014 -- HHs that don't become BW

sum thearn_adj if bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & ft_partner_leave==1, detail // post 2014 - all // is this post or pre?
sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & ft_partner_leave==1, detail // post 2014 - BW
sum thearn_adj if bw60==0 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & ft_partner_leave==1, detail // post 2014 - not BW

	by SSUID PNUM (year), sort: gen hh_income_chg = ((thearn_adj-thearn_adj[_n-1])/thearn_adj[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1) & trans_bw60_alt2==1
	by SSUID PNUM (year), sort: gen hh_income_raw = ((thearn_adj-thearn_adj[_n-1])) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1) & trans_bw60_alt2==1
	browse SSUID PNUM year thearn_adj bw60 trans_bw60_alt2 hh_income_chg hh_income_raw
	
	by SSUID PNUM (year), sort: gen hh_income_raw_all = ((thearn_adj-thearn_adj[_n-1])) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1) & bw60lag==0
