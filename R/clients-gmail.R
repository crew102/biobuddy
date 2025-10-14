send_email <- function(subject, body, to = "chriscrewbaker@gmail.com") {
  token_fi <- "gmailr-token.rds"
  on.exit(try(unlink(token_fi)))
  key <- "GMAILR_KEY"
  from <- "pfanalytics787@gmail.com"
  val <- get_secret(key)
  Sys.setenv(GMAILR_KEY = val)
  py$download_file_from_s3(BUCKET, token_fi, token_fi)
  gmailr::gm_auth(token = gmailr::gm_token_read(path = token_fi, key = key))
  print(gmailr::gm_profile())

  email <-
    gmailr::gm_mime() |>
    gmailr::gm_to(to) |>
    gmailr::gm_from(from) |>
    gmailr::gm_subject(subject) |>
    gmailr::gm_text_body(body)

  gmailr::gm_send_message(email)
}
