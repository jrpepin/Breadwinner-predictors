# Decomposition of Breadwinner predictors using the 1996 and 2014 SIPPs


The purpose of this analysis is to decompose differences in Breadwinner transitions over time into the composition of changes v. the effect of changes.
We use 4 changes: the mom experiencing an earnings change, her partner losing earnings, her partner leaving, or someone else in the household either losing earnings or leaving.

## Specification 1: Mom category ONLY includes those where mom earnings went up 


The rate of transition into breadwinning in 1996 was <<dd_di: %9.2f $bw_rate_96*100 >>%.
The rate of transition into breadwinning in 2014 was <<dd_di: %9.2f $bw_rate_14*100 >>%.
This is a difference of <<dd_di: %9.2f $total_gap*100 >>%.

Of the total <<dd_di: %9.2f $total_gap*100 >>% difference, <<dd_di: %9.2f $rate_diff*100 >>% can be explained by rate differences between the two surveys (rate of transition once you experienced the event).
Of the total <<dd_di: %9.2f $total_gap*100 >>% difference, <<dd_di: %9.2f $comp_diff*100 >>% can be explained by compositional differences between the two surveys (e.g. how many people experienced the events).

Further breaking down the gap:
<<dd_di: %9.2f $mom_compt_x*100 >>% could be attributed to the mother increasing component;
<<dd_di: %9.2f $partner_down_mom_compt_x*100>>% could be attributed to the mother increasing + partner earnings decreasing component;
<<dd_di: %9.2f $partner_down_only_compt_x*100 >>% could be attributed to the partner earnings decreasing component (with no other changes);
<<dd_di: %9.2f $partner_leave_compt_x*100 >>% could be attributed to the partner leaving component;
<<dd_di: %9.2f $other_hh_compt_x*100 >>% could be attributed to the other HH members losing earnings or leaving component.



### Results by education

| Group	        	 |   Total Gap                      | Rate Difference					| Composition Difference     		|
|:-------------------|:---------------------------------|:----------------------------------|:--------------------------------- |
|	Overall	    	 | <<dd_di: %9.2f $total_gap*100 >>%	| <<dd_di: %9.2f $rate_diff*100 >>%     | <<dd_di: %9.2f $comp_diff*100 >>%     |
|	College Educated | <<dd_di: %9.2f $total_gap_4*100 >>%	| <<dd_di: %9.2f $rate_diff_4*100 >>%   | <<dd_di: %9.2f $comp_diff_4*100 >>%   |
|	Some College	 | <<dd_di: %9.2f $total_gap_3*100 >>%	| <<dd_di: %9.2f $rate_diff_3*100 >>%   | <<dd_di: %9.2f $comp_diff_3*100 >>%   |
|	HS Degree		 | <<dd_di: %9.2f $total_gap_2*100 >>%	| <<dd_di: %9.2f $rate_diff_2*100 >>%   | <<dd_di: %9.2f $comp_diff_2*100 >>%   |
|	Less than HS	 | <<dd_di: %9.2f $total_gap_1*100 >>%	| <<dd_di: %9.2f $rate_diff_1*100 >>%   | <<dd_di: %9.2f $comp_diff_1*100 >>%   |


| Group	        	 |   Mom Component                      | Partner Down + Mom Up								| Partner Down Only								 |Partner Left		     						 | Other HH Down/Left						   |
|:-------------------|:-------------------------------------|:--------------------------------------------------|:----------------------------------------------|:----------------------------------------------|:----------------------------------------|
|	Overall	    	 | <<dd_di: %9.2f $mom_compt_x*100 >>%	| <<dd_di: %9.2f $partner_down_mom_compt_x*100 >>% | <<dd_di: %9.2f $partner_down_only_compt_x*100 >>%     | <<dd_di: %9.2f $partner_leave_compt_x*100 >>%   | <<dd_di: %9.2f $other_hh_compt_x*100 >>%  |
|	College Educated | <<dd_di: %9.2f $mom_component_4*100 >>%	| <<dd_di: %9.2f $partner_down_mom_component_4*100 >>%   | <<dd_di: %9.2f $partner_down_only_component_4*100 >>%   | <<dd_di: %9.2f $partner_leave_component_4*100 >>% | <<dd_di: %9.2f $other_hh_component_4*100 >>% |
|	Some College	 | <<dd_di: %9.2f $mom_component_3*100 >>%	| <<dd_di: %9.2f $partner_down_mom_component_3*100 >>%   | <<dd_di: %9.2f $partner_down_only_component_3*100 >>%   | <<dd_di: %9.2f $partner_leave_component_3*100 >>% | <<dd_di: %9.2f $other_hh_component_3*100 >>% |
|	HS Degree		 | <<dd_di: %9.2f $mom_component_2*100 >>%	| <<dd_di: %9.2f $partner_down_mom_component_2*100 >>%   | <<dd_di: %9.2f $partner_down_only_component_2*100 >>%   | <<dd_di: %9.2f $partner_leave_component_2*100 >>% | <<dd_di: %9.2f $other_hh_component_2*100 >>% |
|	Less than HS	 | <<dd_di: %9.2f $mom_component_1*100 >>%	| <<dd_di: %9.2f $partner_down_mom_component_1*100 >>%   | <<dd_di: %9.2f $partner_down_only_component_1*100 >>%   | <<dd_di: %9.2f $partner_leave_component_1*100 >>% | <<dd_di: %9.2f $other_hh_component_1*100 >>% |


