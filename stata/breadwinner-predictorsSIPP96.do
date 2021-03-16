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
* cd ".../Breadwinner-predictors/stata" 

set maxvar 5500

// Run the setup script
	do "00_sipp14_setup_breadwinner_environment"
	
********************************************************************************
* A2. DATA
********************************************************************************
* This project uses Wave 1-12 of the 1996 Core SIPP data files, as well as 
* Wave 2 Topical Modules. They can be downloaded here:
* https://www.census.gov/programs-surveys/sipp/data/datasets.html

// Extract the variables for this project and merge across waves
    log using "$logdir/extract_and_merge_for_HH96.log",	replace 
    do "$SIPP2014_code/a_sipp96_extract_and_merge_for_HH.do"
    log close


********************************************************************************
* B1. DEMOGRAPHICS AND ANALYTIC SAMPLE
********************************************************************************
* Execute a series of scripts to develop measures of household composition
* This script was adapted from the supplementary materials for the journal article 
* [10.1007/s13524-019-00806-1]
* (https://link.springer.com/article/10.1007/s13524-019-00806-1#SupplementaryMaterial).

// Create a file with demographic information and relationship types
    log using "$logdir/compute_relationships96.log", replace
    do "$SIPP2014_code/b_sipp96_compute_relationships.do"
    log close

// Create a monthly file with just household composition, includes type2 people
	log using "$logdir/create_hhcomp96.log", replace
	do "$SIPP2014_code/c_sipp96_create_hhcomp.do"
	log close
	
// Create the extract for mothers specifically to get ready for sample creation
	log using "$logdir/extract_and_merge_for_moms96.log",	replace 
	do "$SIPP2014_code/d_sipp96_extract_and_merge_for_moms.do"
	log close
	
// Create a monthly file with earnings & demographic measures. Create analytic sample.
	log using "$logdir/measures_and_sample96.log", replace
	do "$SIPP2014_code/e_sipp96_measures_and_sample.do"
	log close
	
// Merging with HH characteristics to use for predictions
	log using "$logdir/merging_hh_characteristics96.log", replace
	do "$SIPP2014_code/f_sipp96_merging_hh_characteristics.do"
	log close
	
********************************************************************************
* B2. BREADWINNER INDICATORS
********************************************************************************
*Execute breadwinner scripts

// Create annual measures of breadwinning
	log using "$logdir/annualize96.log", replace
	do "$SIPP2014_code/g_sipp96_annualize.do"
	log close

// Create descriptive statistics of who transitions to BW
	log using "$logdir/bw_descriptives96.log", replace
	do "$SIPP2014_code/h_sipp96_bw_descriptives.do"
	log close

********************************************************************************
* C1. COMBINED EVENT HISTORY MODELS
********************************************************************************

// Appends 2014 and 1996 files and executes analysis
	log using "$logdir/combined_models.log", replace
	do "$SIPP2014_code/aa_combined_models.do"
	log close