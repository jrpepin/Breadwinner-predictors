**# What is ccurently being used

	
use "$tempdir/combined_for_decomp.dta", clear // created in ab

foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
	gen `var'_rate=. // have to do this for round 1 to get boostrap to work? Think was throwing errors every time I had to start the file over
	gen `var'_comp=. 
}

	
	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		drop `var'_comp `var'_rate
		svy: mean `var' if bw60lag==0 & survey==1996
		matrix `var'_comp = e(b)
		gen `var'_comp = e(b)[1,1] if survey==1996
		svy: mean trans_bw60_alt2 if bw60lag==0 & survey==1996 & `var'==1
		matrix `var'_rate = e(b)
		gen `var'_rate = e(b)[1,1] if survey==1996
	}

	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		svy: mean `var' if bw60lag==0 & survey==2014
		matrix `var'_comp = e(b)
		replace `var'_comp = e(b)[1,1] if survey==2014
		svy: mean trans_bw60_alt2 if bw60lag==0 & survey==2014 & `var'==1
		matrix `var'_rate = e(b)
		replace `var'_rate = e(b)[1,1] if survey==2014
	}

	preserve
	collapse (mean) mt_mom_rate mt_mom_comp ft_partner_down_mom_rate ft_partner_down_mom_comp ft_partner_down_only_rate ft_partner_down_only_comp ft_partner_leave_rate ft_partner_leave_comp lt_other_changes_rate lt_other_changes_comp, by(survey)

	rdecompose mt_mom_rate mt_mom_comp ft_partner_down_mom_rate ft_partner_down_mom_comp ft_partner_down_only_rate ft_partner_down_only_comp ft_partner_leave_rate ft_partner_leave_comp lt_other_changes_rate lt_other_changes_comp, ///
	group(survey) func((mt_mom_rate*mt_mom_comp) + (ft_partner_down_mom_rate*ft_partner_down_mom_comp) + (ft_partner_down_only_rate*ft_partner_down_only_comp) + (ft_partner_leave_rate*ft_partner_leave_comp) + (lt_other_changes_rate*lt_other_changes_comp)) 
	
	restore
	
	////
		
**# attempting to figure this out - take 1 
use "$tempdir/combined_for_decomp.dta", clear // created in ab
	
	gen pathway=0
	replace pathway=1 if mt_mom==1
	replace pathway=2 if ft_partner_down_mom==1
	replace pathway=3 if ft_partner_down_only==1
	replace pathway=4 if ft_partner_leave==1
	replace pathway=5 if lt_other_changes==1
	label define pathway 0 "None" 1 "Mom up" 2 "Mom up Partner Down" 3 "Partner Down" 4 "Partner Exit" 5 "Other HH"
	label values pathway pathway
	
	tab pathway survey if bw60lag==0, col
	tab pathway survey if bw60lag==0 & pathway!=0, col
	tab pathway survey if bw60lag==0 [aweight=wpfinwgt], col
	
	
	gen no=0
	replace no=1 if pathway==0
	
	gen any_event=0
	replace any_event=1 if inrange(pathway,1,5)
	
	tab survey any_event, row
	tab survey any_event if bw60lag==0, row /// this should match kelly's calculations
	
	tab survey trans_bw60_alt2 if bw60lag==0 & any_event==1, row // this should also match kelly's calculations
