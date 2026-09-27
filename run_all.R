#!/usr/bin/env Rscript
# Reproduces everything in this repository from data/raw/ alone.
#   Rscript run_all.R

options(stringsAsFactors = FALSE)
dir.create("output", showWarnings = FALSE)

source("R/00_download.R")        # fetch and verify the published file
source("R/01_load.R")            # load, map zones, assert structure
source("R/02_reproduce.R")       # recompute the published descriptives
source("R/03_route_vs_vector.R") # the relationship the notebook omits

cat("\ndone.\n")
