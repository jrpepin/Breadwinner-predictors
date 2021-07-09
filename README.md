# Breadwinner-predictors
Predicting mothers' transitions into and out of primary-earning using the 1996 and 2014 SIPPs.

##Instructions to run the code
* Before running the code, first, 
	* create a personal setup file using setup_example.do script as a template and save this file in the base project directory.
	* change into the base code directory (/stata) and do 00_setup_breadwinner_environment.do
* then run breadwinner.do


##Where to get the data
* The 2014 data can be downloaded from: https://www.census.gov/programs-surveys/sipp/data/datasets.2014.html. You need all four waves as well as the Social Security Administration supplement (that is used to categorize marital status at first birth).
* The 1996 data can be downloaded from: https://www.census.gov/programs-surveys/sipp/data/datasets.1996.html. You need the core files from all 12 waves, and the topical module from Wave 2 (https://www.census.gov/programs-surveys/sipp/data/datasets/1996-panel/wave-2.html), which contains marital and fertility histories.
* Once you have downloaded the data, ensure it is saved in the location you reference in your setup file.