### Results by race

| Group	        	 |   Total Gap                      | Rate Difference					 | Composition Difference     		  |
|:-------------------|:---------------------------------|:-----------------------------------|:-----------------------------------|
|	Overall	    	 | <<dd_di: %9.2f $total_gap*100 >>%	| <<dd_di: %9.2f $rate_diff*100 >>%      | <<dd_di: %9.2f $comp_diff*100 >>%      |
|	NH White		 | <<dd_di: %9.2f $total_gap_r1*100 >>%	| <<dd_di: %9.2f $rate_diff_r1*100 >>%   | <<dd_di: %9.2f $comp_diff_r1*100 >>%   |
|	Black			 | <<dd_di: %9.2f $total_gap_r2*100 >>%	| <<dd_di: %9.2f $rate_diff_r2*100 >>%   | <<dd_di: %9.2f $comp_diff_r2*100 >>%   |
|	Hispanic 		 | <<dd_di: %9.2f $total_gap_r4*100 >>%	| <<dd_di: %9.2f $rate_diff_r4*100 >>%   | <<dd_di: %9.2f $comp_diff_r4*100 >>%   |
|	NH Asian	 	 | <<dd_di: %9.2f $total_gap_r3*100 >>%	| <<dd_di: %9.2f $rate_diff_r3*100 >>%   | <<dd_di: %9.2f $comp_diff_r3*100 >>%   |



| Group	        	 |   Mom Component                      | Partner Down + Mom Up  								| Partner Down Only  							| Partner Left     								 | Other HH Down/Left						 |
|:-------------------|:-------------------------------------|:----------------------------------------------|:----------------------------------------------|:-----------------------------------------------|:----------------------------------------|
|	Overall	    	 | <<dd_di: %9.2f $mom_compt_x*100 >>%	| <<dd_di: %9.2f $partner_down_mom_compt_x*100 >>%    | <<dd_di: %9.2f $partner_down_only_compt_x*100 >>%    | <<dd_di: %9.2f $partner_leave_compt_x*100 >>%    | <<dd_di: %9.2f $other_hh_compt_x*100 >>%    |
|	NH White	 	 | <<dd_di: %9.2f $mom_component_r1*100 >>%	| <<dd_di: %9.2f $partner_down_mom_component_r1*100 >>% | <<dd_di: %9.2f $partner_down_only_component_r1*100 >>% | <<dd_di: %9.2f $partner_leave_component_r1*100 >>% | <<dd_di: %9.2f $other_hh_component_r1*100 >>% |
|	Black		 	 | <<dd_di: %9.2f $mom_component_r2*100 >>%	| <<dd_di: %9.2f $partner_down_mom_component_r2*100 >>% | <<dd_di: %9.2f $partner_down_only_component_r2*100 >>% | <<dd_di: %9.2f $partner_leave_component_r2*100 >>% | <<dd_di: %9.2f $other_hh_component_r2*100 >>% |
|	Hispanic 		 | <<dd_di: %9.2f $mom_component_r4*100 >>%	| <<dd_di: %9.2f $partner_down_mom_component_r4*100 >>% | <<dd_di: %9.2f $partner_down_only_component_r4*100 >>% | <<dd_di: %9.2f $partner_leave_component_r4*100 >>% | <<dd_di: %9.2f $other_hh_component_r4*100 >>% |
|	NH Asian	 	 | <<dd_di: %9.2f $mom_component_r3*100 >>%	| <<dd_di: %9.2f $partner_down_mom_component_r3*100 >>% | <<dd_di: %9.2f $partner_down_only_component_r3*100 >>% | <<dd_di: %9.2f $partner_leave_component_r3*100 >>% | <<dd_di: %9.2f $other_hh_component_r3*100 >>% |



