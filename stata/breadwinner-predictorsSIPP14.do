*-------------------------------------------------------------------------------
* BREADWINNER PROJECT
* breadwinnner14.do
* Kelly Raley and Joanna Pepin
*-------------------------------------------------------------------------------
* The goal of these files is to create estimates of breadwinning

********************************************************************************
* A1. ENVIRONMENT
********************************************************************************
* There are two scripts users need to run before running the first .do file. 
	* First, create a personal setup file using the setup_example.do script as a 
	* template and save this file in the base project directory.

	* Second, run the setup_breadwinnerNLSY97_environment script to set the project 
	* filepaths and macros.

//------------------------------------------------------------------------------

* The current directory is assumed to be the stata directory within the NLSY sub-directory.
* cd ".../Breadwinner/SIPP/stata" 

// Run the setup script
	do "00_sipp14_setup_breadwinner_environment"

********************************************************************************
* A2. DATA
********************************************************************************
* This project uses Wave 1-4 of the 2014 SIPP data files. They can be downloaded here:
* https://www.census.gov/programs-surveys/sipp/data/datasets.html

// Extract the variables for this project
    log using "$logdir/extract_and_format.log",	replace 
    do "$SIPP2014_code/01_sipp14_extract_and_format.do"
    log close

// Merge the waves of data to create two datafiles (type 1 and type 2 records)
    log using "$logdir/merge_waves.log", replace
    do "$SIPP2014_code/02_sipp14_merge_waves.do"
    log close
	
// Recode variables as needed to simplify
	log using "$logdir/variable_recodes.log", replace
	do "$SIPP2014_code/03_sipp14_variable_recodes.do"
	log close

********************************************************************************
* B1. DEMOGRAPHICS AND ANALYTIC SAMPLE
********************************************************************************
* Execute a series of scripts to develop measures of household composition
* This script was adapted from the supplementary materials for the journal article 
* [10.1007/s13524-019-00806-1]
* (https://link.springer.com/article/10.1007/s13524-019-00806-1#SupplementaryMaterial).

// Create a file with demographic information and relationship types
    log using "$logdir/compute_relationships.log", replace
    do "$SIPP2014_code/04_sipp14_compute_relationships.do"
    log close

// Create a monthly file with just household composition, includes type2 people
	log using "$logdir/create_hhcomp.log", replace
	do "$SIPP2014_code/05_sipp14_create_hhcomp.do"
	log close
	
// Create a monthly file with earnings & demographic measures. Create analytic sample.
	log using "$logdir/measures_and_sample.log", replace
	do "$SIPP2014_code/06_sipp14_measures_and_sample.do"
	log close
	
// Merging with HH characteristics to use for predictions
	log using "$logdir/merging_hh_characteristics.log", replace
	do "$SIPP2014_code/07_sipp14_merging_hh_characteristics.do"
	log close
	
********************************************************************************
* B2. BREADWINNER INDICATORS
********************************************************************************
*Execute breadwinner scripts

// Create annual measures of breadwinning
	log using "$logdir/annualize.log", replace
	do "$SIPP2014_code/08_sipp14_annualize.do"
	log close

// Create indicators of transitions into and out of breadwinning
	log using "$logdir/bw_transitions.log", replace
	do "$SIPP2014_code/09_sipp14_bw_transitions.do"
	log close

