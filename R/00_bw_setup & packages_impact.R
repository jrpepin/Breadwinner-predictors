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
projcode <- here()

# Filepath to the directory where data is stored (NOT SHARED)
dataDir <- file.path("C:/Users/Joanna/Dropbox/Repositories/Breadwinner-predictors/output/data")


# Filepath where you want produced figures to go (NOT SHARED)
figDir  <- file.path(projcode, "output/results/figures")


#####################################################################################
# Import the data
#####################################################################################

# Figure 1 data ---------------------------------------------------------------------
data_f1 <- read_excel(file.path(dataDir, "outcomes_mother_level.xlsx"), sheet = "mother-level")

# Figure 2 data ---------------------------------------------------------------------
# data_f2  <- read_excel(file.path(dataDir, "impact_tables.xlsx"), sheet = "tab3")


message("End of 00_bw_setup & packages") # Marks end of R Script