### Results by education group

| Group	        	 |   Total Gap                      | Rate Difference					 | Composition Difference     		  |
|:-------------------|:---------------------------------|:-----------------------------------|:-----------------------------------|
|	Overall	    	 | <<dd_di: %9.2f $total_gap*100 >>%	| <<dd_di: %9.2f $rate_diff*100 >>%      | <<dd_di: %9.2f $comp_diff*100 >>%      |
|	HS or Less		 | <<dd_di: %9.2f $total_gap_e1*100 >>%	| <<dd_di: %9.2f $rate_diff_e1*100 >>%   | <<dd_di: %9.2f $comp_diff_e1*100 >>%   |
|	Some College	 | <<dd_di: %9.2f $total_gap_e2*100 >>%	| <<dd_di: %9.2f $rate_diff_e2*100 >>%   | <<dd_di: %9.2f $comp_diff_e2*100 >>%   |
|	College Plus 	 | <<dd_di: %9.2f $total_gap_e3*100 >>%	| <<dd_di: %9.2f $rate_diff_e3*100 >>%   | <<dd_di: %9.2f $comp_diff_e3*100 >>%   |



| Group	        	 |   Mom Component                      | Partner Down + Mom Up 								 | Partner Down Only 								| Partner Left     								 | Other HH Down/Left						 |
|:-------------------|:-------------------------------------|:----------------------------------------------|:-----------------------------------------------|:----------------------------------------|
|	Overall	    	 | <<dd_di: %9.2f $mom_compt_x*100 >>%	| <<dd_di: %9.2f $partner_down_mom_compt_x*100 >>%    | <<dd_di: %9.2f $partner_down_only_compt_x*100 >>%    | <<dd_di: %9.2f $partner_leave_compt_x>>%    | <<dd_di: %9.2f $other_hh_compt_x*100 >>%    |
|	HS or Less	 	 | <<dd_di: %9.2f $mom_component_e1*100 >>%	| <<dd_di: %9.2f $partner_down_mom_component_e1*100 >>% | <<dd_di: %9.2f $partner_down_only_component_e1*100 >>% | <<dd_di: %9.2f $partner_leave_component_e1*100 >>% | <<dd_di: %9.2f $other_hh_component_e1*100 >>% |
|	Some College 	 | <<dd_di: %9.2f $mom_component_e2*100 >>%	| <<dd_di: %9.2f $partner_down_mom_component_e2*100 >>% | <<dd_di: %9.2f $partner_down_only_component_e2*100 >>% | <<dd_di: %9.2f $partner_leave_component_e2*100 >>% | <<dd_di: %9.2f $other_hh_component_e2*100 >>% |
|	College Plus 	 | <<dd_di: %9.2f $mom_component_e3*100 >>%	| <<dd_di: %9.2f $partner_down_mom_component_e3*100 >>% | <<dd_di: %9.2f $partner_down_only_component_e3*100 >>% | <<dd_di: %9.2f $partner_leave_component_e3*100 >>% | <<dd_di: %9.2f $other_hh_component_e3*100 >>% |


## Specification 2: Mom category includes all instances where mom's earnings went up, regardless of what other changes occurred. 

The rate of transition into breadwinning in 1996 was <<dd_di: %9.2f $e2_bw_rate_96 >>%.
The rate of transition into breadwinning in 2014 was <<dd_di: %9.2f $e2_bw_rate_14 >>%.
This is a difference of <<dd_di: %9.2f $e2_total_gap >>%.

Of the total <<dd_di: %9.2f $e2_total_gap >>% difference, <<dd_di: %9.2f $e2_rate_diff >>% can be explained by rate differences between the two surveys (rate of transition once you experienced the event).
Of the total <<dd_di: %9.2f $e2_total_gap >>% difference, <<dd_di: %9.2f $e2_comp_diff >>% can be explained by compositional differences between the two surveys (e.g. how many people experienced the events).

Further breaking down the gap:
<<dd_di: %9.2f $e2_mom_component >>% could be attributed to the mother increasing component;
<<dd_di: %9.2f $e2_partner_down_component >>% could be attributed to the partner earnings decreasing component;
<<dd_di: %9.2f $e2_partner_leave_component >>% could be attributed to the partner leaving component;
<<dd_di: %9.2f $e2_other_hh_component >>% could be attributed to the other HH members losing earnings or leaving component.



### Results by education

