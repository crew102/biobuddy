FROM rocker/tidyverse

WORKDIR /home/app

COPY app.R .

RUN Rscript -e "install.packages('polished')"

CMD ["R", "-e", "shiny::runApp()"]
