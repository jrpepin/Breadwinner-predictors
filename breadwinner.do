*-------------------------------------------------------------------------------
* BREADWINNER-PREDICTOR PROJECT
* Kim McErlean, Kelly Raley and Joanna Pepin
*-------------------------------------------------------------------------------
* This is the main do file that runs all of the scripts in order to create the 
* tables accompaning the publication. This scripts expects that you are in
* its directory when you execute it. 

// 2014 SIPP analysis

* It is not necessary to cd into ./stata because you are using macros. 
* and cd into ./stata causes troubles if one encoungers an error and has to start again.
* cd ./stata
do "$SIPP2014_code/breadwinner-predictorsSIPP14.do"

// 1996 SIPP analysis
do "$SIPP2014_code/breadwinner-predictorsSIPP96.do"
