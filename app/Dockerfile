# Docker build run in top-level dir
# Matrix version has to be 1.6-5
# magic has to be installled

FROM rocker/tidyverse:4.3.3

WORKDIR /home/app

ENV RENV_STARTUP_DIAGNOSTICS TRUE

# Matrix 1.6-5

RUN apt-get update -qq && \
  apt-get -y --no-install-recommends install libmagick++-dev

RUN R -e "install.packages('renv', repos = c(CRAN = 'https://cloud.r-project.org'))"

EXPOSE 3838

# TODO: Currently using dev code, change this in the future
COPY app/dev/app.R .
COPY renv.lock .

RUN mkdir -p renv
COPY .Rprofile .Rprofile
COPY renv/activate.R renv/activate.R
COPY renv/settings.json renv/settings.json

RUN R -e "renv::restore()"

USER root

CMD ["R", "-e", "shiny::runApp()"]
