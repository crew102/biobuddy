## R: Server Helpers

Functions to support Shiny server logic and logging.

### Logging

- **`store_logs(logs)`**: Persists `shinylogs` session data to local file or S3 depending on `is_local()`.

Behavior:

- Local: writes `logs` JSON to `logs/<user>-<sessionid>.json` relative to project root.
- Non-local: uploads the JSON via `write_s3_file()` to the key `logs/<user>-<sessionid>.json` in the catch-all bucket.

Example (server):

```r
server <- function(input, output, session) {
  shinylogs::track_usage(storage_mode = shinylogs::store_custom(FUN = store_logs))
}
```

