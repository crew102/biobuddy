## PetFinder API

auth_pf <- function() {
  token <- content(
    POST(
      "https://api.petfinder.com/v2/oauth2/token",
      body = list(
        grant_type = "client_credentials",
        "client_id" = Sys.getenv("PF_CLIENT_ID"),
        client_secret = Sys.getenv("PF_CLIENT_SECRET")
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

  fromJSON(cnt)
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
        another_res <- fetch_one_pf_page(token, query)
        suppressWarnings(out_animals[i] <- another_res)
        setpb(pb, i)
      }
    }
    unested <- lapply(out_animals, function(x) {
      x %>%
        unnest_wider(where(is.data.frame), names_sep = "_") %>%
        ungroup()
    })
    animals <- do.call(rbind, unested)
    list(animals = animals, pagination = one_res$pagination)

  } else {
    list(
      animals = one_res$animals %>%
        unnest_wider(where(is.data.frame), names_sep = "_") %>%
        ungroup(),
      pagination = one_res$pagination
    )
  }
}

one_org_request <- function(token, query) {
  response <- GET(
    "https://api.petfinder.com/v2/organizations",
    auth_pf_headers(token),
    query = query
  )
  stop_for_status(response)
  cnt <- content(response, "text", encoding = "utf-8", flatten = TRUE)
  fromJSON(cnt)
}


fetch_all_orgs <- function(token) {

  query <- list(limit = 100, page = 1)
  one_res <- one_org_request(token = token, query = query)

  to_pull_pages <- one_res$pagination$total_pages

  out_animals <- list()
  suppressWarnings(out_animals[1] <- one_res)

  pb <- startpb(0, to_pull_pages)
  on.exit(closepb(pb))
  for (i in 2:to_pull_pages) {
    query$page <- i
    another_res <- one_org_request(token, query)
    suppressWarnings(out_animals[i] <- another_res)
    setpb(pb, i)
  }

  unested <- lapply(out_animals, function(x) {
    x %>%
      select(1:social_media) %>%
      select(-hours, -url) %>%
      unnest_wider(where(is.data.frame), names_sep = "_") %>%
      ungroup()
  })
  do.call(rbind, unested) %>%
    select(!matches("address(1|2)")) %>%
    select(-adoption_url) %>%
    select(!matches("pinterest")) %>%
    rename_all(~gsub("address_|social_media_", "", .))
}

## Scraping PF outside of API (needed for full bios)
fetch_one_pf_bio <- function(url) {
  one_full_page <- GET(url)
  if (http_error(one_full_page)) {
    print('errored')
    try(return(http_status(one_full_page)$reason))
  }
  cnt <- content(one_full_page)
  zz <- xml_find_all(cnt, "//div[@data-test='Pet_Story_Section']")
  xml_text(zz)
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
  reqs <- lapply(urls, httr2::request)
  resps <- httr2::req_perform_parallel(reqs, on_error = "continue")
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

## OpenAI

fetch_one_gbt_bio <- function(input, prompt_df, model = "gpt-4-1106-preview") {
  TheOpenAIR::openai_api_key(Sys.getenv("OPENAI_API_KEY"))
  prompt_df[nrow(prompt_df), "content"] <- input
  try({
    x <- TheOpenAIR::chat_completion(prompt_df, n = 1,  model = model)
    TheOpenAIR::messages_content(x)
  })
}

fetch_gbt_bios <- function(inputs, prompt_df, model = "gpt-4-1106-preview") {
  pbsapply(inputs, function(x) fetch_one_gbt_bio(x, prompt_df, model))
}
