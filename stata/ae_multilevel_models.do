*-------------------------------------------------------------------------------
* BREADWINNER PROJECT
* predicting_consequences.do
* Kim McErlean
*-------------------------------------------------------------------------------
di "$S_DATE"

********************************************************************************
* DESCRIPTION
* Multi-level models - this actually allows us to predict BOTH initial level and rate of change?? So is this actually BETTER?!
********************************************************************************
* I am currently following Lecture 2 and 3-4 from Dan's class

use "$tempdir/bw_consequences_long.dta", clear

gen percentile_chg_real = percentile_chg
repace percentile_chg_real = . if time==1

spagplot percentile_ time, id(id) nofit

spagplot percentile_ time if id>100 & id <200, id(id) nofit

gen time2 = time-1
sum percentile_chg

********************************************************************************
* Models
********************************************************************************
// okay don't get r-squared but can do LR tests?

// unconditional means model 
mixed percentile_ || id: , mle var // 4.95 - this is the same as doing sum percentile_

// unconditional growth model
mixed percentile_ time2 || id: time2, cov(un) mle var // this is the same as below individual
/*

------------------------------------------------------------------------------
 percentile_ | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
       time2 |  -.3730887   .0760333    -4.91   0.000    -.5221111   -.2240662
       _cons |    5.14475   .0967562    53.17   0.000     4.955112    5.334389
------------------------------------------------------------------------------
*/


mixed percentile_ time2 || id: time2, mle var // results same as above, it's the random effects parameters that are different

// adding predictors - okay but probably need to INTERACT with time?! (see slide 35 - and I think what I did for growth curves?)
mixed percentile_ time2 i.educ_gp || id: time2, mle var

/* is this the same as this? tabstat percentile_, by(educ_gp)
Okay YES - so this is TOTAL difference

-------------------------------------------------------------------------------
  percentile_ | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
--------------+----------------------------------------------------------------
        time2 |  -.3730887   .0760332    -4.91   0.000     -.522111   -.2240664
              |
      educ_gp |
Some College  |   .9912778   .1782986     5.56   0.000     .6418188    1.340737
College Plus  |   3.377979   .1809451    18.67   0.000     3.023334    3.732625
              |
        _cons |   3.750312   .1300565    28.84   0.000     3.495406    4.005219
-------------------------------------------------------------------------------


     educ_gp |      Mean
-------------+----------
  Hs or Less |  3.563768
Some College |  4.555046
College Plus |  6.941748
-------------+----------
       Total |  4.958206
------------------------
SC - HS = 0.995
College - HS  = 3.38 

*/

mixed percentile_ time2 i.race_gp || id: time2, mle var
mixed percentile_ time2 i.pathway || id: time2, mle var

// gen path_time = pathway*time
// gen educ_time = educ_gp*time
// gen race_time = race_gp*time

mixed percentile_ i.time2##i.educ_gp|| id: time2, mle var

/*
---------------------------------------------------------------------------------
    percentile_ | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
----------------+----------------------------------------------------------------
        1.time2 |  -.4318841   .1278405    -3.38   0.001    -.6824468   -.1813213
                |
        educ_gp |
  Some College  |   1.052094   .2004667     5.25   0.000     .6591866    1.445002
  College Plus  |    3.22029   .2034423    15.83   0.000      2.82155    3.619029
                |
  time2#educ_gp |
1#Some College  |  -.1216328   .1832649    -0.66   0.507    -.4808253    .2375598
1#College Plus  |   .3153792   .1859851     1.70   0.090    -.0491448    .6799032
                |
          _cons |    3.77971     .13984    27.03   0.000     3.505629    4.053792
---------------------------------------------------------------------------------

so the coefficients on own are differences in INITIAL level
then the interaction is the difference in AVERAGE change

tabstat percentile_ if time==1, by(educ_gp)
sc-hs = 1.05
coll-hs = 3.22

     educ_gp |      Mean
-------------+----------
  Hs or Less |   3.77971
Some College |  4.831804
College Plus |         7
-------------+----------
       Total |   5.14475
	   
tabstat percentile_chg, by(educ_gp)
sc-hs = -0.12
coll-hs = 0.314

     educ_gp |      Mean
-------------+----------
  Hs or Less | -.4318841
Some College | -.5535168
College Plus | -.1165049
-------------+----------
       Total | -.3730887
------------------------


tabstat percentile_ if time==2, by(educ_gp)	

     educ_gp |      Mean
-------------+----------
  Hs or Less |  3.347826
Some College |  4.278287
College Plus |  6.883495
-------------+----------
       Total |  4.771662
------------------------

*/


