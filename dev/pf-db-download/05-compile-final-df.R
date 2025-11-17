library(purrr)
library(dplyr)
library(readr)
library(tibble)
library(here)
library(ggplot2)

devtools::load_all()

pet_data <- read_rds(here("dev/pf-db-download/data/pet-df-deduped.rds"))
output_dir <- here("dev/pf-db-download/data/raw-bios")
bio_files <- list.files(output_dir, pattern = "-bios\\.rds$", full.names = TRUE)

all_bios <- bio_files %>%
  set_names() %>%
  map(read_rds) %>%
  bind_rows(.id = "source_file") %>%
  mutate(source_file = basename(source_file))

all_bios <- all_bios %>% select(organization_id, pet_name, status, bio_text)

pet_data <- pet_data %>%
  left_join(all_bios, join_by(organization_id == organization_id, name == pet_name)) %>%
  select(-description, -status) %>%
  mutate(yrs_on_pf = interval(published_at, ymd("2025-11-09")) / years(1)) %>%
  mutate(tags = lapply(tags, function(x) trimws(as.character(x)))) %>%
  mutate(bio_text = gsub("^Meet.{0,30}\n    \n    \n        ", "\n", bio_text))

write_rds(pet_data, here("dev/pf-db-download/data/final-df.rds"))
