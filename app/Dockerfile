ARG DEPS_SHA=latest
FROM ghcr.io/crew102/bb-deps:${DEPS_SHA}

WORKDIR /home/biobuddy

LABEL org.opencontainers.image.source="https://github.com/crew102/biobuddy"

USER root

ENV EDITOR=nano
# Consider making this a config element:
ENV AWS_DEFAULT_REGION="us-east-1"

COPY NAMESPACE DESCRIPTION biobuddy.Rproj renv.lock requirements.txt ./
COPY aws/requirements.txt aws/requirements.txt
COPY app app
COPY R R
COPY db db
COPY inst inst
COPY scripts scripts

# Cron job for daily update
RUN touch /var/log/cron.log
RUN chmod +x scripts/daily-update.sh
COPY scripts/daily-update.crontab /etc/crontab

# Install any dependencies that aren't already installed
RUN R -e "options(renv.consent = TRUE); renv::restore(library = 'renv/lib')"
RUN /home/biobuddy/.local/share/r-miniconda/envs/r-reticulate/bin/pip3 install -r /home/biobuddy/requirements.txt

EXPOSE 3838

CMD ["R", "-e", "shiny::runApp('app')"]
