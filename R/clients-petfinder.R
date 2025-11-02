### Misc.

USER_AGENT <- paste0(
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 ",
  "KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36"
)

auth_pf <- function() {
  token <- content(
    POST(
      "https://api.petfinder.com/v2/oauth2/token",
      body = list(
        grant_type = "client_credentials",
        "client_id" = get_secret("PF_CLIENT_ID"),
        client_secret = get_secret("PF_CLIENT_SECRET")
      ),
      encode = "form"
    )
  )
  token$access_token
}

### Animals endpoint

fetch_pf_pages <- function(token,

                           animal_id = NULL,
                           type = "dog",

                           # name	Return results matching animal name (includes
                           # partial matches; e.g. "Fred" will return "Alfredo"
                           # and "Frederick")
                           name = NULL,

                           # Accepts multiple values, e.g. organization=[ID1],[ID2].
                           organization = NULL,

                           # city, state; latitude,longitude; or postal code.
                           location = NULL,

                           # Requires location to be set (default: 100, max: 500)
                           distance = NULL,

                           # recent, -recent, distance, -distance, random
                           # (default: recent)
                           sort = "random",

                           before_date = NULL,
                           after_date = NULL,

                           pages = 1,
                           limit = 100,

                           size = NULL,
                           gender = NULL,
                           age = NULL,

                           # Optional path to save raw httr response (base path for
                           # multi-page requests; page number will be appended)
                           save_raw_path = NULL) {

  if (length(organization) > 1) {
    organization <- paste0(organization, collapse = ",")
  }

  query <- list(
    animal_id = animal_id,
    type = type,
    name = name,
    organization = organization,
    location = location,
    distance = distance,
    sort = sort,
    before_date = .fdate(before_date),
    after_date = .fdate(after_date),
    limit = limit,
    size = size,
    gender = gender,
    age = age,

    page = 1
  )

  # Determine save path for first page
  page_save_path <- if (!is.null(save_raw_path)) {
    if (is.null(pages) || pages > 1) {
      # Multi-page: add page number to filename
      ext <- tools::file_ext(save_raw_path)
      if (ext != "") {
        paste0(tools::file_path_sans_ext(save_raw_path), "-page1.", ext)
      } else {
        paste0(save_raw_path, "-page1")
      }
    } else {
      save_raw_path
    }
  } else {
    NULL
  }

  one_res <- .fetch_one_pf_page(token, query, save_raw_path = page_save_path)

  if (one_res$pagination$total_count == 0) {
    return(list(
      animals = NULL,
      pagination = one_res$pagination
    ))
  }

  pages_res <- one_res$pagination$total_pages

  if (is.null(pages) || pages > 1) {

    out_animals <- list()
    suppressWarnings(out_animals[1] <- one_res)
    if (pages_res > 1) {
      to_pull_pages <- if (is.null(pages)) pages_res else min(pages_res, pages)
      pb <- startpb(0, to_pull_pages)
      on.exit(closepb(pb))
      for (i in 2:to_pull_pages) {
        query$page <- i
        # Determine save path for this page
        page_save_path_i <- if (!is.null(save_raw_path)) {
          ext <- tools::file_ext(save_raw_path)
          if (ext != "") {
            paste0(tools::file_path_sans_ext(save_raw_path), "-page", i, ".", ext)
          } else {
            paste0(save_raw_path, "-page", i)
          }
        } else {
          NULL
        }
        tryCatch({
          another_res <- .fetch_one_pf_page(token, query, save_raw_path = page_save_path_i)
          suppressWarnings(out_animals[i] <- another_res)
        }, error = function(e) {
          if (grepl("HTTP 500", e$message)) {
            Sys.sleep(10)
            another_res <- .fetch_one_pf_page(token, query, save_raw_path = page_save_path_i)
            suppressWarnings(out_animals[i] <- another_res)
          } else {
            stop(e)
          }
        })
        setpb(pb, i)
      }
    }
    animals <- .unnest_pf_animals(out_animals)
    list(
      animals = animals,
      pagination = one_res$pagination
    )

  } else {
    animals <- .unnest_pf_animals(one_res)
    list(
      animals = animals,
      pagination = one_res$pagination
    )
  }
}

.fdate <- function(x) {
  tm <- as.POSIXlt(ymd(x), "UTC")
  strftime(tm, "%Y-%m-%dT%H:%M:%S%z")
}

.auth_pf_headers <- function(token) {
  add_headers(Authorization = paste("Bearer", token, sep = " "))
}

