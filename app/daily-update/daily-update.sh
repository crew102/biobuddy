#!/bin/bash

# These envvars exist in the base image I'm using but won't get used by cron
# even though the calling environment has them populated, which is expected cron
# behavior.
export R_LIBS_USER="/home/biobuddy/renv/lib"
export RETICULATE_PYTHON="/home/biobuddy/.local/share/r-miniconda/envs/r-reticulate/bin/python"

echo "Running daily job"
cd /home/biobuddy
/usr/local/bin/Rscript app/daily-update/daily-update.R