// but this isn't total rate, need to take the multiplication of both - so try rdecompose with just "any_event"? I am still confused to get the total pathways to add up - but is that because of the no event composition?
	
	
foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes no any_event{
	gen `var'_rate=. // have to do this for round 1 to get boostrap to work? Think was throwing errors every time I had to start the file over
	gen `var'_comp=. 
}

	
	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes no any_event{
		drop `var'_comp `var'_rate
		svy: mean `var' if bw60lag==0 & survey==1996
		matrix `var'_comp = e(b)
		gen `var'_comp = e(b)[1,1] if survey==1996
		svy: mean trans_bw60_alt2 if bw60lag==0 & survey==1996 & `var'==1
		matrix `var'_rate = e(b)
		gen `var'_rate = e(b)[1,1] if survey==1996
	}

	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes no any_event{
		svy: mean `var' if bw60lag==0 & survey==2014
		matrix `var'_comp = e(b)
		replace `var'_comp = e(b)[1,1] if survey==2014
		svy: mean trans_bw60_alt2 if bw60lag==0 & survey==2014 & `var'==1
		matrix `var'_rate = e(b)
		replace `var'_rate = e(b)[1,1] if survey==2014
	}

	preserve
	collapse (mean) mt_mom_rate mt_mom_comp ft_partner_down_mom_rate ft_partner_down_mom_comp ft_partner_down_only_rate ft_partner_down_only_comp ft_partner_leave_rate ft_partner_leave_comp lt_other_changes_rate lt_other_changes_comp no_rate no_comp any_event_rate any_event_comp, by(survey)

	rdecompose mt_mom_rate mt_mom_comp ft_partner_down_mom_rate ft_partner_down_mom_comp ft_partner_down_only_rate ft_partner_down_only_comp ft_partner_leave_rate ft_partner_leave_comp lt_other_changes_rate lt_other_changes_comp no_rate no_comp, ///
	group(survey) func((mt_mom_rate*mt_mom_comp) + (ft_partner_down_mom_rate*ft_partner_down_mom_comp) + (ft_partner_down_only_rate*ft_partner_down_only_comp) + (ft_partner_leave_rate*ft_partner_leave_comp) + (lt_other_changes_rate*lt_other_changes_comp) + (no_rate*no_comp))
	
	rdecompose any_event_rate any_event_comp, group(survey)
	
	rdecompose mt_mom_rate mt_mom_comp ft_partner_down_mom_rate ft_partner_down_mom_comp ft_partner_down_only_rate ft_partner_down_only_comp ft_partner_leave_rate ft_partner_leave_comp lt_other_changes_rate lt_other_changes_comp no_rate no_comp, group(survey)
	
		rdecompose mt_mom_rate mt_mom_comp ft_partner_down_mom_rate ft_partner_down_mom_comp ft_partner_down_only_rate ft_partner_down_only_comp ft_partner_leave_rate ft_partner_leave_comp lt_other_changes_rate lt_other_changes_comp no_comp, ///
	group(survey) func((mt_mom_rate*mt_mom_comp) + (ft_partner_down_mom_rate*ft_partner_down_mom_comp) + (ft_partner_down_only_rate*ft_partner_down_only_comp) + (ft_partner_leave_rate*ft_partner_leave_comp) + (lt_other_changes_rate*lt_other_changes_comp) + no_comp)
	
	restore

	**# attempting to figure this out - take 2 = remove "nos" frm calculation - think this will get me to the 9 and 14
use "$tempdir/combined_for_decomp.dta", clear // created in ab
	
	gen pathway=0
	replace pathway=1 if mt_mom==1
	replace pathway=2 if ft_partner_down_mom==1
	replace pathway=3 if ft_partner_down_only==1
	replace pathway=4 if ft_partner_leave==1
	replace pathway=5 if lt_other_changes==1
	label define pathway 0 "None" 1 "Mom up" 2 "Mom up Partner Down" 3 "Partner Down" 4 "Partner Exit" 5 "Other HH"
	label values pathway pathway
	
	tab pathway survey if bw60lag==0, col
	tab pathway survey if bw60lag==0 & pathway!=0, col
	tab pathway survey if bw60lag==0 [aweight=wpfinwgt], col
	
	
	gen no=0
	replace no=1 if pathway==0
	
	gen any_event=0
	replace any_event=1 if inrange(pathway,1,5)
	
	tab survey any_event, row
	tab survey any_event if bw60lag==0, row /// this should match kelly's calculations
	
	tab survey trans_bw60_alt2 if bw60lag==0 & any_event==1, row // this should also match kelly's calculations
