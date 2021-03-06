*-------------------------------------------------------------------------------
* BREADWINNER PROJECT
* setup_breadwinner_environment.do

*-------------------------------------------------------------------------------
version 16
********************************************************************************
* Setup project macros
********************************************************************************
global bw_base_code "`c(pwd)'" 	/// Creating macro of project working directory

global inflate_adj 1.509 /// Creating a macro to set the adjustment for setting 1996 $ to 2014 - this way, only need to change in 1 place

********************************************************************************
* Setup personal file paths
********************************************************************************
* Use setup_example to set your local filepath macros. 
* This file should be named named setup_<username>.do
* and saved in the base project directory.

// Create a home directory macro, depending on OS.
if ("`c(os)'" == "Windows") {
    local temp_drive : env HOMEDRIVE
    local temp_dir : env HOMEPATH
    global homedir "`temp_drive'`temp_dir'"
    macro drop _temp_drive _temp_dir`
}
else {
    if ("`c(os)'" == "MacOSX") | ("`c(os)'" == "Unix") {
        global homedir : env HOME
    }
    else {
        display "Unknown operating system:  `c(os)'"
        exit
    }
}


// Checks that the setup file exists and runs it.
capture confirm file "setup_`c(username)'.do"
if _rc==0 {
    do setup_`c(username)'
      }
  else {
    display as error "The file setup_`c(username)'.do does not exist"
	exit
  }

// We require a logdir for the project be set.
if ("$logdir" == "") {
    display as error "logdir macro not set."
    exit
}

set maxvar 5500

********************************************************************************
* Check for package dependencies 
********************************************************************************
* This checks for packages that the user should install prior to running the project do files.

// fre: https://ideas.repec.org/c/boc/bocode/s456835.html
capture : which fitstat
if (_rc) {
    display as error in smcl `"Please install package {it:fitstat} from SSC in order to run these do-files;"' _newline ///
        `"you can do so by clicking this link: {stata "ssc install fitstat":auto-install fitstat}"'
    exit 199
}


/*
// fre: https://ideas.repec.org/c/boc/bocode/s456835.html
capture : which fre
if (_rc) {
    display as error in smcl `"Please install package {it:fre} from SSC in order to run these do-files;"' _newline ///
        `"you can do so by clicking this link: {stata "ssc install fre":auto-install fre}"'
    exit 199
}

// unique: https://ideas.repec.org/c/boc/bocode/s354201.html
capture : which unique
if (_rc) {
    display as error in smcl `"Please install package {it:unique} from SSC in order to run these do-files;"' _newline ///
        `"you can do so by clicking this link: {stata "ssc install unique":auto-install unique}"'
    exit 199
}

// ereplace: https://ideas.repec.org/c/boc/bocode/s458420.html
capture : which ereplace
if (_rc) {
    display as error in smcl `"Please install package {it:ereplace} from SSC in order to run these do-files;"' _newline ///
        `"you can do so by clicking this link: {stata "ssc install ereplace":auto-install ereplace}"'

    exit 199
}


// lxpct_2: https://ideas.repec.org/c/boc/bocode/s453001.html
capture : which lxpct_2
if (_rc) {
    display as error in smcl `"Please install package {it:lxpct_2} from SSC in order to run these do-files;"' _newline ///
        `"you can do so by clicking this link: {stata "ssc install lxpct_2":auto-install lxpct_2}"'

    exit 199
}


// https://ideas.repec.org/c/boc/bocode/s456409.html
capture : which cdfplot
if (_rc) {
    display as error in smcl `"Please install package {it:cdfplot} from SSC in order to run these do-files;"' _newline ///
        `"you can do so by clicking this link: {stata "ssc install cdfplot":auto-install cdfplot}"'

    exit 199
}

// https://stats.idre.ucla.edu/stat/stata/ado/analysis)
capture : which collin
if (_rc) {
    display as error in smcl `"Please install package {it:collin} from SSC in order to run these do-files;"' _newline ///
        `"you can do so by clicking this link: {stata "net install collin":auto-install collin}"'

    exit 199
}
*/
