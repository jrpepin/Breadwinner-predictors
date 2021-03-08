*-------------------------------------------------------------------------------
* BREADWINNER-PREDICTOR PROJECT
* Kelly Raley and Joanna Pepin
*-------------------------------------------------------------------------------
* This is the main do file that runs all of the scripts in order to create the 
* tables accompaning the publication. This scripts expects that you are in
* its directory when you execute it. 

set maxvar 5500

// 2014 SIPP analysis
cd ./stata
do breadwinner-predictorsSIPP14.do

// 1996 SIPP analysis
do breadwinner-predictorsSIPP96.do