| Group	        	 |   Total Gap                      | Rate Difference					| Composition Difference     		|
|:-------------------|:---------------------------------|:----------------------------------|:--------------------------------- |
|	Overall	    	 | <<dd_di: %9.2f $e2_total_gap >>%	| <<dd_di: %9.2f $e2_rate_diff >>%     | <<dd_di: %9.2f $e2_comp_diff >>%     |
|	College Educated | <<dd_di: %9.2f $e2_total_gap_4 >>%	| <<dd_di: %9.2f $e2_rate_diff_4 >>%   | <<dd_di: %9.2f $e2_comp_diff_4 >>%   |
|	Some College	 | <<dd_di: %9.2f $e2_total_gap_3 >>%	| <<dd_di: %9.2f $e2_rate_diff_3 >>%   | <<dd_di: %9.2f $e2_comp_diff_3 >>%   |
|	HS Degree		 | <<dd_di: %9.2f $e2_total_gap_2 >>%	| <<dd_di: %9.2f $e2_rate_diff_2 >>%   | <<dd_di: %9.2f $e2_comp_diff_2 >>%   |
|	Less than HS	 | <<dd_di: %9.2f $e2_total_gap_1 >>%	| <<dd_di: %9.2f $e2_rate_diff_1 >>%   | <<dd_di: %9.2f $e2_comp_diff_1 >>%   |


| Group	        	 |   Mom Component                      | Partner Down									 |Partner Left		     						 | Other HH Down/Left						   |
|:-------------------|:-------------------------------------|:-----------------------------------------------|:----------------------------------------------|:----------------------------------------|
|	Overall	    	 | <<dd_di: %9.2f $e2_mom_component >>%	| <<dd_di: %9.2f $e2_partner_down_component >>%     | <<dd_di: %9.2f $e2_partner_leave_component >>%   | <<dd_di: %9.2f $e2_other_hh_component >>%  |
|	College Educated | <<dd_di: %9.2f $e2_mom_component_4 >>%	| <<dd_di: %9.2f $e2_partner_down_component_4 >>%   | <<dd_di: %9.2f $e2_partner_leave_component_4 >>% | <<dd_di: %9.2f $e2_other_hh_component_4 >>% |
|	Some College	 | <<dd_di: %9.2f $e2_mom_component_3 >>%	| <<dd_di: %9.2f $e2_partner_down_component_3 >>%   | <<dd_di: %9.2f $e2_partner_leave_component_3 >>% | <<dd_di: %9.2f $e2_other_hh_component_3 >>% |
|	HS Degree		 | <<dd_di: %9.2f $e2_mom_component_2 >>%	| <<dd_di: %9.2f $e2_partner_down_component_2 >>%   | <<dd_di: %9.2f $e2_partner_leave_component_2 >>% | <<dd_di: %9.2f $e2_other_hh_component_2 >>% |
|	Less than HS	 | <<dd_di: %9.2f $e2_mom_component_1 >>%	| <<dd_di: %9.2f $e2_partner_down_component_1 >>%   | <<dd_di: %9.2f $e2_partner_leave_component_1 >>% | <<dd_di: %9.2f $e2_other_hh_component_1 >>% |


### Results by race

| Group	        	 |   Total Gap                      | Rate Difference					 | Composition Difference     		  |
|:-------------------|:---------------------------------|:-----------------------------------|:-----------------------------------|
|	Overall	    	 | <<dd_di: %9.2f $e2_total_gap >>%	| <<dd_di: %9.2f $e2_rate_diff >>%      | <<dd_di: %9.2f $e2_comp_diff >>%      |
|	NH White		 | <<dd_di: %9.2f $e2_total_gap_r1 >>%	| <<dd_di: %9.2f $e2_rate_diff_r1 >>%   | <<dd_di: %9.2f $e2_comp_diff_r1 >>%   |
|	Black			 | <<dd_di: %9.2f $e2_total_gap_r2 >>%	| <<dd_di: %9.2f $e2_rate_diff_r2 >>%   | <<dd_di: %9.2f $e2_comp_diff_r2 >>%   |
|	Hispanic 		 | <<dd_di: %9.2f $e2_total_gap_r4 >>%	| <<dd_di: %9.2f $e2_rate_diff_r4 >>%   | <<dd_di: %9.2f $e2_comp_diff_r4 >>%   |
|	NH Asian	 	 | <<dd_di: %9.2f $e2_total_gap_r3 >>%	| <<dd_di: %9.2f $e2_rate_diff_r3 >>%   | <<dd_di: %9.2f $e2_comp_diff_r3 >>%   |



