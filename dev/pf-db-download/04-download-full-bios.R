library(httr2)
library(purrr)
library(dplyr)
library(readr)
library(tibble)
library(xml2)
library(here)

devtools::load_all()

pf_base <- "https://www.petfinder.com"

pet_data <- read_rds(here("dev/pf-db-download/data/pet-df-deduped.rds"))

good_desc <- pet_data %>%
  filter(!is.na(description), nchar(description) >= 20) %>%
  distinct(id, .keep_all = TRUE)

org_ids <- good_desc %>%
  distinct(organization_id) %>%
  pull()

org_ids <- sample(org_ids, length(org_ids), replace = F)

output_dir <- here("dev/pf-db-download/data/raw-bios")

if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

cookie_path <- file.path(output_dir, "pf-cookies.txt")

cat("Initializing Petfinder session...\n")
request(pf_base) %>%
  req_user_agent(USER_AGENT) %>%
  req_headers("Accept-Language" = "en-US,en;q=0.9") %>%
  req_cookie_preserve(cookie_path) %>%
  req_retry(max_tries = 5, backoff = ~ min(60, 2^.x)) %>%
  req_perform()

concurrency <- 8L
check_chunk_size <- 100L
recent_orgs <- character()
halted_early <- FALSE

build_request <- function(url) {
  request(url) %>%
    req_user_agent(USER_AGENT) %>%
    req_headers("Accept-Language" = "en-US,en;q=0.9") %>%
    req_cookie_preserve(cookie_path) %>%
    req_retry(
      max_tries = 5,
      backoff = function(i) runif(1, 0.5, 1.5) * min(60, 2^i)
    )
}

extract_story <- function(resp) {
  body <- resp_body_html(resp)
  node <- xml_find_first(body, "//div[@data-test='Pet_Story_Section']")

  if (inherits(node, "xml_missing")) {
    list(
      bio_html = NA_character_,
      bio_text = NA_character_
    )
  } else {
    list(
      bio_html = as.character(node),
      bio_text = xml_text(node, trim = TRUE)
    )
  }
}

parse_response <- function(resp, meta_row) {
  meta <- as_tibble(meta_row)
  fetched_at <- Sys.time()

  base <- meta %>%
    transmute(
      organization_id,
      pet_id = id,
      pet_name = name,
      url,
      fetched_at
    )

  if (inherits(resp, "httr2_response")) {
    status <- resp_status(resp)
    story <- if (status == 200) extract_story(resp) else list(
      bio_html = NA_character_,
      bio_text = NA_character_
    )

    base %>%
      mutate(
        status = status,
        bio_html = story$bio_html,
        bio_text = story$bio_text,
        error_message = NA_character_
      )
  } else if (inherits(resp, "condition")) {
    status <- if (!is.null(resp$response) && inherits(resp$response, "httr2_response")) {
      tryCatch(resp_status(resp$response), error = function(...) NA_integer_)
    } else {
      NA_integer_
    }

    base %>%
      mutate(
        status = status,
        bio_html = NA_character_,
        bio_text = NA_character_,
        error_message = conditionMessage(resp)
      )
  } else {
    base %>%
      mutate(
        status = NA_integer_,
        bio_html = NA_character_,
        bio_text = NA_character_,
        error_message = "Unknown response type"
      )
  }
}

for (org_id in org_ids) {
  output_path <- file.path(output_dir, paste0("org-", org_id, "-bios.rds"))

  if (file.exists(output_path)) {
    cat("Skipping", org_id, "- results already exist\n")
    next
  }

  org_rows <- good_desc %>%
    filter(organization_id == org_id) %>%
    distinct(url, .keep_all = TRUE)

  if (nrow(org_rows) == 0) {
    cat("No bios to process for", org_id, "\n")
    next
  }

  cat("Processing", org_id, "(", nrow(org_rows), "bios )\n")

  req_tbl <- org_rows %>%
    mutate(request = map(url, build_request)) %>%
    slice_sample(prop = 1)

  batches <- split(req_tbl, ceiling(seq_len(nrow(req_tbl)) / concurrency))

  org_results <- vector("list", length = 0)

  for (batch in batches) {
    responses <- req_perform_parallel(batch$request, on_error = "continue")
    batch_meta <- batch %>%
      select(organization_id, id, name, url)

    batch_results <- Map(
      parse_response,
      responses,
      split(batch_meta, seq_len(nrow(batch_meta)))
    )

    org_results <- c(org_results, batch_results)

    Sys.sleep(runif(1, 0.2, 1.2))
  }

  org_results_df <- bind_rows(org_results)

  write_rds(org_results_df, output_path, compress = "gz")
  cat("✓ Saved bios for", org_id, "\n")

  recent_orgs <- c(recent_orgs, org_id)
  if (length(recent_orgs) >= check_chunk_size) {
    chunk_files <- file.path(output_dir, paste0("org-", recent_orgs, "-bios.rds"))
    chunk_files <- chunk_files[file.exists(chunk_files)]

    if (length(chunk_files) > 0) {
      chunk_data <- chunk_files %>%
        set_names() %>%
        map(read_rds) %>%
        bind_rows(.id = "source_file")

      has_error <- !is.na(chunk_data$error_message) & nzchar(chunk_data$error_message)
      chunk_error_rate <- if (length(has_error) == 0) 0 else mean(has_error)

      cat(
        "Recent chunk of",
        length(recent_orgs),
        "orgs has error rate:",
        sprintf("%.1f%%", chunk_error_rate * 100),
        "\n"
      )

      if (!is.na(chunk_error_rate) && chunk_error_rate > 0.20) {
        cat(
          "Error rate exceeded 20% threshold. Halting further downloads.\n"
        )
        halted_early <- TRUE
        break
      }
    } else {
      cat(
        "Unable to locate bios files for the recent chunk of orgs; skipping error check.\n"
      )
    }

    recent_orgs <- character()
  }
}

if (halted_early) {
  cat("Stopped processing due to elevated error rate.\n")
} else {
  cat("All organizations processed.\n")
}

