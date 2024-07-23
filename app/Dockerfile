FROM rocker/rstudio:4.4

WORKDIR /home/biobuddy

USER root

COPY NAMESPACE DESCRIPTION biobuddy.Rproj renv.lock config.yml .
COPY app app
COPY R R

RUN apt-get update -qq && \
  apt-get -y --no-install-recommends install \
  libmagick++-dev cron nano htop

ENV R_LIBS_USER="/home/biobuddy/renv/lib"
ENV RETICULATE_PYTHON="/home/biobuddy/.local/share/r-miniconda/envs/r-reticulate/bin/python"
ENV EDITOR=nano

RUN R -e "install.packages('renv', repos = c(CRAN = 'https://cloud.r-project.org'))"
RUN R -e "options(renv.consent = TRUE); renv::restore(library = 'renv/lib')"
RUN R -e "reticulate::install_miniconda('/home/biobuddy/.local/share/r-miniconda')"
# Alternatively, something like this (after copying in requirements.txt file):
# RUN /home/biobuddy/.local/share/r-miniconda/envs/r-reticulate/bin/pip3 install -r /home/rstudio/biobuddy-dev/aws/requirements.txt
RUN R -e "options(reticulate.conda_binary = '/home/biobuddy/.local/share/r-miniconda/bin/conda'); reticulate::conda_install('r-reticulate', c('boto3==1.34.144', 'botocore==1.34.144'))"

EXPOSE 3838

CMD ["R", "-e", "shiny::runApp('app')"]
