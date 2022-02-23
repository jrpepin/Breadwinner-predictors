use "$CPS/bw_1967_2021.dta", clear
replace incwage=0 if incwage==99999999
replace incwage=0 if incwage==99999998

/*keep year serial pernum incwage
rename pernum spouse
rename incwage incwage_sp
*/
drop *_mom *_mom2
order year serial pernum
reshape wide month-incwage_sp, i(year serial) j(pernum)
/* ds id year, not
reshape wide `r(varlist)', i(id) j(year)
*/

keep year serial incwage*
drop *_sp*
save "$tempdir/cps_wage_match.dta", replace

use "$CPS/bw_1967_2021.dta", clear
// doesn't need to be annualized, already annual - only month is march
* before dropping anything, calculate HH income based on just wages, not total income
replace incwage=0 if incwage==99999999
replace incwage=0 if incwage==99999998
egen hh_earnings = total(incwage), by(serial year)

browse year serial pernum hhincome hh_earnings incwage

*Adding something to later match to get partner earnings
drop spouse
gen spouse=sploc

// 1967 has a lot of missing info...
drop if year==1967

// first figure out sample / what columns / people to look at

keep if nmothers>0
bysort serial year (pernum_mom): egen mom1=min(pernum_mom)
bysort serial year (pernum_mom): egen mom2=max(pernum_mom) if pernum_mom!=.
bysort serial year (mom2): replace mom2=mom2[1]

browse serial year pernum relate nmothers pernum_mom mom1 mom2

keep if pernum==mom1 | pernum==mom2

*only want mothers if they have a kid under 18
keep if yngch<=18

save "$tempdir/cps_mothers_over_time.dta", replace

* add spouse earnings
merge m:1 serial year using  "$tempdir/cps_wage_match.dta"
drop if _merge==2
drop _merge

drop incwage_sp
gen incwage_sp=.
forvalues p=1/26{
	replace incwage_sp = incwage`p' if sploc==`p'
}

browse year serial pernum sploc incwage incwage_sp incwage* 

gen single_mom=(sploc==0)
gen single_mom_work=(single_mom==1 & incwage >0)

// calculate breadwinners v. co-breadwinner mothers
gen mom_earn_pct = incwage/hh_earnings
replace mom_earn_pct = 0 if mom_earn_pct==.

browse serial year pernum hh_earnings incwage incwage_sp mom_earn_pct spouse

gen bw=1 if mom_earn_pct>=0.6000000
gen co_bw=1 if mom_earn_pct<0.600000 & mom_earn_pct >=0.4000000
gen no_bw=1 if mom_earn_pct<0.400000
gen bw_25=1 if mom_earn_pct>=0.2500000

replace bw=0 if bw==.
replace co_bw=0 if co_bw==.
replace no_bw=0 if no_bw==.
replace bw_25=0 if bw_25==.

browse serial year pernum hh_earnings incwage incwage_sp mom_earn_pct bw co_bw
browse serial year pernum hh_earnings incwage mom_earn_pct bw co_bw no_bw if bw==0 & co_bw==0 & no_bw==0

// denote if mom earns more than partner
gen mom_earn_more=.
replace mom_earn_more=1 if incwage>=incwage_sp & single_mom==0
replace mom_earn_more=0 if incwage<incwage_sp & single_mom==0

gen bw_25_dedup=bw_25
replace bw_25_dedup=0 if (mom_earn_more==1 | single_mom==1)

gen bw_25_married=bw_25
replace bw_25_married = 0 if single_mom==1

// how different are hh_earnings v. just couple
egen couple_earnings= rowtotal(incwage incwage_sp)
	// browse year serial incwage incwage_sp couple_earnings hh_earnings

gen mom_earn_couple = incwage / couple_earnings
replace mom_earn_couple = 0 if mom_earn_couple==.
gen bw_25_couple=1 if mom_earn_couple>=0.2500000
replace bw_25_couple=0 if bw_25_couple==.
gen bw_25_couple_dedup=bw_25_couple
replace bw_25_couple_dedup=0 if (mom_earn_more==1 | single_mom==1)

browse serial year pernum hh_earnings incwage incwage_sp mom_earn_pct bw co_bw mom_earn_more single_mom bw_25

*making a column to sum all mothers when I collapse
gen mothers=1

// then consolidate  by years
* need total mothers (summothers, then total bw, total co_bw?

preserve

collapse (sum) mothers bw co_bw no_bw bw_25 bw_25_dedup bw_25_married bw_25_couple bw_25_couple_dedup single_mom single_mom_work mom_earn_more, by(year)
export excel using "$results/cps_bw_over_time.xls", firstrow(variables) replace

restore

// do 1967 separately?