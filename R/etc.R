get_secret <- function(secret_name) {
  os_secret <- Sys.getenv(secret_name)
  if (os_secret == "") {
    # TODO: try to get secret via boto3
    return("")
  } else {
    os_secret
  }
}
