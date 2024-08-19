library(glue)
library(readr)
library(reticulate)
library(dplyr)
library(tibble)
library(httr2)
library(here)

devtools::load_all()

BASE_DIR <- "db/img"
RAW_DIR <- file.path(BASE_DIR, "raw")
CROPPED_DIR <- file.path(BASE_DIR, "cropped")
REWRITES_FILE <- "db/rewrites.csv"
ORG_FILE <- "db/orgs.csv"
SEEN_ON_FILE <- "db/seen-on.csv"
EXIT_STATUS_FILE <- "db/run-exit-status.csv"
try(unlink(RAW_DIR, force = TRUE, recursive = TRUE))
try(unlink(CROPPED_DIR, force = TRUE, recursive = TRUE))

files_in_db <- py$list_files_in_s3(biobuddy::BUCKET, "db")
IS_FIRST_DAY <- !(REWRITES_FILE %in% files_in_db)
NOW_FORMATTED <- format(
  Sys.time(), "%Y-%m-%dT%H:%M:%S+0000", tz = "UTC", usetz = FALSE
)

pf_data <- function() {
  organization <- read_s3_file(ORG_FILE, read_csv)$id

  # PF DOWNLOAD
  token <- auth_pf()
  print("Downloading pages from PetFinder")
  some_pups <- fetch_pf_pages(
    token, organization = organization,
    sort = "-recent", pages = NULL
  )
  todays_pups <- some_pups$animals

  # For now we download all bios, regardless of whether we've seen pet in past
  # "raw" bios and names
  print("Fetching bios")
  raw_bios <- parallel_fetch_pf_bios(todays_pups$url)
  todays_pups$raw_bio <- clean_raw_bios(raw_bios)
  todays_pups$name <- clean_pet_name(todays_pups$name)
  todays_pups
}

seen_on_df <- function(todays_pups) {
  # match time format used by petfinder api
  formatted_time <- format(
    Sys.time(), "%Y-%m-%dT%H:%M:%S+0000", tz = "UTC", usetz = FALSE
  )
  seen_on_df <- todays_pups %>%
    mutate(has_primary_photo = !is.na(primary_photo_cropped_full)) %>%
    mutate(raw_bio_length = nchar(raw_bio)) %>%
    select(id, name, organization_id, published_at, has_primary_photo, raw_bio_length) %>%
    mutate(seen_on = NOW_FORMATTED)

  if (!IS_FIRST_DAY) {
    seen_on_existing <- read_s3_file(
      SEEN_ON_FILE, read_csv, col_types = "iccclic"
    )
    seen_on_df <- seen_on_df %>%
      bind_rows(seen_on_existing) %>%
      distinct()
  }

  seen_on_df
}

todo_pups <- function(todays_pups) {
  # GENERIC FILTER RE: PUPS TO KEEP
  todays_pups <- todays_pups %>% filter(!is.na(raw_bio))
  todays_pups <- todays_pups %>% filter(!is.na(primary_photo_cropped_full))

  # FILTER ON IF WE'VE DONE THEM BEFORE
  if (!IS_FIRST_DAY) {
    existing_rewrites <- read_s3_file(REWRITES_FILE, read_csv)
    existing_imgs <- py$list_files_in_s3(biobuddy::BUCKET, CROPPED_DIR)
    existing_img_ids <- try(as.numeric(gsub("\\..*", "", basename(existing_imgs))))

    rewrite_ids <- existing_rewrites %>% pull(id)
    done_pups <- rewrite_ids[rewrite_ids %in% existing_img_ids]
    todo_pups <- todays_pups %>% filter(!(id %in% done_pups))
  } else {
    todo_pups <- todays_pups
  }
  todo_pups
}

img_path_df <- function(todo_pups) {
  sapply(
    unique(todo_pups$organization_id),
    function(x) dir.create(file.path(RAW_DIR, x), recursive = TRUE)
  )
  sapply(
    unique(todo_pups$organization_id),
    function(x) dir.create(file.path(CROPPED_DIR, x), recursive = TRUE)
  )
  tibble(
    id = todo_pups$id,
    org = todo_pups$organization_id,
    primary_photo_cropped_full = todo_pups$primary_photo_cropped_full,
    photos = todo_pups$photos
  ) %>%
    mutate(
      raw_path = file.path(RAW_DIR, org, paste0(id, ".jpg")),
      cropped_path = file.path(CROPPED_DIR, org, paste0(id, ".jpg"))
    )
}

