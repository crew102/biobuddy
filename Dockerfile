FROM rocker/rstudio:4.4

WORKDIR /home/biobuddy

USER root

COPY renv.lock requirements.txt ./

ENV R_LIBS_USER="/home/biobuddy/renv/lib"
# Reminder that you use biobuddy/.venv venv instead of this env when working locally
ENV RETICULATE_PYTHON="/home/biobuddy/.local/share/r-miniconda/envs/r-reticulate/bin/python"

# Debian deps
RUN apt-get update && apt-get install -y \
  libmagick++-dev cron nano htop libz-dev libharfbuzz-dev libfribidi-dev \
  libgit2-dev cmake libcurl4-openssl-dev

# R deps
RUN R -e "install.packages('renv', repos = c(CRAN = 'https://cloud.r-project.org'))"
RUN R -e "options(renv.consent = TRUE); renv::restore(library = 'renv/lib')"

# Python deps
RUN R -e "reticulate::install_miniconda('/home/biobuddy/.local/share/r-miniconda')"
RUN /home/biobuddy/.local/share/r-miniconda/envs/r-reticulate/bin/pip3 install -r /home/biobuddy/requirements.txt