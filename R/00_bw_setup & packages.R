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

devtools::install_github("hrbrmstr/waffle")
library(waffle)

if(!require(colorspace)){
  install.packages("colorspace")
  library(colorspace)
}

library(ggtext) ## color text in titles in figures
library(ggwaffle)

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

# Figure 1 data ---------------------------------------------------------------------
data_f1 <- data.frame(year = c(rep("1996",5), rep("2014",5)),
                      path = as_factor(c(rep(c("Partner separation",
                                               "Mothers increased earnings",
                                               "Partner lost earnings",
                                               "Mothers increased earnings & partner lost earnings",
                                               "Other member exit or lost earnings"),2))),
                      vals = c(5.89, 32.67, 17.83, 19.67, 23.93,
                               9.68, 31.10, 15.27, 26.35, 17.56),
                      prop = c(rep(6,5), rep(9,5)))  %>%
  group_by(year) %>%
  mutate(total = round(sum(vals * prop))) %>%
  ungroup()

# Figure 2 data ---------------------------------------------------------------------
data_f2  <- read_excel(file.path(dataDir, "bw_decomp.xlsx"), sheet = "tab3")


message("End of 00_bw_setup & packages") # Marks end of R Script