download_crop_imgs <- function(path_df) {
  # DOWNLOAD RAW
  print("Downloading raw images")
  reqs <- lapply(path_df$primary_photo_cropped_full, request)
  resps <- req_perform_parallel(
    reqs, on_error = "continue", paths = path_df$raw_path
  )
  print("Downloaded raw image files:")
  print(list.files(RAW_DIR, recursive = TRUE))

  # RESIZE RAW
  print("Resizing raw images")
  dev_null <- sapply(path_df$raw_path, maybe_resize_image)

  # CROP RAW USING HEAD DETECTOR
  dat_path <- file.path("db", ".dog-head-detector.dat")
  py$download_file_from_s3(
    biobuddy::BUCKET,
    remote_path = "models/dog-head-detector.dat",
    local_path = dat_path
  )
  py_run_string(glue(
    "detector = dlib.cnn_face_detection_model_v1('{dat_path}')"
  ))
  print("Cropping raw images")
  failure_ids <- crop_headshots(
    py$detector, path_df$raw_path, path_df$cropped_path
  )

  # CROP RAW USING ALTERNATE IMG IF NEEDED
  to_retry <- path_df %>% filter(id %in% failure_ids)

  if (length(to_retry) != 0) {
    try({
      alternatives <- to_retry %>%
        select(id, photos) %>%
        unnest(photos) %>%
        select(id, full)
      return(crop_alternate_imgs(py$detector, alternatives, path_df))
    })
  }
  vector()
}

rewrite_bios <- function(todo_pups) {
  print("Rewriting bios")
  styles <- c("interview", "pup-perspective", "sectioned")
  rw <- sapply(styles, function(x) {
    prompt_file <- here(glue("app/prompts/{x}.json"))
    prompt_df <- read_json(prompt_file, TRUE)
    parallel_request_rewrites(prompt_df, todo_pups$raw_bio, "gpt-4o-mini")
  }, simplify = FALSE, USE.NAMES = TRUE)
  rw <- as.data.frame(rw) %>%
    rename(interview_rw = interview, pupper_rw = 2, sectioned_rw = sectioned)

  todo_pups %>%
    select(
      id, name, organization_id, url, headshot_url, breeds_primary, published_at,
      raw_bio
    ) %>%
    bind_cols(as.data.frame(rw))
}

daily_update_worker <- function() {
  todays_pups <- pf_data()
  seen_on_df <- seen_on_df(todays_pups)
  todo_pups <- todo_pups(todays_pups)

  if (length(todo_pups) == 0) {
    write_s3_file(seen_on_df, write_fun = write_csv, remote_path = SEEN_ON_FILE)
    # the oldest five should still be the oldest five, so no need to update that
    return("No pups to process today")
  }
  path_df <- img_path_df(todo_pups)
  blacklist <- download_crop_imgs(path_df)

  # TODO: actually maintain a blacklist across days so we don't do this work
  # each day
  todo_pups <- todo_pups %>% filter(!(id %in% blacklist))
  todo_pups <- todo_pups %>%
    mutate(headshot_url = glue("https://{BUCKET}.s3.amazonaws.com/{CROPPED_DIR}/{organization_id}/{id}.jpg"))

  todo_rewrites <- rewrite_bios(todo_pups)

  if (!IS_FIRST_DAY) {
    existing_rewrites <- read_s3_file(REWRITES_FILE, read_csv)
    todo_rewrites <- todo_rewrites %>% bind_rows(existing_rewrites)
  }

  todo_rewrites <- todo_rewrites %>%
    group_by(organization_id) %>%
    arrange(published_at) %>%
    mutate(is_oldest_five = row_number() <= 5) %>%
    ungroup() %>%
    arrange(organization_id, desc(is_oldest_five))

  write_s3_file(seen_on_df, write_csv, SEEN_ON_FILE)
  py$upload_dir_to_s3(BUCKET, CROPPED_DIR, CROPPED_DIR)
  write_s3_file(todo_rewrites, write_csv, REWRITES_FILE)

  "Full script run with pups updated"
}

daily_update <- function() {
  status <- tryCatch({
    daily_update_worker()
  }, error = function(e) {
    paste("Error:", as.character(e))
  })

  status_df <- tibble(
    daily_update_time = NOW_FORMATTED,
    status = status
  )

  files_in_db <- py$list_files_in_s3(biobuddy::BUCKET, "db")
  if (IS_FIRST_DAY || !(EXIT_STATUS_FILE %in% files_in_db)) {
    write_s3_file(status_df, write_csv, EXIT_STATUS_FILE)
  } else {
    seen_on_existing <- read_s3_file(
      EXIT_STATUS_FILE, read_csv, col_types = "cc"
    )
    write_s3_file(
      bind_rows(seen_on_existing, status_df), write_csv, EXIT_STATUS_FILE
    )
  }
}

daily_update()
