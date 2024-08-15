# TODO: Create a separate deps images for prelim R/Python packages to speed
# up the build process.

FROM rocker/rstudio:4.4

WORKDIR /home/biobuddy

LABEL org.opencontainers.image.source https://github.com/crew102/biobuddy

USER root

COPY NAMESPACE DESCRIPTION biobuddy.Rproj renv.lock requirements.txt .
COPY app app
COPY R R
COPY db db

RUN apt-get update && apt-get install -y \
  libmagick++-dev cron nano htop libz-dev libharfbuzz-dev libfribidi-dev \
  libgit2-dev cmake libcurl4-openssl-dev

ENV R_LIBS_USER="/home/biobuddy/renv/lib"
ENV RETICULATE_PYTHON="/home/biobuddy/.local/share/r-miniconda/envs/r-reticulate/bin/python"
ENV EDITOR=nano

RUN R -e "install.packages('renv', repos = c(CRAN = 'https://cloud.r-project.org'))"
RUN R -e "options(renv.consent = TRUE); renv::restore(library = 'renv/lib')"
RUN R -e "reticulate::install_miniconda('/home/biobuddy/.local/share/r-miniconda')"
RUN /home/biobuddy/.local/share/r-miniconda/envs/r-reticulate/bin/pip3 install -r /home/biobuddy/requirements.txt

EXPOSE 3838

CMD ["R", "-e", "shiny::runApp('app')"]
