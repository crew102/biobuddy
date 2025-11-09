library(dplyr)
library(readr)
library(here)
library(jsonlite)

devtools::load_all()

CHUNK_SIZE <- 100
OUTPUT_DIR <- here("dev/pf-db-download/raw-responses")
BASE_FILENAME <- "raw-chunk"

if (!dir.exists(OUTPUT_DIR)) {
  dir.create(OUTPUT_DIR, recursive = TRUE)
}

orgs <- read_csv(here("dev/pf-db-download/all-orgs-distinct-nov-2025.csv"))

token <- auth_pf()

# Split orgs into chunks
org_ids <- orgs %>% pull(id)
n_chunks <- ceiling(length(org_ids) / CHUNK_SIZE)

cat("Starting download of", length(org_ids), "organizations in", n_chunks, "chunks\n")
cat("Output directory:", OUTPUT_DIR, "\n\n")

# Process each chunk
for (chunk_num in 1:n_chunks) {
  start_idx <- (chunk_num - 1) * CHUNK_SIZE + 1
  end_idx <- min(chunk_num * CHUNK_SIZE, length(org_ids))
  chunk_ids <- org_ids[start_idx:end_idx]

  chunk_filename <- file.path(
    OUTPUT_DIR,
    paste0(BASE_FILENAME, "-", chunk_num, ".json")
  )

  # Check if this chunk has already been downloaded
  base_name <- tools::file_path_sans_ext(chunk_filename)
  page1_filename <- paste0(base_name, "-page1.json")
  chunk_exists <- file.exists(chunk_filename) || file.exists(page1_filename)
  if (chunk_exists) {
    cat("Chunk", chunk_num, "already downloaded, skipping...\n")
    next
  }

  cat("Processing chunk", chunk_num, "of", n_chunks,
      "(", length(chunk_ids), "orgs, IDs", start_idx, "-", end_idx, ")\n")

  # Fetch pages for this chunk
  # Use NULL for pages to fetch all available pages
  tryCatch({
    fetch_pf_pages(
      token = token,
      organization = chunk_ids,
      pages = NULL,  # Fetch all pages
      save_raw_path = chunk_filename
    )
    cat("✓ Chunk", chunk_num, "completed successfully\n\n")
  }, error = function(e) {
    cat("✗ Error in chunk", chunk_num, ":", conditionMessage(e), "\n")
    cat("Progress saved up to chunk", chunk_num - 1, "\n")
    cat("Restart this script to continue from chunk", chunk_num, "\n\n")
  })

  # Small delay between chunks to avoid rate limiting
  Sys.sleep(1)
}

cat("All chunks processed!\n")
