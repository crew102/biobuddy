library(here)
library(jsonlite)
library(glue)
library(readr)

devtools::load_all()
orgs <- c("GA553", "NH177", "VA321", "VA68")


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

# five oldest pups on PF, fetch their rewritten bios

styles <- c("interview", "pup-perspective", "sectioned")
prompt_dfs <- sapply(styles, function(x) {
  prompt_file <- here(glue("app/prompts/{x}.json"))
  read_json(prompt_file, TRUE)
}, simplify = FALSE, USE.NAMES = TRUE)

oldest_five_bios <- animals %>% filter(is_oldest_five) %>% select(id, raw_bio)

rw <- sapply(prompt_dfs, function(x) {
  parallel_request_rewrites(
    x, oldest_five_bios$raw_bio, model = "gpt-3.5-turbo-0125"
  )
}, simplify = FALSE, USE.NAMES = TRUE)

oldest_five_bios <- oldest_five_bios %>%
  mutate(
    interview_rr = rw$interview,
    pupper_rr = rw$`pup-perspective`,
    sectioned_rr = rw$sectioned
  )

# join back to animals and write selected cols
out_df <- animals %>%
  left_join(oldest_five_bios %>% select(-raw_bio)) %>%
  select(
    id, name, organization_id, url, breeds_primary, published_at, raw_bio,
    is_oldest_five, interview_rr, pupper_rr, sectioned_rr
  ) %>%
  mutate(name = gsub("[0-9]+ ", "", name))

write_csv(out_df, here("app/data/lorem-ipsum-bios.csv"))
