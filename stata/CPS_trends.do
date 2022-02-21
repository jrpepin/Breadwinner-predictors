use "$CPS/bw_1967_2021.dta", clear

// doesn't need to be annualized, already annual - only month is march
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

// calculate breadwinners v. co-breadwinner mothers
gen mom_earn_pct = incwage/hhincome
replace mom_earn_pct = 0 if mom_earn_pct==.

browse serial year pernum hhincome incwage mom_earn_pct

gen bw=1 if mom_earn_pct>=0.6000000
gen co_bw=1 if mom_earn_pct<0.600000 & mom_earn_pct >=0.4000000
gen no_bw=1 if mom_earn_pct<0.400000

replace bw=0 if bw==.
replace co_bw=0 if co_bw==.
replace no_bw=0 if no_bw==.

browse serial year pernum hhincome incwage mom_earn_pct bw co_bw
browse serial year pernum hhincome incwage mom_earn_pct bw co_bw no_bw if bw==0 & co_bw==0 & no_bw==0

*making a column to sum all mothers when I collapse
gen mothers=1

// then consolidate  by years
* need total mothers (summothers, then total bw, total co_bw?

preserve

collapse (sum) mothers bw co_bw no_bw, by(year)
export excel using "$results/cps_bw_over_time.xls", firstrow(variables) replace

restore

// do 1967 separately?