// but this isn't total rate, need to take the multiplication of both - so try rdecompose with just "any_event"? I am still confused to get the total pathways to add up - but is that because of the no event composition?
	
	
foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
	gen `var'_rate=. // have to do this for round 1 to get boostrap to work? Think was throwing errors every time I had to start the file over
	gen `var'_comp=. 
}

	
	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		drop `var'_comp `var'_rate
		svy: mean `var' if bw60lag==0 & survey==1996 & pathway!=0
		matrix `var'_comp = e(b)
		gen `var'_comp = e(b)[1,1] if survey==1996
		svy: mean trans_bw60_alt2 if bw60lag==0 & survey==1996 & `var'==1 & pathway!=0
		matrix `var'_rate = e(b)
		gen `var'_rate = e(b)[1,1] if survey==1996
	}

	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		svy: mean `var' if bw60lag==0 & survey==2014 & pathway!=0
		matrix `var'_comp = e(b)
		replace `var'_comp = e(b)[1,1] if survey==2014
		svy: mean trans_bw60_alt2 if bw60lag==0 & survey==2014 & `var'==1 & pathway!=0
		matrix `var'_rate = e(b)
		replace `var'_rate = e(b)[1,1] if survey==2014
	}

	preserve
	collapse (mean) mt_mom_rate mt_mom_comp ft_partner_down_mom_rate ft_partner_down_mom_comp ft_partner_down_only_rate ft_partner_down_only_comp ft_partner_leave_rate ft_partner_leave_comp lt_other_changes_rate lt_other_changes_comp, by(survey)

	rdecompose mt_mom_rate mt_mom_comp ft_partner_down_mom_rate ft_partner_down_mom_comp ft_partner_down_only_rate ft_partner_down_only_comp ft_partner_leave_rate ft_partner_leave_comp lt_other_changes_rate lt_other_changes_comp, ///
	group(survey) func((mt_mom_rate*mt_mom_comp) + (ft_partner_down_mom_rate*ft_partner_down_mom_comp) + (ft_partner_down_only_rate*ft_partner_down_only_comp) + (ft_partner_leave_rate*ft_partner_leave_comp) + (lt_other_changes_rate*lt_other_changes_comp))
	
	rdecompose any_event_rate any_event_comp, group(survey)
	
	rdecompose mt_mom_rate mt_mom_comp ft_partner_down_mom_rate ft_partner_down_mom_comp ft_partner_down_only_rate ft_partner_down_only_comp ft_partner_leave_rate ft_partner_leave_comp lt_other_changes_rate lt_other_changes_comp no_rate no_comp, group(survey)
	
		rdecompose mt_mom_rate mt_mom_comp ft_partner_down_mom_rate ft_partner_down_mom_comp ft_partner_down_only_rate ft_partner_down_only_comp ft_partner_leave_rate ft_partner_leave_comp lt_other_changes_rate lt_other_changes_comp no_comp, ///
	group(survey) func((mt_mom_rate*mt_mom_comp) + (ft_partner_down_mom_rate*ft_partner_down_mom_comp) + (ft_partner_down_only_rate*ft_partner_down_only_comp) + (ft_partner_leave_rate*ft_partner_leave_comp) + (lt_other_changes_rate*lt_other_changes_comp) + no_comp)
	
	restore

**# attempting to figure this out - need TWO compositions
use "$tempdir/combined_for_decomp.dta", clear // created in ab
	
	gen pathway=0
	replace pathway=1 if mt_mom==1
	replace pathway=2 if ft_partner_down_mom==1
	replace pathway=3 if ft_partner_down_only==1
	replace pathway=4 if ft_partner_leave==1
	replace pathway=5 if lt_other_changes==1
	label define pathway 0 "None" 1 "Mom up" 2 "Mom up Partner Down" 3 "Partner Down" 4 "Partner Exit" 5 "Other HH"
	label values pathway pathway
	
	tab pathway survey if bw60lag==0, col
	tab pathway survey if bw60lag==0 & pathway!=0, col
	tab pathway survey if bw60lag==0 [aweight=wpfinwgt], col
	
	tab pathway trans_bw60_alt2 if bw60lag==0, row
	tab pathway trans_bw60_alt2 if bw60lag==0 & pathway!=0, row

	gen no=0
	replace no=1 if pathway==0
	
	gen any_event=0
	replace any_event=1 if inrange(pathway,1,5)
	
	tab survey any_event, row
	tab survey any_event if bw60lag==0, row /// this should match kelly's calculations
	
	tab survey trans_bw60_alt2 if bw60lag==0 & any_event==1, row // this should also match kelly's calculations