mixed percentile_ i.time2##i.race_gp|| id: time2, mle var
/*
-------------------------------------------------------------------------------
  percentile_ | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
--------------+----------------------------------------------------------------
      1.time2 |  -.4158607   .1046219    -3.97   0.000    -.6209159   -.2108055
              |
      race_gp |
       Black  |  -1.743542   .2505271    -6.96   0.000    -2.234567   -1.252518
    Hispanic  |  -1.393981   .2376892    -5.86   0.000    -1.859843   -.9281186
           4  |  -.5880744   .3319552    -1.77   0.076    -1.238695    .0625459
              |
time2#race_gp |
     1#Black  |  -.0469964   .2080447    -0.23   0.821    -.4547566    .3607638
  1#Hispanic  |   .2574449   .1973838     1.30   0.192    -.1294202      .64431
         1 4  |  -.0209209    .275665    -0.08   0.940    -.5612143    .5193725
              |
        _cons |   5.794971   .1259855    46.00   0.000     5.548044    6.041898
-------------------------------------------------------------------------------
*/


mixed percentile_ i.time2##i.pathway|| id: time2, mle var

/*
----------------------------------------------------------------------------------------
           percentile_ | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-----------------------+----------------------------------------------------------------
               1.time2 |   1.334951   .1341123     9.95   0.000     1.072096    1.597807
                       |
               pathway |
     Mom Up, employed  |   5.760213   .2516066    22.89   0.000     5.267073    6.253353
  Mom Up Partner Down  |   4.939376   .1928794    25.61   0.000     4.561339    5.317413
         Partner Down  |   6.438534   .2245345    28.68   0.000     5.998454    6.878613
         Partner Left  |   4.964486   .2568828    19.33   0.000     4.461005    5.467967
      Other HH Change  |   3.760386   .2139416    17.58   0.000     3.341068    4.179704
                       |
         time2#pathway |
   1#Mom Up, employed  |   .3581179   .2338175     1.53   0.126     -.100156    .8163917
1#Mom Up Partner Down  |  -1.758616   .1792424    -9.81   0.000    -2.109924   -1.407307
       1#Partner Down  |  -3.893572   .2086594   -18.66   0.000    -4.302537   -3.484607
       1#Partner Left  |  -2.745478   .2387206   -11.50   0.000    -3.213362   -2.277594
    1#Other HH Change  |  -2.474486   .1988155   -12.45   0.000    -2.864158   -2.084815
                       |
                 _cons |   1.140777   .1443157     7.90   0.000     .8579231     1.42363
----------------------------------------------------------------------------------------
*/

mixed thearn_ i.time2##i.educ_gp|| id: time2, mle var
/*

---------------------------------------------------------------------------------
        thearn_ | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
----------------+----------------------------------------------------------------
        1.time2 |  -7046.012   4565.623    -1.54   0.123    -15994.47    1902.446
                |
        educ_gp |
  Some College  |   14104.38   5438.754     2.59   0.010     3444.616    24764.14
  College Plus  |   71361.66   5519.481    12.93   0.000     60543.67    82179.64
                |
  time2#educ_gp |
1#Some College  |   3890.715   6545.018     0.59   0.552    -8937.284    16718.71
1#College Plus  |   7892.581   6642.166     1.19   0.235    -5125.825    20910.99
                |
          _cons |   36861.57   3793.924     9.72   0.000     29425.61    44297.52
---------------------------------------------------------------------------------
*/

