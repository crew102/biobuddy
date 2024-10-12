store_logs <- function(logs) {
  sid <- unlist(logs$session)
  sid <- sesh[["sessionid"]]
  user <- sesh[["user"]]
  path <- paste0("logs/", user, "-", sid, ".json")
  if (is_local()) {
    write_json(path, logs)
  } else {
    write_s3_file(
      obj = logs,
      write_fun = write_json,
      remote_path = path
    )
  }
}
