get_secret <- function(secret_name) {
  os_secret <- Sys.getenv(secret_name)
  if (os_secret == "") {
    conf <- config::get()
    x <- paws::secretsmanager(region = conf$region)
    secret <- x$get_secret_value(secret_name)
    fromJSON(secret$SecretString)[[secret_name]]
  } else {
    os_secret
  }
}
