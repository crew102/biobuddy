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

auth_pf_headers <- function(token) {
  add_headers(Authorization = paste("Bearer", token, sep = " "))
}

fdate <- function(x) {
  tm <- as.POSIXlt(ymd(x), "UTC")
  strftime(tm , "%Y-%m-%dT%H:%M:%S%z")
}

fetch_one_pf_page <- function(token, query) {
  response <- GET(
    "https://api.petfinder.com/v2/animals",
    auth_pf_headers(token),
    query = query
  )
  stop_for_status(response)
  cnt <- content(response, "text", encoding = "utf-8", flatten = TRUE)

  jsonlite::fromJSON(cnt)
}

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
                           age = NULL) {

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
    before_date = fdate(before_date),
    after_date = fdate(after_date),
    limit = limit,
    size = size,
    gender = gender,
    age = age,

    page = 1
  )

  one_res <- fetch_one_pf_page(token, query)

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
      to_pull_pages <- min(pages_res, pages)
      pb <- startpb(0, to_pull_pages)
      on.exit(closepb(pb))
      for (i in 2:to_pull_pages) {
        query$page <- i
        tryCatch({
          another_res <- fetch_one_pf_page(token, query)
          suppressWarnings(out_animals[i] <- another_res)
        }, error = function(e) {
          if (grepl("HTTP 500", e$message)) {
            Sys.sleep(10)
            another_res <- fetch_one_pf_page(token, query)
            suppressWarnings(out_animals[i] <- another_res)
          } else {
            stop(e)
          }
        })
        setpb(pb, i)
      }
    }
    unnested <- lapply(out_animals, function(x) {
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

    animals <- do.call(rbind, unnested)
    list(
      animals = animals,
      pagination = one_res$pagination
    )

  } else {
    animals <- one_res$animals %>%
      unnest_wider(where(is.data.frame), names_sep = "_") %>%
      ungroup()
    list(
      animals = animals,
      pagination = one_res$pagination
    )
  }
}

one_orgs_request <- function(token, query) {
  response <- GET(
    "https://api.petfinder.com/v2/organizations",
    auth_pf_headers(token),
    query = query
  )
  stop_for_status(response)
  cnt <- content(response, "text", encoding = "utf-8", flatten = TRUE)
  jsonlite::fromJSON(cnt)
}

fetch_all_orgs <- function(token) {

  query <- list(limit = 100, page = 1)
  one_res <- one_orgs_request(token = token, query = query)

  to_pull_pages <- one_res$pagination$total_pages

  out_animals <- list()
  suppressWarnings(out_animals[1] <- one_res)

  pb <- startpb(0, to_pull_pages)
  on.exit(closepb(pb))
  for (i in 2:to_pull_pages) {
    query$page <- i
    another_res <- one_orgs_request(token, query)
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

one_org_request <- function(id, token) {
  response <- GET(
    glue("https://api.petfinder.com/v2/organizations/{id}"),
    auth_pf_headers(token)
  )
  stop_for_status(response)
  cnt <- content(response, "text", encoding = "utf-8", flatten = TRUE)
  x <- jsonlite::fromJSON(cnt)
  as.data.frame(
    x$organization[c("id", "name", "email", "website")],
    stringsAsFactors = FALSE
  )
}

fetch_some_orgs <- function(token, organizations) {
  out <- lapply(organizations, function(x) one_org_request(x, token))
  do.call(rbind, out)
}

## Scraping PF outside of API (needed for full bios)

# Sequential

fetch_one_pf_bio <- function(url) {
  one_full_page <- GET(url, add_headers("user-agent" = USER_AGENT))
  if (http_error(one_full_page)) {
    try(return(http_status(one_full_page)$reason))
  }
  cnt <- content(one_full_page)
  bio <- xml_find_all(cnt, "//div[@data-test='Pet_Story_Section']")
  xml_text(bio)
}

fetch_pf_bios <- function(urls) {
  pbsapply(urls, function(x) {
    bio <- fetch_one_pf_bio(x)
    if (is.null(bio) || length(bio) == 0) NA else bio
  }, USE.NAMES = FALSE)
}

# Parallel

parallel_fetch_pf_bios <- function(urls) {
  # Download
  reqs <- lapply(
    urls, function(x)
      httr2::request(x) %>% httr2::req_headers("user-agent" = USER_AGENT)
  )
  resps <- httr2::req_perform_sequential(reqs, on_error = "continue")
  # Parse (not in parallel)
  sapply(resps, function(x) {
    try({
      bod <- httr2::resp_body_html(resp = x)
      bio <- xml_find_all(bod, "//div[@data-test='Pet_Story_Section']")
      bio_txt <- xml_text(bio)
      if (is.null(bio_txt) || length(bio_txt) == 0) NA else bio_txt
    })
  })
}
