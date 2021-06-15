
use "$CPS/cps_1996_2014.dta", clear

//restricted sample to females BEFORE downloading
// restricting to those with children in the household - probably over-simplified but best I have  without doing complex household relationships
keep if nchild > 0

recode educ (1/71=1) (73=2) (81/92=3) (100/125=4), gen(education)
label define educ 1 "Less than HS" 2 "HS" 3 "some college" 4 "College plus"
label values education educ

save "$tempdir/cps_educ.dta", replace

tab year education, row

/*

           |   RECODE of educ (Educational attainment
    Survey |                   recode)
      year | Less than         HS  some coll  College p |     Total
-----------+--------------------------------------------+----------
      1996 |     4,487      8,315      6,265      4,418 |    23,485 
           |     19.11      35.41      26.68      18.81 |    100.00 
-----------+--------------------------------------------+----------
      2014 |     4,537      9,737     10,735     11,831 |    36,840 
           |     12.32      26.43      29.14      32.11 |    100.00 
-----------+--------------------------------------------+----------
     Total |     9,024     18,052     17,000     16,249 |    60,325 
           |     14.96      29.92      28.18      26.94 |    100.00 

. 
*/

use "$ACS/acs_1990_2014.dta", clear
// 2000 sample is very small  - and it's not 5% so confused.

// testing 2 different specifications: children in HH  v. children born in last year (the latter doesn't necessarily relate to our full sample, but want to test different specifications)

recode educ (0/5=1) (6=2) (7/8=3) (10/11=4), gen(education)
label define educ 1 "Less than HS" 2 "HS" 3 "some college" 4 "College plus"
label values education educ


tab year education if fertyr==2, row // fertyr not in 1990
/*

           |   RECODE of educ (Educational attainment
    Census |             [general version])
      year | Less than         HS  some coll  College p |     Total
-----------+--------------------------------------------+----------
      2000 |       776      1,917      1,184      1,461 |     5,338 
           |     14.54      35.91      22.18      27.37 |    100.00 
-----------+--------------------------------------------+----------
      2014 |     3,681     10,853      8,669     12,311 |    35,514 
           |     10.36      30.56      24.41      34.67 |    100.00 
-----------+--------------------------------------------+----------
     Total |     4,457     12,770      9,853     13,772 |    40,852 
           |     10.91      31.26      24.12      33.71 |    100.00 
*/

tab year education if chborn>1 & chborn!=., row // only in 1990, not directly comparable to above
/*

           |   RECODE of educ (Educational attainment
    Census |             [general version])
      year | Less than         HS  some coll  College p |     Total
-----------+--------------------------------------------+----------
      1990 |   865,701  1,388,971    856,620    466,862 | 3,578,154 
           |     24.19      38.82      23.94      13.05 |    100.00 
-----------+--------------------------------------------+----------
     Total |   865,701  1,388,971    856,620    466,862 | 3,578,154 
           |     24.19      38.82      23.94      13.05 |    100.00 
*/

tab year education if nchild > 0, row // in all
/*
          |   RECODE of educ (Educational attainment
    Census |             [general version])
      year | Less than         HS  some coll  College p |     Total
-----------+--------------------------------------------+----------
      1990 |   425,765    849,202    601,465    339,520 | 2,215,952 
           |     19.21      38.32      27.14      15.32 |    100.00 
-----------+--------------------------------------------+----------
      2000 |     7,996     25,590     14,607     14,947 |    63,140 
           |     12.66      40.53      23.13      23.67 |    100.00 
-----------+--------------------------------------------+----------
      2014 |    54,964    164,213    121,069    149,300 |   489,546 
           |     11.23      33.54      24.73      30.50 |    100.00 
-----------+--------------------------------------------+----------
     Total |   488,725  1,039,005    737,141    503,767 | 2,768,638 
           |     17.65      37.53      26.62      18.20 |    100.00 

*/