* This is an example setup file. You should create your own setup file named
* setup_username.do that replaces the directories for project code, log files,
* etc to the location for these files on your computer

* STANDARD PROJECT MACROS-------------------------------------------------------
global projcode 		"$homedir/github/Breadwinner-predictors"
global logdir 			"$homedir/logs/breadwinner-predictors"
global tempdir 			"$homedir/data/tmp"

// Where you want produced tables, html or putdoc output files to go (NOT SHARED)
global results 			"$homedir/projects/breadwinner-predictors/results"

* PROJECT SPECIFIC MACROS-------------------------------------------------------
// SIPP 2014
global SIPP2014 		"$homedir/data/sipp/2014"
global SIPP2014_code 	"$projcode/stata"
global SIPP14keep 		"$homedir/projects/breadwinner-predictors/data"

// SIPP 1996
global SIPP1996			"$homedir/data/sipp/1996"
global SIPP1996tm 		"/data/sipp/1996_TM/StataData"
global SIPP1996_code 		"$projcode/stata/1996"
global SIPP96keep 		"$homedir/projects/breadwinner-predictor/data/keep/1996"

// combined data

global combined_data 		"$homedir/projects/breadwinner-predictor/data/keep/combined"