| Group	        	 |   Mom Component                      | Partner Down  								| Partner Left     								 | Other HH Down/Left						 |
|:-------------------|:-------------------------------------|:----------------------------------------------|:-----------------------------------------------|:----------------------------------------|
|	Overall	    	 | <<dd_di: %9.2f $e2_mom_component >>%	| <<dd_di: %9.2f $e2_partner_down_component >>%    | <<dd_di: %9.2f $e2_partner_leave_component >>%    | <<dd_di: %9.2f $e2_other_hh_component >>%    |
|	NH White	 	 | <<dd_di: %9.2f $e2_mom_component_r1 >>%	| <<dd_di: %9.2f $e2_partner_down_component_r1 >>% | <<dd_di: %9.2f $e2_partner_leave_component_r1 >>% | <<dd_di: %9.2f $e2_other_hh_component_r1 >>% |
|	Black		 	 | <<dd_di: %9.2f $e2_mom_component_r2 >>%	| <<dd_di: %9.2f $e2_partner_down_component_r2 >>% | <<dd_di: %9.2f $e2_partner_leave_component_r2 >>% | <<dd_di: %9.2f $e2_other_hh_component_r2 >>% |
|	Hispanic 		 | <<dd_di: %9.2f $e2_mom_component_r4 >>%	| <<dd_di: %9.2f $e2_partner_down_component_r4 >>% | <<dd_di: %9.2f $e2_partner_leave_component_r4 >>% | <<dd_di: %9.2f $e2_other_hh_component_r4 >>% |
|	NH Asian	 	 | <<dd_di: %9.2f $e2_mom_component_r3 >>%	| <<dd_di: %9.2f $e2_partner_down_component_r3 >>% | <<dd_di: %9.2f $e2_partner_leave_component_r3 >>% | <<dd_di: %9.2f $e2_other_hh_component_r3 >>% |



### Results by education group

| Group	        	 |   Total Gap                      | Rate Difference					 | Composition Difference     		  |
|:-------------------|:---------------------------------|:-----------------------------------|:-----------------------------------|
|	Overall	    	 | <<dd_di: %9.2f $e2_total_gap >>%	| <<dd_di: %9.2f $e2_rate_diff >>%      | <<dd_di: %9.2f $e2_comp_diff >>%      |
|	HS or Less		 | <<dd_di: %9.2f $e2_total_gap_e1 >>%	| <<dd_di: %9.2f $e2_rate_diff_e1 >>%   | <<dd_di: %9.2f $e2_comp_diff_e1 >>%   |
|	Some College	 | <<dd_di: %9.2f $e2_total_gap_e2 >>%	| <<dd_di: %9.2f $e2_rate_diff_e2 >>%   | <<dd_di: %9.2f $e2_comp_diff_e2 >>%   |
|	College Plus 	 | <<dd_di: %9.2f $e2_total_gap_e3 >>%	| <<dd_di: %9.2f $e2_rate_diff_e3 >>%   | <<dd_di: %9.2f $e2_comp_diff_e3 >>%   |



| Group	        	 |   Mom Component                      | Partner Down 									| Partner Left     								 | Other HH Down/Left						 |
|:-------------------|:-------------------------------------|:----------------------------------------------|:-----------------------------------------------|:----------------------------------------|
|	Overall	    	 | <<dd_di: %9.2f $e2_mom_component >>%	| <<dd_di: %9.2f $e2_partner_down_component >>%    | <<dd_di: %9.2f $e2_partner_leave_component >>%    | <<dd_di: %9.2f $e2_other_hh_component >>%    |
|	HS or Less	 	 | <<dd_di: %9.2f $e2_mom_component_e1 >>%	| <<dd_di: %9.2f $e2_partner_down_component_e1 >>% | <<dd_di: %9.2f $e2_partner_leave_component_e1 >>% | <<dd_di: %9.2f $e2_other_hh_component_e1 >>% |
|	Some College 	 | <<dd_di: %9.2f $e2_mom_component_e2 >>%	| <<dd_di: %9.2f $e2_partner_down_component_e2 >>% | <<dd_di: %9.2f $e2_partner_leave_component_e2 >>% | <<dd_di: %9.2f $e2_other_hh_component_e2 >>% |
|	College Plus 	 | <<dd_di: %9.2f $e2_mom_component_e3 >>%	| <<dd_di: %9.2f $e2_partner_down_component_e3 >>% | <<dd_di: %9.2f $e2_partner_leave_component_e3 >>% | <<dd_di: %9.2f $e2_other_hh_component_e3 >>% |


