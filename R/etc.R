get_secret <- function(secret_name) {
  os_secret <- Sys.getenv(secret_name)
  if (os_secret == "") {
    py$get_secret(secret_name)
  } else {
    os_secret
  }
}

# read arbit file on s3 into R
read_s3_file <- function(file, read_fun, ...) {
  fi <- tempfile()
  py$download_file_from_s3(BUCKET, file, fi)
  read_fun(fi, ...)
}

# write arbit r object to s3
write_s3_file <- function(obj, write_fun, remote_path, log = NULL, ...) {
  if (!is.null(log)) {
    cat("\n")
    cat(log, ...)
    cat("\n")
  }
  fi <- tempfile()
  write_fun(obj, fi, ...)
  py$upload_file_to_s3(BUCKET, remote_path = remote_path, local_path = fi)
  if (!is.null(log)) {
    cat("\n")
    cat("\tDone")
    cat("\n")
  }
}

is_local <- function() {
  Sys.getenv("LOCAL") == "true"
}

get_env <- function() {
  env <- Sys.getenv("ENVIRONMENT")
  if (env == "") {
    "staging"
  } else {
    env
  }
}

get_url <- function() {
  if (is_local()) {
    return("http://127.0.0.1:3838")
  }
  if (get_env() == "staging") {
    "biobuddydev.com"
  } else {
    "biobuddyai.com"
  }
}

get_version <- function() {
  readLines(here::here("version.txt"))
}

dprint <- function(x, ...) {
  cat("\n")
  cat(x, ...)
  cat("\n")
}
