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

// Appends 2014 and 1996 files and executes analysis
	log using "$logdir/combined_models.log", replace
	do aa_combined_models.do
	log close
	
********************************************************************************
* D1. DECOMPOSITION ANALYSIS
********************************************************************************

// Appends 2014 and 1996 files and executes analysis
	log using "$logdir/decomposition_equation.log", replace
	do ab_decomposition_equation.do
	log close
