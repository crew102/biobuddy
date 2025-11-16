library(httr2)
library(dplyr)
library(readr)
library(here)
library(tools)

devtools::load_all()

pet_data <- read_rds(here("dev/pf-db-download/final-df.rds"))

# Filter for dogs with images
dogs_with_images <- pet_data %>%
  filter(
    !is.na(primary_photo_cropped_medium),
    nchar(primary_photo_cropped_medium) > 0
  ) %>%
  select(organization_id, name, primary_photo_cropped_medium) %>%
  distinct(organization_id, name, .keep_all = TRUE)

cat("Found", nrow(dogs_with_images), "dogs with images to download\n")

output_base_dir <- here("dev/pf-db-download/pet-images")

if (!dir.exists(output_base_dir)) {
  dir.create(output_base_dir, recursive = TRUE)
}

# Function to get file extension from URL or content type
.get_file_extension <- function(url, content_type = NULL) {
  # Try to get extension from URL first
  url_ext <- tools::file_ext(url)
  url_ext <- tolower(url_ext)

  # Common image extensions
  if (url_ext %in% c("jpg", "jpeg", "png", "gif", "webp")) {
    return(url_ext)
  }

  # If no extension in URL, try content type
  if (!is.null(content_type)) {
    if (grepl("jpeg|jpg", content_type, ignore.case = TRUE)) {
      return("jpg")
    } else if (grepl("png", content_type, ignore.case = TRUE)) {
      return("png")
    } else if (grepl("gif", content_type, ignore.case = TRUE)) {
      return("gif")
    } else if (grepl("webp", content_type, ignore.case = TRUE)) {
      return("webp")
    }
  }

  # Default to jpg if we can't determine
  return("jpg")
}

# Function to sanitize filename
.sanitize_filename <- function(name) {
  # Remove or replace invalid filename characters
  sanitized <- gsub("[^a-zA-Z0-9._-]", "_", name)
  # Remove multiple consecutive underscores
  sanitized <- gsub("_{2,}", "_", sanitized)
  # Remove leading/trailing underscores
  sanitized <- gsub("^_+|_+$", "", sanitized)
  sanitized
}

# Function to download a single image
.download_image <- function(url, org_id, pet_name, output_base_dir) {
  # Create organization directory
  org_dir <- file.path(output_base_dir, as.character(org_id))
  if (!dir.exists(org_dir)) {
    dir.create(org_dir, recursive = TRUE)
  }

  # Sanitize pet name for filename
  safe_name <- .sanitize_filename(pet_name)

  # Build request
  req <- request(url) %>%
    req_user_agent(USER_AGENT) %>%
    req_headers("Accept" = "image/*") %>%
    req_retry(
      max_tries = 3,
      backoff = function(i) runif(1, 0.5, 2) * min(10, 2^i)
    )

  # Perform request
  resp <- tryCatch(
    {
      req_perform(req)
    },
    error = function(e) {
      return(list(error = conditionMessage(e)))
    }
  )

  # Check if request failed
  if (is.list(resp) && !is.null(resp$error)) {
    cat("  ✗ Error downloading", pet_name, ":", resp$error, "\n")
    return(FALSE)
  }

  # Get content type and determine extension
  content_type <- resp_content_type(resp)
  ext <- .get_file_extension(url, content_type)

  # Build output file path
  output_file <- file.path(org_dir, paste0(safe_name, ".", ext))

  # Write image to file
  tryCatch(
    {
      resp_body_raw(resp) %>%
        writeBin(output_file)
      return(TRUE)
    },
    error = function(e) {
      cat("  ✗ Error saving", pet_name, ":", conditionMessage(e), "\n")
      return(FALSE)
    }
  )
}

# Process each dog
total <- nrow(dogs_with_images)
success_count <- 0
skip_count <- 0
error_count <- 0

for (i in seq_len(nrow(dogs_with_images))) {
  row <- dogs_with_images[i, ]
  org_id <- row$organization_id
  pet_name <- row$name
  image_url <- row$primary_photo_cropped_medium

  # Check if image already exists (restart capability)
  org_dir <- file.path(output_base_dir, as.character(org_id))
  safe_name <- .sanitize_filename(pet_name)

  # Try to determine extension from URL first
  url_ext <- .get_file_extension(image_url, NULL)
  expected_file <- file.path(org_dir, paste0(safe_name, ".", url_ext))

  # Check if file already exists
  if (file.exists(expected_file)) {
    cat(
      sprintf("[%d/%d] Skipping %s (org: %s) - already exists\n",
        i, total, pet_name, org_id)
    )
    skip_count <- skip_count + 1
    next
  }

  # Also check for any file with this base name (in case extension differs)
  if (dir.exists(org_dir)) {
    all_files <- list.files(org_dir, full.names = FALSE)
    matching_files <- all_files[grepl(
      paste0("^", gsub(".", "\\.", safe_name, fixed = TRUE), "\\."),
      all_files
    )]

    if (length(matching_files) > 0) {
      cat(
        sprintf("[%d/%d] Skipping %s (org: %s) - already exists\n",
          i, total, pet_name, org_id)
      )
      skip_count <- skip_count + 1
      next
    }
  }

  cat(
    sprintf("[%d/%d] Downloading %s (org: %s)...\n",
      i, total, pet_name, org_id)
  )

  success <- .download_image(image_url, org_id, pet_name, output_base_dir)

  if (success) {
    success_count <- success_count + 1
    cat("  ✓ Success\n")
  } else {
    error_count <- error_count + 1
  }

  # Small delay to avoid overwhelming the server
  Sys.sleep(runif(1, 0.1, 0.5))

  # Progress update every 50 images
  if (i %% 50 == 0) {
    cat(
      "\nProgress:",
      success_count, "successful,",
      skip_count, "skipped,",
      error_count, "errors\n\n"
    )
  }
}

cat("\n=== Download Complete ===\n")
cat("Successful:", success_count, "\n")
cat("Skipped (already existed):", skip_count, "\n")
cat("Errors:", error_count, "\n")
cat("Total processed:", total, "\n")

# du -h ~/Documents/git-repos/biobuddy/dev/pf-db-download/ | sort -hr
# du -h -d 1 ~/Documents/git-repos/biobuddy/dev/pf-db-download/ | sort -hr
# du -sh /Users/cbaker/Documents/git-repos/biobuddy/dev/pf-db-download/pet-images