mixed thearn_ i.time2##i.race_gp|| id: time2, mle var
/*

-------------------------------------------------------------------------------
      thearn_ | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
--------------+----------------------------------------------------------------
      1.time2 |  -3920.044   3729.776    -1.05   0.293    -11230.27    3390.182
              |
      race_gp |
       Black  |  -38193.98   6545.735    -5.83   0.000    -51023.39   -25364.58
    Hispanic  |  -34357.47   6210.308    -5.53   0.000    -46529.45   -22185.49
           4  |  -8342.915   8673.277    -0.96   0.336    -25342.23    8656.395
              |
time2#race_gp |
     1#Black  |  -3023.961   7416.803    -0.41   0.683    -17560.63    11512.71
  1#Hispanic  |   6385.886    7036.74     0.91   0.364    -7405.871    20177.64
         1 4  |    -1336.3   9827.467    -0.14   0.892    -20597.78    17925.18
              |
        _cons |   78668.78   3291.731    23.90   0.000      72217.1    85120.45
-------------------------------------------------------------------------------

*/

mixed thearn_ i.time2##i.pathway|| id: time2, mle var

/*

----------------------------------------------------------------------------------------
               thearn_ | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-----------------------+----------------------------------------------------------------
               1.time2 |   19966.09   5212.847     3.83   0.000     9749.095    30183.08
                       |
               pathway |
     Mom Up, employed  |   86735.76   8096.868    10.71   0.000     70866.19    102605.3
  Mom Up Partner Down  |   76113.84   6206.987    12.26   0.000     63948.37    88279.31
         Partner Down  |   118415.9   7225.669    16.39   0.000     104253.9      132578
         Partner Left  |    76560.4   8266.658     9.26   0.000     60358.05    92762.75
      Other HH Change  |    46847.1   6884.782     6.80   0.000     33353.17    60341.02
                       |
         time2#pathway |
   1#Mom Up, employed  |    67713.1   9088.317     7.45   0.000     49900.33    85525.87
1#Mom Up Partner Down  |  -27107.16   6967.023    -3.89   0.000    -40762.28   -13452.05
       1#Partner Down  |  -84550.69   8110.442   -10.42   0.000    -100446.9   -68654.52
       1#Partner Left  |  -48893.06   9278.898    -5.27   0.000    -67079.36   -30706.75
    1#Other HH Change  |  -32674.73   7727.814    -4.23   0.000    -47820.96   -17528.49
                       |
                 _cons |   1652.083   4644.175     0.36   0.722    -7450.332     10754.5
----------------------------------------------------------------------------------------

*/

/*
save "$tempdir/bw_consequences_long.dta", replace

statsby "regress percentile_ time2" _b[_cons] _se[_cons] _b[time] ///
 _se[time] (e(rmse)^2) e(r2), by(id)
gen b0 = _stat_1
gen seb0 = _stat_2
gen b1 = _stat_3
gen seb1 = _stat_4
gen sigma2 = _stat_5
gen r2 = _stat_6
label var b0 "intercept"
label var b1 "slope"
sum b0 b1 sigma2
corr b0 b1
list b0 b1 sigma2 r2, clean

/*
. sum b0 b1 sigma2


    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
          b0 |        981     5.14475    3.032047          1         10
          b1 |        981   -.3730887    2.382643         -9          8
      sigma2 |        981           0           0          0          0

	 
	 
sum percentile_ if time==1 // mean = 5.14 // okay it becomes a match when I update time (need it to startat 0, not 1)
sum percentile_ if time==2 // mean = 4.77 - okay so that difference is -0.37
sum percentile_chg // -0.37	  

this correlation is that higher initial levels have faster decline?


             |       b0       b1
-------------+------------------
          b0 |   1.0000
          b1 |  -0.4555   1.0000

*/

*/