.unnest_pf_animals <- function(page_results) {
  # page_results can be a list of page results or a single page result
  # Each page result is a full API response with $animals component
  if (!is.list(page_results)) {
    page_results <- list(page_results)
  }

  # Extract animals from each page result
  # If page_results[[1]] is an API response object with $animals component, extract it
  # Otherwise assume page_results is already a list of animal data frames
  if (length(page_results) > 0) {
    first_result <- page_results[[1]]
    # Check if first result is an API response object (has both $animals and $pagination)
    if (is.list(first_result) && !is.data.frame(first_result) &&
        !is.null(first_result$animals) && !is.null(first_result$pagination)) {
      animals_list <- lapply(page_results, function(x) x$animals)
    } else {
      animals_list <- page_results
    }
  } else {
    animals_list <- page_results
  }

  expected_cols <- c(
    "id", "organization_id", "url", "type", "species", "breeds_primary",
    "breeds_secondary", "breeds_mixed", "breeds_unknown", "colors_primary",
    "colors_secondary", "colors_tertiary", "age", "gender", "size",
    "coat", "attributes_spayed_neutered", "attributes_house_trained",
    "attributes_declawed", "attributes_special_needs", "attributes_shots_current",
    "environment_children", "environment_dogs", "environment_cats",
    "tags", "name", "description", "organization_animal_id", "photos",
    "primary_photo_cropped_small", "primary_photo_cropped_medium",
    "primary_photo_cropped_large", "primary_photo_cropped_full",
    "videos", "status", "status_changed_at", "published_at", "distance",
    "contact_email", "contact_phone", "contact_address", "_links_self",
    "_links_type", "_links_organization"
  )

  unnested <- lapply(animals_list, function(x) {
    raw_df <- x %>%
      unnest_wider(where(is.data.frame), names_sep = "_") %>%
      ungroup()
    # not super proud of this:
    existing_cols <- colnames(raw_df)
    for (col in expected_cols) {
      if (!(col %in% existing_cols)) {
        raw_df[[col]] <- NA
      }
    }
    raw_df[expected_cols]
  })

  do.call(rbind, unnested)
}

.fetch_one_pf_page <- function(token, query, save_raw_path = NULL) {
  response <- GET(
    "https://api.petfinder.com/v2/animals",
    .auth_pf_headers(token),
    query = query
  )
  stop_for_status(response)
  cnt <- content(response, "text", encoding = "utf-8", flatten = TRUE)

  if (!is.null(save_raw_path)) {
    writeLines(cnt, save_raw_path)
  }

  jsonlite::fromJSON(cnt)
}

### Organizations endpoint, getting details on all orgs on Petfinder

fetch_all_orgs <- function(token) {

  query <- list(limit = 100, page = 1)
  one_res <- .one_orgs_request(token = token, query = query)

  to_pull_pages <- one_res$pagination$total_pages

  out_animals <- list()
  suppressWarnings(out_animals[1] <- one_res)

  pb <- startpb(0, to_pull_pages)
  on.exit(closepb(pb))
  for (i in 2:to_pull_pages) {
    query$page <- i
    another_res <- .one_orgs_request(token, query)
    suppressWarnings(out_animals[i] <- another_res)
    setpb(pb, i)
  }

  unnested <- lapply(out_animals, function(x) {
    x %>%
      select(1:social_media) %>%
      select(-hours, -url) %>%
      unnest_wider(where(is.data.frame), names_sep = "_") %>%
      ungroup()
  })
  do.call(rbind, unnested) %>%
    select(!matches("address(1|2)")) %>%
    select(-adoption_url) %>%
    select(!matches("pinterest")) %>%
    rename_all(~gsub("address_|social_media_", "", .))
}

.one_orgs_request <- function(token, query) {
  response <- GET(
    "https://api.petfinder.com/v2/organizations",
    .auth_pf_headers(token),
    query = query
  )
  stop_for_status(response)
  cnt <- content(response, "text", encoding = "utf-8", flatten = TRUE)
  jsonlite::fromJSON(cnt)
}

## Scraping PF outside of API (needed for full bios)

fetch_pf_bios <- function(urls) {
  # Download
  reqs <- lapply(
    urls, function(x)
      httr2::request(x) %>% httr2::req_headers("user-agent" = USER_AGENT)
  )
  resps <- httr2::req_perform_sequential(reqs, on_error = "continue")
  # Parse
  sapply(resps, function(x) {
    try({
      bod <- httr2::resp_body_html(resp = x)
      bio <- xml_find_all(bod, "//div[@data-test='Pet_Story_Section']")
      bio_txt <- xml_text(bio)
      if (is.null(bio_txt) || length(bio_txt) == 0) NA else bio_txt
    })
  })
}
