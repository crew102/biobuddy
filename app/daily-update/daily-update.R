library(glue)
library(readr)
library(reticulate)
library(dplyr)
library(tibble)
library(httr2)
library(here)
library(jsonlite)

devtools::load_all()

# Manually managed file with orgs that are participating
ORG_FILE <- "app/db/orgs.csv"

BASE_IMG_DIR <- "app/db/img"
RAW_DIR <- file.path(BASE_IMG_DIR, "raw")
CROPPED_DIR <- file.path(BASE_IMG_DIR, "cropped")
REWRITES_FILE <- "app/db/rewrites.csv"
SEEN_ON_FILE <- "app/db/seen-on.csv"
EXIT_STATUS_FILE <- "app/db/run-exit-status.csv"
try(unlink(RAW_DIR, force = TRUE, recursive = TRUE))
try(unlink(CROPPED_DIR, force = TRUE, recursive = TRUE))

files_in_db <- py$list_files_in_s3(BUCKET, "app/db")
IS_FIRST_DAY <- !(REWRITES_FILE %in% files_in_db)
time_to_char <- function(x) {
  format(x, "%Y-%m-%dT%H:%M:%S+0000", tz = "utc", usetz = FALSE)
}
NOW_FORMATTED <- time_to_char(Sys.time())
EST_TIME <- format(
  Sys.time(), "%Y-%m-%d %I:%M:%S %p", tz = "US/Eastern", usetz = FALSE
)

if (IS_FIRST_DAY) {
  EXISTING_REWRITES <- tibble()
  SEEN_ON_EXISTING <- tibble()
} else {
  EXISTING_REWRITES <- read_s3_file(REWRITES_FILE, read_csv)
  EXISTING_REWRITES <- EXISTING_REWRITES %>%
    mutate(published_at = time_to_char(published_at))
  SEEN_ON_EXISTING <- read_s3_file(SEEN_ON_FILE, read_csv, col_types = "iccclic")
}

# So log ordering isn't confusing, in cases where we set logger to info level
Sys.sleep(3)

fetch_all_pf_data <- function() {
  orgs <- read_s3_file(ORG_FILE, read_csv)

  # PF DOWNLOAD
  token <- auth_pf()
  dprint("Downloading pages from PetFinder")
  some_pups <- fetch_pf_pages(
    token, organization = orgs$id,
    sort = "-recent", pages = NULL
  )
  todays_pups <- some_pups$animals

  # For now we download all bios, regardless of whether we've seen pet in past
  dprint("Fetching bios")
  raw_bios <- parallel_fetch_pf_bios(todays_pups$url)
  todays_pups$raw_bio <- clean_raw_bios(raw_bios)
  todays_pups$name <- clean_pet_name(todays_pups$name)

  # We need org name and email for filtering down to relevant bios in the app
  o <- orgs %>%
    select(id, name, email) %>%
    rename(organization_name = name, organization_email = email)
  todays_pups %>%
    left_join(o, by = c(organization_id = "id"))
}

