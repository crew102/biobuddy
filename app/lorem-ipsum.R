library(here)
library(jsonlite)
library(glue)
library(readr)
library(magrittr)

devtools::load_all()
orgs <- c("GA553", "NH177", "VA321", "VA68")
orgs <- c("GA553", "NH177")

token <- auth_pf()

some_pups <- fetch_pf_pages(
  token, organization = paste0(orgs, collapse = ","),
  sort = "-recent", pages = NULL
)
animals <- some_pups$animals

raw_bios <- parallel_fetch_pf_bios(animals$url)
raw_cleaned <- clean_raw_bios(raw_bios)
animals$raw_bio <- raw_cleaned

animals <- animals %>% filter(!is.na(raw_bio))
animals <- animals %>% filter(!is.na(primary_photo_cropped_large))

## write processed bio images

animals <- animals %>%
  group_by(organization_id) %>%
  arrange(published_at) %>%
  mutate(is_oldest_five = row_number() <= 5) %>%
  ungroup()

wdir <- here("app/www/.bio-images")
animals <-
  animals %>%
    rowwise() %>%
    mutate(dev_null = write_local_cropped_img(id, primary_photo_cropped_large, wdir)) %>%
    ungroup()

# fetch rewritten bios
# TODO(): refactor so i send multiple bios in one prompt
styles <- c("interview", "pup-perspective", "sectioned")
prompt_dfs <- sapply(styles, function(x) {
  prompt_file <- here(glue("app/prompts/{x}.json"))
  read_json(prompt_file, TRUE)
}, simplify = FALSE, USE.NAMES = TRUE)

rw <- sapply(prompt_dfs, function(x) {
  parallel_request_rewrites(
    x, animals$raw_bio, model = "gpt-4o"
  )
}, simplify = FALSE, USE.NAMES = TRUE)
rw <- as.data.frame(rw) %>%
  rename(interview_rw = interview, pupper_rw = 2, sectioned_rw = sectioned)

out_df <- animals %>%
  select(
    id, name, organization_id, url, breeds_primary, published_at, raw_bio,
    is_oldest_five
  ) %>%
  mutate(name = gsub("[0-9]+ ", "", name)) %>%
  bind_cols(as.data.frame(rw)) %>%
  arrange(organization_id, desc(is_oldest_five))

write_csv(out_df, here("app/data/lorem-ipsum-bios.csv"))
