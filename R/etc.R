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
write_s3_file <- function(obj, write_fun, remote_path, ...) {
  fi <- tempfile()
  write_fun(obj, fi, ...)
  py$upload_file_to_s3(BUCKET, remote_path = remote_path, local_path = fi)
}
