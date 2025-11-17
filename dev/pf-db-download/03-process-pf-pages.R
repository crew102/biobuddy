library(dplyr)
library(readr)
library(here)
library(jsonlite)

devtools::load_all()

process_raw_pf_responses <- function(output_dir) {
  # Find all JSON files in the output directory
  json_files <- list.files(
    output_dir,
    pattern = "\\.json$",
    full.names = TRUE
  )

  if (length(json_files) == 0) {
    cat("No JSON files found in", output_dir, "\n")
    return(NULL)
  }

  cat("Processing", length(json_files), "JSON files...\n")

  # Group files by chunk
  # Files are named like: pf_raw_chunk_1.json, pf_raw_chunk_1_page1.json, etc.
  # Extract chunk number from filename
  get_chunk_num <- function(file_path) {
    basename_no_ext <- tools::file_path_sans_ext(basename(file_path))
    # Remove "_pageN" suffix if present
    basename_no_ext <- gsub("-page\\d+$", "", basename_no_ext)
    # Extract chunk number
    chunk_match <- regmatches(basename_no_ext, regexpr("\\d+$", basename_no_ext))
    if (length(chunk_match) > 0) {
      as.numeric(chunk_match)
    } else {
      NA
    }
  }

  chunk_nums <- vapply(json_files, get_chunk_num, numeric(1))
  chunk_files <- split(json_files, chunk_nums)

  all_animals <- list()

  for (chunk_num in sort(as.numeric(names(chunk_files)))) {
    chunk_file_list <- chunk_files[[as.character(chunk_num)]]
    # Sort to ensure pages are in order (single page file first, then page1, page2, etc.)
    chunk_file_list <- sort(chunk_file_list)

    # Read and parse all pages for this chunk
    chunk_pages <- lapply(chunk_file_list, function(file_path) {
      jsonlite::fromJSON(readLines(file_path))
    })

    # Process this chunk's pages
    chunk_animals <- .unnest_pf_animals(chunk_pages)
    all_animals[[as.character(chunk_num)]] <- chunk_animals

    cat("Processed chunk", chunk_num, "-", nrow(chunk_animals), "animals\n")
  }

  # Combine all chunks
  # Use bind_rows from dplyr to handle row names and missing columns gracefully
  combined_animals <- bind_rows(all_animals)

  cat("\nTotal animals processed:", nrow(combined_animals), "\n")
  return(combined_animals)
}


OUTPUT_DIR <- here("dev/pf-db-download/data/raw-responses")
proc_responses <- process_raw_pf_responses(OUTPUT_DIR)

orgs <- read_csv(here("dev/pf-db-download/data/all-orgs-distinct-nov-2025.csv"))

pet_df <- orgs %>%
  select(id, name, email, state, city, postcode, website) %>%
  rename_all(~paste0("organization_", .)) %>%
  inner_join(
    proc_responses,
    join_by(organization_id)
  ) %>%
  rename_all(~gsub("attributes_", "", .)) %>%
  arrange(organization_id, name) %>%
  select(one_of(c(
    "organization_id", "organization_name", "organization_email",
    "organization_state", "organization_city", "organization_postcode",

    "name", "id", "description", "url",
    "breeds_primary", "colors_primary", "age", "gender", "size", "coat",
    "spayed_neutered", "house_trained", "declawed", "special_needs",
    "shots_current",
    "environment_children", "environment_dogs", "environment_cats", "tags",
    "primary_photo_cropped_medium", "status_changed_at", "published_at"
  )))

pdf_df_deduped <- pet_df %>%
  mutate(bio_len = nchar(description)) %>%
  mutate(bio_len = ifelse(is.na(bio_len), 0, bio_len)) %>%
  group_by(organization_id, name) %>%
  # Don't use slice_max here, given there are ties
  arrange(desc(status_changed_at), desc(bio_len)) %>%
  slice_head(n = 1) %>%
  ungroup()

pdf_df_deduped %>%
  write_rds(here("dev/pf-db-download/data/pet-df-deduped.rds"))

