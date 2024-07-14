FROM rocker/rstudio

WORKDIR /home/biobuddy

USER root

COPY NAMESPACE DESCRIPTION biobuddy.Rproj renv.lock .
COPY app app
COPY R R

RUN apt-get update -qq && \
  apt-get -y --no-install-recommends install \
  libmagick++-dev cron certbot python3-certbot-nginx nano

ENV EDITOR nano

RUN R -e "install.packages('renv', repos = c(CRAN = 'https://cloud.r-project.org'))"

RUN R -e "options(renv.consent = TRUE); renv::restore()"

EXPOSE 3838

CMD ["R", "-e", "shiny::runApp('app')"]
