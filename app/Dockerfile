FROM rocker/tidyverse

# TODO: Start from lighter base image, install renv, use lockfile and recreate
# env from that.
RUN /rocker_scripts/setup_R.sh https://packagemanager.posit.co/cran/__linux__/jammy/latest \
  echo "\noptions(shiny.port = 3838, shiny.host = '0.0.0.0')" >> /usr/local/lib/R/etc/Rprofile.site \
  Rscript -e "install.packages('polished', repos = 'https://packagemanager.posit.co/cran/latest')"

EXPOSE 3838

WORKDIR /home/app

USER root

# TODO: Currently using dev code, change this in the future
COPY dev/app.R .

CMD ["R", "-e", "shiny::runApp()"]
