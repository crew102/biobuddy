## R: Clients (APIs, OpenAI, Gmail)

Public functions to interact with external services used by BioBuddy.

### Authentication and headers

- **`auth_pf()`**: Obtain a Petfinder OAuth token using `PF_CLIENT_ID` and `PF_CLIENT_SECRET`.
- **`auth_pf_headers(token)`**: Build Authorization header for Petfinder requests.

Example:

```r
token <- auth_pf()
hdrs <- auth_pf_headers(token)
```

### Petfinder animals

- **`fetch_pf_pages(token, ..., pages = 1, limit = 100)`**: Fetch animals with filtering and pagination. Returns a list with `animals` (data.frame) and `pagination`.

Key parameters: `animal_id`, `type`, `name`, `organization`, `location`, `distance`, `sort`, `before_date`, `after_date`, `size`, `gender`, `age`.

Example:

```r
token <- auth_pf()
res <- fetch_pf_pages(
  token,
  type = "dog",
  location = "20723",
  distance = 100,
  sort = "recent",
  pages = 2,
  limit = 50
)
dogs <- res$animals
```

### Petfinder organizations

- **`fetch_all_orgs(token)`**: Fetch all organizations. Returns a data.frame of org attributes.
- **`fetch_some_orgs(token, organizations)`**: Fetch a subset by IDs. Returns a data.frame.

Example:

```r
token <- auth_pf()
orgs <- fetch_all_orgs(token)
some <- fetch_some_orgs(token, organizations = c("MD123", "VA456"))
```

### Petfinder bio scraping (non-API)

- **`fetch_pf_bios(urls)`**: Sequentially download bios by listing page URLs.
- **`parallel_fetch_pf_bios(urls)`**: Concurrent version using httr2.

Example:

```r
urls <- c("https://www.petfinder.com/dog/abc", "https://www.petfinder.com/dog/def")
bios <- parallel_fetch_pf_bios(urls)
```

### OpenAI requests

- **`parallel_request_rewrites(prompt_df, raw_bios, model = "gpt-4o-mini")`**: Batch chat completions; returns a character vector of rewrites aligned to `raw_bios`.
- **`generic_openai_request(prompt_df, model = "gpt-4o-mini")`**: Single chat completion; returns parsed response list.

Example:

```r
prompt <- jsonlite::read_json("app/prompts/interview.json", simplifyVector = TRUE)
prompt$content[2] <- "Write an interview-style bio for a friendly dog."
resp <- generic_openai_request(prompt)
text <- resp$choices[[1]]$message$content
```

### Email (Gmail)

- **`send_email(subject, body, to = "you@example.com")`**: Send a plain-text email via `gmailr`. Requires `GMAILR_KEY` secret and an RDS token file fetched from S3.

Example:

```r
send_email(
  subject = "Daily BioBuddy run complete",
  body = "Processed 125 dogs and generated rewrites.",
  to = "ops@example.org"
)
```

