#------------------------------------------------------------------------------------
# BW PREDICTORS PROJECT
# 00_BW_setup & packages.R
# Joanna Pepin
#------------------------------------------------------------------------------------

#####################################################################################
## Install and load required packages
#####################################################################################
# The version of Rtools is assumed to be installed on your machine. 
## https://cran.r-project.org/bin/windows/Rtools/

## install.packages("pacman")       # Install pacman package if not installed
library("pacman")                  # Load pacman package

# Install packages not yet installed & load them
pacman::p_load(
  here,
  dplyr,
  forcats,
  ggplot2,
  readxl,
  ggeffects,
  gtools, 
  ggfittext,
  directlabels,
  ggrepel,
  scales,     # percentages for ggplots axes
  colorspace, # color palettes of figures
  ggtext,
  ggh4x,      # color text of facet strips
  conflicted
)

# Address any conflicts in the packages
conflict_scout() # Identify the conflicts
conflict_prefer("here", "here")
conflict_prefer("filter", "dplyr")
conflict_prefer("remove", "base")

#####################################################################################
# Set-up the Directories
#####################################################################################
# Filepath to this project's directory
projcode <- file.path("C:/Users/Joanna/Dropbox/Repositories/Breadwinner-predictors")

# Filepath to the directory where data is stored (NOT SHARED)
dataDir <- file.path("C:/Users/Joanna/Box/Breadwinning/Predictor paper/Demography")

# Filepath where you want produced figures to go (NOT SHARED)
figDir  <- file.path(projcode, "output/results/figures")


#####################################################################################
# Import the data
#####################################################################################

# Figure 1 data ---------------------------------------------------------------------
data_f1 <- read_excel(file.path(dataDir, "Breadwinner_Predictor_Tables_Demography R&R.xlsx"), sheet = "Figure1")

# Figure 2 data ---------------------------------------------------------------------
data_f2  <- read_excel(file.path(dataDir, "Breadwinner_Predictor_Tables_Demography R&R.xlsx"), sheet = "Figure2")

message("End of 00_bw_setup & packages") # Marks end of R Script