// but this isn't total rate, need to take the multiplication of both - so try rdecompose with just "any_event"? I am still confused to get the total pathways to add up - but is that because of the no event composition?
	
	
foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
	gen `var'_rate_a=. // have to do this for round 1 to get boostrap to work? Think was throwing errors every time I had to start the file over
	gen `var'_comp_all=.
	gen `var'_comp_path=.
}

	
	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		drop `var'_comp_all `var'_comp_path `var'_rate_a
		svy: mean `var' if bw60lag==0 & survey==1996
		matrix `var'_comp_all = e(b)
		gen `var'_comp_all = e(b)[1,1] if survey==1996
		svy: mean `var' if bw60lag==0 & survey==1996 & pathway!=0
		matrix `var'_comp_path = e(b)
		gen `var'_comp_path = e(b)[1,1] if survey==1996
		svy: mean trans_bw60_alt2 if bw60lag==0 & survey==1996 & `var'==1
		matrix `var'_rate_a = e(b)
		gen `var'_rate_a = e(b)[1,1] if survey==1996
	}

	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		svy: mean `var' if bw60lag==0 & survey==2014
		matrix `var'_comp_all = e(b)
		replace `var'_comp_all = e(b)[1,1] if survey==2014
		svy: mean `var' if bw60lag==0 & survey==2014 & pathway!=0
		matrix `var'_comp_path = e(b)
		replace `var'_comp_path = e(b)[1,1] if survey==2014
		svy: mean trans_bw60_alt2 if bw60lag==0 & survey==2014 & `var'==1
		matrix `var'_rate_a = e(b)
		replace `var'_rate_a = e(b)[1,1] if survey==2014
	}

	preserve
	collapse (mean) mt_mom_rate_a mt_mom_comp_all mt_mom_comp_path ft_partner_down_mom_rate_a ft_partner_down_mom_comp_all ft_partner_down_mom_comp_path ft_partner_down_only_rate_a ft_partner_down_only_comp_all ft_partner_down_only_comp_path ft_partner_leave_rate_a ft_partner_leave_comp_all ft_partner_leave_comp_path lt_other_changes_rate_a lt_other_changes_comp_all lt_other_changes_comp_path, by(survey)
	
foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
	gen `var'_rate = `var'_comp_path * `var'_rate_a
}
	
	rdecompose mt_mom_rate mt_mom_comp_all ft_partner_down_mom_rate ft_partner_down_mom_comp_all ft_partner_down_only_rate ft_partner_down_only_comp_all ft_partner_leave_rate ft_partner_leave_comp_all lt_other_changes_rate lt_other_changes_comp_all, ///
	group(survey) func((mt_mom_rate + ft_partner_down_mom_rate + ft_partner_down_only_rate + ft_partner_leave_rate + lt_other_changes_rate) * (mt_mom_comp_all + ft_partner_down_mom_comp_all + ft_partner_down_only_comp_all + ft_partner_leave_comp_all + lt_other_changes_comp_all))
	
	
	restore
	
**# How to get aggregate view?! okay so this doesn't change, but does that make sense?
use "$tempdir/combined_for_decomp.dta", clear // created in ab
	
	gen pathway=0
	replace pathway=1 if mt_mom==1
	replace pathway=2 if ft_partner_down_mom==1
	replace pathway=3 if ft_partner_down_only==1
	replace pathway=4 if ft_partner_leave==1
	replace pathway=5 if lt_other_changes==1
	label define pathway 0 "None" 1 "Mom up" 2 "Mom up Partner Down" 3 "Partner Down" 4 "Partner Exit" 5 "Other HH"
	label values pathway pathway
	
	tab pathway survey if bw60lag==0, col
	tab pathway survey if bw60lag==0 & pathway!=0, col
	tab pathway survey if bw60lag==0 [aweight=wpfinwgt], col
	
	tab pathway trans_bw60_alt2 if bw60lag==0, row
	tab pathway trans_bw60_alt2 if bw60lag==0 & pathway!=0, row

	gen no=0
	replace no=1 if pathway==0
	

foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes no{
	gen `var'_rate=. // have to do this for round 1 to get boostrap to work? Think was throwing errors every time I had to start the file over
	gen `var'_comp=. 
	gen `var'_total=.
}

	
	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes no{
		drop `var'_comp `var'_rate `var'_total
		svy: mean `var' if bw60lag==0 & survey==1996
		matrix `var'_comp = e(b)
		gen `var'_comp = e(b)[1,1] if survey==1996
		svy: mean trans_bw60_alt2 if bw60lag==0 & survey==1996 & `var'==1
		matrix `var'_rate = e(b)
		gen `var'_rate = e(b)[1,1] if survey==1996
	}

	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes no{
		svy: mean `var' if bw60lag==0 & survey==2014
		matrix `var'_comp = e(b)
		replace `var'_comp = e(b)[1,1] if survey==2014
		svy: mean trans_bw60_alt2 if bw60lag==0 & survey==2014 & `var'==1
		matrix `var'_rate = e(b)
		replace `var'_rate = e(b)[1,1] if survey==2014
	}
	
	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes no{
		gen `var'_total = `var'_rate * `var'_comp // to get aggregate pathway level
	}

	preserve
	collapse (mean) mt_mom_total ft_partner_down_mom_total ft_partner_down_only_total ft_partner_leave_total lt_other_changes_total no_total, by(survey) // to get aggregate pathway level
	
	rdecompose mt_mom_total ft_partner_down_mom_total ft_partner_down_only_total ft_partner_leave_total lt_other_changes_total no_total, group(survey) ///
	func(mt_mom_total + ft_partner_down_mom_total + ft_partner_down_only_total + ft_partner_leave_total + lt_other_changes_total + no_total)
	
	restore