gen_seen_on_df <- function(todays_pups) {
  todays_pups %>%
    # Some metadata cols to explain to future self why rewrites/imgs are missing
    mutate(has_primary_photo = !is.na(primary_photo_cropped_full)) %>%
    mutate(raw_bio_length = nchar(raw_bio)) %>%
    select(id, name, organization_id, published_at, has_primary_photo, raw_bio_length) %>%
    mutate(seen_on = NOW_FORMATTED)
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

download_and_crop_imgs <- function(path_df) {
  # Download raw
  dprint("Downloading raw images")
  reqs <- lapply(path_df$primary_photo_cropped_full, request)
  resps <- req_perform_parallel(
    reqs, on_error = "continue", paths = path_df$raw_path
  )
  dprint("Downloaded raw image files:")
  dprint(list.files(RAW_DIR, recursive = TRUE))

  # Resize raw
  dprint("Resizing raw images")
  dev_null <- sapply(path_df$raw_path, maybe_resize_image)

  # Crop raw image using head detector
  dat_path <- file.path("app/db", ".dog-head-detector.dat")
  py$download_file_from_s3(
    BUCKET,
    remote_path = "models/dog-head-detector.dat",
    local_path = dat_path
  )
  py_run_string(glue(
    "import dlib; detector = dlib.cnn_face_detection_model_v1('{dat_path}')"
  ))
  dprint("Cropping raw images using head detector")
  failure_ids <- crop_headshots(
    py$detector, path_df$raw_path, path_df$cropped_path
  )

  # Crop raw using alternate img if needed
  to_retry <- path_df %>% filter(id %in% failure_ids)

  if (nrow(to_retry) != 0) {
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
  dprint("Rewriting bios")
  styles <- c("interview", "pup-perspective", "sectioned")
  rw <- sapply(styles, function(x) {
    dprint(paste("Rewriting using style:", x))
    prompt_file <- here(glue("app/prompts/{x}.json"))
    prompt_df <- read_json(prompt_file, TRUE)
    parallel_request_rewrites(prompt_df, todo_pups$raw_bio, "gpt-4o-mini")
  }, simplify = FALSE, USE.NAMES = TRUE)
  rw <- as.data.frame(rw) %>%
    rename(interview_rw = interview, pupper_rw = 2, sectioned_rw = sectioned)

  todo_pups %>%
    select(
      id, name, organization_id, organization_name, organization_email,
      url, headshot_url, breeds_primary, published_at, raw_bio
    ) %>%
    bind_cols(as.data.frame(rw))
}

execute_daily_update <- function() {
  todays_pups <- fetch_all_pf_data()

  # Seen on file creation and upload
  seen_on_df <- gen_seen_on_df(todays_pups)
  seen_on_df <- bind_rows(SEEN_ON_EXISTING, seen_on_df)
  write_s3_file(
    seen_on_df, write_csv, SEEN_ON_FILE, log = "Uploading SEEN_ON_FILE"
  )

  # Remove pups we don't need to update for whatever reason
  if (nrow(EXISTING_REWRITES) == 0) {
    existing_ids <- c()
  } else {
    existing_ids <- EXISTING_REWRITES$id
  }
  todo_pups <- todays_pups %>%
    filter(!is.na(raw_bio)) %>%
    filter(!is.na(primary_photo_cropped_full)) %>%
    filter(!(id %in% existing_ids))
  if (nrow(todo_pups) == 0) {
    # The oldest five should still be the oldest five, so no need to update that
    status <- "No pups to process today, all in daily download are already in rewrites.csv"
    dprint(status)
    return(status)
  }

  path_df <- img_path_df(todo_pups)
  blacklist <- download_and_crop_imgs(path_df)

  # TODO: actually maintain a blacklist across days so we don't do this work
  # each day
  todo_pups <- todo_pups %>% filter(!(id %in% blacklist))
  if (nrow(todays_pups) == 0) {
    status <- "There were TODO pups but none had a detectible dog head in photo"
    dprint(status)
    return(status)
  }
  todo_pups <- todo_pups %>%
    mutate(headshot_url = glue("https://{BUCKET}.s3.amazonaws.com/{CROPPED_DIR}/{organization_id}/{id}.jpg"))

  todo_rewrites <- rewrite_bios(todo_pups)

  if (!IS_FIRST_DAY && nrow(todo_rewrites) > 0) {
    dprint("Not first day and > 0 bios rewritten, binding rewrite df")
    # Filter existing rewrites to only include dogs that are still in todays_pups
    todays_pup_ids <- todays_pups$id
    filtered_existing_rewrites <- EXISTING_REWRITES %>%
      filter(id %in% todays_pup_ids)
    dprint(paste(
      "Filtered existing rewrites from", nrow(EXISTING_REWRITES),
      "to", nrow(filtered_existing_rewrites), "entries"
    ))
    todo_rewrites <- todo_rewrites %>% bind_rows(filtered_existing_rewrites)
  } else if (!IS_FIRST_DAY && nrow(todo_rewrites) == 0) {
    status <- "Not first day, photos detectible, but no available bios to rewrite"
    dprint(status)
    return(status)
  } else {
    dprint("First day, no need to bind with existing rewrites")
  }

  todo_rewrites <- todo_rewrites %>%
    group_by(organization_id) %>%
    arrange(published_at) %>%
    mutate(is_oldest_five = row_number() <= 5) %>%
    ungroup() %>%
    arrange(organization_id, desc(is_oldest_five))

  dprint("Uploading CROPPED_DIR")
  py$upload_dir_to_s3(BUCKET, CROPPED_DIR, CROPPED_DIR)

  dprint("Uploading REWRITES_FILE")
  write_s3_file(todo_rewrites, write_csv, REWRITES_FILE)

  status <- "Full script run with pups updated"
  dprint(status)
  status
}

execute_and_log_daily_update <- function() {
  on.exit({
    try(unlink(RAW_DIR, force = TRUE, recursive = TRUE))
    try(unlink(CROPPED_DIR, force = TRUE, recursive = TRUE))
    try(unlink("app/db/.dog-head-detector.dat", force = TRUE))
  })

  dprint(paste("IS_FIRST_DAY is", IS_FIRST_DAY))

  status <- tryCatch({
    execute_daily_update()
  }, error = function(e) {
    print(as.character(e))
    paste("Error:", as.character(e))
  })

  status_df <- tibble(
    daily_update_time = NOW_FORMATTED,
    est_update_time = EST_TIME,
    status = status,
    home_dir = as.character(Sys.getenv()['HOME'])
  )

  dprint("Sending exit status email")
  send_email(subject = "Daily update exit status", body = status)

  dprint("Uploading exit status file")
  files_in_db <- py$list_files_in_s3(BUCKET, "app/db")
  if (IS_FIRST_DAY || !(EXIT_STATUS_FILE %in% files_in_db)) {
    write_s3_file(status_df, write_csv, EXIT_STATUS_FILE)
  } else {
    existing_status <- read_s3_file(EXIT_STATUS_FILE, read_csv, col_types = "cc")
    full_status <- bind_rows(existing_status, status_df)
    write_s3_file(full_status, write_csv, EXIT_STATUS_FILE)
  }
  dprint("Daily update done")
}

execute_and_log_daily_update()
