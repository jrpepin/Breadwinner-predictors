// 1996 descriptives
use "$SIPP14keep/96_bw_descriptives.dta", clear

label define emomlivh 1 "Yes" 2 "No"
label values emomlivh emomlivh

putexcel set "$results/overtime_comparison.xlsx", replace

tabout bw60 using "$results/overtime_comparison.xlsx", c(freq row) clab(1996 Percent) layout(cb) f(0c 1p) style(xlsx) title(Overall Breadwinner Status - 1996) append
tabout year bw60 using "$results/overtime_comparison.xlsx", c(freq row) clab(1996 Percent) layout(cb) style(xlsx) title(Breadwinner Status by Year - 1996) f(0c 1p) location(10 1) append
tabout educ bw60 using "$results/overtime_comparison.xlsx", c(freq row) clab(1996 Percent) layout(cb) f(0c 1p) style(xlsx) title(Breadwinner Status by Education - 1996) location(25 1) append
tabout emomlivh bw60 using "$results/overtime_comparison.xlsx", c(freq row) clab(1996 Percent) layout(cb) f(0c 1p) style(xlsx) title(Breadwinner Status by Children's Living - 1996) location(40 1)append

tabout trans_bw60 using "$results/overtime_comparison.xlsx", c(freq row) clab(1996 Percent) layout(cb) f(0c 1p) style(xlsx) title(Overall Breadwinner Transitions - 1996) location(55 1) append
tabout year trans_bw60 using "$results/overtime_comparison.xlsx", c(freq row) clab(1996 Percent) layout(cb) f(0c 1p) style(xlsx) title(Breadwinner Transitions by Year - 1996) location(65 1) append
tabout educ trans_bw60 using "$results/overtime_comparison.xlsx", c(freq row) clab(1996 Percent) layout(cb)f(0c 1p) style(xlsx) title(Breadwinner Transitions by Education - 1996) location(80 1) append
tabout emomlivh trans_bw60 using "$results/overtime_comparison.xlsx", c(freq row) clab(1996 Percent) layout(cb) f(0c 1p) style(xlsx) title(Breadwinner Transitions by Children's Living - 1996) location(95 1) append


// 2014 descriptives
use "$SIPP14keep/bw_descriptives.dta", clear

putexcel set "$results/overtime_comparison.xlsx", modify

tabout bw60 using "$results/overtime_comparison.xlsx", c(freq row) clab(2014 Percent) layout(cb) f(0c 1p) style(xlsx) title(Overall Breadwinner Status - 2014) location (1 12) append
tabout year bw60 using "$results/overtime_comparison.xlsx", c(freq row) clab(2014 Percent) layout(cb) style(xlsx) title(Breadwinner Status by Year - 2014) f(0c 1p) location(10 12) append
tabout educ bw60 using "$results/overtime_comparison.xlsx", c(freq row) clab(2014 Percent) layout(cb) f(0c 1p) style(xlsx) title(Breadwinner Status by Education - 2014) location(25 12) append

tabout trans_bw60 using "$results/overtime_comparison.xlsx", c(freq row) clab(2014 Percent) layout(cb) f(0c 1p) style(xlsx) title(Overall Breadwinner Transitions - 2014) location(55 12) append
tabout year trans_bw60 using "$results/overtime_comparison.xlsx", c(freq row) clab(2014 Percent) layout(cb) f(0c 1p) style(xlsx) title(Breadwinner Transitions by Year - 2014) location(65 12) append
tabout educ trans_bw60 using "$results/overtime_comparison.xlsx", c(freq row) clab(2014 Percent) layout(cb)f(0c 1p) style(xlsx) title(Breadwinner Transitions by Education - 2014) location(80 12) append
