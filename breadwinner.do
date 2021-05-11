*-------------------------------------------------------------------------------
* BREADWINNER-PREDICTOR PROJECT
* Kim McErlean, Kelly Raley and Joanna Pepin
*-------------------------------------------------------------------------------
* This is the main do file that runs all of the scripts in order to create the 
* tables accompaning the publication. This scripts expects that you are in
* its directory when you execute it. 

cd ./stata

do 00_setup_breadwinner_environment.do

// 2014 SIPP analysis

do "$SIPP2014_code/breadwinner-predictorsSIPP14.do"

// 1996 SIPP analysis
do "$SIPP1996_code/breadwinner-predictorsSIPP96.do"
