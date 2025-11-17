library(dplyr)
library(readr)
library(here)

devtools::load_all()

token <- auth_pf()
all_orgs <- fetch_all_orgs(token)

# Randomly order orgs, in case API doesn't return in a random order
all_orgs <- all_orgs %>% sample_n(nrow(.))

all_orgs %>%
  write_csv(here("dev/pf-db-download/data/all-orgs-raw-nov-2025.csv"))
all_orgs %>%
  distinct() %>%
  write_csv(here("dev/pf-db-download/data/all-orgs-distinct-nov-2025.csv"))
