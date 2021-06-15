
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