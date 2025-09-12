## R: Utilities (env, S3, secrets)

Helper functions for environment detection, secrets, and S3 read/write.

### Environment and configuration

- **`is_local()`**: `TRUE` if `LOCAL == "true"`.
- **`get_env()`**: Returns `"staging"` (default) or `Sys.getenv("ENVIRONMENT")`.
- **`get_url()`**: App URL based on environment. Returns local host if `is_local()`.
- **`get_version()`**: Returns the contents of `version.txt`.
- **`dprint(x, ...)`**: Convenience printer with leading/trailing newlines.

### Secrets

- **`get_secret(secret_name)`**: Returns `Sys.getenv(secret_name)` if set; otherwise uses Python `secrets.get_secret` via reticulate.

Example:

```r
api_key <- get_secret("OPENAI_API_KEY")
```

### S3 helpers

- **`read_s3_file(file, read_fun, ...)`**: Downloads `file` from S3 and parses with `read_fun`.
- **`write_s3_file(obj, write_fun, remote_path, log = NULL, ...)`**: Writes an object using `write_fun` to a temp file and uploads to S3.

Examples:

```r
# Read CSV from S3 into a tibble
rewrites <- read_s3_file("db/rewrites.csv", readr::read_csv)

# Write JSON to S3
write_s3_file(
  obj = list(ok = TRUE),
  write_fun = jsonlite::write_json,
  remote_path = "logs/check.json",
  auto_unbox = TRUE, pretty = TRUE,
  log = "Uploading status to S3"
)
```

