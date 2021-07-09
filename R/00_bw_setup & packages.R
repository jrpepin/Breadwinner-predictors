#------------------------------------------------------------------------------------
# BW PREDICTORS PROJECT
# 00_BW_setup & packages.R
# Joanna Pepin
#------------------------------------------------------------------------------------

setwd("C:/Users/Joanna/Dropbox/Repositories/Breadwinner-predictors/R")
#####################################################################################
## Install and load required packages
#####################################################################################
# The version of Rtools is assumed to be installed on your machine. 
## https://cran.r-project.org/bin/windows/Rtools/

if(!require(dplyr)){
  install.packages("dplyr")
  library(dplyr)
}

if(!require(ggplot2)){
  install.packages("ggplot2")
  library(ggplot2)
}


if(!require(readxl)){
  install.packages("readxl")
  library(readxl)
}

if(!require(haven)){
  install.packages("haven")
  library(haven)
}

if(!require(lubridate)){
  install.packages("lubridate")
  library(lubridate)
}

if(!require(ipumsr)){
  install.packages("ipumsr")
  library(ipumsr)
}

if(!require(tableone)){
  install.packages("tableone")
  library(tableone)
}

if(!require(foreign)){
  install.packages("foreign")
  library(foreign)
}

if(!require(ggeffects)){
  install.packages("ggeffects") 
  library(ggeffects)
}

if(!require(gtools)){
  install.packages("gtools")
  library(gtools)
}

if(!require(directlabels)){
  install.packages("directlabels")
  library(directlabels)
}

if(!require(nnet)){
  install.packages("nnet")
  library(nnet)
}

if(!require(srvyr)){
  install.packages("srvyr")
  library(srvyr)
}

if(!require(ggrepel)){
  install.packages("ggrepel")
  library(ggrepel)
}

if(!require(scales)){
  install.packages("scales")
  library(scales)
}

if(!require(here)){
  install.packages("here")
  library(here)
}

if(!require(conflicted)){
  devtools::install_github("r-lib/conflicted")
  library(conflicted)
}

# Address any conflicts in the packages
conflict_scout() # Identify the conflicts
conflict_prefer("here", "here")
conflict_prefer("filter", "dplyr")
conflict_prefer("remove", "base")

#####################################################################################
# Set-up the Directories
#####################################################################################
# Filepath to this project's directory
projcode <- here()

# Filepath to the directory where data is stored (NOT SHARED)
dataDir <- file.path("C:/Users/Joanna/Dropbox/Repositories/Breadwinner-predictors/output/results")


# Filepath where you want produced figures to go (NOT SHARED)
figDir  <- file.path(projcode, "output/results/figures")


#####################################################################################
# Import the data
#####################################################################################

data <- read_excel(file.path(dataDir, "Breadwinner_Predictor_Tables.xlsx"), sheet = "Table4")

message("End of 00_bw_setup & packages") # Marks end of R Script